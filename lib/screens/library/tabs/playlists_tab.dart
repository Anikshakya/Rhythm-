import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/playlist_controller.dart';
import '../../../widgets/custom_scroll_animation.dart';
import '../../favorites/favorites_screen.dart';
import '../../playlists/playlists_screen.dart';

class PlaylistsTab extends StatelessWidget {
  final VoidCallback onNavigateToPlayer;

  const PlaylistsTab({
    super.key,
    required this.onNavigateToPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final playlistController = Get.find<PlaylistController>();
    final favoritesController = Get.find<FavoritesController>();

    return Obx(() {
      if (playlistController.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final playlists = playlistController.playlists;

      return Column(
        children: [

          /// PINNED DEFAULT FAVORITES CARD
          Obx(() {
            final favCount = favoritesController.favoriteSongs.length;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 26),
                ),
                title: const Text(
                  'Favorite Songs',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  '$favCount favorited tracks',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                trailing: const Icon(CupertinoIcons.chevron_forward, color: Colors.white70, size: 20),
                onTap: () => Get.to(() => const FavoritesScreen()),
              ),
            );
          }),

          /// CREATE PLAYLIST BUTTON
          ListTile(
            leading: const Icon(CupertinoIcons.plus_circle_fill, color: Colors.pinkAccent),
            title: const Text('Create New Playlist', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            onTap: () => _showCreateDialog(context, playlistController),
          ),
          const Divider(height: 1),

          /// USER PLAYLISTS LIST
          Expanded(
            child: playlists.isEmpty
                ? const Center(child: Text('No custom playlists created yet'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return CustomScrollAnimation(
                        key: ValueKey('pl_${playlist.id}'),
                        index: index,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              playlist.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.music_albums,
                              color: playlist.isFavorite ? Colors.redAccent : Colors.white70,
                            ),
                          ),
                          title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${playlist.songCount} songs'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(CupertinoIcons.doc_on_doc, size: 20),
                                onPressed: () => playlistController.duplicatePlaylist(playlist),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, size: 20, color: Colors.redAccent),
                                onPressed: () => playlistController.deletePlaylist(playlist.id),
                              ),
                            ],
                          ),
                          onTap: () {
                            Get.to(() => PlaylistDetailScreen(playlist: playlist));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  void _showCreateDialog(BuildContext context, PlaylistController controller) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Playlist Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(hintText: 'Description (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  controller.createPlaylist(nameCtrl.text, description: descCtrl.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}