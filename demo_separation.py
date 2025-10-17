#!/usr/bin/env python3
"""
Demo script to test audio separation with a sample file
"""

import os
import sys
from pathlib import Path
import subprocess
import tempfile
from pydub import AudioSegment
from pydub.generators import Sine

def create_demo_audio():
    """Create a simple demo audio file with multiple 'instruments'."""
    
    print("🎵 Creating demo audio file...")
    
    # Create different frequency components to simulate instruments
    duration = 10000  # 10 seconds in milliseconds
    
    # "Vocals" - mid-high frequency sine wave with some modulation
    vocals = Sine(440).to_audio_segment(duration=duration)
    vocals = vocals - 10  # Reduce volume
    
    # "Bass" - low frequency
    bass = Sine(110).to_audio_segment(duration=duration)
    bass = bass - 15
    
    # "Drums" - noise-like signal
    drums = AudioSegment.silent(duration=duration)
    for i in range(0, duration, 200):  # Every 200ms
        click = Sine(1000).to_audio_segment(duration=50) - 20
        drums = drums.overlay(click, position=i)
    
    # "Other" - mid frequency
    other = Sine(330).to_audio_segment(duration=duration)
    other = other - 12
    
    # Mix all components
    mixed = vocals.overlay(bass).overlay(drums).overlay(other)
    
    # Save demo file
    demo_path = "demo_song.wav"
    mixed.export(demo_path, format="wav")
    
    print(f"✅ Demo audio created: {demo_path}")
    return demo_path

def run_separation_demo():
    """Run a complete separation demo."""
    
    print("🚀 Audio Separation Demo")
    print("=" * 40)
    
    # Create demo audio
    demo_file = create_demo_audio()
    
    # Run separation
    print("\n🤖 Running AI separation...")
    
    cmd = [
        "python3", "batch_separate.py", 
        demo_file,
        "--output-dir", "./demo_results",
        "--analyze"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print("✅ Separation completed successfully!")
            print("\n📁 Results:")
            
            # List generated files
            results_dir = Path("./demo_results/demo_song")
            if results_dir.exists():
                for file in results_dir.iterdir():
                    print(f"   - {file.name}")
                
                # Show quality report if available
                metadata_file = results_dir / "separation_results.json"
                if metadata_file.exists():
                    import json
                    with open(metadata_file) as f:
                        data = json.load(f)
                    print(f"\n📊 Quality Report: {data.get('quality_report', 'N/A')}")
            
        else:
            print("❌ Separation failed:")
            print(result.stderr)
            
    except subprocess.TimeoutExpired:
        print("⏰ Separation timed out (5 minutes)")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Cleanup
    if os.path.exists(demo_file):
        os.remove(demo_file)
    
    print(f"\n🎉 Demo completed! Check ./demo_results/ for output files.")

if __name__ == "__main__":
    run_separation_demo()
