import 'package:dhun/widgets/fullscreen_player.dart';
import 'package:dhun/widgets/song_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' as on_audio;
import '../../core/models/playlist_model.dart';
import '../../core/services/audio_handler.dart';

// --- MAIN SCREEN ---

class PlaylistSongsScreen extends StatefulWidget {
  final PlaylistModel playlist;
  final VoidCallback onNavigateToPlayer;
  final VoidCallback onUpdatePlaylist;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.onNavigateToPlayer,
    required this.onUpdatePlaylist,
  });

  @override
  State<PlaylistSongsScreen> createState() => _PlaylistSongsScreenState();
}

class _PlaylistSongsScreenState extends State<PlaylistSongsScreen> {
  
  void _playSong(int index) async {
    if (!mounted) return;
    
    // Navigate using Cupertino transition
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const FullScreenPlayer()),
    );

    final handler = audioHandler as AudioPlayerHandler;
    handler.setQueue(widget.playlist.songs);
    await handler.playSongAt(index);
  }

  Future<void> _confirmRemoveSong(int index) async {
    final song = widget.playlist.songs[index];
    
    // Using Cupertino Style Dialog to match your Tile
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Remove Song'),
        content: Text('Are you sure you want to remove "${song.title}" from this playlist?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => widget.playlist.songs.removeAt(index));
      widget.onUpdatePlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songs = widget.playlist.songs;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        // Thin iOS-style bottom border
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      body: songs.isEmpty
          ? Center(
              child: Text(
                'No songs in this playlist',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final playlistSong = songs[index];
                
                // Map the custom PlaylistSong to the expected SongModel
                // Note: Use the constructor that matches your on_audio_query version
                final songModel = on_audio.SongModel({
                  '_id': playlistSong.id,
                  'title': playlistSong.title,
                  'artist': playlistSong.artist,
                  'duration': playlistSong.duration,
                  // Add other required fields from your PlaylistSong model
                });

                return SongTile(
                  song: songModel, // Now the types match!
                  index: index,
                  onTap: () => _playSong(index),
                  onLongPress: () => _confirmRemoveSong(index),
                );
              },
            ),
    );
  }
}