import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../core/models/song_model.dart';
import '../../widgets/song_tile.dart';

class AlbumSongsScreen extends StatelessWidget {
  final String albumName;
  final List<Song> songs;
  final VoidCallback? onNavigateToPlayer;

  const AlbumSongsScreen({
    super.key,
    required this.albumName,
    required this.songs,
    this.onNavigateToPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs found in this album.'))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  contextQueue: songs,
                  onTap: () {
                    audioController.playSong(song, contextQueue: songs);
                    if (onNavigateToPlayer != null) onNavigateToPlayer!();
                  },
                );
              },
            ),
    );
  }
}