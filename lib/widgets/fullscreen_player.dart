import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/library_controller.dart';
import '../core/models/song_model.dart';
import 'artwork_widget.dart';
import 'ios_popover_menu.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;
  late Animation<double> _scaleAnimation;

  // Tracks the last song so we can detect changes
  String? _lastSongId;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.06).animate(
      CurvedAnimation(parent: _playPauseController, curve: Curves.easeOutBack),
    );

    // Start from the "paused" scale so the first appearance also bounces
    _playPauseController.value = 0.0;
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Triggers the same scale bounce used by play/pause
  void _triggerArtworkBounce({required bool isPlaying}) {
    if (isPlaying) {
      _playPauseController.forward(from: 0.0);
    } else {
      _playPauseController.reverse(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final favoritesController = Get.find<FavoritesController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      final currentSong = audioController.currentSong.value;
      final isPlaying = audioController.playing.value;

      // ── Detect song change (next / previous / open) ──────────────────────
      final currentId = currentSong?.id;
      if (currentId != null && currentId != _lastSongId) {
        _lastSongId = currentId;
        // Run after the current frame so AnimatedSwitcher has already swapped
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _triggerArtworkBounce(isPlaying: isPlaying);
          }
        });
      } else {
        // Normal play/pause (no song change)
        if (isPlaying) {
          _playPauseController.forward();
        } else {
          _playPauseController.reverse();
        }
      }

      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // Ambient Blur Backdrop
            if (currentSong != null)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      key: ValueKey(currentSong.id),
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: 0.16,
                          child: Transform.scale(
                            scale: 1.5,
                            child: ArtworkWidget(
                              songId: currentSong.id,
                              artworkUrl: currentSong.artwork,
                              borderRadius: 0,
                            ),
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Column(
              children: [
                const SizedBox(height: 18),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.chevron_down,
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Column(
                        children: [
                          Text(
                            'PLAYING FROM QUEUE',
                            style: TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentSong?.album ?? 'Rhythm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (btnContext) {
                          return IconButton(
                            icon: Icon(
                              CupertinoIcons.ellipsis,
                              size: 22,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            onPressed: () {
                              final box =
                                  btnContext.findRenderObject() as RenderBox;
                              final offset = box.localToGlobal(Offset.zero);
                              _showIosOptionsDialog(
                                context,
                                offset,
                                audioController,
                                favoritesController,
                                currentSong,
                                primaryColor,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Artwork
                if (currentSong != null)
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.96,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: ValueKey(currentSong.id),
                        width: MediaQuery.of(context).size.width * 0.80,
                        height: MediaQuery.of(context).size.width * 0.80,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: MediaQuery.of(context).size.width * 0.80,
                            height: MediaQuery.of(context).size.width * 0.80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isDark
                                          ? Colors.white.withValues(
                                            alpha: isPlaying ? 0.15 : 0.12,
                                          )
                                          : Colors.black.withValues(
                                            alpha: isPlaying ? 0.2 : 0.2,
                                          ),
                                  blurRadius: 12,
                                  spreadRadius: isPlaying ? 6 : 2,
                                  offset: Offset(0, isPlaying ? 4 : 2),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'artwork_${currentSong.id}',
                              child: ArtworkWidget(
                                songId: currentSong.id,
                                artworkUrl: currentSong.artwork,
                                size: MediaQuery.of(context).size.width * 0.80,
                                borderRadius: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // Song Info + Favorite
                if (currentSong != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: Row(
                        key: ValueKey(currentSong.id),
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              favoritesController.isFavorite(currentSong.id)
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color:
                                  favoritesController.isFavorite(currentSong.id)
                                      ? primaryColor
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                              size: 24,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              favoritesController.toggleFavoriteSong(
                                currentSong,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // iOS Style Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProgressSlider(
                    position: audioController.position.value,
                    total: audioController.totalDuration.value,
                    primaryColor: primaryColor,
                    onSeek: (duration) => audioController.seek(duration),
                  ),
                ),

                const SizedBox(height: 12),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.shuffle,
                        color:
                            audioController.shuffleMode.value ==
                                    AudioServiceShuffleMode.all
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        audioController.toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.backward_fill,
                        size: 34,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => audioController.previous(),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        audioController.playing.value
                            ? audioController.pause()
                            : audioController.play();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          audioController.playing.value
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          color: isDark ? Colors.white : Colors.black,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.forward_fill,
                        size: 34,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => audioController.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        audioController.repeatMode.value ==
                                AudioServiceRepeatMode.one
                            ? CupertinoIcons.repeat_1
                            : CupertinoIcons.repeat,
                        color:
                            audioController.repeatMode.value !=
                                    AudioServiceRepeatMode.none
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        audioController.cycleRepeat();
                      },
                    ),
                  ],
                ),

                const Spacer(),

                // Bottom Toolbar – with speed + sleep countdown
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── Playback Speed ──────────────────────────────
                      Obx(() {
                        final speed = audioController.speed.value;
                        final isCustom = speed != 1.0;
                        return GestureDetector(
                          onTap:
                              () => _showIosSpeedDialog(
                                context,
                                audioController,
                                primaryColor,
                              ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.speedometer,
                                color:
                                    isCustom
                                        ? primaryColor
                                        : (isDark
                                            ? Colors.white54
                                            : Colors.black45),
                                size: 21,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isCustom ? '${speed}x' : 'Speed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      isCustom
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color:
                                      isCustom
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.black45),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // ── Sleep Timer + Countdown ─────────────────────
                      Obx(() {
                        final remaining = audioController.sleepTimer.value;
                        final isActive =
                            remaining != null && remaining > Duration.zero;
                        return GestureDetector(
                          onTap:
                              () => _showIosSleepTimerDialog(
                                context,
                                audioController,
                                primaryColor,
                              ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.timer,
                                color:
                                    isActive
                                        ? primaryColor
                                        : (isDark
                                            ? Colors.white54
                                            : Colors.black45),
                                size: 21,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isActive
                                    ? _formatCountdown(remaining)
                                    : 'Timer',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color:
                                      isActive
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.black45),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // ── Queue ───────────────────────────────────────
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.list_bullet,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        onPressed:
                            () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const QueueSheet(),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ==================== Dialogs ====================

void _showIosOptionsDialog(
  BuildContext context,
  Offset position,
  AudioController controller,
  FavoritesController favs,
  dynamic song,
  Color primaryColor,
) {
  if (song == null) return;
  HapticFeedback.mediumImpact();

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isFav = favs.isFavorite(song.id);

  showIosPopoverMenu(
    context: context,
    position: position,
    isCentered: false,
    width: 250,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ArtworkWidget(
              songId: song.id,
              artworkUrl: song.artwork,
              size: 48,
              borderRadius: 10,
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
                  Text(
                    song.artist,
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
            title: isFav ? 'Remove Favorite' : 'Favorite Song',
            icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            iconColor: isFav ? primaryColor : null,
            onTap: () {
              favs.toggleFavoriteSong(song);
            },
          ),
          IosPopoverAction(
            title: 'Play Next',
            icon: CupertinoIcons.text_insert,
            onTap: () {
              controller.playNext(song);
            },
          ),
        ],
      ),
    ],
  );
}

void _showIosSpeedDialog(
  BuildContext context,
  AudioController controller,
  Color primaryColor,
) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showIosPopoverMenu(
    context: context,
    isCentered: true,
    width: 260,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Playback Speed',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
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
        actions:
            [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
              return IosPopoverAction(
                title: '${s}x Speed',
                icon: CupertinoIcons.speedometer,
                trailing: Obx(() {
                  final isSelected = controller.speed.value == s;
                  return isSelected
                      ? Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: primaryColor,
                      )
                      : const SizedBox.shrink();
                }),
                onTap: () {
                  controller.setSpeed(s);
                },
              );
            }).toList(),
      ),
    ],
  );
}

void _showIosSleepTimerDialog(
  BuildContext context,
  AudioController controller,
  Color primaryColor,
) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showIosPopoverMenu(
    context: context,
    isCentered: true,
    width: 260,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Sleep Timer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
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
            title: 'Off',
            icon: CupertinoIcons.clear_circled,
            isDestructive: true,
            onTap: () {
              controller.setSleepTimer(null);
            },
          ),
          IosPopoverAction(
            title: '15 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 15));
            },
          ),
          IosPopoverAction(
            title: '30 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 30));
            },
          ),
          IosPopoverAction(
            title: '60 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 60));
            },
          ),
        ],
      ),
    ],
  );
}

// ==================== Queue Sheet ====================
class QueueSheet extends StatefulWidget {
  const QueueSheet({super.key});

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
              ? queue.indexWhere((s) => s.id == currentSong.id)
              : -1;
      final upNext =
          (currentIndex >= 0 && currentIndex < queue.length)
              ? queue.sublist(currentIndex + 1)
              : queue;

      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.72,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
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
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // --- DRAG HANDLE ---
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 12),
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiaryLabel.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),

                    // --- TOP NOW PLAYING SECTION ---
                    if (currentSong != null)
                      SliverToBoxAdapter(
                        child: _buildNowPlayingHeader(currentSong, context),
                      ),

                    // --- 4 PILL CONTROL BUTTONS ---
                    SliverToBoxAdapter(
                      child: _buildPillControlsRow(context, isDark),
                    ),

                    // --- QUEUE HEADER ---
                    SliverToBoxAdapter(
                      child: Padding(
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
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (_isHistoryMode) {
                                  libraryController.clearHistory();
                                } else {
                                  audioController.clearQueue();
                                }
                              },
                              minimumSize: const Size(0, 0),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- QUEUE ITEMS ---
                    if (_isHistoryMode)
                      Obx(() {
                        final history = libraryController.recentlyPlayed;
                        if (history.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No recently played songs',
                                  style: TextStyle(
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final song = history[index];
                            return _buildHistoryTile(context, song);
                          }, childCount: history.length),
                        );
                      })
                    else
                      SliverReorderableList(
                        itemCount: upNext.length,
                        onReorder: (oldIndex, newIndex) {
                          final actualOld = currentIndex + 1 + oldIndex;
                          final actualNew = currentIndex + 1 + newIndex;
                          audioController.reorderQueue(actualOld, actualNew);
                        },
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final animValue = Curves.easeOutBack.transform(
                                animation.value,
                              );
                              return Transform.scale(
                                scale: lerpDouble(1.0, 1.04, animValue)!,
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: lerpDouble(0, 10, animValue)!,
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
                          );
                        },
                      ),

                    // --- ADD SONGS TO QUEUE BUTTON ---
                    if (!_isHistoryMode)
                      SliverToBoxAdapter(
                        child: _buildAddSongsTile(context, isDark),
                      ),
                    // --- AUTOPLAY HEADER ---
                    if (!_isHistoryMode)
                      Obx(() {
                        if (!audioController.autoplayEnabled.value) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.infinite,
                                      size: 20,
                                      color: CupertinoColors.label.resolveFrom(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'AutoPlay',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Similar music will keep playing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    // --- AUTOPLAY ITEMS ---
                    if (!_isHistoryMode)
                      Obx(() {
                        if (!audioController.autoplayEnabled.value ||
                            audioController.autoplayQueue.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final song = audioController.autoplayQueue[index];
                            return _buildAutoplayTile(context, song);
                          }, childCount: audioController.autoplayQueue.length),
                        );
                      }),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  /// 1. TOP NOW PLAYING TILE WITH STAR & MORE BUTTONS
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

          // Star / Favorite Button
          _CircleIconButton(
            icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            onTap: (_) {
              favoritesController.toggleFavoriteSong(song);
              setState(() {});
            },
          ),
          const SizedBox(width: 10),

          // More Options Button
          _CircleIconButton(
            icon: CupertinoIcons.ellipsis,
            onTap: (btnContext) {
              final box = btnContext.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);
              _showIosOptionsDialog(
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

  /// 2. APPLE MUSIC 4-PILL CONTROL ROW
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
              child: _PillButton(
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
              child: _PillButton(
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
              child: _PillButton(
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
              child: _PillButton(
                icon: CupertinoIcons.line_horizontal_3_decrease,
                isActive: _isHistoryMode,
                onTap: () => setState(() => _isHistoryMode = !_isHistoryMode),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 3. QUEUE ITEM LIST TILE
  Widget _buildQueueTile({
    required Key key,
    required dynamic song,
    required int index,
  }) {
    final dragIndex =
        index -
        (audioController.currentSong.value != null
            ? audioController.queue.indexWhere(
                  (s) => s.id == audioController.currentSong.value!.id,
                ) +
                1
            : 0);

    return ReorderableDelayedDragStartListener(
      key: key,
      index: dragIndex,
      child: Dismissible(
        key: key,
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          color: Colors.transparent,
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
                ReorderableDragStartListener(
                  index: dragIndex,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 4,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Icon(
                      CupertinoIcons.bars,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 4. "ADD SONGS TO QUEUE" BUTTON TILE
  Widget _buildAddSongsTile(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
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

  /// AUTOPLAY TILE
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
            _CircleIconButton(
              icon: CupertinoIcons.ellipsis,
              onTap: (btnContext) {
                final box = btnContext.findRenderObject() as RenderBox;
                final offset = box.localToGlobal(Offset.zero);
                _showIosOptionsDialog(
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

  /// HISTORY TILE
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
            _CircleIconButton(
              icon: CupertinoIcons.ellipsis,
              onTap: (btnContext) {
                final box = btnContext.findRenderObject() as RenderBox;
                final offset = box.localToGlobal(Offset.zero);
                _showIosOptionsDialog(
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

// ==================== Add Songs Sheet ====================
class AddSongsSheet extends StatefulWidget {
  const AddSongsSheet({super.key});

  @override
  State<AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<AddSongsSheet> {
  final libraryController = Get.find<LibraryController>();
  final audioController = Get.find<AudioController>();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Songs to Queue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: CupertinoSearchTextField(
                      placeholder: 'Search songs or artists...',
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List
                  Expanded(
                    child: Obx(() {
                      final allSongs = libraryController.songs;
                      final filtered =
                          allSongs.where((song) {
                            final q = _searchQuery.toLowerCase();
                            return song.title.toLowerCase().contains(q) ||
                                song.artist.toLowerCase().contains(q);
                          }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No songs found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final Song song = filtered[index];
                          // Check if it's already in the queue or current
                          final isInQueue =
                              audioController.queue.any(
                                (s) => s.id == song.id,
                              ) ||
                              audioController.currentSong.value?.id == song.id;

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: ArtworkWidget(
                                songId: song.id,
                                artworkUrl: song.artwork,
                                size: 40,
                                borderRadius: 6,
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            trailing:
                                isInQueue
                                    ? Icon(
                                      CupertinoIcons.checkmark_alt_circle_fill,
                                      color: primaryColor,
                                      size: 24,
                                    )
                                    : IconButton(
                                      icon: const Icon(
                                        CupertinoIcons.plus_circle,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        audioController.addToQueue(song);
                                        setState(() {});
                                        Get.snackbar(
                                          'Added to Queue',
                                          '"${song.title}" was added to your queue.',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor:
                                              isDark
                                                  ? Colors.black87
                                                  : Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                          colorText:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                          duration: const Duration(seconds: 1),
                                        );
                                      },
                                    ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CIRCULAR ICON BUTTON FOR NOW PLAYING ACTIONS
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Function(BuildContext) onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return InkWell(
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

/// WIDE PILL CONTROL BUTTON
class _PillButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Theme-driven background colors
    final baseBg = colorScheme.onSurface.withValues(alpha: 0.08);
    final activeBg = colorScheme.primaryContainer.withValues(alpha: 0.7);

    // Theme-driven icon colors
    final activeIconColor = colorScheme.onPrimaryContainer;
    final inactiveIconColor = colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? activeBg : baseBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? activeIconColor : inactiveIconColor,
        ),
      ),
    );
  }
}

class _ProgressSlider extends StatefulWidget {
  final Duration position;
  final Duration total;
  final Color primaryColor;
  final ValueChanged<Duration> onSeek;

  const _ProgressSlider({
    required this.position,
    required this.total,
    required this.primaryColor,
    required this.onSeek,
  });

  @override
  State<_ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<_ProgressSlider>
    with SingleTickerProviderStateMixin {
  bool _dragging = false;
  double _dragValue = 0.0;

  late final AnimationController _interactionController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _trackHeightAnimation;
  late final Animation<double> _timeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(begin: 1.04, end: 1.065).animate(
      CurvedAnimation(
        parent: _interactionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _trackHeightAnimation = Tween<double>(begin: 5.0, end: 7.5).animate(
      CurvedAnimation(
        parent: _interactionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _timeScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _interactionController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _interactionController.dispose();
    super.dispose();
  }

  void _onInteractionStart(double v) {
    setState(() {
      _dragging = true;
      _dragValue = v;
    });
    _interactionController.forward();
  }

  void _onInteractionEnd(double v) {
    setState(() {
      _dragging = false;
      _dragValue = v;
    });
    _interactionController.reverse();
    widget.onSeek(Duration(milliseconds: v.round()));
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxMs =
        widget.total.inMilliseconds > 0
            ? widget.total.inMilliseconds.toDouble()
            : 1.0;

    final currentMs =
        _dragging
            ? _dragValue
            : widget.position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    final currentDuration = Duration(milliseconds: currentMs.round());
    final totalDuration = widget.total;

    return AnimatedBuilder(
      animation: _interactionController,
      builder: (context, child) {
        final isInteracting = _dragging || _interactionController.isAnimating;

        final Color activeTrackColor;
        final Color inactiveTrackColor;

        if (isDark) {
          activeTrackColor =
              isInteracting
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75);
          inactiveTrackColor =
              isInteracting
                  ? Colors.white.withValues(alpha: 0.38)
                  : Colors.white24;
        } else {
          activeTrackColor =
              isInteracting
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.55);
          inactiveTrackColor =
              isInteracting
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black12;
        }

        final timeColor =
            isInteracting
                ? (isDark ? Colors.white : Colors.black)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.45));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: _trackHeightAnimation.value,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0.0,
                    pressedElevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  activeTrackColor: activeTrackColor,
                  inactiveTrackColor: inactiveTrackColor,
                  overlayColor: widget.primaryColor.withValues(alpha: 0.18),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: currentMs,
                  max: maxMs,
                  onChangeStart: _onInteractionStart,
                  onChanged: (v) {
                    setState(() => _dragValue = v);
                  },
                  onChangeEnd: _onInteractionEnd,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: _timeScaleAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatDuration(currentDuration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isInteracting ? FontWeight.w600 : FontWeight.w500,
                        color: timeColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: _timeScaleAnimation.value,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isInteracting ? FontWeight.w600 : FontWeight.w500,
                        color: timeColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
