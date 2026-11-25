import 'package:flutter/material.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../../models/music_model.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  final MusicController controller;

  const MiniPlayer({super.key, required this.controller});

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = controller.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      ),
      child: _buildBar(context, song),
    );
  }

  Widget _buildBar(BuildContext context, MusicModel song) {
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 3),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<bool>(
                  stream: controller.player.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;

                    return IconButton(
                      onPressed: controller.togglePlayPause,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: controller.nextSong,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: AppColors.accent,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<Duration>(
            stream: controller.player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = controller.player.duration ?? Duration.zero;

              final maxValue = duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0;

              final value =
                  position.inMilliseconds.toDouble().clamp(0.0, maxValue);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 12,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 4,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        min: 0,
                        max: maxValue,
                        value: value,
                        activeColor: AppColors.accent,
                        inactiveColor: Colors.white24,
                        onChanged: duration.inMilliseconds > 0
                            ? (newValue) {
                                controller.player.seek(
                                  Duration(milliseconds: newValue.toInt()),
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(position),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatTime(duration),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
