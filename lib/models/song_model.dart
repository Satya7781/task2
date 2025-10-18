import 'stem_model.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final Duration duration;
  final DateTime createdAt;
  final List<Stem> stems;
  final bool isProcessed;
  final double processingProgress;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.duration,
    required this.createdAt,
    this.stems = const [],
    this.isProcessed = false,
    this.processingProgress = 0.0,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? filePath,
    Duration? duration,
    DateTime? createdAt,
    List<Stem>? stems,
    bool? isProcessed,
    double? processingProgress,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      stems: stems ?? this.stems,
      isProcessed: isProcessed ?? this.isProcessed,
      processingProgress: processingProgress ?? this.processingProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
      'stems': stems.map((stem) => stem.toJson()).toList(),
      'isProcessed': isProcessed,
      'processingProgress': processingProgress,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      createdAt: DateTime.parse(json['createdAt']),
      stems: (json['stems'] as List<dynamic>?)
          ?.map((stemJson) => Stem.fromJson(stemJson))
          .toList() ?? [],
      isProcessed: json['isProcessed'] ?? false,
      processingProgress: json['processingProgress']?.toDouble() ?? 0.0,
    );
  }
}
