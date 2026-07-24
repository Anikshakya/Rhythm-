import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../core/models/playlist_model.dart';
import '../../widgets/song_tile.dart';

class PlaylistSongsScreen extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback? onNavigateToPlayer;
  final VoidCallback? onUpdatePlaylist;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    this.onNavigateToPlayer,
    this.onUpdatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
      ),
      body: playlist.songs.isEmpty
          ? const Center(child: Text('No songs in this playlist.'))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: playlist.songs.length,
              itemBuilder: (context, index) {
                final song = playlist.songs[index];
                return SongTile(
                  song: song,
                  contextQueue: playlist.songs,
                  onTap: () {
                    audioController.playSong(song, contextQueue: playlist.songs);
                    if (onNavigateToPlayer != null) onNavigateToPlayer!();
                  },
                );
              },
            ),
    );
  }
}