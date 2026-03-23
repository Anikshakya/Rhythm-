import 'package:dhun/widgets/custom_scroll_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dhun/widgets/fullscreen_player.dart';
import '../../artist/artist_songs_screen.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({super.key});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late Future<List<ArtistModel>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  initialize() async{
    _artistsFuture = _audioQuery.queryArtists(
      ignoreCase: false
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<ArtistModel>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final artists = snapshot.data ?? [];
        if (artists.isEmpty) {
          return const Center(
            child: Text('No artists found', style: TextStyle(color: Colors.grey)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Padding for MiniPlayer
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85, // Adjusted for circular avatar + text
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];

            return CustomScrollAnimation(
              key: ValueKey(artist.id),
              index: index,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ArtistSongsScreen(
                        artist: artist,
                        onNavigateToPlayer: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const FullScreenPlayer(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 1. CIRCULAR ARTIST AVATAR (iOS Style)
                    Container(
                      width: 146,
                      height: 146,
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
                          id: artist.id,
                          type: ArtworkType.ARTIST,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.person_crop_circle_fill,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 2. ARTIST TEXT
                    Text(
                      artist.artist,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${artist.numberOfTracks} songs',
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