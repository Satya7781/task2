#!/bin/bash

# Debug and Fix Script for Song Splitter
# This script identifies and resolves common issues

echo "🔧 Song Splitter Debug & Fix Tool"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if we're in the right directory
if [ ! -f "python_backend/flask_api_simple.py" ]; then
    print_status $RED "❌ Error: Please run this script from the song_splitter directory"
    exit 1
fi

print_status $BLUE "📋 Running diagnostics..."

# 1. Check Python and dependencies
print_status $YELLOW "🐍 Checking Python environment..."
if command -v python3 &> /dev/null; then
    print_status $GREEN "✅ Python3 found: $(python3 --version)"
else
    print_status $RED "❌ Python3 not found"
    exit 1
fi

# Check Flask
if python3 -c "import flask" 2>/dev/null; then
    print_status $GREEN "✅ Flask available"
else
    print_status $YELLOW "⚠️ Installing Flask..."
    pip3 install flask flask-cors
fi

# 2. Check ports
print_status $YELLOW "🔌 Checking ports..."

# Check if port 5000 is in use
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_status $GREEN "✅ Port 5000 is in use (Flask API likely running)"
    API_RUNNING=true
else
    print_status $YELLOW "⚠️ Port 5000 is free - Flask API not running"
    API_RUNNING=false
fi

# Check if port 8080 is in use
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_status $GREEN "✅ Port 8080 is in use (Web demo likely running)"
    WEB_RUNNING=true
else
    print_status $YELLOW "⚠️ Port 8080 is free - Web demo not running"
    WEB_RUNNING=false
fi

# 3. Test API if running
if [ "$API_RUNNING" = true ]; then
    print_status $YELLOW "🧪 Testing API endpoints..."
    
    # Test health endpoint
    if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
        print_status $GREEN "✅ API health endpoint responding"
        
        # Get API status
        API_STATUS=$(curl -s http://localhost:5000/api/health | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])" 2>/dev/null)
        if [ "$API_STATUS" = "healthy" ]; then
            print_status $GREEN "✅ API is healthy"
        else
            print_status $YELLOW "⚠️ API status: $API_STATUS"
        fi
    else
        print_status $RED "❌ API health endpoint not responding"
    fi
    
    # Test jobs endpoint
    if curl -s http://localhost:5000/api/jobs >/dev/null 2>&1; then
        print_status $GREEN "✅ API jobs endpoint responding"
    else
        print_status $RED "❌ API jobs endpoint not responding"
    fi
else
    print_status $YELLOW "🚀 Starting Flask API..."
    cd python_backend
    python3 flask_api_simple.py &
    API_PID=$!
    cd ..
    
    # Wait for API to start
    sleep 3
    
    # Test if API started successfully
    if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
        print_status $GREEN "✅ Flask API started successfully"
    else
        print_status $RED "❌ Failed to start Flask API"
        kill $API_PID 2>/dev/null
    fi
fi

# 4. Test web demo
if [ "$WEB_RUNNING" = false ]; then
    print_status $YELLOW "🌐 Starting web demo..."
    cd demo_web
    python3 server.py &
    WEB_PID=$!
    cd ..
    
    # Wait for web server to start
    sleep 2
    
    # Test if web server started
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        print_status $GREEN "✅ Web demo started successfully"
    else
        print_status $RED "❌ Failed to start web demo"
        kill $WEB_PID 2>/dev/null
    fi
fi

# 5. Check Flutter setup (if available)
print_status $YELLOW "📱 Checking Flutter setup..."
if command -v flutter &> /dev/null; then
    print_status $GREEN "✅ Flutter found: $(flutter --version | head -1)"
    
    # Check Flutter dependencies
    if [ -f "pubspec.yaml" ]; then
        print_status $YELLOW "📦 Checking Flutter dependencies..."
        flutter pub get >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_status $GREEN "✅ Flutter dependencies resolved"
        else
            print_status $RED "❌ Flutter dependency issues"
        fi
    fi
else
    print_status $YELLOW "⚠️ Flutter not found (mobile app won't work)"
fi

# 6. Check Android configuration
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    print_status $YELLOW "🤖 Checking Android configuration..."
    
    # Check network security config
    if grep -q "networkSecurityConfig" android/app/src/main/AndroidManifest.xml; then
        print_status $GREEN "✅ Network security config found"
    else
        print_status $RED "❌ Network security config missing"
    fi
    
    # Check cleartext traffic permission
    if grep -q "usesCleartextTraffic" android/app/src/main/AndroidManifest.xml; then
        print_status $GREEN "✅ Cleartext traffic permission found"
    else
        print_status $RED "❌ Cleartext traffic permission missing"
    fi
fi

# 7. Final status report
echo ""
print_status $BLUE "📊 Final Status Report:"
echo "========================"

# Check final API status
if curl -s http://localhost:5000/api/health >/dev/null 2>&1; then
    print_status $GREEN "✅ Flask API: Running (http://localhost:5000)"
else
    print_status $RED "❌ Flask API: Not running"
fi

# Check final web demo status
if curl -s http://localhost:8080 >/dev/null 2>&1; then
    print_status $GREEN "✅ Web Demo: Running (http://localhost:8080)"
else
    print_status $RED "❌ Web Demo: Not running"
fi

# Mobile app status
if command -v flutter &> /dev/null && [ -f "pubspec.yaml" ]; then
    print_status $GREEN "✅ Mobile App: Ready (run 'flutter run')"
else
    print_status $YELLOW "⚠️ Mobile App: Flutter not available"
fi

echo ""
print_status $BLUE "🎯 Next Steps:"
echo "==============="

if curl -s http://localhost:5000/api/health >/dev/null 2>&1 && curl -s http://localhost:8080 >/dev/null 2>&1; then
    print_status $GREEN "🎉 Everything is working!"
    echo "   • Web Demo: http://localhost:8080"
    echo "   • API Backend: http://localhost:5000"
    echo "   • Mobile App: Run 'flutter run' in another terminal"
else
    print_status $YELLOW "🔧 Some issues found. Try running:"
    echo "   ./start_demo.sh"
    echo ""
    echo "   Or manually:"
    echo "   Terminal 1: cd python_backend && python3 flask_api_simple.py"
    echo "   Terminal 2: cd demo_web && python3 server.py"
fi

echo ""
print_status $BLUE "📚 For troubleshooting, see: TROUBLESHOOTING.md"
