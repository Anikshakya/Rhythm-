import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:melo/widgets/artwork_widget.dart';
import '../../controllers/audio_controller.dart';
import '../../core/models/song_model.dart';
import '../../widgets/song_tile.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final List<dynamic> songs;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final RxBool _isFavorite = false.obs;
  final RxBool _isPlayPressed = false.obs;
  final RxBool _isShuffled = false.obs;

  // Only used to trigger the fade-in after the route has settled
  final RxBool _allowHeavyUI = false.obs;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      _routeAnimation = ModalRoute.of(context)?.animation;
      _routeAnimation?.addListener(_onRouteAnimation);

      if (_routeAnimation?.isCompleted == true) {
        _scheduleHeavyUI();
      }
    }
  }

  void _onRouteAnimation() {
    final anim = _routeAnimation;
    if (anim == null) return;

    // The moment reverse starts or value drops → kill heavy UI immediately
    if (anim.status == AnimationStatus.reverse || anim.value < 0.995) {
      if (_allowHeavyUI.value) {
        _allowHeavyUI.value = false;
      }
    } else if (anim.isCompleted) {
      _scheduleHeavyUI();
    }
  }

  void _scheduleHeavyUI() {
    if (_allowHeavyUI.value || !mounted) return;
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted &&
          _routeAnimation?.isCompleted == true &&
          _routeAnimation?.status != AnimationStatus.reverse) {
        _allowHeavyUI.value = true;
      }
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onRouteAnimation);
    super.dispose();
  }

  void _goBack() {
    // Force flag off before the navigator starts the reverse animation
    _allowHeavyUI.value = false;
    Navigator.of(context).pop();
  }

  // Helper method to format total album duration
  String _formatTotalDuration(List<Song> songs) {
    int totalMilliseconds = songs.fold(
      0,
      (sum, song) => sum + song.duration.inMilliseconds,
    );
    int totalSeconds = (totalMilliseconds / 1000).floor();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes mins' : ''}'.trim();
    } else if (minutes > 0) {
      return '$minutes mins';
    } else {
      return '< 1 min';
    }
  }

  void _showAlbumOptions(BuildContext context) {
    final theme = Theme.of(context);
    final typedSongs = List<Song>.from(widget.songs);
    final audioController = Get.find<AudioController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(CupertinoIcons.play_circle),
                  title: const Text('Play Next'),
                  onTap: () {
                    if (typedSongs.isNotEmpty) {
                      _isShuffled.value = false;
                      audioController.playSong(
                        typedSongs.first,
                        contextQueue: typedSongs,
                      );
                    }
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.shuffle),
                  title: const Text('Shuffle Album Queue'),
                  onTap: () {
                    if (typedSongs.isNotEmpty) {
                      _isShuffled.value = true;
                      final shuffledList = List<Song>.from(typedSongs)
                        ..shuffle();
                      audioController.playSong(
                        shuffledList.first,
                        contextQueue: shuffledList,
                      );
                      if (audioController.shuffleMode.value !=
                          AudioServiceShuffleMode.all) {
                        audioController.toggleShuffle();
                      }
                    }
                    Navigator.pop(context);
                  },
                ),
                Obx(
                  () => ListTile(
                    leading: Icon(
                      _isFavorite.value
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color:
                          _isFavorite.value ? theme.colorScheme.primary : null,
                    ),
                    title: Text(
                      _isFavorite.value
                          ? 'Remove from Favorites'
                          : 'Add Album to Favorites',
                    ),
                    onTap: () {
                      _isFavorite.toggle();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<Song> typedSongs = List<Song>.from(widget.songs);

    final sampleArt =
        typedSongs
            .firstWhere(
              (s) => s.artwork != null && s.artwork!.isNotEmpty,
              orElse: () => typedSongs.first,
            )
            .artwork;

    final primaryColor = theme.colorScheme.primary;
    final baseBgColor = theme.scaffoldBackgroundColor;

    // Always read the current animation value in build
    // so even if the Rx is slightly late we still hide the blur
    final anim = _routeAnimation;
    final isFullySettled =
        anim == null ||
        (anim.isCompleted &&
            anim.status != AnimationStatus.reverse &&
            anim.value >= 0.995);

    final totalDurationStr = _formatTotalDuration(typedSongs);

    return Scaffold(
      backgroundColor: baseBgColor,
      body: Stack(
        children: [
          // 1. Always solid clean background
          Positioned.fill(child: Container(color: baseBgColor)),

          // 2. Heavy blur – Positioned.fill is direct child of Stack, Opacity wraps internal content.
          Obx(() {
            final showHeavy = _allowHeavyUI.value && isFullySettled;

            if (!showHeavy) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: TweenAnimationBuilder<double>(
                key: const ValueKey('album_heavy_blur'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ArtworkWidget(
                          songId: typedSongs.first.id,
                          artworkUrl: sampleArt,
                          size: double.infinity,
                          borderRadius: 0,
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                          child: Container(
                            color:
                                isDark
                                    ? Colors.black.withValues(alpha: 0.45)
                                    : baseBgColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.6),
                              radius: 1.2,
                              colors: [
                                primaryColor.withValues(
                                  alpha: isDark ? 0.45 : 0.35,
                                ),
                                primaryColor.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                baseBgColor.withValues(alpha: 0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                baseBgColor.withValues(alpha: 0.8),
                                baseBgColor,
                              ],
                              stops: const [0.0, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 44),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: ValueKey('album_hero_${widget.albumName}'),
                              child: ArtworkWidget(
                                songId: typedSongs.first.id,
                                artworkUrl: sampleArt,
                                size: 210,
                                borderRadius: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.albumName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${typedSongs.first.artist} • ${typedSongs.length} Songs • $totalDurationStr',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(() {
                              final isShuffled = _isShuffled.value;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color:
                                      isShuffled
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.18,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.08,
                                              )),
                                  shape: BoxShape.circle,
                                  boxShadow:
                                      isShuffled
                                          ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                          : [],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    CupertinoIcons.shuffle,
                                    size: 20,
                                    color:
                                        isShuffled
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                  ),
                                  onPressed: () {
                                    if (typedSongs.isEmpty) return;
                                    _isShuffled.toggle();
                                    if (_isShuffled.value) {
                                      final shuffledList = List<Song>.from(
                                        typedSongs,
                                      )..shuffle();
                                      audioController.playSong(
                                        shuffledList.first,
                                        contextQueue: shuffledList,
                                      );
                                      if (audioController.shuffleMode.value !=
                                          AudioServiceShuffleMode.all) {
                                        audioController.toggleShuffle();
                                      }
                                    } else {
                                      audioController.playSong(
                                        typedSongs.first,
                                        contextQueue: typedSongs,
                                      );
                                      if (audioController.shuffleMode.value ==
                                          AudioServiceShuffleMode.all) {
                                        audioController.toggleShuffle();
                                      }
                                    }
                                  },
                                ),
                              );
                            }),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTapDown: (_) => _isPlayPressed.value = true,
                              onTapUp: (_) => _isPlayPressed.value = false,
                              onTapCancel: () => _isPlayPressed.value = false,
                              child: Obx(
                                () => AnimatedScale(
                                  scale: _isPlayPressed.value ? 0.94 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (typedSongs.isEmpty) return;
                                      _isShuffled.value = false;
                                      if (audioController.shuffleMode.value ==
                                          AudioServiceShuffleMode.all) {
                                        audioController.toggleShuffle();
                                      }
                                      audioController.playSong(
                                        typedSongs.first,
                                        contextQueue: typedSongs,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isDark ? Colors.white : Colors.black,
                                      foregroundColor:
                                          isDark ? Colors.black : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 42,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      CupertinoIcons.play_fill,
                                      size: 18,
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                    ),
                                    label: Text(
                                      'Play',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color:
                                            isDark
                                                ? Colors.black
                                                : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
              // Tracklist
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = typedSongs[index];
                    return SongTile(
                      song: song,
                      index: index,
                      contextQueue: typedSongs,
                      onTap: () {
                        _isShuffled.value = false;
                        audioController.playSong(
                          song,
                          contextQueue: typedSongs,
                        );
                      },
                    );
                  }, childCount: typedSongs.length),
                ),
              ),
            ],
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          CupertinoIcons.back,
                          color: theme.colorScheme.onSurface,
                          size: 18,
                        ),
                        onPressed: _goBack,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          CupertinoIcons.ellipsis,
                          color: theme.colorScheme.onSurface,
                          size: 18,
                        ),
                        onPressed: () => _showAlbumOptions(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
