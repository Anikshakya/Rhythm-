import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../controllers/favorites_controller.dart';
import 'artwork_widget.dart';
import 'queue_sheet.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;
  late Animation<double> _scaleAnimation;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _playPauseController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final favoritesController = Get.find<FavoritesController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          setState(() {
            _dragOffsetY += details.delta.dy;
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragOffsetY > 100 || (details.primaryVelocity != null && details.primaryVelocity! > 250)) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _dragOffsetY = 0.0;
          });
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: Obx(() {
          final currentSong = audioController.currentSong.value;

          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
            body: Stack(
              children: [

                /// 1. APPLE MUSIC AMBIENT ARTWORK BACKDROP BLUR
                if (currentSong != null)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Transform.scale(
                          scale: 1.3,
                          child: ArtworkWidget(
                            songId: currentSong.id,
                            artworkUrl: currentSong.artwork,
                            size: double.infinity,
                            borderRadius: 0,
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: Container(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// 2. MAIN PLAYER CONTENT
                SafeArea(
                  child: Column(
                    children: [

                      /// TOP GRAB HANDLE BAR
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white30 : Colors.black26,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// HEADER TITLE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.chevron_down, size: 24),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Column(
                              children: [
                                Text(
                                  'PLAYING FROM QUEUE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong?.album ?? 'Rhythm',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.ellipsis, size: 24),
                              onPressed: () => _showOptionMenu(context, audioController, favoritesController, currentSong),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      /// 3. APPLE MUSIC SCALING ARTWORK CARD WITH GLOW
                      if (currentSong != null)
                        Obx(() {
                          final isPlaying = audioController.playing.value;
                          if (isPlaying) {
                            _playPauseController.forward();
                          } else {
                            _playPauseController.reverse();
                          }

                          final artSize = MediaQuery.of(context).size.width * 0.82;

                          return Center(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: artSize,
                                height: artSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isPlaying ? 0.45 : 0.15),
                                      blurRadius: isPlaying ? 30 : 12,
                                      spreadRadius: isPlaying ? 4 : 0,
                                      offset: Offset(0, isPlaying ? 16 : 8),
                                    ),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'artwork_${currentSong.id}',
                                  child: ArtworkWidget(
                                    songId: currentSong.id,
                                    artworkUrl: currentSong.artwork,
                                    size: artSize,
                                    borderRadius: 20,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                      const Spacer(),

                      /// 4. SONG TITLE & ARTIST & FAVORITE
                      if (currentSong != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
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
                                    const SizedBox(height: 4),
                                    Text(
                                      currentSong.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: isDark ? Colors.white60 : Colors.black54,
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
                                  color: favoritesController.isFavorite(currentSong.id)
                                      ? const Color(0xFFFA2D48)
                                      : (isDark ? Colors.white54 : Colors.black45),
                                  size: 26,
                                ),
                                onPressed: () => favoritesController.toggleFavoriteSong(currentSong),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      /// 5. APPLE MUSIC SCRUBBER SLIDER
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: isDark ? Colors.white : Colors.black87,
                                inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                                thumbColor: isDark ? Colors.white : Colors.black,
                              ),
                              child: Slider(
                                value: audioController.position.value.inMilliseconds.toDouble().clamp(
                                      0.0,
                                      audioController.totalDuration.value.inMilliseconds > 0
                                          ? audioController.totalDuration.value.inMilliseconds.toDouble()
                                          : 1.0,
                                    ),
                                max: audioController.totalDuration.value.inMilliseconds > 0
                                    ? audioController.totalDuration.value.inMilliseconds.toDouble()
                                    : 1.0,
                                onChanged: (val) => audioController.seek(Duration(milliseconds: val.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(audioController.position.value),
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                                  Text(
                                    _formatDuration(audioController.totalDuration.value),
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// 6. APPLE MUSIC PLAYBACK CONTROLS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.shuffle,
                              color: audioController.shuffleMode.value == AudioServiceShuffleMode.all
                                  ? const Color(0xFFFA2D48)
                                  : (isDark ? Colors.white54 : Colors.black45),
                              size: 22,
                            ),
                            onPressed: () => audioController.toggleShuffle(),
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.backward_fill, size: 36, color: isDark ? Colors.white : Colors.black),
                            onPressed: () => audioController.previous(),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (audioController.playing.value) {
                                audioController.pause();
                              } else {
                                audioController.play();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFA2D48),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                audioController.playing.value
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.forward_fill, size: 36, color: isDark ? Colors.white : Colors.black),
                            onPressed: () => audioController.next(),
                          ),
                          IconButton(
                            icon: Icon(
                              audioController.repeatMode.value == AudioServiceRepeatMode.one
                                  ? CupertinoIcons.repeat_1
                                  : CupertinoIcons.repeat,
                              color: audioController.repeatMode.value != AudioServiceRepeatMode.none
                                  ? const Color(0xFFFA2D48)
                                  : (isDark ? Colors.white54 : Colors.black45),
                              size: 22,
                            ),
                            onPressed: () => audioController.cycleRepeat(),
                          ),
                        ],
                      ),

                      const Spacer(),

                      /// 7. BOTTOM APPLE MUSIC TOOLBAR (AIRPLAY, LYRICS, QUEUE)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(CupertinoIcons.speedometer, color: isDark ? Colors.white60 : Colors.black54, size: 22),
                              onPressed: () => _showSpeedDialog(context, audioController),
                            ),
                            IconButton(
                              icon: Icon(CupertinoIcons.timer, color: isDark ? Colors.white60 : Colors.black54, size: 22),
                              onPressed: () => _showSleepTimerDialog(context, audioController),
                            ),
                            IconButton(
                              icon: Icon(CupertinoIcons.list_bullet, color: isDark ? Colors.white : Colors.black, size: 24),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const QueueSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showOptionMenu(BuildContext context, AudioController controller, FavoritesController favs, dynamic song) {
    if (song == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ArtworkWidget(songId: song.id, artworkUrl: song.artwork, size: 44, borderRadius: 8),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(CupertinoIcons.heart),
                title: Text(favs.isFavorite(song.id) ? 'Remove Favorite' : 'Favorite Song'),
                onTap: () {
                  favs.toggleFavoriteSong(song);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.text_insert),
                title: const Text('Play Next'),
                onTap: () {
                  controller.playNext(song);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context, AudioController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playback Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                  return Obx(() {
                    return ChoiceChip(
                      label: Text('${s}x'),
                      selected: controller.speed.value == s,
                      onSelected: (val) {
                        if (val) {
                          controller.setSpeed(s);
                          Navigator.pop(context);
                        }
                      },
                    );
                  });
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sleep Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Off'),
                onTap: () {
                  controller.setSleepTimer(null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('15 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('30 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('60 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 60));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}