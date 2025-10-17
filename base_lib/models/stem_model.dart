enum StemType {
  vocals,
  drums,
  bass,
  piano,
  guitar,
  other,
  harmony,
}

class Stem {
  final String id;
  final StemType type;
  final String filePath;
  final Duration duration;
  final double volume;
  final bool isMuted;
  final bool isSolo;

  Stem({
    required this.id,
    required this.type,
    required this.filePath,
    required this.duration,
    this.volume = 0.8,
    this.isMuted = false,
    this.isSolo = false,
  });

  String get displayName {
    switch (type) {
      case StemType.vocals:
        return 'Vocals';
      case StemType.drums:
        return 'Drums';
      case StemType.bass:
        return 'Bass';
      case StemType.piano:
        return 'Piano';
      case StemType.guitar:
        return 'Guitar';
      case StemType.harmony:
        return 'Harmony';
      case StemType.other:
        return 'Other';
    }
  }

  Stem copyWith({
    String? id,
    StemType? type,
    String? filePath,
    Duration? duration,
    double? volume,
    bool? isMuted,
    bool? isSolo,
  }) {
    return Stem(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'volume': volume,
      'isMuted': isMuted,
      'isSolo': isSolo,
    };
  }

  factory Stem.fromJson(Map<String, dynamic> json) {
    return Stem(
      id: json['id'],
      type: StemType.values.firstWhere((e) => e.name == json['type']),
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      volume: json['volume']?.toDouble() ?? 0.8,
      isMuted: json['isMuted'] ?? false,
      isSolo: json['isSolo'] ?? false,
    );
  }
}
