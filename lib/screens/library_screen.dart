import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, processed, unprocessed

  // Mock data - in a real app, this would come from a database or shared state
  final List<Song> _allSongs = [];

  List<Song> get _filteredSongs {
    var songs = _allSongs.where((song) {
      final matchesSearch = song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _filterType == 'all' ||
          (_filterType == 'processed' && song.isProcessed) ||
          (_filterType == 'unprocessed' && !song.isProcessed);
      
      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by creation date (newest first)
    songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Songs'),
              ),
              const PopupMenuItem(
                value: 'processed',
                child: Text('Processed Only'),
              ),
              const PopupMenuItem(
                value: 'unprocessed',
                child: Text('Unprocessed Only'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getFilterDisplayName(_filterType),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),

          // Stats row
          if (_allSongs.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Songs',
                      value: _allSongs.length.toString(),
                      icon: Icons.library_music,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Processed',
                      value: _allSongs.where((s) => s.isProcessed).length.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending',
                      value: _allSongs.where((s) => !s.isProcessed).length.toString(),
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Songs list
          Expanded(
            child: _filteredSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return _LibrarySongCard(song: song);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_allSongs.isEmpty) {
      message = 'No songs in library';
      subtitle = 'Import songs from the Home tab to get started';
      icon = Icons.library_music_outlined;
    } else if (_searchQuery.isNotEmpty) {
      message = 'No results found';
      subtitle = 'Try adjusting your search query';
      icon = Icons.search_off;
    } else {
      message = 'No songs match filter';
      subtitle = 'Try changing the filter criteria';
      icon = Icons.filter_list_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'processed':
        return 'Processed';
      case 'unprocessed':
        return 'Pending';
      default:
        return 'All';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LibrarySongCard extends StatelessWidget {
  final Song song;

  const _LibrarySongCard({required this.song});

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
                  song.isProcessed 
                      ? '${song.stems.length} stems available'
                      : 'Not processed',
                  style: TextStyle(
                    color: song.isProcessed ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(song.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.isProcessed) ...[
              IconButton(
                onPressed: () {
                  // Navigate to player with this song
                  final playerService = context.read<AudioPlayerService>();
                  playerService.loadSong(song);
                },
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Play',
              ),
              IconButton(
                onPressed: () {
                  _showStemDetails(context, song);
                },
                icon: const Icon(Icons.info_outline),
                tooltip: 'Details',
              ),
            ] else
              IconButton(
                onPressed: () {
                  // Navigate to home screen for processing
                },
                icon: const Icon(Icons.auto_fix_high),
                tooltip: 'Process',
              ),
          ],
        ),
      ),
    );
  }

  void _showStemDetails(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Stems',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...song.stems.map((stem) => ListTile(
              leading: Icon(_getStemIcon(stem.type)),
              title: Text(stem.displayName),
              trailing: Text('${stem.duration.inMinutes}:${(stem.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
            )),
          ],
        ),
      ),
    );
  }

  IconData _getStemIcon(stemType) {
    switch (stemType.toString()) {
      case 'StemType.vocals':
        return Icons.mic;
      case 'StemType.drums':
        return Icons.album;
      case 'StemType.bass':
        return Icons.music_note;
      case 'StemType.guitar':
        return Icons.music_note;
      case 'StemType.piano':
        return Icons.piano;
      default:
        return Icons.audiotrack;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
