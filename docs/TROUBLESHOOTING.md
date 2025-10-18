# Troubleshooting Guide - AI Song Splitter

## Common Issues and Solutions

### 1. Connection Refused Errors (ERR_CONNECTION_REFUSED)

**Problem**: Web demo shows "Failed to load resource: net::ERR_CONNECTION_REFUSED"

**Solutions**:

#### Option A: Use the Startup Script (Recommended)
```bash
cd /home/igris/sandesh_2/song_splitter
./start_demo.sh
```

#### Option B: Manual Startup
```bash
# Terminal 1 - Start Flask API
cd python_backend
python3 flask_api_simple.py

# Terminal 2 - Start Web Demo
cd demo_web  
python3 server.py
```

#### Option C: Check if Services are Running
```bash
# Check if Flask API is running
curl http://localhost:5000/api/health

# Check if web server is running  
curl http://localhost:8080
```

### 2. Python Dependencies Issues

**Problem**: Import errors or missing modules

**Solutions**:

#### Install Required Packages
```bash
# For basic functionality (Flask API)
pip3 install flask flask-cors

# For full AI functionality
pip3 install torch torchaudio demucs librosa soundfile
```

#### Use Virtual Environment (Recommended)
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r python_backend/requirements.txt
```

### 3. Mobile App Connection Issues

**Problem**: Flutter app can't connect to API

**Solutions**:

#### Check API Configuration
The mobile app is configured to use `http://localhost:5000/api`. Make sure:
- Flask API is running on port 5000
- No firewall blocking the connection
- Using correct IP address for device testing

#### For Physical Device Testing
Update the API URL in `lib/services/audio_separation_service.dart`:
```dart
static const String _baseUrl = 'http://YOUR_COMPUTER_IP:5000/api';
```

#### Test API Connection
```bash
# From the mobile device/emulator
curl http://localhost:5000/api/health
```

### 4. File Upload Issues

**Problem**: Files won't upload or processing fails

**Solutions**:

#### Check File Format
Supported formats:
- MP3 (.mp3)
- WAV (.wav)  
- M4A (.m4a)
- FLAC (.flac)
- AAC (.aac)

#### Check File Size
- Maximum file size: 50MB
- For larger files, compress or use a shorter clip

#### Check Disk Space
```bash
df -h  # Check available disk space
```

### 5. Processing Stuck or Slow

**Problem**: Audio separation takes too long or gets stuck

**Solutions**:

#### Use Mock Mode for Testing
The simplified API (`flask_api_simple.py`) runs in mock mode for testing without heavy AI processing.

#### For Real AI Processing
Use the full API (`flask_api.py`) but ensure:
- Sufficient RAM (8GB+ recommended)
- GPU support for faster processing (optional)
- Stable internet for downloading AI models

### 6. Audio Playback Issues

**Problem**: Separated stems won't play in web demo

**Solutions**:

#### Browser Compatibility
- Use Chrome 90+ or Firefox 88+
- Enable audio permissions
- Check browser console for errors

#### Audio File Issues
- Ensure stems were generated successfully
- Check if files exist in the output directory
- Verify file permissions

### 7. Favicon 404 Error

**Problem**: Browser shows favicon.ico not found

**Solution**: ✅ **FIXED** - Added `favicon.svg` to the demo

### 8. Port Already in Use

**Problem**: "Address already in use" error

**Solutions**:

#### Find and Kill Existing Processes
```bash
# Find processes using port 5000
lsof -i :5000
kill -9 <PID>

# Find processes using port 8080  
lsof -i :8080
kill -9 <PID>
```

#### Use Different Ports
Edit the configuration files to use different ports if needed.

## Testing Checklist

### ✅ API Backend
- [ ] Flask API starts without errors
- [ ] Health endpoint responds: `curl http://localhost:5000/api/health`
- [ ] Jobs endpoint responds: `curl http://localhost:5000/api/jobs`

### ✅ Web Demo  
- [ ] Web server starts on port 8080
- [ ] Page loads without JavaScript errors
- [ ] API status shows "Online" 
- [ ] File upload works
- [ ] Processing progress updates
- [ ] Audio playback works

### ✅ Mobile App
- [ ] App builds successfully: `flutter build apk`
- [ ] API connection initializes
- [ ] File selection works
- [ ] Processing starts and completes
- [ ] Stems can be played

## Quick Verification Commands

```bash
# Test everything is working
cd /home/igris/sandesh_2/song_splitter
python3 test_api.py

# Check running processes
ps aux | grep python
ps aux | grep flutter

# Check network connections
netstat -tlnp | grep :5000
netstat -tlnp | grep :8080
```

## Log Files and Debugging

### Flask API Logs
- Console output shows request logs
- Check for Python errors or import issues

### Web Demo Logs  
- Open browser Developer Tools (F12)
- Check Console tab for JavaScript errors
- Check Network tab for failed requests

### Mobile App Logs
```bash
flutter logs  # For connected device
adb logcat    # For Android debugging
```

## Performance Tips

### For Better Processing Speed
1. Use SSD storage for faster I/O
2. Close unnecessary applications
3. Use GPU if available (CUDA/Metal)
4. Process shorter audio clips for testing

### For Development
1. Use mock mode for UI testing
2. Test with small files first
3. Monitor system resources during processing

## Getting Help

If issues persist:
1. Check the console/terminal output for specific error messages
2. Verify all dependencies are installed correctly
3. Test with a simple audio file (short MP3)
4. Try the mock mode first before full AI processing

## Version Information

- **Flask API**: Simple mock version for testing
- **Web Demo**: Modern HTML5/JavaScript interface  
- **Mobile App**: Flutter with API integration
- **AI Model**: Demucs (when using full version)
