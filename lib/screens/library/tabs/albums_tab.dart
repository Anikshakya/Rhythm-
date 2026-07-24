import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/audio_controller.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/artwork_widget.dart';
import '../../../widgets/custom_scroll_animation.dart';
import '../../../widgets/miniplayer.dart';
import '../../../widgets/fullscreen_player.dart';
import '../../../widgets/song_tile.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Obx(() {
      final albumsMap = libraryController.albums;

      if (albumsMap.isEmpty) {
        return const Center(
          child: Text('No albums found', style: TextStyle(color: Colors.grey)),
        );
      }

      final albumEntries = albumsMap.entries.toList();

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
          final sampleArt = songs.firstWhere((s) => s.artwork != null && s.artwork!.isNotEmpty, orElse: () => songs.first).artwork;

          return CustomScrollAnimation(
            key: ValueKey('album_$albumName'),
            index: index,
            child: GestureDetector(
              onTap: () {
                Get.to(() => AlbumDetailScreen(albumName: albumName, songs: songs));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ArtworkWidget(
                      songId: songs.first.id,
                      artworkUrl: sampleArt,
                      size: double.infinity,
                      borderRadius: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${songs.length} tracks • ${songs.first.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<dynamic> songs;

  const AlbumDetailScreen({super.key, required this.albumName, required this.songs});

  void _navigateToPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const FullScreenPlayer(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();

    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongTile(
                song: song,
                index: index,
                contextQueue: List.from(songs),
                onTap: () => audioController.playSong(song, contextQueue: List.from(songs)),
              );
            },
          ),

          /// GLOBAL MINI PLAYER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(
              onTap: () => _navigateToPlayer(context),
              onSwipeUp: () => _navigateToPlayer(context),
            ),
          ),
        ],
      ),
    );
  }
}