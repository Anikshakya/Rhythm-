import 'package:dhun/widgets/song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dhun/core/services/audio_handler.dart';

class AlbumSongsScreen extends StatefulWidget {
  final AlbumModel album;
  final VoidCallback onNavigateToPlayer;

  const AlbumSongsScreen({
    super.key,
    required this.album,
    required this.onNavigateToPlayer,
  });

  @override
  State<AlbumSongsScreen> createState() => _AlbumSongsScreenState();
}

class _AlbumSongsScreenState extends State<AlbumSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<void> _playSong(List<SongModel> songs, int index) async {
    widget.onNavigateToPlayer();

    if (!isAudioServiceInitialized()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio service is not ready yet. Please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final handler = audioHandler as AudioPlayerHandler;
    handler.setQueue(songs);
    await handler.playSongAt(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.album),
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.queryAudiosFrom(
          AudiosFromType.ALBUM_ID,
          widget.album.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading songs: ${snapshot.error}'),
            );
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return const Center(
              child: Text('No songs found in this album.'),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return SongTile(
                song: song,
                index: index,
                onTap: () => _playSong(songs, index),
              );
            },
          );
        },
      ),
    );
  }
}