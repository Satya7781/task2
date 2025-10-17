// API Configuration
const API_BASE_URL = 'http://localhost:5000/api';

// Global variables
let currentJobId = null;
let statusCheckInterval = null;

// DOM Elements
const uploadArea = document.getElementById('upload-area');
const fileInput = document.getElementById('file-input');
const fileInfo = document.getElementById('file-info');
const fileName = document.getElementById('file-name');
const fileSize = document.getElementById('file-size');
const uploadBtn = document.getElementById('upload-btn');
const processingSection = document.getElementById('processing-section');
const resultsSection = document.getElementById('results-section');
const qualitySection = document.getElementById('quality-section');
const statusText = document.getElementById('status-text');
const progressPercent = document.getElementById('progress-percent');
const progressBar = document.getElementById('progress-bar');
const stemsContainer = document.getElementById('stems-container');
const qualityMetrics = document.getElementById('quality-metrics');
const jobsList = document.getElementById('jobs-list');
const healthStatus = document.getElementById('health-status');
const audioModal = document.getElementById('audio-modal');
const audioPlayer = document.getElementById('audio-player');
const modalTitle = document.getElementById('modal-title');
const closeModal = document.getElementById('close-modal');

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    checkAPIHealth();
    loadJobsHistory();
});

function initializeEventListeners() {
    // File upload events
    uploadArea.addEventListener('click', () => fileInput.click());
    uploadArea.addEventListener('dragover', handleDragOver);
    uploadArea.addEventListener('drop', handleDrop);
    fileInput.addEventListener('change', handleFileSelect);
    uploadBtn.addEventListener('click', uploadFile);
    
    // Modal events
    closeModal.addEventListener('click', () => audioModal.classList.add('hidden'));
    audioModal.addEventListener('click', (e) => {
        if (e.target === audioModal) audioModal.classList.add('hidden');
    });
}

function handleDragOver(e) {
    e.preventDefault();
    uploadArea.classList.add('border-blue-400', 'bg-blue-50');
}

function handleDrop(e) {
    e.preventDefault();
    uploadArea.classList.remove('border-blue-400', 'bg-blue-50');
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFileSelect({ target: { files: files } });
    }
}

function handleFileSelect(e) {
    const file = e.target.files[0];
    if (!file) return;
    
    // Validate file type
    const allowedTypes = ['audio/mpeg', 'audio/wav', 'audio/mp4', 'audio/flac', 'audio/aac'];
    const allowedExtensions = ['.mp3', '.wav', '.m4a', '.flac', '.aac'];
    
    const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
    if (!allowedExtensions.includes(fileExtension)) {
        showNotification('Invalid file type. Please select an audio file.', 'error');
        return;
    }
    
    // Check file size (50MB limit)
    if (file.size > 50 * 1024 * 1024) {
        showNotification('File too large. Please select a file smaller than 50MB.', 'error');
        return;
    }
    
    // Display file info
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);
    fileInfo.classList.remove('hidden');
    
    // Store file for upload
    fileInput.file = file;
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

async function uploadFile() {
    const file = fileInput.file;
    if (!file) return;
    
    const formData = new FormData();
    formData.append('file', file);
    
    try {
        uploadBtn.disabled = true;
        uploadBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Uploading...';
        
        const response = await fetch(`${API_BASE_URL}/upload`, {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (response.ok) {
            currentJobId = result.job_id;
            showProcessingSection();
            startSeparation();
        } else {
            throw new Error(result.error || 'Upload failed');
        }
    } catch (error) {
        showNotification('Upload failed: ' + error.message, 'error');
    } finally {
        uploadBtn.disabled = false;
        uploadBtn.innerHTML = '<i class="fas fa-upload mr-2"></i>Upload';
    }
}

function showProcessingSection() {
    processingSection.classList.remove('hidden');
    updateProcessingStep(0, 'active');
    statusText.textContent = 'File uploaded successfully';
    updateProgress(10);
}

async function startSeparation() {
    try {
        const response = await fetch(`${API_BASE_URL}/separate/${currentJobId}`, {
            method: 'POST'
        });
        
        const result = await response.json();
        
        if (response.ok) {
            statusText.textContent = 'Starting AI separation...';
            updateProcessingStep(1, 'active');
            updateProgress(20);
            
            // Start polling for status
            statusCheckInterval = setInterval(checkProcessingStatus, 2000);
        } else {
            throw new Error(result.error || 'Failed to start separation');
        }
    } catch (error) {
        showNotification('Failed to start separation: ' + error.message, 'error');
    }
}

async function checkProcessingStatus() {
    try {
        const response = await fetch(`${API_BASE_URL}/status/${currentJobId}`);
        const result = await response.json();
        
        if (response.ok) {
            updateProcessingProgress(result);
            
            if (result.status === 'completed') {
                clearInterval(statusCheckInterval);
                showResults(result);
            } else if (result.status === 'failed') {
                clearInterval(statusCheckInterval);
                showNotification('Processing failed: ' + result.error, 'error');
                resetProcessing();
            }
        }
    } catch (error) {
        console.error('Status check failed:', error);
    }
}

function updateProcessingProgress(result) {
    const progress = Math.round(result.progress * 100);
    updateProgress(progress);
    progressPercent.textContent = `${progress}%`;
    
    if (result.status === 'processing') {
        if (progress > 20 && progress < 80) {
            statusText.textContent = 'AI is separating audio tracks...';
            updateProcessingStep(1, 'active');
        } else if (progress >= 80) {
            statusText.textContent = 'Analyzing quality metrics...';
            updateProcessingStep(2, 'active');
        }
    }
}

function updateProgress(percent) {
    progressBar.style.width = `${percent}%`;
}

function updateProcessingStep(stepIndex, status) {
    const steps = document.querySelectorAll('.step-item');
    const step = steps[stepIndex];
    const icon = step.querySelector('.step-icon');
    const text = step.querySelector('.step-text');
    
    // Reset all steps
    steps.forEach((s, i) => {
        if (i < stepIndex) {
            s.classList.remove('bg-gray-50');
            s.classList.add('bg-green-100');
            s.querySelector('.step-icon').classList.remove('text-gray-400');
            s.querySelector('.step-icon').classList.add('text-green-500');
        } else if (i === stepIndex && status === 'active') {
            s.classList.remove('bg-gray-50');
            s.classList.add('bg-blue-100');
            s.querySelector('.step-icon').classList.remove('text-gray-400');
            s.querySelector('.step-icon').classList.add('text-blue-500');
        }
    });
}

function showResults(result) {
    statusText.textContent = 'Processing completed successfully!';
    updateProcessingStep(2, 'completed');
    updateProgress(100);
    
    // Show results sections
    resultsSection.classList.remove('hidden');
    qualitySection.classList.remove('hidden');
    
    // Display stems
    displayStems(result.stems);
    
    // Display quality metrics
    displayQualityMetrics(result.quality_metrics);
    
    // Update jobs history
    loadJobsHistory();
}

function displayStems(stems) {
    stemsContainer.innerHTML = '';
    
    const stemIcons = {
        vocals: 'fa-microphone',
        drums: 'fa-drum',
        bass: 'fa-guitar',
        other: 'fa-music'
    };
    
    const stemColors = {
        vocals: 'from-pink-400 to-red-400',
        drums: 'from-yellow-400 to-orange-400',
        bass: 'from-green-400 to-blue-400',
        other: 'from-purple-400 to-indigo-400'
    };
    
    Object.entries(stems).forEach(([stemName, stemPath]) => {
        const stemCard = document.createElement('div');
        stemCard.className = 'stem-card bg-white rounded-lg p-6 border border-gray-200';
        
        const icon = stemIcons[stemName] || 'fa-music';
        const gradient = stemColors[stemName] || 'from-gray-400 to-gray-600';
        
        const frequencies = {
            vocals: '880Hz Sine Wave',
            drums: '220Hz Square Wave', 
            bass: '110Hz Sawtooth Wave',
            other: '440Hz Triangle Wave'
        };
        
        stemCard.innerHTML = `
            <div class="text-center">
                <div class="w-16 h-16 mx-auto mb-4 bg-gradient-to-r ${gradient} rounded-full flex items-center justify-center">
                    <i class="fas ${icon} text-2xl text-white"></i>
                </div>
                <h3 class="text-lg font-semibold capitalize mb-2">${stemName}</h3>
                <p class="text-sm text-gray-600 mb-4">Demo tone: ${frequencies[stemName] || '440Hz'}</p>
                <div class="space-y-2">
                    <button onclick="playAudio('${stemName}', '${currentJobId}')" 
                            class="w-full bg-blue-500 text-white py-2 px-4 rounded-lg hover:bg-blue-600 transition-colors">
                        <i class="fas fa-play mr-2"></i>Play Demo
                    </button>
                    <button onclick="downloadStem('${stemName}', '${currentJobId}')" 
                            class="w-full bg-green-500 text-white py-2 px-4 rounded-lg hover:bg-green-600 transition-colors">
                        <i class="fas fa-download mr-2"></i>Download
                    </button>
                </div>
            </div>
        `;
        
        stemsContainer.appendChild(stemCard);
    });
}

function displayQualityMetrics(metrics) {
    qualityMetrics.innerHTML = '';
    
    const metricIcons = {
        'Signal-to-Noise Ratio': 'fa-signal',
        'Spectral Centroid': 'fa-wave-square',
        'RMS Energy': 'fa-bolt',
        'Zero Crossing Rate': 'fa-chart-line'
    };
    
    Object.entries(metrics).forEach(([metricName, value]) => {
        const metricCard = document.createElement('div');
        metricCard.className = 'bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-4 border border-blue-200';
        
        const icon = metricIcons[metricName] || 'fa-chart-bar';
        const formattedValue = typeof value === 'number' ? value.toFixed(3) : value;
        
        metricCard.innerHTML = `
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center">
                    <i class="fas ${icon} text-white"></i>
                </div>
                <div>
                    <h4 class="font-medium text-gray-800">${metricName}</h4>
                    <p class="text-lg font-semibold text-blue-600">${formattedValue}</p>
                </div>
            </div>
        `;
        
        qualityMetrics.appendChild(metricCard);
    });
}

async function playAudio(stemName, jobId) {
    try {
        const audioUrl = `${API_BASE_URL}/download/${jobId}/${stemName}`;
        console.log('🎵 Loading audio:', audioUrl);
        
        audioPlayer.src = audioUrl;
        modalTitle.textContent = `Playing: ${stemName.charAt(0).toUpperCase() + stemName.slice(1)}`;
        audioModal.classList.remove('hidden');
        
        // Add error handling for audio loading
        audioPlayer.onerror = function(e) {
            console.error('❌ Audio loading error:', e);
            showNotification(`Failed to load ${stemName} audio. This is a demo with mock files.`, 'error');
            audioModal.classList.add('hidden');
        };
        
        audioPlayer.onloadeddata = function() {
            console.log('✅ Audio loaded successfully');
        };
        
        // Try to play
        const playPromise = audioPlayer.play();
        if (playPromise !== undefined) {
            playPromise.catch(error => {
                console.error('❌ Audio playback error:', error);
                if (error.name === 'NotSupportedError') {
                    showNotification(`${stemName} audio format not supported. This is a demo with mock files.`, 'error');
                } else {
                    showNotification(`Failed to play ${stemName}: ${error.message}`, 'error');
                }
                audioModal.classList.add('hidden');
            });
        }
        
    } catch (error) {
        console.error('❌ Play audio error:', error);
        showNotification('Failed to play audio: ' + error.message, 'error');
    }
}

async function downloadStem(stemName, jobId) {
    try {
        const downloadUrl = `${API_BASE_URL}/download/${jobId}/${stemName}`;
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = `${stemName}.wav`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showNotification(`Downloading ${stemName}...`, 'success');
    } catch (error) {
        showNotification('Download failed: ' + error.message, 'error');
    }
}

async function loadJobsHistory() {
    try {
        const response = await fetch(`${API_BASE_URL}/jobs`);
        const result = await response.json();
        
        if (response.ok) {
            displayJobsHistory(result.jobs);
        }
    } catch (error) {
        console.error('Failed to load jobs history:', error);
    }
}

function displayJobsHistory(jobs) {
    jobsList.innerHTML = '';
    
    if (jobs.length === 0) {
        jobsList.innerHTML = '<p class="text-gray-500 text-center py-4">No processing history yet</p>';
        return;
    }
    
    jobs.reverse().forEach(job => {
        const jobItem = document.createElement('div');
        jobItem.className = 'flex items-center justify-between p-4 bg-gray-50 rounded-lg';
        
        const statusColor = {
            'uploaded': 'text-blue-500',
            'processing': 'text-yellow-500',
            'completed': 'text-green-500',
            'failed': 'text-red-500'
        }[job.status] || 'text-gray-500';
        
        const statusIcon = {
            'uploaded': 'fa-upload',
            'processing': 'fa-spinner fa-spin',
            'completed': 'fa-check-circle',
            'failed': 'fa-exclamation-circle'
        }[job.status] || 'fa-question-circle';
        
        jobItem.innerHTML = `
            <div class="flex items-center space-x-3">
                <i class="fas ${statusIcon} ${statusColor}"></i>
                <div>
                    <p class="font-medium">${job.filename || 'Unknown file'}</p>
                    <p class="text-sm text-gray-600">Job ID: ${job.job_id.substring(0, 8)}...</p>
                </div>
            </div>
            <div class="flex items-center space-x-4">
                <span class="text-sm ${statusColor} capitalize">${job.status}</span>
                <span class="text-sm text-gray-500">${Math.round(job.progress * 100)}%</span>
            </div>
        `;
        
        jobsList.appendChild(jobItem);
    });
}

async function checkAPIHealth() {
    try {
        console.log('🔍 Checking API health at:', `${API_BASE_URL}/health`);
        
        const response = await fetch(`${API_BASE_URL}/health`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
            }
        });
        
        console.log('📡 API Health Response:', response.status, response.statusText);
        
        if (response.ok) {
            const result = await response.json();
            console.log('✅ API Health Data:', result);
            
            if (result.status === 'healthy') {
                healthStatus.innerHTML = `
                    <div class="w-3 h-3 bg-green-400 rounded-full"></div>
                    <span class="text-sm">API Online - ${result.device}</span>
                `;
                return;
            }
        }
        
        throw new Error(`API responded with status: ${response.status}`);
    } catch (error) {
        console.error('❌ API Health Check Failed:', error);
        healthStatus.innerHTML = `
            <div class="w-3 h-3 bg-red-400 rounded-full animate-pulse"></div>
            <span class="text-sm">API Offline - ${error.message}</span>
        `;
        
        // Show user-friendly notification
        showNotification(`API Connection Failed: ${error.message}. Make sure Flask API is running on port 5000.`, 'error');
    }
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 ${
        type === 'error' ? 'bg-red-500 text-white' :
        type === 'success' ? 'bg-green-500 text-white' :
        'bg-blue-500 text-white'
    }`;
    
    notification.innerHTML = `
        <div class="flex items-center space-x-2">
            <i class="fas ${
                type === 'error' ? 'fa-exclamation-circle' :
                type === 'success' ? 'fa-check-circle' :
                'fa-info-circle'
            }"></i>
            <span>${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

function resetProcessing() {
    processingSection.classList.add('hidden');
    resultsSection.classList.add('hidden');
    qualitySection.classList.add('hidden');
    fileInfo.classList.add('hidden');
    currentJobId = null;
    
    // Reset progress
    updateProgress(0);
    progressPercent.textContent = '0%';
    
    // Reset file input
    fileInput.value = '';
    fileInput.file = null;
}
