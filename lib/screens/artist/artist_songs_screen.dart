import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../core/models/song_model.dart';
import '../../widgets/song_tile.dart';

class ArtistSongsScreen extends StatelessWidget {
  final String artistName;
  final List<Song> songs;
  final VoidCallback? onNavigateToPlayer;

  const ArtistSongsScreen({
    super.key,
    required this.artistName,
    required this.songs,
    this.onNavigateToPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs found for this artist.'))
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