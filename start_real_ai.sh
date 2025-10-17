#!/bin/bash

echo "🤖 Starting Real AI Audio Separation System"
echo "============================================"

# Navigate to project directory
cd /home/igris/sandesh_2/song_splitter

# Kill any existing processes
echo "🛑 Stopping any existing services..."
pkill -f flask_api 2>/dev/null
pkill -f server.py 2>/dev/null
sleep 2

# Activate virtual environment and start Flask API
echo "🚀 Starting AI Flask API with virtual environment..."
source ai_env/bin/activate

# Verify dependencies in virtual environment
echo "📦 Verifying AI dependencies..."
python3 -c "
import torch, demucs, librosa, soundfile
print('✅ All dependencies available')
print(f'   PyTorch: {torch.__version__}')
print(f'   Device: {\"CUDA\" if torch.cuda.is_available() else \"CPU\"}')
try:
    import torchcodec
    print('✅ TorchCodec available')
except ImportError:
    print('⚠️ TorchCodec not found, installing...')
    import subprocess
    subprocess.run(['pip', 'install', 'torchcodec'])
"

# Start Flask API in background
cd python_backend
echo "🔄 Starting Flask API..."
python3 flask_api.py &
FLASK_PID=$!
cd ..

# Wait for Flask API to initialize
echo "⏳ Waiting for AI model to load..."
sleep 15

# Check if Flask API is running
for i in {1..20}; do
    if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
        echo "✅ AI Flask API is running!"
        break
    fi
    echo "   Loading... ($i/20)"
    sleep 3
done

if ! curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    echo "❌ Flask API failed to start"
    echo "   Check the console output above for errors"
    kill $FLASK_PID 2>/dev/null
    exit 1
fi

# Start web demo
echo "🌐 Starting web demo..."
cd demo_web
python3 server.py &
WEB_PID=$!
cd ..

sleep 3

# Final status
echo ""
echo "🎉 Real AI Audio Separation System is Ready!"
echo "============================================="
echo ""
echo "📱 Mobile App: Run 'flutter run' in a new terminal"
echo "🌐 Web Demo: http://localhost:8080"
echo "🔧 API Backend: http://localhost:5000"
echo ""
echo "⚡ Features:"
echo "   • Real AI audio separation (not demo beeps)"
echo "   • CUDA GPU acceleration available"
echo "   • Processing time: 30 seconds to 5 minutes"
echo "   • Output: Real separated vocals, drums, bass, other"
echo ""
echo "🛑 Press Ctrl+C to stop all services"

# Keep script running
trap "echo ''; echo '🛑 Stopping services...'; kill $FLASK_PID $WEB_PID 2>/dev/null; exit 0" SIGINT SIGTERM
wait
