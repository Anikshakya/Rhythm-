import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/playlist_controller.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/custom_scroll_animation.dart';
import '../../favorites/favorites_screen.dart';
import '../../playlists/playlists_screen.dart';

class PlaylistsTab extends StatelessWidget {
  final VoidCallback onNavigateToPlayer;

  const PlaylistsTab({super.key, required this.onNavigateToPlayer});

  void _showIOSContextMenu(
    BuildContext context,
    Offset position,
    PlaylistController controller,
    dynamic playlist,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              right: 16,
              top: position.dy,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2E).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Duplicate Action
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                controller.duplicatePlaylist(playlist);
                              },
                              splashColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              highlightColor:
                                  isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Duplicate',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.doc_on_doc,
                                      size: 20,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1),
                          ),

                          /// Delete Action
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(
                                  context,
                                  controller,
                                  playlist,
                                );
                              },
                              splashColor: CupertinoColors.destructiveRed
                                  .withValues(alpha: 0.15),
                              highlightColor: CupertinoColors.destructiveRed
                                  .withValues(alpha: 0.1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Delete Playlist',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: CupertinoColors.destructiveRed,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.trash,
                                      size: 20,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                  ],
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
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final playlistController = Get.find<PlaylistController>();
    final favoritesController = Get.find<FavoritesController>();
    final libraryController = Get.find<LibraryController>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final iosDividerColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    );

    return Obx(() {
      if (playlistController.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final query = libraryController.searchQuery.value.toLowerCase();
      final filteredPlaylists =
          playlistController.playlists.where((pl) {
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
                  libraryController.searchQuery.value.isNotEmpty
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
    });
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
}
