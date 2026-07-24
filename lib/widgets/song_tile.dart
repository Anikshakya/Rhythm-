import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../core/models/song_model.dart';
import 'artwork_widget.dart';
import 'custom_scroll_animation.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song>? contextQueue;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    this.index = 0,
    this.contextQueue,
    this.onTap,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final favoritesController = Get.find<FavoritesController>();
    final playlistController = Get.find<PlaylistController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollAnimation(
      index: index,
      child: Obx(() {
        final isPlayingCurrent = audioController.currentSong.value?.id == song.id;
        final isFav = favoritesController.isFavorite(song.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                onTap!();
              } else {
                audioController.playSong(song, contextQueue: contextQueue);
              }
            },
            onLongPress: () => _showCupertinoActionSheet(context, audioController, favoritesController, playlistController),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [

                  /// ARTWORK + PLAYING INDICATOR
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ArtworkWidget(
                        songId: song.id,
                        artworkUrl: song.artwork,
                        size: 52,
                        borderRadius: 10,
                      ),
                      if (isPlayingCurrent)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.speaker_2_fill,
                            color: Color(0xFFFA2D48),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  /// TITLE & ARTIST
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isPlayingCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isPlayingCurrent
                                ? const Color(0xFFFA2D48)
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (song.isNetwork)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA2D48).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ONLINE',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFA2D48)),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                '${song.artist} • ${song.album}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// DURATION & OVERFLOW BUTTON
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFav)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(CupertinoIcons.heart_fill, color: Color(0xFFFA2D48), size: 16),
                        ),
                      Text(
                        _formatDuration(song.duration),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(CupertinoIcons.ellipsis, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                        onPressed: () => _showCupertinoActionSheet(context, audioController, favoritesController, playlistController),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showCupertinoActionSheet(
    BuildContext context,
    AudioController audioController,
    FavoritesController favoritesController,
    PlaylistController playlistController,
  ) {
    final isFav = favoritesController.isFavorite(song.id);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        message: Text('${song.artist} • ${song.album}'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFav ? const Color(0xFFFA2D48) : CupertinoColors.activeBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
              ],
            ),
            onPressed: () {
              favoritesController.toggleFavoriteSong(song);
              Navigator.pop(context);
              Get.snackbar(
                'Favorites',
                isFav ? 'Removed from favorites' : 'Added to favorites',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.text_insert, size: 20),
                SizedBox(width: 8),
                Text('Play Next'),
              ],
            ),
            onPressed: () {
              audioController.playNext(song);
              Navigator.pop(context);
              Get.snackbar('Queue', 'Playing next: ${song.title}', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.list_bullet_indent, size: 20),
                SizedBox(width: 8),
                Text('Add to Queue'),
              ],
            ),
            onPressed: () {
              audioController.addToQueue(song);
              Navigator.pop(context);
              Get.snackbar('Queue', 'Added to queue: ${song.title}', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.music_albums, size: 20),
                SizedBox(width: 8),
                Text('Add to Playlist'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _showCupertinoPlaylistPicker(context, playlistController);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCupertinoPlaylistPicker(BuildContext context, PlaylistController controller) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        message: Text(song.title),
        actions: controller.playlists.isEmpty
            ? [
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No playlists found. Create one first!'),
                ),
              ]
            : controller.playlists.map((pl) {
                return CupertinoActionSheetAction(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await controller.addSongToPlaylist(pl.id, song);
                    navigator.pop();
                    Get.snackbar('Playlist', 'Added to "${pl.name}"', snackPosition: SnackPosition.BOTTOM);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.music_note_list, size: 18),
                      const SizedBox(width: 8),
                      Text('${pl.name} (${pl.songCount} songs)'),
                    ],
                  ),
                );
              }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}