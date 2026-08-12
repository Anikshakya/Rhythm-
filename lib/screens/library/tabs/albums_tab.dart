import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import '../../../controllers/audio_controller.dart';
import '../../../controllers/library_controller.dart';
import '../../../widgets/artwork_widget.dart';
import '../../../widgets/custom_scroll_animation.dart';
import '../../../widgets/miniplayer.dart';
import '../../../widgets/fullscreen_player.dart';
import '../../../widgets/song_tile.dart';
import '../../../core/models/song_model.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Obx(() {
      final albumEntries = libraryController.filteredAlbums;

      if (albumEntries.isEmpty) {
        return Center(
          child: Text(
            libraryController.searchQuery.value.isNotEmpty
                ? 'No matching albums found'
                : 'No albums found',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: albumEntries.length,
        itemBuilder: (context, index) {
          final entry = albumEntries[index];
          final albumName = entry.key;
          final songs = entry.value;
          final sampleArt =
              songs
                  .firstWhere(
                    (s) => s.artwork != null && s.artwork!.isNotEmpty,
                    orElse: () => songs.first,
                  )
                  .artwork;

          return CustomScrollAnimation(
            key: ValueKey('album_$albumName'),
            index: index,
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => AlbumDetailScreen(albumName: albumName, songs: songs),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ArtworkWidget(
                      songId: songs.first.id,
                      artworkUrl: sampleArt,
                      size: double.infinity,
                      borderRadius: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${songs.length} tracks • ${songs.first.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

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

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _navigateToPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const FullScreenPlayer(),
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

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: IconButton(
                  icon: Icon(
                    CupertinoIcons.back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final isCollapsed =
                        top <=
                        kToolbarHeight +
                            MediaQuery.of(context).padding.top +
                            20;
                    final double percent = ((top -
                                (kToolbarHeight +
                                    MediaQuery.of(context).padding.top)) /
                            (280.0 -
                                (kToolbarHeight +
                                    MediaQuery.of(context).padding.top)))
                        .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (sampleArt != null) ...[
                            ArtworkWidget(
                              songId: typedSongs.first.id,
                              artworkUrl: sampleArt,
                              borderRadius: 0,
                            ),
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                              child: Container(
                                color:
                                    isDark
                                        ? Colors.black.withValues(alpha: 0.65)
                                        : Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                          Opacity(
                            opacity: percent,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ArtworkWidget(
                                    songId: typedSongs.first.id,
                                    artworkUrl: sampleArt,
                                    size: 132 * percent,
                                    borderRadius: 16,
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      widget.albumName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${typedSongs.first.artist} • ${typedSongs.length} tracks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      title:
                          isCollapsed
                              ? Text(
                                widget.albumName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              )
                              : null,
                      centerTitle: true,
                    );
                  },
                ),
              ),

              /// Play & Shuffle buttons
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _entranceController,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entranceController,
                        curve: Curves.easeOut,
                      ),
                    );
                    return SlideTransition(
                      position: slide,
                      child: FadeTransition(opacity: opacity, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              audioController.playSong(
                                typedSongs.first,
                                contextQueue: typedSongs,
                              );
                            },
                            icon: const Icon(
                              CupertinoIcons.play_fill,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Play',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final list = List<Song>.from(typedSongs)
                                ..shuffle();
                              audioController.playSong(
                                list.first,
                                contextQueue: list,
                              );
                              audioController.shuffleMode.value =
                                  AudioServiceShuffleMode.all;
                            },
                            icon: Icon(
                              CupertinoIcons.shuffle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'Shuffle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Track list
              SliverToBoxAdapter(child: const SizedBox(height: 8)),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = typedSongs[index];
                  return AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      final delayFactor = (index * 0.05).clamp(0.0, 0.4);
                      final animation = CurvedAnimation(
                        parent: _entranceController,
                        curve: Interval(
                          delayFactor,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation);
                      final opacity = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(animation);

                      return SlideTransition(
                        position: slide,
                        child: FadeTransition(opacity: opacity, child: child),
                      );
                    },
                    child: SongTile(
                      song: song,
                      index: index,
                      contextQueue: typedSongs,
                      onTap: () {
                        audioController.playSong(
                          song,
                          contextQueue: typedSongs,
                        );
                      },
                    ),
                  );
                }, childCount: typedSongs.length),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          /// GLOBAL MINI PLAYER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(
              onTap: () => _navigateToPlayer(context),
              onSwipeUp: () => _navigateToPlayer(context),
            ),
          ),
        ],
      ),
    );
  }
}
