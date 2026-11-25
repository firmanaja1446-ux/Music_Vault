import 'package:flutter/material.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class HomeTab extends StatelessWidget {
  final MusicController controller;

  const HomeTab({super.key, required this.controller});

  Future<void> _addMusic(BuildContext context) async {
    final imported = await controller.importAudioFiles();

    if (!context.mounted) return;

    if (imported > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported file audio berhasil ditambahkan.')),
      );
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage!)),
      );
    }
  }

  Widget _sectionTitle(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null)
            Text(
              action,
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = controller.songs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const Text(
          'YOUR MUSIC, YOUR WORLD',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 178,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.accentMid, AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.graphic_eq, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'MUSICVAULT SPOTLIGHT',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.currentSong?.title ?? 'Your music collection',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.currentSong?.artist ??
                        'Everything you love, in one place.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addMusic(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Musik'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: songs.isEmpty
                    ? null
                    : () => controller.playShuffled(songs),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Acak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        _sectionTitle('Recently Added', action: '${songs.length} TRACKS'),
        if (songs.isEmpty)
          const EmptyState(
            message:
                'Belum ada musik di MusicVault. Tekan Tambah Musik untuk memulai.',
          )
        else
          for (var i = 0; i < songs.length && i < 5; i++)
            SongTile(controller: controller, song: songs[i], index: i),
      ],
    );
  }
}
