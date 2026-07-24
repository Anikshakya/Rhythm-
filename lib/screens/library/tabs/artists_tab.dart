import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/audio_controller.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/artwork_widget.dart';
import '../../../widgets/custom_scroll_animation.dart';
import '../../../widgets/miniplayer.dart';
import '../../../widgets/fullscreen_player.dart';
import '../../../widgets/song_tile.dart';

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Obx(() {
      final artistsMap = libraryController.artists;

      if (artistsMap.isEmpty) {
        return const Center(
          child: Text('No artists found', style: TextStyle(color: Colors.grey)),
        );
      }

      final artistEntries = artistsMap.entries.toList();

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
          final sampleArt = songs.firstWhere((s) => s.artwork != null && s.artwork!.isNotEmpty, orElse: () => songs.first).artwork;

          return CustomScrollAnimation(
            key: ValueKey('artist_$artistName'),
            index: index,
            child: GestureDetector(
              onTap: () {
                Get.to(() => ArtistDetailScreen(artistName: artistName, songs: songs));
              },
              child: Column(
                children: [
                  ArtworkWidget(
                    songId: songs.first.id,
                    artworkUrl: sampleArt,
                    size: 130,
                    borderRadius: 65,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${songs.length} songs',
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

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final List<dynamic> songs;

  const ArtistDetailScreen({super.key, required this.artistName, required this.songs});

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
      appBar: AppBar(title: Text(artistName)),
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