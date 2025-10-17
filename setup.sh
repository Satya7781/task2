#!/bin/bash

echo "🎵 Song Splitter Setup Script"
echo "=============================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is required but not installed."
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Python and Flutter found"

# Setup Python backend
echo ""
echo "🐍 Setting up Python backend..."
cd python_backend

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Python backend setup complete"

# Setup Flutter app
cd ..
echo ""
echo "📱 Setting up Flutter app..."

# Get Flutter dependencies
flutter pub get

echo "✅ Flutter app setup complete"

# Create test directories
echo ""
echo "📁 Creating test directories..."
mkdir -p test_audio
mkdir -p python_backend/uploads
mkdir -p python_backend/outputs

echo "✅ Test directories created"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Place test audio files in the 'test_audio' directory"
echo "2. Start the Python API: cd python_backend && source venv/bin/activate && python flask_api.py"
echo "3. In another terminal, run the Flutter app: flutter run"
echo "4. Or use the command line tool: cd python_backend && python song_splitter.py ../test_audio/your_song.mp3"
echo ""
echo "For command line usage:"
echo "  python song_splitter.py input.mp3 --output-dir ./output --format both --analyze"
echo ""
