import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../core/models/song_model.dart';
import 'artwork_widget.dart';
import 'custom_scroll_animation.dart';
import 'ios_popover_menu.dart';

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
        final isPlayingCurrent =
            audioController.currentSong.value?.id == song.id;
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
            onLongPress: () {
              final box = context.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);
              _showIosPopUp(
                context,
                offset,
                audioController,
                favoritesController,
                playlistController,
                primaryColor,
              );
            },
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
                            fontWeight:
                                isPlayingCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                            color:
                                isPlayingCurrent
                                    ? primaryColor
                                    : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (song.isNetwork)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
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
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
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
                          child: Icon(
                            CupertinoIcons.heart_fill,
                            color: primaryColor,
                            size: 16,
                          ),
                        ),
                      Text(
                        _formatDuration(song.duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (btnContext) {
                          return IconButton(
                            icon: Icon(
                              CupertinoIcons.ellipsis,
                              size: 20,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () {
                              final box =
                                  btnContext.findRenderObject() as RenderBox;
                              final offset = box.localToGlobal(Offset.zero);
                              _showIosPopUp(
                                context,
                                offset,
                                audioController,
                                favoritesController,
                                playlistController,
                                primaryColor,
                              );
                            },
                          );
                        },
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
    Offset position,
    AudioController audioController,
    FavoritesController favoritesController,
    PlaylistController playlistController,
    Color primaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = favoritesController.isFavorite(song.id);

    showIosPopoverMenu(
      context: context,
      position: position,
      isCentered: false,
      width: 250,
      children: [
        /// SONG HEADER INFO
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
        ),

        Divider(
          height: 0.5,
          thickness: 0.5,
          color: isDark ? Colors.white12 : Colors.black12,
        ),

        ...IosPopoverMenu.buildActionList(
          isDark: isDark,
          isFirstGroup: false,
          isLastGroup: false,
          actions: [
            IosPopoverAction(
              title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              iconColor: isFav ? primaryColor : null,
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
            IosPopoverAction(
              title: 'Play Next',
              icon: CupertinoIcons.text_insert,
              onTap: () {
                audioController.playNext(song);
                Navigator.pop(context);
                Get.snackbar(
                  'Queue',
                  'Playing next: ${song.title}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            IosPopoverAction(
              title: 'Add to Queue',
              icon: CupertinoIcons.list_bullet_indent,
              onTap: () {
                audioController.addToQueue(song);
                Navigator.pop(context);
                Get.snackbar(
                  'Queue',
                  'Added to queue: ${song.title}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            IosPopoverAction(
              title: 'Add to Playlist',
              icon: CupertinoIcons.music_albums,
              onTap: () {
                Navigator.pop(context);
                _showIosPlaylistPicker(
                  context,
                  position,
                  playlistController,
                  primaryColor,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Sub-dialog for selecting a playlist
  void _showIosPlaylistPicker(
    BuildContext context,
    Offset position,
    PlaylistController controller,
    Color primaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showIosPopoverMenu(
      context: context,
      position: position,
      isCentered: false,
      width: 250,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
            ],
          ),
        ),

        Divider(
          height: 0.5,
          thickness: 0.5,
          color: isDark ? Colors.white12 : Colors.black12,
        ),

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
                children: IosPopoverMenu.buildActionList(
                  isDark: isDark,
                  isFirstGroup: false,
                  isLastGroup: false,
                  actions:
                      controller.playlists.map((pl) {
                        return IosPopoverAction(
                          title: pl.name,
                          icon: CupertinoIcons.music_note_list,
                          trailing: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${pl.songCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            await controller.addSongToPlaylist(pl.id, song);
                            navigator.pop();
                            Get.snackbar(
                              'Playlist',
                              'Added to "${pl.name}"',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
