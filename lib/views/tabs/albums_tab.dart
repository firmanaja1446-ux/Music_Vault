import 'package:flutter/material.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class AlbumsTab extends StatelessWidget {
  final MusicController controller;

  const AlbumsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final songs = controller.songs;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.library_music,
                  color: AppColors.accent, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MusicVault Storage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${songs.length} songs on this device',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.loadSongs(),
                icon: const Icon(Icons.refresh, color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (songs.isEmpty)
          const EmptyState(
            message:
                'Belum ada musik di MusicVault. Tekan Tambah Musik untuk memulai.',
          )
        else
          for (var i = 0; i < songs.length; i++)
            SongTile(controller: controller, song: songs[i], index: i),
      ],
    );
  }
}
