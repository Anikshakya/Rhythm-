import 'package:dhun/widgets/custom_scroll_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dhun/widgets/fullscreen_player.dart';
import '../../albums/album_songs_screen.dart';
class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late Future<List<AlbumModel>> _albumsFuture; // Optimization: Cache the future

  @override
  void initState() {
    super.initState();
    _albumsFuture = _audioQuery.queryAlbums();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<AlbumModel>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return const Center(
            child: Text('No albums found', style: TextStyle(color: Colors.grey)),
          );
        }

        // Use GridView.builder without shrinkWrap to allow lazy loading
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Bottom padding for MiniPlayer
          // CHANGE: Use BouncingScrollPhysics for independent iOS-style scrolling
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 24, // Slightly more vertical space for better iOS look
            crossAxisSpacing: 16,
            childAspectRatio: 0.78, // Adjusted to prevent text clipping
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];

            return CustomScrollAnimation(
              // Key is crucial: it tells Flutter this is a unique item to animate
              key: ValueKey(album.id), 
              index: index,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => AlbumSongsScreen(
                        album: album,
                        onNavigateToPlayer: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => const FullScreenPlayer()),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Album Cover
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: QueryArtworkWidget(
                            artworkClipBehavior: Clip.none,
                            id: album.id,
                            type: ArtworkType.ALBUM,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Container(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                              child: Icon(
                                CupertinoIcons.music_albums_fill,
                                size: 50,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      album.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600, // Semi-bold for iOS look
                        fontSize: 15,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      album.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ===============================
/// Delayed Album Animation
/// ===============================

// class DelayedItemAnimation extends StatefulWidget {
//   final Widget child;
//   final int index;

//   const DelayedItemAnimation({
//     super.key,
//     required this.child,
//     required this.index,
//   });

//   @override
//   State<DelayedItemAnimation> createState() => _DelayedItemAnimationState();
// }

// class _DelayedItemAnimationState extends State<DelayedItemAnimation>
//     with SingleTickerProviderStateMixin {

//   late AnimationController controller;
//   late Animation<double> animation;

//   @override
//   void initState() {
//     super.initState();

//     controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     animation = CurvedAnimation(
//       parent: controller,
//       curve: Curves.easeOutCubic,
//     );

//     /// 🔑 Start animation AFTER first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(Duration(milliseconds: widget.index * 2), () {
//         if (mounted) controller.forward();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: animation,
//       child: AnimatedBuilder(
//         animation: animation,
//         builder: (context, child) {
//           return Transform.translate(
//             offset: Offset(0, 40 * (1 - animation.value)),
//             child: child,
//           );
//         },
//         child: widget.child,
//       ),
//     );
//   }
// }