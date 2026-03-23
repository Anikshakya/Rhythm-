import 'dart:convert';
import 'dart:io';
import 'package:dhun/widgets/custom_scroll_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import '../../../core/models/playlist_model.dart';
import '../../playlists/playlist_songs_screen.dart';

class PlaylistsTab extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;
  const PlaylistsTab({super.key, required this.onNavigateToPlayer});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  List<PlaylistModel> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  Future<void> _loadPlaylists() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List<dynamic>;
        if (mounted) {
          setState(() {
            _playlists = jsonList
                .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        final favorite = PlaylistModel(name: 'Favorites', songs: [], isFavourite: true);
        _playlists = [favorite];
        await _savePlaylists();
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlaylists() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(_playlists.map((p) => p.toJson()).toList()));
  }

  void _showCreateDialog() {
    if (_playlists.length >= 6) return; // Limit check

    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Playlist'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Playlist Name',
            autofocus: true,
            style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Create'),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _playlists.add(PlaylistModel(name: name, songs: []));
                });
                _savePlaylists();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        /// iOS Style "Add New" Row
        GestureDetector(
          onTap: _showCreateDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.plus_circle_fill, color: CupertinoColors.systemPink.resolveFrom(context)),
                const SizedBox(width: 12),
                const Text('New Playlist...', style: TextStyle(fontSize: 17, color: CupertinoColors.systemPink)),
              ],
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return CustomScrollAnimation(
                      key: ValueKey(playlist.name + index.toString()),
                      index: index,
                      child: _buildPlaylistTile(playlist, index, isDark),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistTile(PlaylistModel playlist, int index, bool isDark) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => PlaylistSongsScreen(
              playlist: playlist,
              onNavigateToPlayer: widget.onNavigateToPlayer,
              onUpdatePlaylist: () {
                setState(() {});
                _savePlaylists();
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            /// Playlist Artwork Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              ),
              child: Icon(
                playlist.isFavourite ? CupertinoIcons.heart_fill : CupertinoIcons.music_note_list,
                color: playlist.isFavourite ? CupertinoColors.systemPink : (isDark ? Colors.white30 : Colors.black26),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${playlist.songs.length} songs',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, size: 18, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}