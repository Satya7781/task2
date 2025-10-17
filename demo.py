#!/usr/bin/env python3
"""
Demo script to test Song Splitter functionality
Creates a synthetic audio file for testing if no real audio is available
"""

import numpy as np
import soundfile as sf
import os
from pathlib import Path

def create_test_audio():
    """Create a synthetic test audio file with vocals, drums, and bass."""
    
    # Audio parameters
    duration = 30  # seconds
    sample_rate = 44100
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Create synthetic components
    # Vocals (sine wave with vibrato)
    vocals_freq = 440  # A4
    vibrato = 5  # Hz
    vocals = 0.3 * np.sin(2 * np.pi * vocals_freq * t) * (1 + 0.1 * np.sin(2 * np.pi * vibrato * t))
    
    # Drums (noise bursts at regular intervals)
    drums = np.zeros_like(t)
    beat_interval = int(sample_rate * 0.5)  # Every 0.5 seconds
    for i in range(0, len(t), beat_interval):
        if i + 1000 < len(t):
            drums[i:i+1000] = 0.5 * np.random.normal(0, 1, 1000)
    
    # Bass (low frequency sine wave)
    bass_freq = 110  # A2
    bass = 0.4 * np.sin(2 * np.pi * bass_freq * t)
    
    # Other instruments (higher frequency content)
    other = 0.2 * np.sin(2 * np.pi * 880 * t) + 0.15 * np.sin(2 * np.pi * 1320 * t)
    
    # Mix all components
    mixed = vocals + drums + bass + other
    
    # Normalize
    mixed = mixed / np.max(np.abs(mixed)) * 0.8
    
    # Make stereo
    stereo_audio = np.column_stack([mixed, mixed])
    
    return stereo_audio, sample_rate

def main():
    # Create test_audio directory
    test_dir = Path("test_audio")
    test_dir.mkdir(exist_ok=True)
    
    # Create synthetic test file
    test_file = test_dir / "synthetic_test.wav"
    
    if not test_file.exists():
        print("🎵 Creating synthetic test audio file...")
        audio, sr = create_test_audio()
        sf.write(test_file, audio, sr)
        print(f"✅ Created: {test_file}")
    else:
        print(f"✅ Test file already exists: {test_file}")
    
    print("\n🧪 Ready to test! Run one of these commands:")
    print(f"1. Quick test: ./test_separation.sh")
    print(f"2. Manual test: cd python_backend && python song_splitter.py ../{test_file} --analyze")
    print(f"3. Setup first: ./setup.sh")

if __name__ == "__main__":
    main()
