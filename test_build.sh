#!/bin/bash

echo "🔧 Testing APK build with namespace fix..."

# Clean first
echo "🧹 Cleaning build cache..."
~/flutter/bin/flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
~/flutter/bin/flutter pub get

# Test build
echo "🚀 Testing build..."
~/flutter/bin/flutter build apk --release --verbose

if [ $? -eq 0 ]; then
    echo "✅ BUILD SUCCESSFUL!"
    echo "📱 APK created at: build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "📊 APK Size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
        echo ""
        echo "🎯 Ready to install on your phone!"
        echo "📲 Transfer the APK to your phone and install it."
    fi
else
    echo "❌ Build still failing. Let me check what's wrong..."
fi
