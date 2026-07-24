import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import 'artwork_widget.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.queue, size: 22),
                    const SizedBox(width: 8),
                    Obx(() => Text(
                          'Playing Queue (${audioController.queue.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
                TextButton(
                  onPressed: () => audioController.clearQueue(),
                  child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final queue = audioController.queue;
              final current = audioController.currentSong.value;

              if (queue.isEmpty) {
                return const Center(
                  child: Text('Queue is empty'),
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: queue.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  audioController.reorderQueue(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isCurrent = current?.id == song.id;

                  return ListTile(
                    key: ValueKey('${song.id}_$index'),
                    leading: ArtworkWidget(artworkUrl: song.artwork, size: 42),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark, size: 18),
                          onPressed: () => audioController.removeFromQueue(index),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                    onTap: () => audioController.skipToQueueItem(index),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
