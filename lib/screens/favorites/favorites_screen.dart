import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              CupertinoIcons.heart_fill,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Favorite Songs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final songs = favoritesController.favoriteSongs;
            if (songs.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                CupertinoIcons.play_circle_fill,
                color: colorScheme.primary,
                size: 28,
              ),
              onPressed: () {
                audioController.setQueue(songs, initialIndex: 0);
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        final favSongs = favoritesController.favoriteSongs;

        if (favSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.heart,
                  size: 64,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any song to add it here.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: favSongs.length,
          itemBuilder: (context, index) {
            final song = favSongs[index];
            return SongTile(
              song: song,
              index: index,
              contextQueue: favSongs,
              onTap:
                  () => audioController.playSong(
                    song,
                    contextQueue: favSongs,
                  ),
            );
          },
        );
      }),
    );
  }
}
