# Song Splitter - AI-Powered Audio Source Separation

A cross-platform mobile application that uses AI to separate songs into individual stems (vocals, drums, bass, and other instruments).

## Features

- 🎵 **Audio Import**: Support for MP3, WAV, M4A, and FLAC files
- 🤖 **AI-Powered Separation**: Split songs into vocals, drums, bass, and other instruments
- 🎛️ **Stem Controls**: Individual volume, mute, and solo controls for each stem
- 📱 **Cross-Platform**: Works on both iOS and Android
- 🎨 **Modern UI**: Clean, intuitive interface with Material Design 3
- 📊 **Waveform Visualization**: Visual representation of audio playback
- 💾 **Export Options**: Export individual stems or custom mixes

## Screenshots

*Screenshots will be added once the app is running*

## Installation

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.10.0 or later
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   flutter --version
   ```

2. **Platform-specific requirements**:
   - **Android**: Android Studio with Android SDK
   - **iOS**: Xcode (macOS only)

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd song_splitter
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**:

   **Android**:
   - Ensure Android SDK is installed
   - Connect an Android device or start an emulator
   
   **iOS** (macOS only):
   - Ensure Xcode is installed
   - Connect an iOS device or start a simulator

4. **Run the app**:
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## Project Structure

```
song_splitter/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── song_model.dart         # Song data structure
│   │   └── stem_model.dart         # Audio stem data structure
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart        # Main import/processing screen
│   │   ├── library_screen.dart     # Song library management
│   │   └── player_screen.dart      # Audio playback and stem controls
│   ├── services/                    # Business logic
│   │   ├── audio_separation_service.dart  # AI separation logic
│   │   └── audio_player_service.dart      # Audio playback management
│   └── widgets/                     # Reusable UI components
│       ├── stem_player_widget.dart  # Individual stem controls
│       └── waveform_widget.dart     # Audio waveform visualization
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
└── assets/                         # Static assets
    └── models/                     # AI model files (TensorFlow Lite)
```

## Architecture

### State Management
- **Provider**: Used for state management across the app
- **Services**: Separate business logic from UI components

### Audio Processing
- **Mock Implementation**: Currently uses mock data for demonstration
- **TensorFlow Lite Ready**: Structured to integrate real AI models
- **Cloud Processing**: Architecture supports both on-device and cloud processing

### Key Services

1. **AudioSeparationService**: Handles AI-powered audio separation
2. **AudioPlayerService**: Manages audio playback and stem mixing

## Development Roadmap

### Phase 1: Core Functionality ✅
- [x] Project setup and basic UI
- [x] Audio file import
- [x] Mock audio separation
- [x] Basic playback controls
- [x] Stem volume controls

### Phase 2: AI Integration (Next)
- [ ] Integrate TensorFlow Lite models
- [ ] Implement real audio separation
- [ ] Add processing progress indicators
- [ ] Optimize for mobile performance

### Phase 3: Advanced Features
- [ ] Cloud processing option
- [ ] Real-time separation
- [ ] Advanced export options
- [ ] Social sharing features

### Phase 4: Polish & Release
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] App store preparation
- [ ] User documentation

## AI Model Integration

The app is designed to work with audio separation models like:

- **Demucs**: Facebook's state-of-the-art source separation model
- **Spleeter**: Deezer's open-source separation library
- **Custom Models**: Optimized for mobile deployment

### Model Requirements
- **Format**: TensorFlow Lite (.tflite)
- **Input**: Audio spectrograms or raw waveforms
- **Output**: Separated audio stems
- **Size**: Optimized for mobile (< 50MB recommended)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Dependencies

### Core Dependencies
- `flutter`: Cross-platform UI framework
- `provider`: State management
- `just_audio`: Audio playback
- `audioplayers`: Additional audio functionality
- `file_picker`: File selection
- `path_provider`: File system access
- `permission_handler`: Device permissions

### AI/ML Dependencies
- `tflite_flutter`: TensorFlow Lite integration
- `http` & `dio`: Cloud processing APIs

### UI Dependencies
- `flutter_svg`: SVG support
- Material Design 3 components

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **TensorFlow Team**: For TensorFlow Lite mobile ML capabilities
- **Audio Separation Research**: Built on research from Facebook AI, Deezer, and others

## Support

For support, please open an issue on GitHub or contact the development team.

---

**Note**: This is currently a demonstration version with mock AI processing. Real audio separation will be implemented in the next development phase.
