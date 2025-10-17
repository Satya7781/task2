# AI Models Directory

This directory contains the TensorFlow Lite models used for audio source separation.

## Model Files

Place your `.tflite` model files in this directory:

- `demucs_lite.tflite` - Lightweight Demucs model for on-device processing
- `spleeter_mobile.tflite` - Mobile-optimized Spleeter model
- `custom_model.tflite` - Your custom trained model

## Model Requirements

### Input Format
- **Audio Format**: 16-bit PCM, mono or stereo
- **Sample Rate**: 44.1 kHz or 22.05 kHz
- **Input Shape**: Depends on model architecture (e.g., [1, 8192] for waveform input)

### Output Format
- **Number of Stems**: Typically 4 (vocals, drums, bass, other)
- **Output Shape**: [batch_size, num_stems, audio_length]

### Performance Considerations
- **Model Size**: Keep under 50MB for mobile deployment
- **Inference Time**: Target < 30 seconds for a 3-minute song
- **Memory Usage**: Optimize for devices with 4GB+ RAM

## Integration

Models are loaded in `AudioSeparationService`:

```dart
// Load model
_interpreter = await Interpreter.fromAsset('assets/models/demucs_lite.tflite');

// Run inference
final output = await _interpreter.run(inputTensor);
```

## Model Training

For custom model training:

1. **Dataset**: Use high-quality multi-track recordings
2. **Framework**: TensorFlow/PyTorch for training
3. **Conversion**: Convert to TensorFlow Lite format
4. **Optimization**: Use quantization for smaller size

## Licensing

Ensure you have proper licensing for any pre-trained models used in production.
