import 'dart:convert';
import 'dart:io';
import 'package:dhun/widgets/custom_scroll_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:dhun/widgets/song_tile.dart';
import 'package:dhun/core/services/audio_handler.dart';
import '../../../core/models/playlist_model.dart';

class SongsTab extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;
  const SongsTab({super.key, required this.onNavigateToPlayer});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<PlaylistModel> _playlists = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _loadPlaylists();
  }

  /// ===============================
  /// PLAYLIST PERSISTENCE
  /// ===============================

  Future<File> get _playlistFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  Future<void> _loadPlaylists() async {
    try {
      final file = await _playlistFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        if (mounted) {
          setState(() {
            _playlists = jsonList.map((e) => PlaylistModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final file = await _playlistFile;
      await file.writeAsString(
        jsonEncode(_playlists.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  /// ===============================
  /// ADD TO PLAYLIST DIALOG (YOUR UI)
  /// ===============================

  void _showAddToPlaylistDialog(SongModel song) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          backgroundColor: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.playlist_add, color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Playlist',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Playlist list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final alreadyAdded = playlist.songs.any((s) => s.id == song.id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: alreadyAdded ? null : () async {
                          playlist.songs.add(
                            PlaylistSong(
                              id: song.id,
                              title: song.title,
                              artist: song.artist ?? 'Unknown Artist',
                              data: song.data,
                              duration: song.duration,
                            ),
                          );
                          await _savePlaylists();
                          setState(() {});
                          Navigator.pop(ctx);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${song.title}" to ${playlist.name}'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alreadyAdded ? Colors.grey.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  playlist.isFavourite ? Icons.favorite : Icons.playlist_play,
                                  color: alreadyAdded ? (isDark ? Colors.white38 : Colors.black38) : theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: alreadyAdded ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) : theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${playlist.songs.length} songs', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (alreadyAdded) Icon(Icons.check_circle, color: Colors.green.withValues(alpha: 0.7), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ===============================
  /// CORE BUILD
  /// ===============================

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (mounted) setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSongs = _songs.where((song) {
      final lowerSearch = _searchText.toLowerCase();
      return song.title.toLowerCase().contains(lowerSearch) ||
          (song.artist ?? '').toLowerCase().contains(lowerSearch);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CupertinoSearchTextField(
            backgroundColor: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),

            placeholder: 'Search songs',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            placeholderStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),

            // Optional: cursor color for visibility
            cursorColor: isDark ? Colors.white : Colors.black,

            onChanged: (value) => setState(() => _searchText = value),
          )
        ),
        Expanded(
          child: _songs.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 0, bottom: 120),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    return CustomScrollAnimation(
                      key: ValueKey(song.id),
                      index: index,
                      child: SongTile(
                        song: song,
                        index: index,
                        onTap: () async {
                          widget.onNavigateToPlayer();
                          final handler = audioHandler as AudioPlayerHandler;
                          handler.setQueue(_songs);
                          await handler.playSongAt(_songs.indexOf(song));
                        },
                        onLongPress: () => _showAddToPlaylistDialog(song),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}