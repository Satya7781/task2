#!/bin/bash

# AI Song Splitter Demo Startup Script
# This script starts both the Flask API and the demo web server

echo "🎵 AI Song Splitter Demo Startup"
echo "================================="

# Check if we're in the right directory
if [ ! -f "python_backend/flask_api.py" ]; then
    echo "❌ Error: Please run this script from the song_splitter directory"
    exit 1
fi

# Check Python dependencies
echo "📦 Checking Python dependencies..."
if ! python3 -c "import flask, demucs, torch" 2>/dev/null; then
    echo "⚠️  Warning: Some Python dependencies might be missing"
    echo "   Run: pip install -r python_backend/requirements.txt"
fi

# Function to cleanup background processes
cleanup() {
    echo ""
    echo "🛑 Shutting down servers..."
    kill $API_PID 2>/dev/null
    kill $WEB_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start Flask API in background
echo "🚀 Starting Flask API server..."
cd python_backend
python3 flask_api_simple.py &
API_PID=$!
cd ..

# Wait a moment for API to start
sleep 3

# Check if API is running
if ! curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    echo "❌ Flask API failed to start properly"
    echo "   Check python_backend/flask_api_simple.py for errors"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo "✅ Flask API running on http://localhost:5000"

# Start demo web server in background
echo "🌐 Starting demo web server..."
cd demo_web
python3 server.py &
WEB_PID=$!
cd ..

# Wait a moment for web server to start
sleep 2

echo ""
echo "🎉 Demo is ready!"
echo "📱 Web Interface: http://localhost:8080"
echo "🔧 API Backend: http://localhost:5000"
echo ""
echo "📋 Usage:"
echo "   1. Open http://localhost:8080 in your browser"
echo "   2. Upload an audio file (MP3, WAV, etc.)"
echo "   3. Watch the AI separate vocals and instruments"
echo "   4. Play and download the separated stems"
echo ""
echo "⏹️  Press Ctrl+C to stop both servers"
echo ""

# Wait for user to stop
wait
