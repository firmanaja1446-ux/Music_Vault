import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import 'queue_screen.dart';
import 'equalizer_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        final song = controller.currentSong;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: Colors.white,
              iconSize: 30,
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Sedang Diputar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Equalizer',
                icon: const Icon(Icons.equalizer_rounded),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EqualizerScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Antrean',
                icon: const Icon(Icons.queue_music_rounded),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QueueScreen()),
                  );
                },
              ),
            ],
          ),
          body: song == null
              ? const Center(
                  child: Text(
                    'Pilih lagu untuk mulai mendengarkan',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: AppColors.tile,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.album_rounded,
                            size: 130,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildProgress(controller),
                        const SizedBox(height: 16),
                        _buildControls(controller),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProgress(MusicController controller) {
    return StreamBuilder<Duration>(
      stream: controller.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = controller.player.duration ?? Duration.zero;
        final maxValue = duration.inMilliseconds > 0
            ? duration.inMilliseconds.toDouble()
            : 1.0;
        final value = position.inMilliseconds.toDouble().clamp(0.0, maxValue);

        return Column(
          children: [
            Slider(
              value: value,
              max: maxValue,
              onChanged: duration.inMilliseconds > 0
                  ? (newValue) {
                      controller.player.seek(
                        Duration(milliseconds: newValue.toInt()),
                      );
                    }
                  : null,
              activeColor: AppColors.accent,
              inactiveColor: Colors.white24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white60),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(MusicController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<bool>(
          stream: controller.player.shuffleModeEnabledStream,
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return IconButton(
              tooltip: 'Acak',
              onPressed: controller.toggleShuffle,
              icon: const Icon(Icons.shuffle_rounded),
              color: enabled ? AppColors.accent : Colors.white54,
              iconSize: 28,
            );
          },
        ),
        IconButton(
          onPressed: controller.previousSong,
          icon: const Icon(Icons.skip_previous_rounded),
          color: Colors.white,
          iconSize: 42,
        ),
        StreamBuilder<bool>(
          stream: controller.player.playingStream,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return IconButton.filled(
              onPressed: controller.togglePlayPause,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              iconSize: 38,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            );
          },
        ),
        IconButton(
          onPressed: controller.nextSong,
          icon: const Icon(Icons.skip_next_rounded),
          color: Colors.white,
          iconSize: 42,
        ),
        StreamBuilder<LoopMode>(
          stream: controller.player.loopModeStream,
          builder: (context, snapshot) {
            final mode = snapshot.data ?? LoopMode.off;
            return IconButton(
              tooltip: 'Ulangi',
              onPressed: controller.cycleLoopMode,
              icon: Icon(
                mode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
              ),
              color: mode == LoopMode.off ? Colors.white54 : AppColors.accent,
              iconSize: 28,
            );
          },
        ),
      ],
    );
  }
}


