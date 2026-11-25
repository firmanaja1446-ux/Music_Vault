import 'package:flutter/material.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../../models/music_model.dart';
import '../screens/equalizer_screen.dart';

Future<void> confirmDeleteSong(
  BuildContext context,
  MusicController controller,
  MusicModel song,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text(
          'Hapus Musik?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'File "${song.title}" akan dihapus dari folder MusicVault. '
          'File asli di lokasi sebelumnya tidak akan dihapus.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  final success = await controller.removeSong(song);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Musik berhasil dihapus dari MusicVault.'
            : controller.errorMessage ?? 'Gagal menghapus musik.',
      ),
    ),
  );
}

class SongTile extends StatelessWidget {
  final MusicController controller;
  final MusicModel song;

  /// Posisi lagu di library (dipakai untuk memutar dari lagu ini).
  final int index;

  const SongTile({
    super.key,
    required this.controller,
    required this.song,
    required this.index,
  });

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = controller.currentSong?.id == song.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isCurrent ? Icons.graphic_eq : Icons.music_note,
          color: AppColors.accent,
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => controller.playSong(index),
            icon: const Icon(
              Icons.play_circle_fill,
              color: AppColors.accent,
              size: 30,
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.panel,
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onSelected: (value) async {
              switch (value) {
                case 'equalizer':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EqualizerScreen(song: song),
                    ),
                  );
                case 'next':
                  await controller.playNext(song);
                  if (context.mounted) {
                    _showMessage(context, 'Akan diputar berikutnya.');
                  }
                case 'queue':
                  await controller.addToQueue(song);
                  if (context.mounted) {
                    _showMessage(context, 'Ditambahkan ke antrean.');
                  }
                case 'delete':
                  await confirmDeleteSong(context, controller, song);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'equalizer',
                child: Row(
                  children: [
                    Icon(Icons.equalizer_rounded, color: AppColors.accent),
                    SizedBox(width: 10),
                    Text(
                      'Equalizer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'next',
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: AppColors.accent),
                    SizedBox(width: 10),
                    Text(
                      'Putar berikutnya',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'queue',
                child: Row(
                  children: [
                    Icon(Icons.queue_music, color: AppColors.accent),
                    SizedBox(width: 10),
                    Text(
                      'Tambah ke antrean',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.accent),
                    SizedBox(width: 10),
                    Text(
                      'Hapus dari MusicVault',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => controller.playSong(index),
    );
  }
}

