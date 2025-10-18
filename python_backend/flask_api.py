#!/usr/bin/env python3
"""
Flask API for Song Splitter - Provides REST API for the Flutter app
"""

import os
import uuid
import json
import threading
from pathlib import Path
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename
from song_splitter import SongSplitter

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
splitter = SongSplitter()

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def process_audio_async(job_id, input_path, output_dir):
    """Process audio separation in background thread."""
    try:
        processing_jobs[job_id]['status'] = 'processing'
        processing_jobs[job_id]['progress'] = 0.1
        
        # Separate audio
        stems = splitter.separate_audio(input_path, output_dir)
        processing_jobs[job_id]['progress'] = 0.8
        
        # Analyze quality
        quality_metrics = splitter.analyze_quality(input_path, stems)
        processing_jobs[job_id]['progress'] = 0.9
        
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
        target=process_audio_async,
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
        'model_loaded': splitter.model is not None,
        'device': splitter.device
    })

if __name__ == '__main__':
    print("Starting Song Splitter API...")
    print(f"Upload folder: {UPLOAD_FOLDER.absolute()}")
    print(f"Output folder: {OUTPUT_FOLDER.absolute()}")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
