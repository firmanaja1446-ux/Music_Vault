import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        final queue = controller.queue;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Antrean (${queue.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: queue.isEmpty
              ? const Center(
                  child: Text(
                    'Antrean kosong.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : Column(
                  children: [
                    StreamBuilder<bool>(
                      stream: controller.player.shuffleModeEnabledStream,
                      builder: (context, snapshot) {
                        if (snapshot.data != true) {
                          return const SizedBox.shrink();
                        }
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
                          child: Text(
                            'Mode acak aktif: urutan putar diacak, '
                            'daftar di bawah menunjukkan urutan asli.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: queue.length,
                        onReorderItem: (oldIndex, newIndex) { controller.moveInQueue(oldIndex, newIndex); },
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isCurrent =
                              controller.player.currentIndex == index;

                          return ListTile(
                            key: ValueKey('queue-$index-${song.id}'),
                            leading: Icon(
                              isCurrent ? Icons.graphic_eq : Icons.music_note,
                              color: AppColors.accent,
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Hapus dari antrean',
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () =>
                                      controller.removeFromQueue(index),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => controller.playQueueIndex(index),
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
}
