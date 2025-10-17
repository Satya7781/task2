import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/song_model.dart';
import '../models/stem_model.dart';

class AudioSeparationService extends ChangeNotifier {
  static const _uuid = Uuid();
  static const String _baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // For physical device, use: 'http://YOUR_COMPUTER_IP:5000/api'
  // For iOS simulator, use: 'http://localhost:5000/api'
  
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String? _currentProcessingId;
  String? _currentJobId;
  late Dio _dio;
  
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  String? get currentProcessingId => _currentProcessingId;

  Future<void> initialize() async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      // Test API connection with multiple attempts
      for (int i = 0; i < 3; i++) {
        try {
          final response = await _dio.get('/health');
          if (response.statusCode == 200) {
            print('✅ Audio separation service initialized - API connected');
            print('   API Status: ${response.data['status']}');
            print('   Device: ${response.data['device']}');
            return;
          }
        } catch (e) {
          print('🔄 API connection attempt ${i + 1}/3 failed: $e');
          if (i < 2) await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      print('⚠️ API not available - will use mock mode as fallback');
    } catch (e) {
      print('❌ Failed to initialize audio separation service: $e');
      print('   Will use mock mode for audio separation');
    }
  }

  Future<Song> separateAudio(Song song) async {
    if (_isProcessing) {
      throw Exception('Another separation is already in progress');
    }

    _isProcessing = true;
    _processingProgress = 0.0;
    _currentProcessingId = song.id;
    notifyListeners();

    try {
      // Upload file to API
      _processingProgress = 0.1;
      notifyListeners();
      
      final uploadResponse = await _uploadFile(song.filePath);
      _currentJobId = uploadResponse['job_id'];
      
      // Start separation
      _processingProgress = 0.2;
      notifyListeners();
      
      await _dio.post('/separate/$_currentJobId');
      
      // Poll for completion
      final stems = await _pollForCompletion();
      
      final processedSong = song.copyWith(
        stems: stems,
        isProcessed: true,
        processingProgress: 1.0,
      );

      return processedSong;
    } catch (e) {
      print('Error during audio separation: $e');
      // Fallback to mock if API fails
      return await _separateAudioMock(song);
    } finally {
      _isProcessing = false;
      _processingProgress = 0.0;
      _currentProcessingId = null;
      _currentJobId = null;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _uploadFile(String filePath) async {
    final file = File(filePath);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: file.path.split('/').last),
    });
    
    final response = await _dio.post('/upload', data: formData);
    return response.data;
  }

  Future<List<Stem>> _pollForCompletion() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      
      final response = await _dio.get('/status/$_currentJobId');
      final data = response.data;
      
      _processingProgress = (data['progress'] as num).toDouble();
      notifyListeners();
      
      if (data['status'] == 'completed') {
        return await _downloadStems(data['stems']);
      } else if (data['status'] == 'failed') {
        throw Exception(data['error'] ?? 'Processing failed');
      }
    }
  }

  Future<List<Stem>> _downloadStems(Map<String, dynamic> stemPaths) async {
    final stems = <Stem>[];
    final directory = await getApplicationDocumentsDirectory();
    final stemsDir = Directory('${directory.path}/stems');
    if (!await stemsDir.exists()) {
      await stemsDir.create(recursive: true);
    }

    for (final entry in stemPaths.entries) {
      final stemType = _getStemTypeFromName(entry.key);
      final localPath = '${stemsDir.path}/${_currentJobId}_${entry.key}.wav';
      
      // Download stem file
      await _dio.download('/download/$_currentJobId/${entry.key}', localPath);
      
      final stem = Stem(
        id: _uuid.v4(),
        type: stemType,
        filePath: localPath,
        duration: const Duration(seconds: 180), // Will be updated by player
      );
      
      stems.add(stem);
    }
    
    return stems;
  }

  StemType _getStemTypeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'vocals':
        return StemType.vocals;
      case 'drums':
        return StemType.drums;
      case 'bass':
        return StemType.bass;
      case 'piano':
        return StemType.piano;
      case 'guitar':
        return StemType.guitar;
      case 'harmony':
        return StemType.harmony;
      default:
        return StemType.other;
    }
  }

  // Fallback mock implementation
  Future<Song> _separateAudioMock(Song song) async {
    final stems = <Stem>[];
    final stemTypes = [StemType.vocals, StemType.drums, StemType.bass, StemType.other];

    for (int i = 0; i < stemTypes.length; i++) {
      _processingProgress = (i + 1) / stemTypes.length;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));

      final stemPath = await _createMockStemFile(song, stemTypes[i]);
      final stem = Stem(
        id: _uuid.v4(),
        type: stemTypes[i],
        filePath: stemPath,
        duration: song.duration,
      );
      stems.add(stem);
    }

    return song.copyWith(
      stems: stems,
      isProcessed: true,
      processingProgress: 1.0,
    );
  }

  Future<String> _createMockStemFile(Song song, StemType stemType) async {
    final directory = await getApplicationDocumentsDirectory();
    final stemsDir = Directory('${directory.path}/stems');
    if (!await stemsDir.exists()) {
      await stemsDir.create(recursive: true);
    }

    final stemFileName = '${song.id}_${stemType.name}.wav';
    final stemPath = '${stemsDir.path}/$stemFileName';
    
    // In a real implementation, this would be the actual separated audio data
    // For now, we'll create an empty file as a placeholder
    final file = File(stemPath);
    await file.writeAsBytes(Uint8List(0));
    
    return stemPath;
  }

  // Real implementation would use TensorFlow Lite for on-device processing
  Future<List<Float32List>> _processAudioWithModel(Float32List audioData) async {
    // This is where you would:
    // 1. Preprocess the audio data (normalize, convert to spectrograms, etc.)
    // 2. Run inference using the loaded TensorFlow Lite model
    // 3. Postprocess the output to get individual stems
    // 4. Return the separated audio streams
    
    throw UnimplementedError('Model processing not implemented in mock version');
  }

  Future<Song> separateAudioCloud(Song song) async {
    // Implementation for cloud-based processing
    // This would upload the audio file to a cloud service and download the results
    throw UnimplementedError('Cloud processing not implemented');
  }

  void cancelProcessing() {
    if (_isProcessing) {
      _isProcessing = false;
      _processingProgress = 0.0;
      _currentProcessingId = null;
      notifyListeners();
    }
  }
}
