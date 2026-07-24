import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/search_controller.dart';
import '../../widgets/song_tile.dart';

class UnifiedSearchScreen extends StatelessWidget {
  const UnifiedSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = Get.find<UnifiedSearchController>();
    final audioController = Get.find<AudioController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                placeholder: 'Search songs, albums, artists, online tracks...',
                onChanged: (val) => searchController.search(val),
              ),
            ),
          ),

          Obx(() {
            if (searchController.query.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.search, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Search for local or online music', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildListDelegate([

                /// LOCAL SONGS RESULTS
                if (searchController.localResults.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Local Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...searchController.localResults.map(
                    (song) => SongTile(
                      song: song,
                      contextQueue: searchController.localResults,
                      onTap: () => audioController.playSong(song, contextQueue: searchController.localResults),
                    ),
                  ),
                ],

                /// ONLINE SONGS RESULTS
                if (searchController.onlineResults.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Online Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...searchController.onlineResults.map(
                    (song) => SongTile(
                      song: song,
                      contextQueue: searchController.onlineResults,
                      onTap: () => audioController.playSong(song, contextQueue: searchController.onlineResults),
                    ),
                  ),
                ],

                if (searchController.localResults.isEmpty && searchController.onlineResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No results matching your query')),
                  ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
