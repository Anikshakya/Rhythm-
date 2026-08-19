import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:melo/screens/albums/album_songs_screen.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/artwork_widget.dart';
import '../../../widgets/custom_scroll_animation.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Obx(() {
      final albumEntries = libraryController.filteredAlbums;

      if (albumEntries.isEmpty) {
        return Center(
          child: Text(
            libraryController.searchQuery.value.isNotEmpty
                ? 'No matching albums found'
                : 'No albums found',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: albumEntries.length,
        itemBuilder: (context, index) {
          final entry = albumEntries[index];
          final albumName = entry.key;
          final songs = entry.value;
          final sampleArt =
              songs
                  .firstWhere(
                    (s) => s.artwork != null && s.artwork!.isNotEmpty,
                    orElse: () => songs.first,
                  )
                  .artwork;

          return CustomScrollAnimation(
            key: ValueKey('album_$albumName'),
            index: index,
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => AlbumDetailScreen(
                    key: ValueKey('album_$albumName'),
                    albumName: albumName,
                    songs: songs,
                  ),
                  preventDuplicates: false,
                  transition: Transition.cupertinoDialog,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Hero(
                          tag: ValueKey('album_hero_$albumName'),
                          child: ArtworkWidget(
                            songId: songs.first.id,
                            artworkUrl: sampleArt,
                            size: constraints.maxWidth,
                            borderRadius: 16,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${songs.length} tracks • ${songs.first.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}