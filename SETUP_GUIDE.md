# 🚀 Complete Setup Guide - AI Audio Separation System

## 📋 Quick Start (Anyone Can Run This)

### **Prerequisites**
- Python 3.8+ 
- Flutter SDK (for mobile app)
- Git

### **1. Clone Repository**
```bash
git clone https://github.com/Satya7781/task2.git
cd task2
```

### **2. One-Command Setup**
```bash
chmod +x setup.sh && ./setup.sh
```

### **3. Run Applications**

#### **Option A: Web Demo (Easiest)**
```bash
./start_demo.sh
# Open http://localhost:8080 in browser
```

#### **Option B: Mobile App**
```bash
# Terminal 1 - Start API
./start_real_ai.sh

# Terminal 2 - Run Mobile App  
flutter run
```

#### **Option C: Command Line Processing**
```bash
# Process audio files directly
python3 batch_separate.py your_song.mp3
```

## 🔧 Manual Setup (If Automatic Setup Fails)

### **Step 1: Install Python Dependencies**
```bash
# Create virtual environment
python3 -m venv ai_env
source ai_env/bin/activate

# Install AI dependencies
pip install torch torchaudio demucs librosa soundfile scipy pydub mutagen click flask flask-cors

# Or use requirements file
pip install -r python_backend/requirements.txt
```

### **Step 2: Install Flutter Dependencies (For Mobile App)**
```bash
flutter pub get
```

### **Step 3: Test Installation**
```bash
# Test API
cd python_backend
python3 flask_api_simple.py

# Test web demo
cd ../demo_web
python3 server.py
```

## 🎯 What You Can Do

### **Web Demo Features**
- ✅ Upload audio files (MP3, WAV, M4A, FLAC)
- ✅ Real-time processing progress
- ✅ Play separated stems (vocals, drums, bass, other)
- ✅ Download individual tracks
- ✅ Quality analysis reports

### **Mobile App Features**  
- ✅ Cross-platform (Android/iOS)
- ✅ File picker integration
- ✅ Real-time progress tracking
- ✅ Audio playback controls
- ✅ Stem management

### **Command Line Features**
- ✅ Batch processing multiple files
- ✅ Parallel processing support
- ✅ Multiple AI models (4-stem, 6-stem)
- ✅ Quality analysis and bleed detection
- ✅ WAV + MP3 export

## 🚨 Troubleshooting

### **Common Issues**

#### **"Module not found" errors**
```bash
source ai_env/bin/activate
pip install -r python_backend/requirements.txt
```

#### **Port already in use**
```bash
pkill -f flask_api
pkill -f server.py
```

#### **Flutter issues**
```bash
flutter clean
flutter pub get
flutter doctor
```

#### **Permission errors**
```bash
chmod +x *.sh
```

## 📱 Mobile App Setup Details

### **Android**
- Network security configured for localhost connections
- Supports both emulator and physical devices
- Auto-detects API availability

### **iOS** 
- Simulator ready
- Physical device requires developer account
- Network permissions configured

## 🤖 AI Models Available

| Model | Stems | Quality | Speed | Use Case |
|-------|-------|---------|-------|----------|
| htdemucs | 4 | High | Fast | General purpose |
| htdemucs_ft | 4 | Higher | Medium | Vocal-focused |
| htdemucs_6s | 6 | Highest | Slow | Individual instruments |
| mdx_extra | 2 | Excellent | Fast | Vocal extraction |

## 📊 System Requirements

### **Minimum**
- 8GB RAM
- 4-core CPU  
- 2GB free storage

### **Recommended**
- 16GB RAM
- 8-core CPU
- NVIDIA GPU (for faster processing)
- 5GB free storage

## 🎵 Supported Formats

### **Input**
- MP3, WAV, M4A, FLAC, AAC
- Sample rates: Auto-converted to 44.1kHz
- Channels: Mono/Stereo (auto-converted)

### **Output**
- WAV (lossless, 44.1kHz stereo)
- MP3 (320kbps, high quality)
- Test clips (30-second samples)

## 📞 Support

If you encounter issues:

1. **Check TROUBLESHOOTING.md** for detailed solutions
2. **Run diagnostic**: `./debug_and_fix.sh`
3. **Check logs** in terminal output
4. **Verify dependencies** with setup script

## 🎉 Success Indicators

### **Web Demo Working**
- API shows "Online" status
- File upload accepts audio files
- Processing completes with progress bar
- Audio playback works for all stems

### **Mobile App Working**
- App connects to API successfully
- File picker opens and selects audio
- Processing shows real-time progress
- Stems can be played and managed

### **Command Line Working**
```bash
python3 batch_separate.py test_song.mp3
# Should create separated_audio/test_song/ with stems
```

**Ready to use! 🚀 Anyone can now clone and run this complete AI audio separation system.**
