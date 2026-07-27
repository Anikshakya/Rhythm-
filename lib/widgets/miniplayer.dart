import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onSwipeUp;

  const MiniPlayer({
    super.key,
    required this.onTap,
    this.onSwipeUp,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final currentSong = audioController.currentSong.value;
      if (currentSong == null) return const SizedBox.shrink();

      final total = audioController.totalDuration.value;
      final current = audioController.position.value;
      final progress = total.inMilliseconds > 0
          ? (current.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onTap: onTap,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -250) {
            if (onSwipeUp != null) {
              onSwipeUp!();
            } else {
              onTap();
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: isDark
                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'artwork_${currentSong.id}',
                            child: ArtworkWidget(
                              songId: currentSong.id,
                              artworkUrl: currentSong.artwork,
                              size: 46,
                              borderRadius: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              audioController.playing.value
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              size: 26,
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
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.forward_fill,
                              size: 24,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () => audioController.next(),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        // valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFA2D48)),
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