import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../models/stem_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/stem_player_widget.dart';
import '../widgets/waveform_widget.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showExportOptions(context);
            },
            icon: const Icon(Icons.file_download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, child) {
          final currentSong = playerService.currentSong;
          
          if (currentSong == null) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Song info section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Album art placeholder
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      currentSong.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSong.artist,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Waveform visualization
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: WaveformWidget(),
              ),

              // Progress and time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: playerService.position.inMilliseconds.toDouble(),
                        max: playerService.duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          playerService.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerService.position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _formatDuration(playerService.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Playback controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Previous track (not implemented)
                      },
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (playerService.isPlaying) {
                            playerService.pause();
                          } else {
                            playerService.play();
                          }
                        },
                        icon: Icon(
                          playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        iconSize: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        // Next track (not implemented)
                      },
                      icon: const Icon(Icons.skip_next),
                      iconSize: 32,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stem controls
              if (currentSong.isProcessed && currentSong.stems.isNotEmpty)
                Expanded(
                  child: StemPlayerWidget(stems: currentSong.stems),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Song not processed yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Process this song to access individual stems',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to home screen for processing
                          },
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Process Song'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No song selected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a song from your library to start playing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to library screen
            },
            icon: const Icon(Icons.library_music),
            label: const Text('Go to Library'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final playerService = context.read<AudioPlayerService>();
    final currentSong = playerService.currentSong;
    
    if (currentSong == null || !currentSong.isProcessed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No processed song to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export All Stems'),
              subtitle: const Text('Export all individual stems as separate files'),
              onTap: () {
                Navigator.pop(context);
                _exportAllStems(currentSong);
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge),
              title: const Text('Export Mixed Audio'),
              subtitle: const Text('Export the current mix as a single file'),
              onTap: () {
                Navigator.pop(context);
                _exportMixedAudio(currentSong);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Custom Export'),
              subtitle: const Text('Choose specific stems to export'),
              onTap: () {
                Navigator.pop(context);
                _showCustomExportDialog(currentSong);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAllStems(Song song) {
    // Implementation for exporting all stems
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting all stems...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportMixedAudio(Song song) {
    // Implementation for exporting mixed audio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting mixed audio...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCustomExportDialog(Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: song.stems.map((stem) => CheckboxListTile(
            title: Text(stem.displayName),
            value: true, // Default to all selected
            onChanged: (value) {
              // Handle stem selection
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement custom export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting selected stems...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
