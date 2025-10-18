#!/bin/bash

echo "🎵 Setting up Complete AI Audio Separation System..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    print_status $RED "❌ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

print_status $GREEN "✅ Python 3 found: $(python3 --version)"

# Check if pip is available
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    print_status $RED "❌ pip is not available. Please install pip first."
    exit 1
fi

print_status $GREEN "✅ pip found"

# Create virtual environment if it doesn't exist
if [ ! -d "ai_env" ]; then
    print_status $YELLOW "📦 Creating virtual environment..."
    python3 -m venv ai_env
    if [ $? -ne 0 ]; then
        print_status $RED "❌ Failed to create virtual environment"
        exit 1
    fi
fi

# Activate virtual environment
print_status $YELLOW "🔄 Activating virtual environment..."
source ai_env/bin/activate

# Upgrade pip
print_status $YELLOW "⬆️ Upgrading pip..."
python -m pip install --upgrade pip

# Install basic dependencies first
print_status $YELLOW "📥 Installing basic dependencies..."
pip install flask flask-cors requests

# Check if user wants full AI setup
read -p "Install full AI dependencies? This will download ~2GB of packages (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status $YELLOW "🤖 Installing AI dependencies (this may take several minutes)..."
    
    # Install AI packages
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install demucs librosa soundfile scipy pydub mutagen click
    
    if [ $? -eq 0 ]; then
        print_status $GREEN "✅ AI dependencies installed successfully!"
        AI_INSTALLED=true
    else
        print_status $YELLOW "⚠️ AI installation failed, but basic demo will work"
        AI_INSTALLED=false
    fi
else
    print_status $BLUE "📝 Skipping AI dependencies - demo mode only"
    AI_INSTALLED=false
fi

# Check Flutter (optional)
if command -v flutter &> /dev/null; then
    print_status $GREEN "✅ Flutter found: $(flutter --version | head -1)"
    print_status $YELLOW "📦 Installing Flutter dependencies..."
    flutter pub get
    FLUTTER_AVAILABLE=true
else
    print_status $YELLOW "⚠️ Flutter not found - mobile app won't work"
    FLUTTER_AVAILABLE=false
fi

# Make scripts executable
print_status $YELLOW "🔧 Making scripts executable..."
chmod +x *.sh 2>/dev/null

# Create sample audio file for testing (if none exists)
if [ ! -f "sample_audio.mp3" ] && command -v python3 &> /dev/null; then
    print_status $YELLOW "🎵 Creating sample audio file for testing..."
    python3 -c "
from pydub import AudioSegment
from pydub.generators import Sine
import os

try:
    # Create a simple test audio file
    duration = 10000  # 10 seconds
    tone1 = Sine(440).to_audio_segment(duration=duration) - 10
    tone2 = Sine(220).to_audio_segment(duration=duration) - 15
    mixed = tone1.overlay(tone2)
    mixed.export('sample_audio.mp3', format='mp3', bitrate='128k')
    print('✅ Sample audio created: sample_audio.mp3')
except Exception as e:
    print(f'⚠️ Could not create sample audio: {e}')
" 2>/dev/null
fi

# Final status report
print_status $BLUE "📊 Setup Summary:"
echo "=================="

print_status $GREEN "✅ Basic web demo: Ready"
print_status $GREEN "✅ Flask API: Ready"

if [ "$AI_INSTALLED" = true ]; then
    print_status $GREEN "✅ AI separation: Ready (full functionality)"
else
    print_status $YELLOW "⚠️ AI separation: Demo mode only"
fi

if [ "$FLUTTER_AVAILABLE" = true ]; then
    print_status $GREEN "✅ Mobile app: Ready"
else
    print_status $YELLOW "⚠️ Mobile app: Flutter not available"
fi

print_status $BLUE "🚀 Quick Start Commands:"
echo "========================"

echo "📱 Web Demo (Recommended):"
echo "   ./scripts/start_demo.sh"
echo "   Open http://localhost:8080"
echo ""

if [ "$AI_INSTALLED" = true ]; then
    echo "🤖 Full AI Processing:"
    echo "   ./scripts/start_real_ai.sh"
    echo ""
fi

if [ "$FLUTTER_AVAILABLE" = true ]; then
    echo "📱 Mobile App:"
    echo "   flutter run"
    echo ""
fi

echo "⚡ Command Line:"
echo "   python3 tools/batch_separate.py sample_audio.mp3"
echo ""

print_status $GREEN "🎉 Setup completed successfully!"
print_status $BLUE "📖 See docs/SETUP_GUIDE.md for detailed instructions"
