import 'dart:ui';
import 'package:melo/widgets/marquee_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onSwipeUp;

  const MiniPlayer({super.key, required this.onTap, this.onSwipeUp});

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      final currentSong = audioController.currentSong.value;
      if (currentSong == null) return const SizedBox.shrink();

      final total = audioController.totalDuration.value;
      final current = audioController.position.value;
      final progress =
          total.inMilliseconds > 0
              ? (current.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;

      final speed = audioController.speed.value;
      final isCustomSpeed = speed != 1.0;

      final sleepRemaining = audioController.sleepTimer.value;
      final isSleepActive =
          sleepRemaining != null && sleepRemaining > Duration.zero;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: GestureDetector(
              onTap: onTap,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -250) {
                  if (onSwipeUp != null) {
                    onSwipeUp!();
                  } else {
                    onTap();
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'artwork_${currentSong.id}',
                            child: ArtworkWidget(
                              songId: currentSong.id,
                              artworkUrl: currentSong.artwork,
                              size: 40,
                              borderRadius: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MarqueeText(
                                  text: currentSong.title,
                                  height: 20,
                                  velocity: 28,
                                  blankSpace: 50,
                                  fadeWidth: 16,
                                  pauseDuration: const Duration(milliseconds: 1400),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        currentSong.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    if (isSleepActive) ...[
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.timer,
                                              size: 11,
                                              color: primaryColor,
                                            ),
                                            Text(
                                              _formatCountdown(sleepRemaining),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Speed Indicator Chip
                                    if (isCustomSpeed) ...[
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${speed}x',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          

                          // Play / Pause Action
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              audioController.playing.value
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              size: 22,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () {
                              if (audioController.playing.value) {
                                audioController.pause();
                              } else {
                                audioController.play();
                              }
                            },
                          ),

                          // Next Action
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              CupertinoIcons.forward_fill,
                              size: 20,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () => audioController.next(),
                          ),
                        ],
                      ),
                    ),

                    // Seamless Bottom Progress Bar
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}