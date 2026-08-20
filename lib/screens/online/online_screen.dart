import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/online_controller.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/song_tile.dart';

class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onlineController = Get.find<OnlineController>();
    final audioController = Get.find<AudioController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover Music',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          /// SEARCH BAR
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                placeholder: 'Search online tracks, artists...',
                onChanged: (val) => onlineController.searchOnline(val),
              ),
            ),
          ),

          /// ONLINE SEARCH RESULTS OR DISCOVER DASHBOARD
          Obx(() {
            if (onlineController.searchQuery.isNotEmpty) {
              if (onlineController.isLoadingSearch.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (onlineController.searchResults.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No online songs found.')),
                );
              }

              return SliverPadding(
                padding: EdgeInsetsGeometry.only(bottom: 66),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = onlineController.searchResults[index];
                    return SongTile(
                      song: song,
                      contextQueue: onlineController.searchResults,
                    );
                  }, childCount: onlineController.searchResults.length),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildListDelegate([
                /// TRENDING CAROUSEL
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Trending Songs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: Obx(() {
                    if (onlineController.isLoadingTrending.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: onlineController.trendingSongs.length,
                      itemBuilder: (context, index) {
                        final song = onlineController.trendingSongs[index];
                        return GestureDetector(
                          onTap:
                              () => audioController.playSong(
                                song,
                                contextQueue: onlineController.trendingSongs,
                              ),
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArtworkWidget(
                                  artworkUrl: song.artwork,
                                  size: 130,
                                  borderRadius: 12,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                const SizedBox(height: 16),

                /// NEW RELEASES LIST
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'New Releases',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Obx(() {
                  return Column(
                    children:
                        onlineController.newReleases.map((song) {
                          return SongTile(
                            song: song,
                            contextQueue: onlineController.newReleases,
                          );
                        }).toList(),
                  );
                }),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
