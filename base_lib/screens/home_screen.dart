import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/song_model.dart';
import '../services/audio_separation_service.dart';
import '../services/audio_player_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _uuid = Uuid();
  final List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final separationService = context.read<AudioSeparationService>();
    final playerService = context.read<AudioPlayerService>();
    
    await separationService.initialize();
    await playerService.initialize();
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${permission.toString()} permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAudioFile() async {
    await _requestPermissions();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _importAudioFile(file.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final fileNameWithoutExtension = fileName.split('.').first;
      
      // Extract title and artist from filename (basic implementation)
      final parts = fileNameWithoutExtension.split(' - ');
      final title = parts.length > 1 ? parts[1] : fileNameWithoutExtension;
      final artist = parts.length > 1 ? parts[0] : 'Unknown Artist';

      final song = Song(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        filePath: filePath,
        duration: const Duration(minutes: 3, seconds: 30), // Mock duration
        createdAt: DateTime.now(),
      );

      setState(() {
        _songs.add(song);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported: $title'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processSong(Song song) async {
    final separationService = context.read<AudioSeparationService>();
    
    try {
      final processedSong = await separationService.separateAudio(song);
      
      setState(() {
        final index = _songs.indexWhere((s) => s.id == song.id);
        if (index != -1) {
          _songs[index] = processedSong;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully processed: ${song.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Splitter'),
        elevation: 0,
      ),
      body: Consumer<AudioSeparationService>(
        builder: (context, separationService, child) {
          return Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI-Powered Song Splitter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Separate vocals, drums, bass, and other instruments from your favorite songs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Import button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: separationService.isProcessing ? null : _pickAudioFile,
                    icon: const Icon(Icons.add),
                    label: const Text('Import Audio File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Processing indicator
              if (separationService.isProcessing)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Processing Audio...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: separationService.processingProgress,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(separationService.processingProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // Songs list
              Expanded(
                child: _songs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_music_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No songs imported yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Import an audio file to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return _SongCard(
                            song: song,
                            onProcess: () => _processSong(song),
                            isProcessing: separationService.isProcessing &&
                                separationService.currentProcessingId == song.id,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onProcess;
  final bool isProcessing;

  const _SongCard({
    required this.song,
    required this.onProcess,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.artist),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  song.isProcessed ? Icons.check_circle : Icons.pending,
                  size: 16,
                  color: song.isProcessed ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  song.isProcessed ? 'Processed' : 'Not processed',
                  style: TextStyle(
                    color: song.isProcessed ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: song.isProcessed
            ? IconButton(
                onPressed: () {
                  final playerService = context.read<AudioPlayerService>();
                  playerService.loadSong(song);
                },
                icon: const Icon(Icons.play_arrow),
              )
            : isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: onProcess,
                    icon: const Icon(Icons.auto_fix_high),
                  ),
      ),
    );
  }
}
