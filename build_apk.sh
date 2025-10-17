#!/bin/bash

echo "🚀 Building Song Splitter APK..."

# Set Flutter path
export PATH="$PATH:$HOME/flutter/bin"

# Clean any existing build
echo "🧹 Cleaning previous builds..."
rm -rf build/

# Create basic Android project structure if missing
mkdir -p android/app/src/main/kotlin/com/example/song_splitter
mkdir -p android/app/src/main/res/values
mkdir -p android/gradle/wrapper

# Create MainActivity.kt if missing
if [ ! -f "android/app/src/main/kotlin/com/example/song_splitter/MainActivity.kt" ]; then
cat > android/app/src/main/kotlin/com/example/song_splitter/MainActivity.kt << 'EOF'
package com.example.song_splitter

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
EOF
fi

# Create build.gradle for app if missing
if [ ! -f "android/app/build.gradle" ]; then
cat > android/app/build.gradle << 'EOF'
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    compileSdkVersion 33
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.song_splitter"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.7.10"
}
EOF
fi

# Create settings.gradle if missing
if [ ! -f "android/settings.gradle" ]; then
cat > android/settings.gradle << 'EOF'
include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()

assert localPropertiesFile.exists()
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
EOF
fi

# Create local.properties
cat > android/local.properties << EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=$HOME/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF

# Try to build APK directly
echo "🔨 Building APK..."
~/flutter/bin/flutter build apk --release --no-pub

if [ $? -eq 0 ]; then
    echo "✅ APK built successfully!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    ls -la build/app/outputs/flutter-apk/
else
    echo "❌ Build failed. Trying alternative approach..."
    
    # Try building without dependencies
    echo "🔄 Attempting minimal build..."
    ~/flutter/bin/flutter build apk --release --no-pub --no-tree-shake-icons
fi
