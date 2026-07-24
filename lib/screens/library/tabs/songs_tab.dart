import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/audio_controller.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/song_tile.dart';

class SongsTab extends StatelessWidget {
  final VoidCallback onNavigateToPlayer;

  const SongsTab({
    super.key,
    required this.onNavigateToPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final audioController = Get.find<AudioController>();

    return Obx(() {
      if (libraryController.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final songs = libraryController.songs;

      if (songs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.music_note, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No local songs found.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => libraryController.scanLibrary(),
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Rescan Library'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            contextQueue: songs,
            onTap: () {
              audioController.playSong(song, contextQueue: songs);
              onNavigateToPlayer();
            },
          );
        },
      );
    });
  }
}