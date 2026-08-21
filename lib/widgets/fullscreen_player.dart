import 'dart:ui';

import 'package:melo/screens/artist/artist_songs_screen.dart';
import 'package:melo/screens/albums/album_songs_screen.dart';
import 'package:melo/widgets/audio_speed_dialogue.dart';
import 'package:melo/widgets/global_bottom_sheet.dart';
import 'package:melo/widgets/ios_pop_over.dart';
import 'package:melo/widgets/marquee_text.dart';
import 'package:melo/widgets/queue_sheet.dart';
import 'package:melo/widgets/sleep_timer_dialogue.dart';
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

class FullScreenPlayer extends StatefulWidget {
  final VoidCallback? onDismiss;

  const FullScreenPlayer({super.key, this.onDismiss});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;
  late Animation<double> _scaleAnimation;

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

    return Obx(() {
      final currentSong = audioController.currentSong.value;
      final isPlaying = audioController.playing.value;

      final currentId = currentSong?.id;

      if (currentId != null && currentId != _lastSongId) {
        _lastSongId = currentId;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _triggerArtworkBounce(isPlaying: isPlaying);
        });
      } else {
        if (isPlaying) {
          _playPauseController.forward();
        } else {
          _playPauseController.reverse();
        }
      }

      return _buildPlayerScaffold(
        context,
        audioController,
        favoritesController,
        currentSong,
        isPlaying,
      );
    });
  }

  Widget _buildPlayerScaffold(
    BuildContext context,
    AudioController audioController,
    FavoritesController favoritesController,
    Song? currentSong,
    bool isPlaying,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          isDark
              ? const Color.fromARGB(255, 16, 16, 16)
              : const Color(0xffffffff),
      body: Stack(
        children: [
          // ============================================================
          // AMBIENT BLUR BACKDROP
          // ============================================================
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
                        opacity: isDark ? 0.12 : 0.40,
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
                            color:
                                isDark
                                    ? Colors.black.withValues(alpha: 0.06)
                                    : const Color.fromARGB(
                                      255,
                                      235,
                                      234,
                                      234,
                                    ).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ========================================================
                // HEADER
                // ========================================================
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
                        onPressed: () {
                          widget.onDismiss?.call();
                        },
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

                          GestureDetector(
                            onTap: () {
                              if (currentSong == null) return;

                              final libraryController =
                                  Get.find<LibraryController>();

                              final albumSongs =
                                  libraryController.albums[currentSong.album] ??
                                  [currentSong];

                              Get.to(
                                () => AlbumDetailScreen(
                                  key: ValueKey('album_${currentSong.album}'),
                                  albumName: currentSong.album,
                                  songs: albumSongs,
                                ),
                                preventDuplicates: false,
                                transition: Transition.cupertinoDialog,
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width - 140,
                                ),
                                child: MarqueeText(
                                  text: currentSong?.album ?? 'Melo',
                                  height: 20,
                                  velocity: 22,
                                  blankSpace: 36,
                                  fadeWidth: 12,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ==================================================
                      // OPTIONS
                      // ==================================================
                      Builder(
                        builder: (buttonContext) {
                          return IconButton(
                            icon: Icon(
                              CupertinoIcons.ellipsis,
                              size: 22,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            onPressed: () {
                              if (currentSong == null) return;

                              final renderObject =
                                  buttonContext.findRenderObject();

                              if (renderObject is! RenderBox) return;

                              final offset = renderObject.localToGlobal(
                                Offset.zero,
                              );

                              /*
                               * IMPORTANT:
                               *
                               * buttonContext is BELOW our local Overlay.
                               *
                               * Therefore showIosPopoverMenu() can safely
                               * call Overlay.of(buttonContext).
                               */

                              showIosOptionsDialog(
                                buttonContext,
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

                // ========================================================
                // ARTWORK
                // ========================================================
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 14,
                                  spreadRadius: isPlaying ? 4 : 2,
                                  offset: Offset(0, isPlaying ? 2 : 2),
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

                // ========================================================
                // SONG INFO
                // ========================================================
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
                                MarqueeText(
                                  text: currentSong.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  height: 28,
                                ),

                                const SizedBox(height: 2),

                                GestureDetector(
                                  onTap: () {
                                    widget.onDismiss?.call();

                                    final libraryController =
                                        Get.find<LibraryController>();

                                    final artistSongs =
                                        libraryController.artists[currentSong
                                            .artist] ??
                                        [currentSong];

                                    Get.to(
                                      () => ArtistDetailScreen(
                                        key: ValueKey(
                                          'artist_${currentSong.artist}',
                                        ),
                                        artistName: currentSong.artist,
                                        songs: artistSongs,
                                      ),
                                      preventDuplicates: false,
                                      transition: Transition.cupertinoDialog,
                                    );
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: MarqueeText(
                                      text: currentSong.artist,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                      ),
                                      height: 22,
                                    ),
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
                                      : isDark
                                      ? Colors.white38
                                      : Colors.black38,
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

                // ========================================================
                // PROGRESS
                // ========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ProgressSlider(
                    position: audioController.position.value,
                    total: audioController.totalDuration.value,
                    primaryColor: primaryColor,
                    onSeek: (duration) {
                      audioController.seek(duration);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ========================================================
                // CONTROLS
                // ========================================================
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
                                : isDark
                                ? Colors.white38
                                : Colors.black38,
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
                      onPressed: () async {
                        try {
                          await audioController.previous();
                        } catch (e) {
                          debugPrint('UI: Previous error: $e');
                        }
                      },
                    ),

                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();

                        try {
                          if (audioController.playing.value) {
                            await audioController.pause();
                          } else {
                            await audioController.play();
                          }
                        } catch (e) {
                          debugPrint('UI: Playback error: $e');

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Playback error: $e')),
                          );
                        }
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
                      onPressed: () async {
                        try {
                          await audioController.next();
                        } catch (e) {
                          debugPrint('UI: Next error: $e');
                        }
                      },
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
                                : isDark
                                ? Colors.white38
                                : Colors.black38,
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

                // ========================================================
                // BOTTOM TOOLBAR
                // ========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        final speed = audioController.speed.value;

                        final isCustom = speed != 1.0;

                        return GestureDetector(
                          onTap: () {
                            showIosSpeedDialog(
                              context,
                              audioController,
                              primaryColor,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.speedometer,
                                color:
                                    isCustom
                                        ? primaryColor
                                        : isDark
                                        ? Colors.white54
                                        : Colors.black45,
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
                                          : isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      Obx(() {
                        final remaining = audioController.sleepTimer.value;

                        final isActive =
                            remaining != null && remaining > Duration.zero;

                        return GestureDetector(
                          onTap: () {
                            showIosSleepTimerDialog(
                              context,
                              audioController,
                              primaryColor,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.timer,
                                color:
                                    isActive
                                        ? primaryColor
                                        : isDark
                                        ? Colors.white54
                                        : Colors.black45,
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
                                          : isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      IconButton(
                        icon: Icon(
                          CupertinoIcons.list_bullet,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 22,
                        ),
                        onPressed: () {
                          showGlobalQueueSheet(
                            builder: (context, scrollController) {
                              return QueueSheet(
                                scrollController: scrollController,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================================
// IOS OPTIONS DIALOG
// ============================================================================

void showIosOptionsDialog(
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

// ============================================================================
// ADD SONGS SHEET
// ============================================================================

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
                  // Drag handle
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

                  // Search
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

// ============================================================================
// CIRCLE ICON BUTTON
// ============================================================================

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Function(BuildContext) onTap;

  const CircleIconButton({super.key, required this.icon, required this.onTap});

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

// ============================================================================
// PILL BUTTON
// ============================================================================

class PillButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const PillButton({super.key, 
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseBg = colorScheme.onSurface.withValues(alpha: 0.08);

    final activeBg = colorScheme.primaryContainer.withValues(alpha: 0.7);

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

// ============================================================================
// PROGRESS SLIDER
// ============================================================================

class ProgressSlider extends StatefulWidget {
  final Duration position;
  final Duration total;
  final Color primaryColor;
  final ValueChanged<Duration> onSeek;

  const ProgressSlider({
    super.key,
    required this.position,
    required this.total,
    required this.primaryColor,
    required this.onSeek,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider>
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
                    setState(() {
                      _dragValue = v;
                    });
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
