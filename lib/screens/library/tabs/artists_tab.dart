import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:melo/screens/artist/artist_songs_screen.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/artwork_widget.dart';
import '../../../widgets/custom_scroll_animation.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Obx(() {
      final artistEntries = libraryController.filteredArtists;

      if (artistEntries.isEmpty) {
        return Center(
          child: Text(
            libraryController.searchQuery.value.isNotEmpty
                ? 'No matching artists found'
                : 'No artists found',
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
        itemCount: artistEntries.length,
        itemBuilder: (context, index) {
          final entry = artistEntries[index];
          final artistName = entry.key;
          final songs = entry.value;
          final sampleArt =
              songs
                  .firstWhere(
                    (s) => s.artwork != null && s.artwork!.isNotEmpty,
                    orElse: () => songs.first,
                  )
                  .artwork;

          return CustomScrollAnimation(
            key: ValueKey('artist_$artistName'),
            index: index,
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => ArtistDetailScreen(
                    key: ValueKey('artist_$artistName'),
                    artistName: artistName,
                    songs: songs,
                  ),
                  preventDuplicates: false,
                  transition: Transition.cupertinoDialog,
                );
              },
              child: Column(
                children: [
                  Hero(
                    tag: ValueKey('artist_hero_$artistName'),
                    child: ArtworkWidget(
                      songId: songs.first.id,
                      artworkUrl: sampleArt,
                      size: 160,
                      borderRadius: 24,
                      artworkType: ArtworkType.ARTIST,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${songs.length} songs',
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