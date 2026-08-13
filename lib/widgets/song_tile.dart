import 'dart:ui';
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
    final primaryColor = theme.colorScheme.primary; // Theme-aware accent color

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
            onLongPress: () => _showIosPopUp(context, audioController, favoritesController, playlistController, primaryColor),
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
                          child: Icon(
                            CupertinoIcons.speaker_2_fill,
                            color: primaryColor,
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
                            color: isPlayingCurrent ? primaryColor : (isDark ? Colors.white : Colors.black),
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
                                  color: primaryColor.withValues(alpha:0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ONLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
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
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(CupertinoIcons.heart_fill, color: primaryColor, size: 16),
                        ),
                      Text(
                        _formatDuration(song.duration),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(CupertinoIcons.ellipsis, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                        onPressed: () => _showIosPopUp(context, audioController, favoritesController, playlistController, primaryColor),
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

  /// Displays a smooth iOS-style central pop-up modal
  void _showIosPopUp(
    BuildContext context,
    AudioController audioController,
    FavoritesController favoritesController,
    PlaylistController playlistController,
    Color primaryColor,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha:0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isFav = favoritesController.isFavorite(song.id);

        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252525).withValues(alpha:0.85)
                          : Colors.white.withValues(alpha:0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// SONG HEADER INFO
                        Row(
                          children: [
                            ArtworkWidget(
                              songId: song.id,
                              artworkUrl: song.artwork,
                              size: 48,
                              borderRadius: 12,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${song.artist} • ${song.album}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 8),

                        /// POPUP OPTIONS LIST
                        _buildPopUpAction(
                          context: context,
                          icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          iconColor: isFav ? primaryColor : null,
                          title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                          isDark: isDark,
                          onTap: () {
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
                        _buildPopUpAction(
                          context: context,
                          icon: CupertinoIcons.text_insert,
                          title: 'Play Next',
                          isDark: isDark,
                          onTap: () {
                            audioController.playNext(song);
                            Navigator.pop(context);
                            Get.snackbar('Queue', 'Playing next: ${song.title}', snackPosition: SnackPosition.BOTTOM);
                          },
                        ),
                        _buildPopUpAction(
                          context: context,
                          icon: CupertinoIcons.list_bullet_indent,
                          title: 'Add to Queue',
                          isDark: isDark,
                          onTap: () {
                            audioController.addToQueue(song);
                            Navigator.pop(context);
                            Get.snackbar('Queue', 'Added to queue: ${song.title}', snackPosition: SnackPosition.BOTTOM);
                          },
                        ),
                        _buildPopUpAction(
                          context: context,
                          icon: CupertinoIcons.music_albums,
                          title: 'Add to Playlist',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            _showIosPlaylistPicker(context, playlistController, primaryColor);
                          },
                        ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 8),

                        /// CANCEL BUTTON
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper for building individual pop-up options
  Widget _buildPopUpAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-dialog for selecting a playlist
  void _showIosPlaylistPicker(
    BuildContext context,
    PlaylistController controller,
    Color primaryColor,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha:0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252525).withValues(alpha:0.85)
                          : Colors.white.withValues(alpha:0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Add to Playlist',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 8),

                        if (controller.playlists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No playlists found. Create one first!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: controller.playlists.map((pl) {
                                  return _buildPopUpAction(
                                    context: context,
                                    icon: CupertinoIcons.music_note_list,
                                    title: '${pl.name} (${pl.songCount} songs)',
                                    isDark: isDark,
                                    onTap: () async {
                                      final navigator = Navigator.of(context);
                                      await controller.addSongToPlaylist(pl.id, song);
                                      navigator.pop();
                                      Get.snackbar('Playlist', 'Added to "${pl.name}"', snackPosition: SnackPosition.BOTTOM);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 8),

                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}