import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../core/models/playlist_model.dart';
import '../../widgets/miniplayer.dart';
import '../../widgets/fullscreen_player.dart';
import '../../widgets/song_tile.dart';

class PlaylistsScreen extends StatelessWidget {
  final VoidCallback onNavigateToPlayer;

  const PlaylistsScreen({
    super.key,
    required this.onNavigateToPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final playlistController = Get.find<PlaylistController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (playlistController.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final playlists = playlistController.playlists;

        if (playlists.isEmpty) {
          return const Center(child: Text('No playlists created yet'));
        }

        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.music_albums, color: Colors.white),
              ),
              title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${playlist.songCount} songs'),
              onTap: () {
                Get.to(() => PlaylistDetailScreen(playlist: playlist));
              },
            );
          },
        );
      }),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

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
    final playlistController = Get.find<PlaylistController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.play_circle_fill, color: Color(0xFFFA2D48), size: 28),
            onPressed: () {
              if (playlist.songs.isNotEmpty) {
                audioController.setQueue(playlist.songs, initialIndex: 0);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            final currentPlaylist = playlistController.playlists.firstWhere(
              (p) => p.id == playlist.id,
              orElse: () => playlist,
            );

            if (currentPlaylist.songs.isEmpty) {
              return const Center(child: Text('Playlist is empty'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: currentPlaylist.songs.length,
              itemBuilder: (context, index) {
                final song = currentPlaylist.songs[index];
                return Dismissible(
                  key: ValueKey('${song.id}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(CupertinoIcons.trash, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    playlistController.removeSongFromPlaylist(playlist.id, song.id);
                  },
                  child: SongTile(
                    song: song,
                    index: index,
                    contextQueue: currentPlaylist.songs,
                    onTap: () => audioController.playSong(song, contextQueue: currentPlaylist.songs),
                  ),
                );
              },
            );
          }),

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