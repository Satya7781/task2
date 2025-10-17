#!/bin/bash

echo "🎮 Switching to DEMO Mode (Test Tones)"
echo "======================================"

# Stop real AI API
echo "🛑 Stopping real AI API..."
pkill -f flask_api.py 2>/dev/null
sleep 2

# Start demo API
echo "🚀 Starting demo API..."
cd python_backend
python3 flask_api_simple.py &
API_PID=$!

# Wait for API to start
sleep 3

# Test API
if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    echo "✅ Demo API is running!"
else
    echo "❌ Failed to start demo API"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🎮 Demo Mode Active!"
echo "==================="
echo ""
echo "📱 Mobile App: Will now generate test tones (different beeps)"
echo "🌐 Web Demo: http://localhost:8080 - fast processing with test sounds"
echo ""
echo "⚡ Processing time: 6 seconds (fast for testing)"
echo "🔊 Output: Different test tones for each stem"
echo ""
echo "🤖 To switch to real AI separation, run: ./switch_to_real_ai.sh"
