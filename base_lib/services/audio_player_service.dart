import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../models/stem_model.dart';

class AudioPlayerService extends ChangeNotifier {
  final Map<String, AudioPlayer> _stemPlayers = {};
  AudioPlayer? _mainPlayer;
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> initialize() async {
    _mainPlayer = AudioPlayer();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _mainPlayer?.playbackEventStream.listen((event) {
      _duration = event.duration ?? Duration.zero;
      _position = event.updatePosition;
      notifyListeners();
    });

    _mainPlayer?.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> loadSong(Song song) async {
    if (_currentSong?.id == song.id) return;

    await stop();
    _currentSong = song;

    try {
      // Load the original audio file
      await _mainPlayer?.setFilePath(song.filePath);
      
      // Load stem players if the song is processed
      if (song.isProcessed && song.stems.isNotEmpty) {
        await _loadStems(song.stems);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading song: $e');
      rethrow;
    }
  }

  Future<void> _loadStems(List<Stem> stems) async {
    // Clear existing stem players
    for (final player in _stemPlayers.values) {
      await player.dispose();
    }
    _stemPlayers.clear();

    // Create new players for each stem
    for (final stem in stems) {
      final player = AudioPlayer();
      try {
        await player.setFilePath(stem.filePath);
        await player.setVolume(stem.volume);
        _stemPlayers[stem.id] = player;
      } catch (e) {
        print('Error loading stem ${stem.displayName}: $e');
      }
    }
  }

  Future<void> play() async {
    if (_currentSong == null) return;

    try {
      if (_currentSong!.isProcessed && _stemPlayers.isNotEmpty) {
        // Play all stems synchronously
        final futures = _stemPlayers.values.map((player) => player.play());
        await Future.wait(futures);
      } else {
        // Play original audio
        await _mainPlayer?.play();
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      if (_currentSong?.isProcessed == true && _stemPlayers.isNotEmpty) {
        final futures = _stemPlayers.values.map((player) => player.pause());
        await Future.wait(futures);
      } else {
        await _mainPlayer?.pause();
      }
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _mainPlayer?.stop();
      for (final player in _stemPlayers.values) {
        await player.stop();
      }
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      if (_currentSong?.isProcessed == true && _stemPlayers.isNotEmpty) {
        final futures = _stemPlayers.values.map((player) => player.seek(position));
        await Future.wait(futures);
      } else {
        await _mainPlayer?.seek(position);
      }
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  Future<void> setStemVolume(String stemId, double volume) async {
    final player = _stemPlayers[stemId];
    if (player != null) {
      await player.setVolume(volume);
      
      // Update the stem in the current song
      if (_currentSong != null) {
        final updatedStems = _currentSong!.stems.map((stem) {
          if (stem.id == stemId) {
            return stem.copyWith(volume: volume);
          }
          return stem;
        }).toList();
        
        _currentSong = _currentSong!.copyWith(stems: updatedStems);
        notifyListeners();
      }
    }
  }

  Future<void> muteStem(String stemId, bool mute) async {
    final player = _stemPlayers[stemId];
    if (player != null) {
      await player.setVolume(mute ? 0.0 : 1.0);
      
      // Update the stem in the current song
      if (_currentSong != null) {
        final updatedStems = _currentSong!.stems.map((stem) {
          if (stem.id == stemId) {
            return stem.copyWith(isMuted: mute);
          }
          return stem;
        }).toList();
        
        _currentSong = _currentSong!.copyWith(stems: updatedStems);
        notifyListeners();
      }
    }
  }

  Future<void> soloStem(String stemId, bool solo) async {
    if (_currentSong == null) return;

    for (final stem in _currentSong!.stems) {
      final player = _stemPlayers[stem.id];
      if (player != null) {
        if (solo) {
          // Mute all other stems
          await player.setVolume(stem.id == stemId ? stem.volume : 0.0);
        } else {
          // Restore original volumes
          await player.setVolume(stem.isMuted ? 0.0 : stem.volume);
        }
      }
    }

    // Update the stem in the current song
    final updatedStems = _currentSong!.stems.map((stem) {
      return stem.copyWith(isSolo: stem.id == stemId ? solo : false);
    }).toList();
    
    _currentSong = _currentSong!.copyWith(stems: updatedStems);
    notifyListeners();
  }

  @override
  void dispose() {
    _mainPlayer?.dispose();
    for (final player in _stemPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }
}
