#!/bin/bash

echo "🚀 Building Song Splitter APK (Fixed Version)..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
~/flutter/bin/flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
~/flutter/bin/flutter pub get

# Build APK with additional flags to handle warnings
echo "🔨 Building APK with warning fixes..."
~/flutter/bin/flutter build apk --release \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
    --no-tree-shake-icons \
    --verbose

if [ $? -eq 0 ]; then
    echo "✅ APK built successfully!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    
    # Show APK info
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "📊 APK Size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
        echo "🎯 Ready for installation!"
    fi
else
    echo "❌ Build failed. Check the error messages above."
    echo "💡 Common solutions:"
    echo "   1. Make sure Android SDK 34 is installed"
    echo "   2. Check Java version (should be 11+)"
    echo "   3. Try: flutter doctor"
fi
