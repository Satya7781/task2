#!/bin/bash

echo "🔄 Restarting Flask API with audio fix..."

# Kill existing Flask processes
pkill -f flask_api_simple.py 2>/dev/null
sleep 2

# Start the updated Flask API
cd python_backend
echo "🚀 Starting updated Flask API..."
python3 flask_api_simple.py &
API_PID=$!

# Wait for API to start
sleep 3

# Test if API is working
if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    echo "✅ Flask API restarted successfully"
    echo "🎵 Audio files will now be generated with proper WAV content"
    echo "📱 Web demo should play audio without errors"
else
    echo "❌ Failed to restart Flask API"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🧪 Test the fix by:"
echo "   1. Upload a file in the web demo"
echo "   2. Wait for processing to complete" 
echo "   3. Click 'Play Demo' on any stem"
echo "   4. You should hear different tones for each stem"
