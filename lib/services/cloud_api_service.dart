import 'dart:io';
import 'package:dio/dio.dart';
import '../models/song_model.dart';
import '../models/stem_model.dart';

class CloudApiService {
  static const String _baseUrl = 'https://api.songsplitter.com'; // Replace with actual API
  late final Dio _dio;

  CloudApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10), // Long timeout for processing
    ));
  }

  /// Upload audio file for cloud processing
  Future<String> uploadAudio(String filePath) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post('/upload', data: formData);
      
      if (response.statusCode == 200) {
        return response.data['upload_id'];
      } else {
        throw Exception('Failed to upload audio file');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Start audio separation process
  Future<String> startSeparation(String uploadId, {
    List<StemType> stemTypes = const [
      StemType.vocals,
      StemType.drums,
      StemType.bass,
      StemType.other,
    ],
    String quality = 'high',
  }) async {
    try {
      final response = await _dio.post('/separate', data: {
        'upload_id': uploadId,
        'stem_types': stemTypes.map((e) => e.name).toList(),
        'quality': quality,
      });

      if (response.statusCode == 200) {
        return response.data['job_id'];
      } else {
        throw Exception('Failed to start separation');
      }
    } catch (e) {
      throw Exception('Separation start failed: $e');
    }
  }

  /// Check separation job status
  Future<SeparationJobStatus> checkJobStatus(String jobId) async {
    try {
      final response = await _dio.get('/status/$jobId');
      
      if (response.statusCode == 200) {
        return SeparationJobStatus.fromJson(response.data);
      } else {
        throw Exception('Failed to check job status');
      }
    } catch (e) {
      throw Exception('Status check failed: $e');
    }
  }

  /// Download separated stems
  Future<List<String>> downloadStems(String jobId, String outputDir) async {
    try {
      final response = await _dio.get('/download/$jobId');
      
      if (response.statusCode == 200) {
        final stemUrls = List<String>.from(response.data['stem_urls']);
        final downloadedPaths = <String>[];

        for (int i = 0; i < stemUrls.length; i++) {
          final url = stemUrls[i];
          final fileName = 'stem_$i.wav';
          final filePath = '$outputDir/$fileName';
          
          await _dio.download(url, filePath);
          downloadedPaths.add(filePath);
        }

        return downloadedPaths;
      } else {
        throw Exception('Failed to download stems');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Complete cloud separation workflow
  Future<Song> processAudioCloud(Song song) async {
    try {
      // 1. Upload audio
      final uploadId = await uploadAudio(song.filePath);
      
      // 2. Start separation
      final jobId = await startSeparation(uploadId);
      
      // 3. Poll for completion
      SeparationJobStatus status;
      do {
        await Future.delayed(const Duration(seconds: 5));
        status = await checkJobStatus(jobId);
      } while (status.status == 'processing');

      if (status.status != 'completed') {
        throw Exception('Separation failed: ${status.error}');
      }

      // 4. Download results
      final outputDir = '/path/to/output'; // Use proper directory
      final stemPaths = await downloadStems(jobId, outputDir);
      
      // 5. Create stem objects
      final stems = <Stem>[];
      final stemTypes = [StemType.vocals, StemType.drums, StemType.bass, StemType.other];
      
      for (int i = 0; i < stemPaths.length && i < stemTypes.length; i++) {
        stems.add(Stem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          type: stemTypes[i],
          filePath: stemPaths[i],
          duration: song.duration,
        ));
      }

      return song.copyWith(
        stems: stems,
        isProcessed: true,
        processingProgress: 1.0,
      );
    } catch (e) {
      throw Exception('Cloud processing failed: $e');
    }
  }
}

class SeparationJobStatus {
  final String status; // 'processing', 'completed', 'failed'
  final double progress;
  final String? error;
  final Map<String, dynamic>? metadata;

  SeparationJobStatus({
    required this.status,
    required this.progress,
    this.error,
    this.metadata,
  });

  factory SeparationJobStatus.fromJson(Map<String, dynamic> json) {
    return SeparationJobStatus(
      status: json['status'],
      progress: json['progress']?.toDouble() ?? 0.0,
      error: json['error'],
      metadata: json['metadata'],
    );
  }
}
