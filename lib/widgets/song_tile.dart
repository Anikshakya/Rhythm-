import 'package:audio_service/audio_service.dart';
import 'package:dhun/widgets/fullscreen_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_handler.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.onTap,
    this.onLongPress,
  });

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentSongId = snapshot.data?.id;
        final isPlaying = currentSongId == song.id.toString();

        return Column(
          children: [
            Material(
              color: Colors.transparent, // Let the parent container handle background
              child: InkWell(
                // iOS uses a quick fade/highlight rather than a ripple
                splashColor: Colors.transparent,
                highlightColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                onTap: () {
                  if (isPlaying) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => const FullScreenPlayer(),
                      ),
                    );
                  } else {
                    onTap?.call();
                  }
                },
                onLongPress: onLongPress,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // 1. IOS STYLE ARTWORK
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: QueryArtworkWidget(
                          id: song.id,
                          artworkClipBehavior: Clip.none,
                          type: ArtworkType.AUDIO,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            width: 48,
                            height: 48,
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            child: Icon(
                              CupertinoIcons.music_note, 
                              color: isDark ? Colors.white24 : Colors.black26,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // 2. SONG INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17, // Native iOS body size
                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                                letterSpacing: -0.4,
                                color: isPlaying ? theme.colorScheme.primary : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist ?? "Unknown Artist",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: -0.2,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. RIGHT SIDE INDICATOR
                      if (isPlaying)
                        // iOS Style Equalizer icon or dot
                        Icon(CupertinoIcons.waveform, color: theme.colorScheme.primary, size: 18)
                      else
                        Text(
                          _formatDuration(song.duration ?? 0),
                          style: TextStyle(
                            fontSize: 14, 
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right, 
                        size: 14, 
                        color: isDark ? Colors.white10 : Colors.black12
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 4. INDENTED DIVIDER (Classic iOS)
            Padding(
              padding: const EdgeInsets.only(left: 78), // Indented past the artwork
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ],
        );
      },
    );
  }
}