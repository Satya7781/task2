#!/usr/bin/env python3
"""
Batch Audio Separation Script
Processes multiple audio files and generates separated stems with quality analysis.
"""

import os
import sys
import json
import argparse
import time
from pathlib import Path
from typing import List, Dict
import concurrent.futures
from datetime import datetime

# Add the python_backend directory to the path
sys.path.append(str(Path(__file__).parent / "python_backend"))

from song_splitter import SongSplitter

def create_test_clip(input_file: str, output_file: str, start_time: int = 30, duration: int = 30):
    """Create a test clip from the original audio."""
    from pydub import AudioSegment
    
    try:
        audio = AudioSegment.from_file(input_file)
        
        # Extract clip (start_time to start_time + duration seconds)
        start_ms = start_time * 1000
        end_ms = (start_time + duration) * 1000
        
        # Ensure we don't exceed audio length
        if end_ms > len(audio):
            end_ms = len(audio)
            start_ms = max(0, end_ms - (duration * 1000))
        
        clip = audio[start_ms:end_ms]
        clip.export(output_file, format="mp3", bitrate="320k")
        
        print(f"✅ Created test clip: {output_file}")
        return True
    except Exception as e:
        print(f"❌ Failed to create test clip: {e}")
        return False

def process_single_file(input_file: str, output_dir: str, model_name: str = "htdemucs", 
                       export_mp3: bool = True, create_clip: bool = True) -> Dict:
    """Process a single audio file."""
    
    print(f"\n🎵 Processing: {Path(input_file).name}")
    print("=" * 50)
    
    start_time = time.time()
    
    # Initialize splitter
    splitter = SongSplitter(model_name=model_name)
    
    # Create output directory for this file
    file_output_dir = Path(output_dir) / Path(input_file).stem
    file_output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        # Separate audio
        stems = splitter.separate_audio(input_file, str(file_output_dir))
        
        # Analyze quality
        quality_metrics = splitter.analyze_quality(input_file, stems)
        
        # Detect bleed
        bleed_analysis = splitter.detect_bleed(stems)
        
        # Export to MP3 if requested
        mp3_stems = {}
        if export_mp3:
            print("\n📀 Exporting to MP3...")
            for stem_name, wav_path in stems.items():
                mp3_path = str(file_output_dir / f"{Path(input_file).stem}_{stem_name}.mp3")
                if splitter.export_to_mp3(wav_path, mp3_path):
                    mp3_stems[stem_name] = mp3_path
        
        # Create test clip
        test_clip_path = None
        if create_clip:
            test_clip_path = str(file_output_dir / f"{Path(input_file).stem}_test_clip.mp3")
            create_test_clip(input_file, test_clip_path)
        
        processing_time = time.time() - start_time
        
        # Generate quality report
        quality_report = generate_quality_report(bleed_analysis, quality_metrics)
        
        # Save results metadata
        results = {
            "input_file": input_file,
            "output_directory": str(file_output_dir),
            "model_used": model_name,
            "processing_time_seconds": round(processing_time, 2),
            "timestamp": datetime.now().isoformat(),
            "stems": {
                "wav": stems,
                "mp3": mp3_stems if export_mp3 else {}
            },
            "test_clip": test_clip_path,
            "quality_metrics": quality_metrics,
            "bleed_analysis": bleed_analysis,
            "quality_report": quality_report
        }
        
        # Save metadata
        metadata_path = file_output_dir / "separation_results.json"
        with open(metadata_path, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ Processing completed in {processing_time:.2f} seconds")
        print(f"📁 Results saved to: {file_output_dir}")
        print(f"📊 Quality report: {quality_report}")
        
        return results
        
    except Exception as e:
        print(f"❌ Error processing {input_file}: {e}")
        return {"error": str(e), "input_file": input_file}

def generate_quality_report(bleed_analysis: Dict, quality_metrics: Dict) -> str:
    """Generate a concise quality report."""
    
    good_stems = []
    bleed_stems = []
    
    for stem_name, analysis in bleed_analysis.items():
        if analysis["quality"] == "Good":
            good_stems.append(stem_name)
        else:
            bleed_stems.append(stem_name)
    
    report = f"Clean separation: {', '.join(good_stems) if good_stems else 'None'}"
    if bleed_stems:
        report += f" | Bleed detected: {', '.join(bleed_stems)}"
    
    return report

def batch_process(input_paths: List[str], output_dir: str, model_name: str = "htdemucs",
                 parallel: int = 1, export_mp3: bool = True, create_clips: bool = True) -> List[Dict]:
    """Process multiple files in batch."""
    
    print(f"🚀 Starting batch processing of {len(input_paths)} files")
    print(f"📁 Output directory: {output_dir}")
    print(f"🤖 Model: {model_name}")
    print(f"⚡ Parallel processes: {parallel}")
    print("=" * 60)
    
    # Create output directory
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    results = []
    
    if parallel > 1:
        # Parallel processing
        with concurrent.futures.ProcessPoolExecutor(max_workers=parallel) as executor:
            futures = []
            for input_file in input_paths:
                future = executor.submit(process_single_file, input_file, output_dir, 
                                       model_name, export_mp3, create_clips)
                futures.append(future)
            
            for future in concurrent.futures.as_completed(futures):
                results.append(future.result())
    else:
        # Sequential processing
        for input_file in input_paths:
            result = process_single_file(input_file, output_dir, model_name, export_mp3, create_clips)
            results.append(result)
    
    # Generate batch summary
    generate_batch_summary(results, output_dir)
    
    return results

def generate_batch_summary(results: List[Dict], output_dir: str):
    """Generate a summary report for the batch processing."""
    
    successful = [r for r in results if "error" not in r]
    failed = [r for r in results if "error" in r]
    
    summary = {
        "batch_summary": {
            "total_files": len(results),
            "successful": len(successful),
            "failed": len(failed),
            "total_processing_time": sum(r.get("processing_time_seconds", 0) for r in successful),
            "timestamp": datetime.now().isoformat()
        },
        "results": results
    }
    
    # Save batch summary
    summary_path = Path(output_dir) / "batch_summary.json"
    with open(summary_path, 'w') as f:
        json.dump(summary, f, indent=2)
    
    # Generate README
    generate_batch_readme(summary, output_dir)
    
    print(f"\n📊 Batch Summary:")
    print(f"   Total files: {len(results)}")
    print(f"   Successful: {len(successful)}")
    print(f"   Failed: {len(failed)}")
    print(f"   Total time: {summary['batch_summary']['total_processing_time']:.2f} seconds")
    print(f"📁 Summary saved to: {summary_path}")

def generate_batch_readme(summary: Dict, output_dir: str):
    """Generate README for the batch results."""
    
    readme_content = f"""# Audio Separation Results

## Batch Summary
- **Total Files Processed**: {summary['batch_summary']['total_files']}
- **Successful**: {summary['batch_summary']['successful']}
- **Failed**: {summary['batch_summary']['failed']}
- **Total Processing Time**: {summary['batch_summary']['total_processing_time']:.2f} seconds
- **Processed On**: {summary['batch_summary']['timestamp']}

## Results Structure

Each processed file creates a directory with:
- `*_vocals.wav/mp3` - Isolated vocals
- `*_drums.wav/mp3` - Drum track
- `*_bass.wav/mp3` - Bass line
- `*_other.wav/mp3` - Other instruments
- `*_test_clip.mp3` - 30-second sample from original
- `separation_results.json` - Detailed metadata and quality analysis

## Quality Analysis

Each result includes:
- **Energy Ratio**: Proportion of original energy in each stem
- **Spectral Centroid**: Brightness measure (Hz)
- **Bleed Detection**: Cross-contamination analysis
- **Quality Report**: Summary of separation effectiveness

## Download Links

"""
    
    # Add download links for each successful result
    for result in summary['results']:
        if "error" not in result:
            file_name = Path(result['input_file']).stem
            readme_content += f"### {file_name}\n"
            readme_content += f"- **Quality**: {result['quality_report']}\n"
            readme_content += f"- **Processing Time**: {result['processing_time_seconds']}s\n"
            
            # Add stem links
            if result['stems']['wav']:
                readme_content += "- **WAV Stems**:\n"
                for stem_name, path in result['stems']['wav'].items():
                    readme_content += f"  - [{stem_name}]({Path(path).name})\n"
            
            if result['stems']['mp3']:
                readme_content += "- **MP3 Stems**:\n"
                for stem_name, path in result['stems']['mp3'].items():
                    readme_content += f"  - [{stem_name}]({Path(path).name})\n"
            
            if result['test_clip']:
                readme_content += f"- **Test Clip**: [{file_name}_test_clip.mp3]({Path(result['test_clip']).name})\n"
            
            readme_content += "\n"
    
    # Save README
    readme_path = Path(output_dir) / "README.md"
    with open(readme_path, 'w') as f:
        f.write(readme_content)
    
    print(f"📖 README generated: {readme_path}")

def main():
    parser = argparse.ArgumentParser(description="Batch Audio Separation Tool")
    parser.add_argument("input", nargs="+", help="Input audio files or directories")
    parser.add_argument("--output-dir", "-o", default="./separated_audio", 
                       help="Output directory (default: ./separated_audio)")
    parser.add_argument("--model", "-m", default="htdemucs", 
                       choices=["htdemucs", "htdemucs_ft", "htdemucs_6s", "mdx_extra"],
                       help="Demucs model to use (default: htdemucs)")
    parser.add_argument("--parallel", "-p", type=int, default=1,
                       help="Number of parallel processes (default: 1)")
    parser.add_argument("--no-mp3", action="store_true", help="Skip MP3 export")
    parser.add_argument("--no-clips", action="store_true", help="Skip test clip creation")
    parser.add_argument("--analyze", "-a", action="store_true", help="Perform detailed quality analysis")
    
    args = parser.parse_args()
    
    # Collect input files
    input_files = []
    for input_path in args.input:
        path = Path(input_path)
        if path.is_file():
            input_files.append(str(path))
        elif path.is_dir():
            # Find audio files in directory
            for ext in ['.mp3', '.wav', '.m4a', '.flac', '.aac']:
                input_files.extend(str(f) for f in path.glob(f"*{ext}"))
        else:
            print(f"Warning: {input_path} not found")
    
    if not input_files:
        print("No audio files found!")
        return
    
    print(f"Found {len(input_files)} audio files to process")
    
    # Process files
    results = batch_process(
        input_files, 
        args.output_dir, 
        args.model,
        args.parallel,
        not args.no_mp3,
        not args.no_clips
    )
    
    print(f"\n🎉 Batch processing completed!")
    print(f"📁 Results available in: {args.output_dir}")

if __name__ == "__main__":
    main()
