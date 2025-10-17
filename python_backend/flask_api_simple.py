#!/usr/bin/env python3
"""
Simplified Flask API for Song Splitter - For testing without heavy dependencies
"""

import os
import uuid
import json
import time
import threading
import struct
import wave
from pathlib import Path
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = Path('./uploads')
OUTPUT_FOLDER = Path('./outputs')
ALLOWED_EXTENSIONS = {'mp3', 'wav', 'm4a', 'flac', 'aac'}

UPLOAD_FOLDER.mkdir(exist_ok=True)
OUTPUT_FOLDER.mkdir(exist_ok=True)

# Global state for processing jobs
processing_jobs = {}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def _create_minimal_wav_file(file_path):
    """Create a minimal valid WAV file with a simple tone."""
    import math
    
    sample_rate = 44100
    duration = 2.0  # 2 seconds
    num_samples = int(sample_rate * duration)
    
    # Generate different tones for different stems
    stem_name = file_path.stem
    print(f"🎵 Creating audio for stem: {stem_name}")
    
    frequencies = {
        'vocals': 880.0,    # A5 note (high pitch)
        'drums': 220.0,     # A3 note (low pitch)  
        'bass': 110.0,      # A2 note (very low pitch)
        'other': 440.0      # A4 note (medium pitch)
    }
    
    frequency = frequencies.get(stem_name, 440.0)
    print(f"   Using frequency: {frequency}Hz")
    
    with wave.open(str(file_path), 'w') as wav_file:
        wav_file.setnchannels(2)  # Stereo
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        # Generate different waveforms for different stems
        frames = []
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Apply fade in/out to avoid clicks
            fade = min(1.0, t * 10) * min(1.0, (duration - t) * 10)
            
            # Different waveforms for different stems
            if stem_name == 'vocals':
                # Sine wave (pure tone)
                wave_value = math.sin(2 * math.pi * frequency * t)
            elif stem_name == 'drums':
                # Square wave (more percussive)
                wave_value = 1.0 if math.sin(2 * math.pi * frequency * t) > 0 else -1.0
            elif stem_name == 'bass':
                # Sawtooth wave (rich harmonics)
                wave_value = 2 * (t * frequency - math.floor(t * frequency + 0.5))
            else:  # other
                # Triangle wave
                wave_value = 2 * abs(2 * (t * frequency - math.floor(t * frequency + 0.5))) - 1
            
            amplitude = int(16384 * 0.3 * fade * wave_value)
            
            # Pack as 16-bit signed integers for stereo
            sample = struct.pack('<hh', amplitude, amplitude)
            frames.append(sample)
        
        wav_file.writeframes(b''.join(frames))

def process_audio_mock(job_id, input_path, output_dir):
    """Mock audio separation process for testing."""
    try:
        processing_jobs[job_id]['status'] = 'processing'
        processing_jobs[job_id]['progress'] = 0.1
        
        # Simulate processing time
        time.sleep(2)
        processing_jobs[job_id]['progress'] = 0.3
        
        time.sleep(2)
        processing_jobs[job_id]['progress'] = 0.6
        
        time.sleep(2)
        processing_jobs[job_id]['progress'] = 0.8
        
        # Create mock output files with minimal WAV content
        stems = {}
        stem_names = ['vocals', 'drums', 'bass', 'other']
        
        for stem_name in stem_names:
            stem_path = Path(output_dir) / f"{stem_name}.wav"
            # Create minimal valid WAV file for demo
            _create_minimal_wav_file(stem_path)
            stems[stem_name] = str(stem_path)
        
        processing_jobs[job_id]['progress'] = 0.9
        
        # Mock quality metrics
        quality_metrics = {
            'Signal-to-Noise Ratio': 23.45,
            'Spectral Centroid': 1234.56,
            'RMS Energy': 0.234,
            'Zero Crossing Rate': 0.123
        }
        
        # Update job status
        processing_jobs[job_id].update({
            'status': 'completed',
            'progress': 1.0,
            'stems': stems,
            'quality_metrics': quality_metrics
        })
        
    except Exception as e:
        processing_jobs[job_id].update({
            'status': 'failed',
            'error': str(e),
            'progress': 0.0
        })

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Upload audio file for processing."""
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    if file and allowed_file(file.filename):
        # Generate unique job ID
        job_id = str(uuid.uuid4())
        
        # Save uploaded file
        filename = secure_filename(file.filename)
        file_path = UPLOAD_FOLDER / f"{job_id}_{filename}"
        file.save(str(file_path))
        
        # Create job entry
        processing_jobs[job_id] = {
            'status': 'uploaded',
            'filename': filename,
            'file_path': str(file_path),
            'progress': 0.0
        }
        
        return jsonify({
            'job_id': job_id,
            'filename': filename,
            'status': 'uploaded'
        })
    
    return jsonify({'error': 'Invalid file type'}), 400

@app.route('/api/separate/<job_id>', methods=['POST'])
def start_separation(job_id):
    """Start audio separation process."""
    if job_id not in processing_jobs:
        return jsonify({'error': 'Job not found'}), 404
    
    job = processing_jobs[job_id]
    if job['status'] != 'uploaded':
        return jsonify({'error': 'Job already processed or in progress'}), 400
    
    # Create output directory
    output_dir = OUTPUT_FOLDER / job_id
    output_dir.mkdir(exist_ok=True)
    
    # Start processing in background thread
    thread = threading.Thread(
        target=process_audio_mock,
        args=(job_id, job['file_path'], str(output_dir))
    )
    thread.start()
    
    return jsonify({
        'job_id': job_id,
        'status': 'processing',
        'message': 'Separation started'
    })

@app.route('/api/status/<job_id>', methods=['GET'])
def get_status(job_id):
    """Get processing status for a job."""
    if job_id not in processing_jobs:
        return jsonify({'error': 'Job not found'}), 404
    
    job = processing_jobs[job_id]
    return jsonify({
        'job_id': job_id,
        'status': job['status'],
        'progress': job['progress'],
        'filename': job.get('filename', ''),
        'stems': job.get('stems', {}),
        'quality_metrics': job.get('quality_metrics', {}),
        'error': job.get('error', '')
    })

@app.route('/api/download/<job_id>/<stem_name>', methods=['GET'])
def download_stem(job_id, stem_name):
    """Download a separated stem."""
    if job_id not in processing_jobs:
        return jsonify({'error': 'Job not found'}), 404
    
    job = processing_jobs[job_id]
    if job['status'] != 'completed':
        return jsonify({'error': 'Job not completed'}), 400
    
    stems = job.get('stems', {})
    if stem_name not in stems:
        return jsonify({'error': 'Stem not found'}), 404
    
    stem_path = stems[stem_name]
    if not os.path.exists(stem_path):
        return jsonify({'error': 'File not found'}), 404
    
    return send_file(stem_path, as_attachment=True)

@app.route('/api/jobs', methods=['GET'])
def list_jobs():
    """List all processing jobs."""
    jobs = []
    for job_id, job in processing_jobs.items():
        jobs.append({
            'job_id': job_id,
            'filename': job.get('filename', ''),
            'status': job['status'],
            'progress': job['progress']
        })
    
    return jsonify({'jobs': jobs})

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'model_loaded': True,  # Mock for testing
        'device': 'cpu'
    })

if __name__ == '__main__':
    print("🚀 Starting Song Splitter API (Simple Mode)...")
    print(f"📁 Upload folder: {UPLOAD_FOLDER.absolute()}")
    print(f"📁 Output folder: {OUTPUT_FOLDER.absolute()}")
    print("🔧 Running in mock mode for testing")
    print("🌐 Server will be available at: http://localhost:5000")
    print("⏹️  Press Ctrl+C to stop")
    
    try:
        app.run(host='0.0.0.0', port=5000, debug=True)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
