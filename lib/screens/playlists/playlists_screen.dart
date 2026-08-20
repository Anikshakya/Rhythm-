import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/models/playlist_model.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/ios_pop_over.dart';
import '../../widgets/custom_scroll_animation.dart';
import '../../widgets/miniplayer.dart';
import '../../widgets/fullscreen_player.dart';
import '../favorites/favorites_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const PlaylistsScreen({super.key, required this.onNavigateToPlayer});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final playlistController = Get.find<PlaylistController>();
  final favoritesController = Get.find<FavoritesController>();
  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showIOSContextMenu(
    BuildContext context,
    Offset position,
    PlaylistController controller,
    dynamic playlist,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showIosPopoverMenu(
      context: context,
      position: position,
      isCentered: false,
      width: 250,
      children: IosPopoverMenu.buildActionList(
        isDark: isDark,
        actions: [
          IosPopoverAction(
            title: 'Duplicate',
            icon: CupertinoIcons.doc_on_doc,
            iconOnRight: true,
            onTap: () {
              controller.duplicatePlaylist(playlist);
            },
          ),
          IosPopoverAction(
            title: 'Delete Playlist',
            icon: CupertinoIcons.trash,
            iconOnRight: true,
            isDestructive: true,
            onTap: () {
              _showDeleteConfirmation(context, controller, playlist);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PlaylistController controller,
    dynamic playlist,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  controller.deletePlaylist(playlist.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showCreateDialog(BuildContext context, PlaylistController controller) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('New Playlist'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: nameCtrl,
                  placeholder: 'Playlist Name',
                  padding: const EdgeInsets.all(10),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: descCtrl,
                  placeholder: 'Description (Optional)',
                  padding: const EdgeInsets.all(10),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  controller.createPlaylist(
                    nameCtrl.text,
                    description: descCtrl.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final iosDividerColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// APPLE MUSIC LARGE HEADER TITLE & SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Playlists',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (val) {
                        searchQuery.value = val;
                      },
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        hintText: 'Search playlists...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: Obx(() {
                          final query = searchQuery.value;
                          if (query.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                            child: Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 16,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          );
                        }),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// PLAYLISTS DASHBOARD LIST
            Expanded(
              child: Obx(() {
                if (playlistController.isLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                final query = searchQuery.value.toLowerCase();
                final filteredPlaylists = playlistController.playlists.where((pl) {
                  return pl.name.toLowerCase().contains(query);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    /// CREATE PLAYLIST BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.plus,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              'New Playlist...',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            onTap: () => _showCreateDialog(context, playlistController),
                          ),
                        ),
                      ),
                    ),

                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 88,
                      color: iosDividerColor,
                    ),

                    /// FAVORITES PINNED ITEM
                    Obx(() {
                      final favCount = favoritesController.favoriteSongs.length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.tertiaryContainer,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  CupertinoIcons.heart_fill,
                                  color: colorScheme.onPrimary,
                                  size: 28,
                                ),
                              ),
                              title: const Text(
                                'Favorite Songs',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Text(
                                '$favCount tracks',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Icon(
                                CupertinoIcons.chevron_forward,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                                size: 18,
                              ),
                              onTap: () => Get.to(() => const FavoritesScreen()),
                            ),
                          ),
                        ),
                      );
                    }),

                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 88,
                      color: iosDividerColor,
                    ),

                    /// USER PLAYLISTS SECTION
                    if (filteredPlaylists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                        child: Center(
                          child: Text(
                            searchQuery.value.isNotEmpty
                                ? 'No matching playlists found.'
                                : 'No custom playlists created yet',
                            style: TextStyle(color: theme.disabledColor, fontSize: 15),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredPlaylists.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 0.5,
                              thickness: 0.5,
                              indent: 88,
                              color: iosDividerColor,
                            ),
                        itemBuilder: (context, index) {
                          final playlist = filteredPlaylists[index];
                          return CustomScrollAnimation(
                            key: ValueKey('pl_${playlist.id}'),
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor:
                                        isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : colorScheme.primary.withValues(alpha: 0.1),
                                    highlightColor:
                                        isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : colorScheme.primary.withValues(alpha: 0.05),
                                    onTap: () {
                                      Get.to(
                                        () => PlaylistDetailScreen(playlist: playlist),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      leading: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          playlist.isFavorite
                                              ? CupertinoIcons.heart_fill
                                              : CupertinoIcons.music_albums,
                                          color:
                                              playlist.isFavorite
                                                  ? colorScheme.error
                                                  : colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.7),
                                          size: 26,
                                        ),
                                      ),
                                      title: Text(
                                        playlist.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${playlist.songCount} songs',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Builder(
                                        builder: (btnContext) {
                                          return IconButton(
                                            icon: Icon(
                                              CupertinoIcons.ellipsis,
                                              color: colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.7),
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              final box =
                                                  btnContext.findRenderObject()
                                                      as RenderBox;
                                              final offset = box.localToGlobal(
                                                Offset.zero,
                                              );
                                              _showIOSContextMenu(
                                                context,
                                                offset,
                                                playlistController,
                                                playlist,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  void _navigateToPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const FullScreenPlayer(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioController = Get.find<AudioController>();
    final playlistController = Get.find<PlaylistController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.play_circle_fill,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            onPressed: () {
              if (playlist.songs.isNotEmpty) {
                audioController.setQueue(playlist.songs, initialIndex: 0);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            final currentPlaylist = playlistController.playlists.firstWhere(
              (p) => p.id == playlist.id,
              orElse: () => playlist,
            );

            if (currentPlaylist.songs.isEmpty) {
              return Center(
                child: Text(
                  'Playlist is empty',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: currentPlaylist.songs.length,
              itemBuilder: (context, index) {
                final song = currentPlaylist.songs[index];
                return Dismissible(
                  key: ValueKey('${song.id}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      CupertinoIcons.trash,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  onDismissed: (_) {
                    playlistController.removeSongFromPlaylist(
                      playlist.id,
                      song.id,
                    );
                  },
                  child: SongTile(
                    song: song,
                    index: index,
                    contextQueue: currentPlaylist.songs,
                    onTap:
                        () => audioController.playSong(
                          song,
                          contextQueue: currentPlaylist.songs,
                        ),
                  ),
                );
              },
            );
          }),

          /// GLOBAL MINI PLAYER
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: MiniPlayer(
              onTap: () => _navigateToPlayer(context),
              onSwipeUp: () => _navigateToPlayer(context),
            ),
          ),
        ],
      ),
    );
  }
}