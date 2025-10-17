#!/usr/bin/env python3
"""
Batch processing script for Song Splitter
Processes multiple audio files in a directory
"""

import os
import sys
import argparse
from pathlib import Path
import subprocess
import json
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

def process_single_file(input_file, output_base_dir, args):
    """Process a single audio file."""
    try:
        # Create output directory for this file
        file_stem = Path(input_file).stem
        output_dir = output_base_dir / file_stem
        
        # Build command
        cmd = [
            sys.executable, 'song_splitter.py',
            str(input_file),
            '--output-dir', str(output_dir),
            '--format', args.format
        ]
        
        if args.analyze:
            cmd.append('--analyze')
        
        if args.clip_duration:
            cmd.extend(['--clip-duration', str(args.clip_duration)])
        
        print(f"🎵 Processing: {Path(input_file).name}")
        start_time = time.time()
        
        # Run processing
        result = subprocess.run(cmd, capture_output=True, text=True, cwd='python_backend')
        
        processing_time = time.time() - start_time
        
        if result.returncode == 0:
            print(f"✅ Completed: {Path(input_file).name} ({processing_time:.1f}s)")
            return {
                'file': str(input_file),
                'status': 'success',
                'processing_time': processing_time,
                'output_dir': str(output_dir)
            }
        else:
            print(f"❌ Failed: {Path(input_file).name}")
            print(f"Error: {result.stderr}")
            return {
                'file': str(input_file),
                'status': 'failed',
                'error': result.stderr
            }
            
    except Exception as e:
        print(f"❌ Exception processing {input_file}: {e}")
        return {
            'file': str(input_file),
            'status': 'error',
            'error': str(e)
        }

def main():
    parser = argparse.ArgumentParser(description='Batch process audio files for separation')
    parser.add_argument('input_dir', help='Directory containing audio files')
    parser.add_argument('--output-dir', '-o', default='./batch_output', 
                       help='Base output directory')
    parser.add_argument('--format', '-f', choices=['wav', 'mp3', 'both'], 
                       default='wav', help='Output format')
    parser.add_argument('--analyze', '-a', action='store_true', 
                       help='Perform quality analysis')
    parser.add_argument('--clip-duration', '-d', type=int, 
                       help='Process only first N seconds')
    parser.add_argument('--parallel', '-p', type=int, default=1, 
                       help='Number of parallel processes')
    parser.add_argument('--extensions', nargs='+', 
                       default=['mp3', 'wav', 'm4a', 'flac'],
                       help='File extensions to process')
    
    args = parser.parse_args()
    
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    
    if not input_dir.exists():
        print(f"❌ Input directory does not exist: {input_dir}")
        sys.exit(1)
    
    # Find audio files
    audio_files = []
    for ext in args.extensions:
        audio_files.extend(input_dir.glob(f"*.{ext}"))
        audio_files.extend(input_dir.glob(f"*.{ext.upper()}"))
    
    if not audio_files:
        print(f"❌ No audio files found in {input_dir}")
        print(f"Looking for extensions: {args.extensions}")
        sys.exit(1)
    
    print(f"🎵 Found {len(audio_files)} audio files")
    print(f"📁 Output directory: {output_dir}")
    print(f"⚡ Parallel processes: {args.parallel}")
    print(f"🎛️ Format: {args.format}")
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Process files
    results = []
    start_time = time.time()
    
    if args.parallel == 1:
        # Sequential processing
        for audio_file in audio_files:
            result = process_single_file(audio_file, output_dir, args)
            results.append(result)
    else:
        # Parallel processing
        with ThreadPoolExecutor(max_workers=args.parallel) as executor:
            futures = {
                executor.submit(process_single_file, audio_file, output_dir, args): audio_file
                for audio_file in audio_files
            }
            
            for future in as_completed(futures):
                result = future.result()
                results.append(result)
    
    total_time = time.time() - start_time
    
    # Summary
    successful = [r for r in results if r['status'] == 'success']
    failed = [r for r in results if r['status'] != 'success']
    
    print(f"\n📊 BATCH PROCESSING COMPLETE")
    print(f"Total time: {total_time:.1f}s")
    print(f"✅ Successful: {len(successful)}")
    print(f"❌ Failed: {len(failed)}")
    
    if successful:
        avg_time = sum(r['processing_time'] for r in successful) / len(successful)
        print(f"⏱️ Average processing time: {avg_time:.1f}s")
    
    # Save results
    results_file = output_dir / 'batch_results.json'
    with open(results_file, 'w') as f:
        json.dump({
            'total_files': len(audio_files),
            'successful': len(successful),
            'failed': len(failed),
            'total_time': total_time,
            'results': results
        }, f, indent=2)
    
    print(f"📝 Results saved to: {results_file}")
    
    if failed:
        print(f"\n❌ Failed files:")
        for result in failed:
            print(f"  {Path(result['file']).name}: {result.get('error', 'Unknown error')}")

if __name__ == '__main__':
    main()
