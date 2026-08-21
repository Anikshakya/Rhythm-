import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:melo/core/models/song_model.dart';
import 'package:melo/controllers/audio_controller.dart';
import 'package:melo/controllers/favorites_controller.dart';
import 'package:melo/controllers/library_controller.dart';
import 'package:melo/widgets/artwork_widget.dart';
import 'package:melo/widgets/fullscreen_player.dart';

// ============================================================================
// QUEUE SHEET
// ============================================================================
//
// IMPORTANT:
//
// This widget does NOT contain DraggableScrollableSheet.
//
// The global overlay owns DraggableScrollableSheet and passes its
// ScrollController into this widget.
//
// This same controller MUST be attached to CustomScrollView.
// ============================================================================

class QueueSheet extends StatefulWidget {
  final ScrollController scrollController;

  const QueueSheet({super.key, required this.scrollController});

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  final AudioController audioController = Get.find<AudioController>();

  final FavoritesController favoritesController =
      Get.find<FavoritesController>();

  final LibraryController libraryController = Get.find<LibraryController>();

  bool _isHistoryMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Obx(() {
      final queue = audioController.queue;

      final currentSong = audioController.currentSong.value;

      final currentIndex =
          currentSong != null
              ? queue.indexWhere((song) => song.id == currentSong.id)
              : -1;

      final List<dynamic> upNext =
          currentIndex >= 0 && currentIndex < queue.length
              ? queue.sublist(currentIndex + 1)
              : queue;

      return _buildSheet(
        context: context,
        isDark: isDark,
        currentSong: currentSong,
        currentIndex: currentIndex,
        upNext: upNext,
      );
    });
  }

  // ==========================================================================
  // SHEET
  // ==========================================================================

  Widget _buildSheet({
    required BuildContext context,
    required bool isDark,
    required Song? currentSong,
    required int currentIndex,
    required List<dynamic> upNext,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          color:
              isDark
                  ? CupertinoColors.systemBackground
                      .resolveFrom(context)
                      .withValues(alpha: 0.65)
                  : CupertinoColors.systemGroupedBackground
                      .resolveFrom(context)
                      .withValues(alpha: 0.85),
          child: CustomScrollView(
            // ----------------------------------------------------------------
            // THIS IS THE CONTROLLER PROVIDED BY
            // DraggableScrollableSheet.
            // ----------------------------------------------------------------
            controller: widget.scrollController,

            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),

            slivers: [
              // ==============================================================
              // DRAG HANDLE
              // ==============================================================
              SliverToBoxAdapter(child: _buildDragHandle(context)),

              // ==============================================================
              // NOW PLAYING
              // ==============================================================
              if (currentSong != null)
                SliverToBoxAdapter(
                  child: _buildNowPlayingHeader(currentSong, context),
                ),

              // ==============================================================
              // CONTROLS
              // ==============================================================
              SliverToBoxAdapter(child: _buildPillControlsRow(context, isDark)),

              // ==============================================================
              // QUEUE / HISTORY HEADER
              // ==============================================================
              SliverToBoxAdapter(child: _buildSectionHeader(context)),

              // ==============================================================
              // HISTORY
              // ==============================================================
              if (_isHistoryMode)
                _buildHistoryList(context)
              // ==============================================================
              // QUEUE
              // ==============================================================
              else
                _buildQueueList(context, upNext, currentIndex),

              // ==============================================================
              // ADD SONGS
              // ==============================================================
              if (!_isHistoryMode)
                SliverToBoxAdapter(child: _buildAddSongsTile(context, isDark)),

              // ==============================================================
              // AUTOPLAY HEADER
              // ==============================================================
              if (!_isHistoryMode)
                Obx(() {
                  final enabled = audioController.autoplayEnabled.value;

                  if (!enabled) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: _buildAutoplayHeader(context),
                  );
                }),

              // ==============================================================
              // AUTOPLAY ITEMS
              // ==============================================================
              if (!_isHistoryMode)
                Obx(() {
                  final enabled = audioController.autoplayEnabled.value;

                  final autoplayQueue = audioController.autoplayQueue;

                  if (!enabled || autoplayQueue.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = autoplayQueue[index];

                      return _buildAutoplayTile(context, song);
                    }, childCount: autoplayQueue.length),
                  );
                }),

              // ==============================================================
              // BOTTOM SPACE
              // ==============================================================
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DRAG HANDLE
  // ==========================================================================

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  // ==========================================================================
  // NOW PLAYING HEADER
  // ==========================================================================

  Widget _buildNowPlayingHeader(Song song, BuildContext context) {
    final isFav = favoritesController.isFavorite(song.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ArtworkWidget(
              songId: song.id,
              artworkUrl: song.artwork,
              size: 58,
              borderRadius: 10,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.2,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),

          CircleIconButton(
            icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            onTap: (_) {
              favoritesController.toggleFavoriteSong(song);

              setState(() {});
            },
          ),

          const SizedBox(width: 10),

          CircleIconButton(
            icon: CupertinoIcons.ellipsis,
            onTap: (btnContext) {
              final renderObject = btnContext.findRenderObject();

              if (renderObject is! RenderBox) {
                return;
              }

              final offset = renderObject.localToGlobal(Offset.zero);

              showIosOptionsDialog(
                context,
                offset,
                audioController,
                favoritesController,
                song,
                Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PILL CONTROLS
  // ==========================================================================

  Widget _buildPillControlsRow(BuildContext context, bool isDark) {
    return Obx(() {
      final isShuffle =
          audioController.shuffleMode.value == AudioServiceShuffleMode.all;

      final isRepeat =
          audioController.repeatMode.value != AudioServiceRepeatMode.none;

      final isRepeatOne =
          audioController.repeatMode.value == AudioServiceRepeatMode.one;

      final isAutoplay = audioController.autoplayEnabled.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: PillButton(
                icon: CupertinoIcons.shuffle,
                isActive: isShuffle,
                onTap: () {
                  HapticFeedback.selectionClick();

                  audioController.toggleShuffle();
                },
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: PillButton(
                icon:
                    isRepeatOne
                        ? CupertinoIcons.repeat_1
                        : CupertinoIcons.repeat,
                isActive: isRepeat,
                onTap: () {
                  HapticFeedback.selectionClick();

                  audioController.cycleRepeat();
                },
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: PillButton(
                icon: CupertinoIcons.infinite,
                isActive: isAutoplay,
                onTap: () {
                  HapticFeedback.selectionClick();

                  audioController.autoplayEnabled.toggle();
                },
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: PillButton(
                icon: CupertinoIcons.line_horizontal_3_decrease,
                isActive: _isHistoryMode,
                onTap: () {
                  HapticFeedback.selectionClick();

                  setState(() {
                    _isHistoryMode = !_isHistoryMode;
                  });
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==========================================================================
  // QUEUE / HISTORY HEADER
  // ==========================================================================

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isHistoryMode ? 'History' : 'Queue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),

          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            onPressed: () {
              HapticFeedback.lightImpact();

              if (_isHistoryMode) {
                libraryController.clearHistory();
              } else {
                audioController.clearQueue();
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // QUEUE LIST
  // ==========================================================================

  Widget _buildQueueList(
    BuildContext context,
    List<dynamic> upNext,
    int currentIndex,
  ) {
    if (upNext.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Queue is empty',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ),
        ),
      );
    }

    return SliverReorderableList(
      itemCount: upNext.length,

      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final actualOld = currentIndex + 1 + oldIndex;

        final actualNew = currentIndex + 1 + newIndex;

        audioController.reorderQueue(actualOld, actualNew);
      },

      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final value = Curves.easeOutBack.transform(animation.value);

            return Transform.scale(
              scale: lerpDouble(1.0, 1.04, value)!,
              child: Material(
                color: Colors.transparent,
                elevation: lerpDouble(0, 10, value)!,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            );
          },
        );
      },

      itemBuilder: (context, index) {
        final song = upNext[index];

        return _buildQueueTile(
          key: ValueKey(song.id),
          song: song,
          index: currentIndex + 1 + index,
          reorderIndex: index,
        );
      },
    );
  }

  // ==========================================================================
  // QUEUE TILE
  // ==========================================================================

  Widget _buildQueueTile({
    required Key key,
    required dynamic song,
    required int index,
    required int reorderIndex,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey('dismiss_${song.id}'),
        direction: DismissDirection.endToStart,

        onDismissed: (_) {
          HapticFeedback.mediumImpact();

          audioController.removeFromQueue(index);
        },

        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: CupertinoColors.destructiveRed,
          child: const Icon(
            CupertinoIcons.trash_fill,
            color: Colors.white,
            size: 22,
          ),
        ),

        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();

            audioController.skipToQueueItem(index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ArtworkWidget(
                  songId: song.id,
                  artworkUrl: song.artwork,
                  size: 48,
                  borderRadius: 8,
                ),
              ),

              const SizedBox(width: 14),

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
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: -0.2,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------------------
              // REORDER HANDLE ONLY
              // ------------------------------------------------------------
              ReorderableDragStartListener(
                index: reorderIndex,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Icon(
                    CupertinoIcons.bars,
                    size: 20,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HISTORY
  // ==========================================================================

  Widget _buildHistoryList(BuildContext context) {
    return Obx(() {
      final history = libraryController.recentlyPlayed;

      if (history.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No recently played songs',
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final song = history[index];

          return _buildHistoryTile(context, song);
        }, childCount: history.length),
      );
    });
  }

  // ==========================================================================
  // HISTORY TILE
  // ==========================================================================

  Widget _buildHistoryTile(BuildContext context, Song song) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();

          audioController.playSong(song);
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ArtworkWidget(
                songId: song.id,
                artworkUrl: song.artwork,
                size: 48,
                borderRadius: 8,
              ),
            ),

            const SizedBox(width: 14),

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
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: -0.2,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            CircleIconButton(
              icon: CupertinoIcons.ellipsis,
              onTap: (btnContext) {
                final renderObject = btnContext.findRenderObject();

                if (renderObject is! RenderBox) {
                  return;
                }

                final offset = renderObject.localToGlobal(Offset.zero);

                showIosOptionsDialog(
                  context,
                  offset,
                  audioController,
                  favoritesController,
                  song,
                  Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ADD SONGS
  // ==========================================================================

  Widget _buildAddSongsTile(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();

          showModalBottomSheet(
            context: Get.context ?? context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddSongsSheet(),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.add,
                size: 24,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),

            const SizedBox(width: 14),

            Text(
              'Add Songs to Queue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // AUTOPLAY HEADER
  // ==========================================================================

  Widget _buildAutoplayHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.infinite,
                size: 20,
                color: CupertinoColors.label.resolveFrom(context),
              ),

              const SizedBox(width: 6),

              Text(
                'AutoPlay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          Text(
            'Similar music will keep playing',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // AUTOPLAY TILE
  // ==========================================================================

  Widget _buildAutoplayTile(BuildContext context, Song song) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();

          audioController.playSong(song);
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ArtworkWidget(
                songId: song.id,
                artworkUrl: song.artwork,
                size: 48,
                borderRadius: 8,
              ),
            ),

            const SizedBox(width: 14),

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
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: -0.2,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            CircleIconButton(
              icon: CupertinoIcons.ellipsis,
              onTap: (btnContext) {
                final renderObject = btnContext.findRenderObject();

                if (renderObject is! RenderBox) {
                  return;
                }

                final offset = renderObject.localToGlobal(Offset.zero);

                showIosOptionsDialog(
                  context,
                  offset,
                  audioController,
                  favoritesController,
                  song,
                  Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CIRCLE ICON BUTTON
// ============================================================================

class CircleIconButton extends StatelessWidget {
  final IconData icon;

  final void Function(BuildContext) onTap;

  const CircleIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();

        onTap(context);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
        ),
        child: Icon(
          icon,
          size: 18,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }
}
