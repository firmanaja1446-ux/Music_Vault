import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../../models/playlist_model.dart';
import '../widgets/playlist_name_dialog.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await _showNameDialog(context, 'Buat Playlist');

    if (name == null || name.trim().isEmpty || !context.mounted) return;

    await context.read<MusicController>().createPlaylist(name);
  }

  Future<String?> _showNameDialog(
    BuildContext context,
    String title, {
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PlaylistNameDialog(
        title: title,
        initialValue: initialValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Buat playlist',
                  onPressed: () => _createPlaylist(context),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.accent,
                    size: 29,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _likedSongsTile(context, controller),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Playlist kamu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${controller.playlists.length} PLAYLIST',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.playlists.isEmpty)
              _emptyLibrary(context)
            else
              ...controller.playlists.map(
                (playlist) => _playlistTile(context, controller, playlist),
              ),
          ],
        );
      },
    );
  }

  Widget _likedSongsTile(BuildContext context, MusicController controller) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [AppColors.accentMid, AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 27),
        ),
        title: const Text(
          'Liked Songs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${controller.songs.length} lagu tersedia',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur Liked Songs akan dibuat berikutnya.'),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyLibrary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.library_music_outlined,
            color: Colors.white24,
            size: 54,
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada playlist.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buat playlist dan kumpulkan lagu favoritmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _createPlaylist(context),
            icon: const Icon(Icons.add, color: AppColors.accent),
            label: const Text(
              'Buat Playlist',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playlistTile(
    BuildContext context,
    MusicController controller,
    PlaylistModel playlist,
  ) {
    final songCount = controller.getPlaylistSongs(playlist.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentDark,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.queue_music,
              color: AppColors.accent,
              size: 26,
            ),
          ),
          title: Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '$songCount lagu',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            color: AppColors.tile,
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onSelected: (value) async {
              if (value == 'rename') {
                final name = await _showNameDialog(
                  context,
                  'Ubah Nama Playlist',
                  initialValue: playlist.name,
                );

                if (name != null &&
                    name.trim().isNotEmpty &&
                    context.mounted) {
                  await controller.renamePlaylist(playlist.id, name);
                }
              } else if (value == 'delete') {
                await controller.deletePlaylist(playlist.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'rename',
                child: Text('Ubah nama'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Hapus playlist',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
