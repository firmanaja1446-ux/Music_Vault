import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        final playlist = controller.playlists
            .where((item) => item.id == playlistId)
            .firstOrNull;

        if (playlist == null) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Text(
                'Playlist tidak ditemukan.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final songs = controller.getPlaylistSongs(playlistId);

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text(
              playlist.name,
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'Putar acak',
                onPressed: songs.isEmpty
                    ? null
                    : () => controller.playShuffled(songs),
                icon: const Icon(Icons.shuffle, color: Colors.white70),
              ),
              IconButton(
                tooltip: 'Tambah lagu',
                onPressed: () => _showAddSongs(context),
                icon: const Icon(Icons.add, color: AppColors.accent),
              ),
            ],
          ),
          body: songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_off,
                        color: Colors.white24,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Playlist ini masih kosong.',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddSongs(context),
                        icon: const Icon(Icons.add, color: AppColors.accent),
                        label: const Text(
                          'Tambah Lagu',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: AppColors.tile,
                        onSelected: (value) {
                          if (value == 'remove') {
                            controller.removeSongFromPlaylist(
                              playlistId,
                              song.id,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Keluarkan dari playlist'),
                          ),
                        ],
                      ),
                      onTap: () => controller.playQueue(songs, index),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _showAddSongs(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            // Consumer supaya ikon centang ikut ter-update saat lagu ditambah.
            child: Consumer<MusicController>(
              builder: (context, controller, child) {
                final playlist = controller.playlists
                    .where((item) => item.id == playlistId)
                    .firstOrNull;

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Tambah Lagu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: controller.songs.isEmpty || playlist == null
                          ? const Center(
                              child: Text(
                                'Belum ada musik di perangkat.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.songs.length,
                              itemBuilder: (context, index) {
                                final song = controller.songs[index];
                                final alreadyAdded =
                                    playlist.songIds.contains(song.id);

                                return ListTile(
                                  title: Text(
                                    song.title,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: const TextStyle(
                                        color: Colors.white54),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      alreadyAdded
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: alreadyAdded
                                          ? Colors.white38
                                          : AppColors.accent,
                                    ),
                                    onPressed: alreadyAdded
                                        ? null
                                        : () => controller.addSongToPlaylist(
                                              playlistId,
                                              song.id,
                                            ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
