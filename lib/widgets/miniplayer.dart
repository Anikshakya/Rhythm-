import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dhun/core/services/audio_handler.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.5) 
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Content Layout
                      Row(
                        children: [
                          SizedBox(width: 8),
                          // Art Work
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: QueryArtworkWidget(
                                artworkClipBehavior: Clip.none,
                                id: int.parse(mediaItem.id),
                                type: ArtworkType.AUDIO,
                                artworkWidth: 52,
                                artworkHeight: 52,
                                nullArtworkWidget: const Icon(CupertinoIcons.music_note_2, size: 70),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            width: MediaQuery.of(context).size.width * 0.73,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                // 1. Song Info (Artist - Title)
                                _buildMetadata(mediaItem, colorScheme, context),
                                const Spacer(),
                                // 2. Center Controls
                                _buildControls(colorScheme),
                                
                                const Spacer(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 3. Progress Bar at the very bottom
                      _buildProgressBar(mediaItem, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadata(MediaItem item, ColorScheme colorScheme, context) {
    return Text(
      "${item.artist} - ${item.title}",
      maxLines: 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
  return StreamBuilder<PlaybackState>(
    stream: audioHandler.playbackState,
    builder: (context, snapshot) {
      final state = snapshot.data;
      final playing = state?.playing ?? false;
      final repeatMode = state?.repeatMode ?? AudioServiceRepeatMode.none;

      // Helper to build uniform circular buttons
      Widget buildCircularButton({
        required Widget child,
        required VoidCallback onTap,
      }) {
        return SizedBox(
          width: 30,
          height: 30,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15), // Half of 30
            customBorder: const CircleBorder(),      // Forces circular ripple
            child: Center(child: child),
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Repeat
          buildCircularButton(
            onTap: () {
              // Defines the cycle: None -> All -> One -> back to None
              final modes = [
                AudioServiceRepeatMode.none,
                AudioServiceRepeatMode.all,
                AudioServiceRepeatMode.one,
              ];
              final nextIndex = (modes.indexOf(repeatMode) + 1) % modes.length;
              audioHandler.setRepeatMode(modes[nextIndex]);
            },
            child: Icon(
              repeatMode == AudioServiceRepeatMode.one 
                  ? CupertinoIcons.repeat_1 
                  : CupertinoIcons.repeat,
              size: 16,
              color: repeatMode == AudioServiceRepeatMode.none 
                  ? colorScheme.onSurface.withValues(alpha: 0.3) 
                  : colorScheme.primary,
            ),
          ),
          
          const Spacer(),

          // 2. Previous
          buildCircularButton(
            onTap: () => audioHandler.skipToPrevious(),
            child: Icon(
              CupertinoIcons.backward_fill, 
              color: colorScheme.onSurface, 
              size: 20
            ),
          ),

          const SizedBox(width: 20), // Spacing between the 30x30 touch areas

          // 3. Play/Pause
          buildCircularButton(
            onTap: playing ? audioHandler.pause : audioHandler.play,
            child: Icon(
              playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: colorScheme.onSurface,
              size: 24, // Icon fits inside the 30px container
            ),
          ),

          const SizedBox(width: 20),

          // 4. Next
          buildCircularButton(
            onTap: () => audioHandler.skipToNext(),
            child: Icon(
              CupertinoIcons.forward_fill, 
              color: colorScheme.onSurface, 
              size: 20
            ),
          ),

          const Spacer(),

          // 5. Heart/Favorite
          buildCircularButton(
            onTap: () {},
            child: Icon(
              CupertinoIcons.heart_fill, 
              color: colorScheme.primary, 
              size: 16
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildProgressBar(MediaItem item, ColorScheme colorScheme) {
    return StreamBuilder<Duration>(
      stream: (audioHandler as AudioPlayerHandler).positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = item.duration ?? Duration.zero;
        
        double progress = 0.0;
        if (total.inMilliseconds > 0) {
          progress = position.inMilliseconds / total.inMilliseconds;
        }

        return Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}