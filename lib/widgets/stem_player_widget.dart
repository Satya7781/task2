import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stem_model.dart';
import '../services/audio_player_service.dart';

class StemPlayerWidget extends StatefulWidget {
  final List<Stem> stems;

  const StemPlayerWidget({
    super.key,
    required this.stems,
  });

  @override
  State<StemPlayerWidget> createState() => _StemPlayerWidgetState();
}

class _StemPlayerWidgetState extends State<StemPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Stem Controls',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Master volume control
                  IconButton(
                    onPressed: () => _showMasterControls(context),
                    icon: const Icon(Icons.tune),
                    tooltip: 'Master Controls',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stem controls
              Expanded(
                child: ListView.builder(
                  itemCount: widget.stems.length,
                  itemBuilder: (context, index) {
                    final stem = widget.stems[index];
                    return _StemControlCard(
                      stem: stem,
                      onVolumeChanged: (volume) {
                        playerService.setStemVolume(stem.id, volume);
                      },
                      onMuteToggled: (muted) {
                        playerService.muteStem(stem.id, muted);
                      },
                      onSoloToggled: (solo) {
                        playerService.soloStem(stem.id, solo);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMasterControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Reset All Volumes'),
              subtitle: const Text('Set all stems to 80% volume'),
              onTap: () {
                Navigator.pop(context);
                _resetAllVolumes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute All'),
              subtitle: const Text('Mute all stems'),
              onTap: () {
                Navigator.pop(context);
                _muteAll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Unmute All'),
              subtitle: const Text('Unmute all stems'),
              onTap: () {
                Navigator.pop(context);
                _unmuteAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllVolumes() {
    final playerService = context.read<AudioPlayerService>();
    for (final stem in widget.stems) {
      playerService.setStemVolume(stem.id, 0.8);
    }
  }

  void _muteAll() {
    final playerService = context.read<AudioPlayerService>();
    for (final stem in widget.stems) {
      playerService.muteStem(stem.id, true);
    }
  }

  void _unmuteAll() {
    final playerService = context.read<AudioPlayerService>();
    for (final stem in widget.stems) {
      playerService.muteStem(stem.id, false);
    }
  }
}

class _StemControlCard extends StatelessWidget {
  final Stem stem;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMuteToggled;
  final ValueChanged<bool> onSoloToggled;

  const _StemControlCard({
    required this.stem,
    required this.onVolumeChanged,
    required this.onMuteToggled,
    required this.onSoloToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                // Stem icon and name
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStemColor(stem.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStemIcon(stem.type),
                    color: _getStemColor(stem.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stem.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDuration(stem.duration),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Control buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Solo button
                    IconButton(
                      onPressed: () => onSoloToggled(!stem.isSolo),
                      icon: Icon(
                        stem.isSolo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: stem.isSolo ? Colors.orange : Colors.grey,
                      ),
                      tooltip: 'Solo',
                    ),
                    // Mute button
                    IconButton(
                      onPressed: () => onMuteToggled(!stem.isMuted),
                      icon: Icon(
                        stem.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: stem.isMuted ? Colors.red : Colors.grey,
                      ),
                      tooltip: 'Mute',
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Volume slider
            Row(
              children: [
                Icon(
                  Icons.volume_down,
                  size: 16,
                  color: Colors.grey[600],
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: _getStemColor(stem.type),
                      thumbColor: _getStemColor(stem.type),
                    ),
                    child: Slider(
                      value: stem.isMuted ? 0.0 : stem.volume,
                      onChanged: stem.isMuted ? null : onVolumeChanged,
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(stem.volume * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStemIcon(StemType type) {
    switch (type) {
      case StemType.vocals:
        return Icons.mic;
      case StemType.drums:
        return Icons.album;
      case StemType.bass:
        return Icons.music_note;
      case StemType.guitar:
        return Icons.music_note;
      case StemType.piano:
        return Icons.piano;
      case StemType.harmony:
        return Icons.queue_music;
      case StemType.other:
        return Icons.audiotrack;
    }
  }

  Color _getStemColor(StemType type) {
    switch (type) {
      case StemType.vocals:
        return Colors.blue;
      case StemType.drums:
        return Colors.red;
      case StemType.bass:
        return Colors.green;
      case StemType.guitar:
        return Colors.orange;
      case StemType.piano:
        return Colors.purple;
      case StemType.harmony:
        return Colors.teal;
      case StemType.other:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
