#!/bin/bash

echo "🤖 Switching to REAL AI Audio Separation"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "python_backend/flask_api.py" ]; then
    echo "❌ Error: Please run this script from the song_splitter directory"
    exit 1
fi

# Stop demo API
echo "🛑 Stopping demo API..."
pkill -f flask_api_simple.py 2>/dev/null
sleep 2

# Check dependencies
echo "📦 Checking AI dependencies..."
python3 -c "
try:
    import torch, demucs, librosa, soundfile
    print('✅ All AI dependencies found')
except ImportError as e:
    print(f'❌ Missing dependency: {e}')
    print('   Run: pip install torch torchaudio demucs librosa soundfile')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo ""
    echo "🔧 Installing AI dependencies (this may take several minutes)..."
    pip install torch torchaudio demucs librosa soundfile numpy scipy
fi

# Start real AI API
echo "🚀 Starting REAL AI API..."
cd python_backend
python3 flask_api.py &
API_PID=$!

# Wait for API to start
echo "⏳ Waiting for AI model to load (this may take a few minutes on first run)..."
sleep 10

# Test API
for i in {1..30}; do
    if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
        echo "✅ Real AI API is running!"
        break
    fi
    echo "   Still loading... ($i/30)"
    sleep 2
done

if ! curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    echo "❌ Failed to start real AI API"
    echo "   Check the console output above for errors"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🎉 REAL AI Separation is now active!"
echo "======================================"
echo ""
echo "📱 Mobile App: Run 'flutter run' - will now do real separation"
echo "🌐 Web Demo: http://localhost:8080 - will now separate real audio"
echo ""
echo "⚠️  Note: Processing will now take 30 seconds to several minutes"
echo "   depending on song length, but you'll get REAL separated audio!"
echo ""
echo "🔄 To switch back to demo mode, run: ./switch_to_demo.sh"
