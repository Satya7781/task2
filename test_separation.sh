#!/bin/bash

echo "🧪 Song Splitter Test Script"
echo "============================"

# Check if test audio exists
if [ ! -d "test_audio" ] || [ -z "$(ls -A test_audio)" ]; then
    echo "❌ No test audio files found in test_audio directory"
    echo "Please add some audio files (.mp3, .wav, .m4a, .flac) to the test_audio directory"
    exit 1
fi

# Find first audio file
TEST_FILE=$(find test_audio -name "*.mp3" -o -name "*.wav" -o -name "*.m4a" -o -name "*.flac" | head -n 1)

if [ -z "$TEST_FILE" ]; then
    echo "❌ No supported audio files found"
    exit 1
fi

echo "🎵 Testing with: $TEST_FILE"

# Setup
cd python_backend
source venv/bin/activate

# Create test clip (30 seconds)
echo "📝 Creating 30-second test clip..."
python song_splitter.py "../$TEST_FILE" \
    --output-dir ./test_output \
    --clip-duration 30 \
    --format both \
    --analyze

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Test completed successfully!"
    echo ""
    echo "📊 Results:"
    echo "Output directory: python_backend/test_output"
    ls -la test_output/
    
    echo ""
    echo "📁 Generated files:"
    find test_output -name "*.wav" -o -name "*.mp3" | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "  $file ($size)"
    done
    
    echo ""
    echo "📈 Quality analysis results are shown above"
    echo ""
    echo "🎬 To create a screen recording:"
    echo "1. Start the Flask API: python flask_api.py"
    echo "2. Run the Flutter app: flutter run"
    echo "3. Import and process the test file"
    echo "4. Record the process from import to separated stems"
    
else
    echo "❌ Test failed"
    exit 1
fi
