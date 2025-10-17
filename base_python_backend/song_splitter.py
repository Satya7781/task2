#!/usr/bin/env python3
"""
Song Splitter - AI-Powered Audio Source Separation
Uses Demucs for high-quality audio separation into vocals, drums, bass, and other instruments.
"""

import os
import sys
import time
import json
import shutil
import librosa
import soundfile as sf
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import click
from pydub import AudioSegment
import torch
import torchaudio
from demucs.pretrained import get_model
from demucs.apply import apply_model
from mutagen import File as MutagenFile

class SongSplitter:
    def __init__(self, model_name: str = "htdemucs"):
        """Initialize the Song Splitter with specified model."""
        self.model_name = model_name
        self.model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.supported_models = {
            "htdemucs": "High-quality 4-stem separation (vocals, drums, bass, other)",
            "htdemucs_ft": "Fine-tuned version with better vocal separation", 
            "htdemucs_6s": "6-stem separation (vocals, drums, bass, piano, guitar, other)",
            "mdx_extra": "Extra quality model for vocals and accompaniment"
        }
        print(f"Using device: {self.device}")
        
    def load_model(self):
        """Load the Demucs model."""
        if self.model is None:
            print(f"Loading {self.model_name} model...")
            self.model = get_model(self.model_name)
            self.model.to(self.device)
            print("Model loaded successfully!")
    
    def separate_audio(self, input_path: str, output_dir: str) -> Dict[str, str]:
        """
        Separate audio into stems using Demucs.
        
        Args:
            input_path: Path to input audio file
            output_dir: Directory to save separated stems
            
        Returns:
            Dictionary mapping stem names to file paths
        """
        self.load_model()
        
        input_path = Path(input_path)
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Processing: {input_path.name}")
        
        # Load audio
        waveform, sample_rate = torchaudio.load(input_path)
        
        # Convert to the model's expected format
        if waveform.shape[0] == 1:  # Mono to stereo
            waveform = waveform.repeat(2, 1)
        elif waveform.shape[0] > 2:  # Multi-channel to stereo
            waveform = waveform[:2]
            
        # Resample if necessary
        if sample_rate != self.model.samplerate:
            resampler = torchaudio.transforms.Resample(sample_rate, self.model.samplerate)
            waveform = resampler(waveform)
            sample_rate = self.model.samplerate
        
        # Move to device
        waveform = waveform.to(self.device)
        
        # Apply separation
        print("Separating audio...")
        start_time = time.time()
        
        with torch.no_grad():
            sources = apply_model(self.model, waveform.unsqueeze(0), device=self.device)[0]
        
        separation_time = time.time() - start_time
        print(f"Separation completed in {separation_time:.2f} seconds")
        
        # Save stems
        stem_names = ["drums", "bass", "other", "vocals"]
        stem_paths = {}
        
        for i, stem_name in enumerate(stem_names):
            stem_audio = sources[i].cpu()
            stem_path = output_dir / f"{input_path.stem}_{stem_name}.wav"
            
            # Save as WAV
            torchaudio.save(str(stem_path), stem_audio, sample_rate)
            stem_paths[stem_name] = str(stem_path)
            
            print(f"Saved {stem_name}: {stem_path}")
        
        return stem_paths
    
    def analyze_quality(self, original_path: str, stems: Dict[str, str]) -> Dict[str, float]:
        """
        Analyze separation quality by measuring spectral energy distribution.
        
        Returns:
            Dictionary with quality metrics for each stem
        """
        print("Analyzing separation quality...")
        
        # Load original audio
        original, sr = librosa.load(original_path, sr=22050)
        original_stft = np.abs(librosa.stft(original))
        
        quality_metrics = {}
        
        for stem_name, stem_path in stems.items():
            # Load stem
            stem_audio, _ = librosa.load(stem_path, sr=22050)
            stem_stft = np.abs(librosa.stft(stem_audio))
            
            # Calculate energy ratio (stem energy / original energy)
            stem_energy = np.sum(stem_stft ** 2)
            original_energy = np.sum(original_stft ** 2)
            energy_ratio = stem_energy / original_energy if original_energy > 0 else 0
            
            # Calculate spectral centroid (brightness measure)
            spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=stem_audio, sr=sr))
            
            quality_metrics[stem_name] = {
                "energy_ratio": float(energy_ratio),
                "spectral_centroid": float(spectral_centroid),
                "rms_energy": float(np.sqrt(np.mean(stem_audio ** 2)))
            }
        
        return quality_metrics
    
    def detect_bleed(self, stems: Dict[str, str]) -> Dict[str, str]:
        """
        Detect audio bleed between stems and provide quality assessment.
        
        Returns:
            Dictionary with bleed analysis for each stem
        """
        print("Detecting audio bleed...")
        
        bleed_analysis = {}
        
        for stem_name, stem_path in stems.items():
            # Load stem audio
            stem_audio, sr = librosa.load(stem_path, sr=22050)
            
            # Calculate various quality indicators
            rms_energy = np.sqrt(np.mean(stem_audio ** 2))
            spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=stem_audio, sr=sr))
            zero_crossing_rate = np.mean(librosa.feature.zero_crossing_rate(stem_audio))
            
            # Determine quality based on stem type and characteristics
            if stem_name == "vocals":
                # Vocals should have higher spectral centroid and moderate energy
                quality = "Good" if spectral_centroid > 1500 and rms_energy > 0.01 else "Some bleed detected"
                notes = "Clean vocal separation" if quality == "Good" else "May contain instrumental bleed"
            elif stem_name == "drums":
                # Drums should have high energy and high zero crossing rate
                quality = "Good" if rms_energy > 0.02 and zero_crossing_rate > 0.1 else "Some bleed detected"
                notes = "Clean drum separation" if quality == "Good" else "May contain other instruments"
            elif stem_name == "bass":
                # Bass should have low spectral centroid and good energy
                quality = "Good" if spectral_centroid < 800 and rms_energy > 0.005 else "Some bleed detected"
                notes = "Clean bass separation" if quality == "Good" else "May contain mid-frequency bleed"
            else:  # other
                # Other should contain remaining instruments
                quality = "Good" if rms_energy > 0.01 else "Weak separation"
                notes = "Contains remaining instruments" if quality == "Good" else "Low energy, check separation"
            
            bleed_analysis[stem_name] = {
                "quality": quality,
                "notes": notes,
                "rms_energy": float(rms_energy),
                "spectral_centroid": float(spectral_centroid),
                "zero_crossing_rate": float(zero_crossing_rate)
            }
        
        return bleed_analysis
    
    def export_to_mp3(self, wav_path: str, mp3_path: str, bitrate: str = "320k"):
        """Convert WAV to MP3 using pydub."""
        try:
            audio = AudioSegment.from_wav(wav_path)
            audio.export(mp3_path, format="mp3", bitrate=bitrate)
            print(f"Exported MP3: {mp3_path}")
            return True
        except Exception as e:
            print(f"Failed to export MP3: {e}")
            return False
    
    def convert_to_mp3(self, wav_path: str, mp3_path: str, bitrate: str = "320k"):
        """Convert WAV file to MP3."""
        audio = AudioSegment.from_wav(wav_path)
        audio.export(mp3_path, format="mp3", bitrate=bitrate)
    
    def get_audio_info(self, file_path: str) -> Dict:
        """Get audio file metadata."""
        try:
            audio_file = MutagenFile(file_path)
            info = {
                "duration": 0,
                "bitrate": 0,
                "sample_rate": 0,
                "channels": 0
            }
            
            if audio_file is not None and hasattr(audio_file, 'info'):
                info["duration"] = getattr(audio_file.info, 'length', 0)
                info["bitrate"] = getattr(audio_file.info, 'bitrate', 0)
                info["sample_rate"] = getattr(audio_file.info, 'sample_rate', 0)
                info["channels"] = getattr(audio_file.info, 'channels', 0)
            
            return info
        except Exception as e:
            print(f"Error getting audio info: {e}")
            return {"duration": 0, "bitrate": 0, "sample_rate": 0, "channels": 0}

@click.command()
@click.argument('input_file', type=click.Path(exists=True))
@click.option('--output-dir', '-o', default='./output', help='Output directory for separated stems')
@click.option('--model', '-m', default='htdemucs', help='Demucs model to use (htdemucs, mdx_extra, etc.)')
@click.option('--format', '-f', type=click.Choice(['wav', 'mp3', 'both']), default='wav', help='Output format')
@click.option('--analyze', '-a', is_flag=True, help='Perform quality analysis')
@click.option('--clip-duration', '-d', type=int, help='Process only first N seconds (for testing)')
def main(input_file, output_dir, model, format, analyze, clip_duration):
    """
    Song Splitter - Separate audio into vocals, drums, bass, and other instruments.
    
    Example usage:
        python song_splitter.py input.mp3 -o ./stems --format both --analyze
    """
    
    input_path = Path(input_file)
    output_path = Path(output_dir)
    
    # Create clip if duration specified
    if clip_duration:
        clip_path = output_path / f"{input_path.stem}_clip.wav"
        output_path.mkdir(parents=True, exist_ok=True)
        
        print(f"Creating {clip_duration}s clip...")
        audio = AudioSegment.from_file(str(input_path))
        clip = audio[:clip_duration * 1000]  # Convert to milliseconds
        clip.export(str(clip_path), format="wav")
        input_path = clip_path
    
    # Initialize splitter
    splitter = SongSplitter(model_name=model)
    
    try:
        # Get original audio info
        original_info = splitter.get_audio_info(str(input_path))
        print(f"Input: {input_path.name}")
        print(f"Duration: {original_info['duration']:.2f}s, Sample Rate: {original_info['sample_rate']}Hz")
        
        # Separate audio
        stems = splitter.separate_audio(str(input_path), str(output_path))
        
        # Convert to MP3 if requested
        if format in ['mp3', 'both']:
            print("Converting to MP3...")
            for stem_name, wav_path in stems.items():
                mp3_path = str(Path(wav_path).with_suffix('.mp3'))
                splitter.convert_to_mp3(wav_path, mp3_path)
                if format == 'mp3':
                    os.remove(wav_path)  # Remove WAV if only MP3 requested
                    stems[stem_name] = mp3_path
        
        # Quality analysis
        if analyze:
            quality_metrics = splitter.analyze_quality(str(input_path), stems)
            
            print("\n=== QUALITY ANALYSIS ===")
            for stem_name, metrics in quality_metrics.items():
                energy = metrics['energy_ratio']
                rms = metrics['rms_energy']
                print(f"{stem_name.upper()}: Energy={energy:.3f}, RMS={rms:.4f}")
                
                # Simple quality assessment
                if stem_name == "vocals" and energy > 0.1:
                    print(f"  ✓ Good vocal separation")
                elif stem_name == "drums" and energy > 0.15:
                    print(f"  ✓ Good drum separation")
                elif stem_name in ["bass", "other"] and energy > 0.05:
                    print(f"  ✓ Decent {stem_name} separation")
                else:
                    print(f"  ⚠ Low energy - possible bleed or weak source")
        
        # Summary
        print(f"\n=== SEPARATION COMPLETE ===")
        print(f"Output directory: {output_path}")
        print("Separated stems:")
        for stem_name, path in stems.items():
            file_size = os.path.getsize(path) / (1024 * 1024)  # MB
            print(f"  {stem_name}: {Path(path).name} ({file_size:.1f} MB)")
        
        # Save metadata
        metadata = {
            "input_file": str(input_path),
            "model_used": model,
            "stems": stems,
            "original_info": original_info,
            "processing_time": time.time()
        }
        
        if analyze:
            metadata["quality_metrics"] = quality_metrics
        
        metadata_path = output_path / f"{input_path.stem}_metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"Metadata saved: {metadata_path}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
