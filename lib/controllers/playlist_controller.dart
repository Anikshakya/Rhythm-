import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/database/db_helper.dart';
import '../core/models/playlist_model.dart';
import '../core/models/song_model.dart';

class PlaylistController extends GetxController {
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    isLoading.value = true;
    try {
      final fetched = await DatabaseHelper.instance.getPlaylists();
      playlists.assignAll(fetched);
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    if (name.trim().isEmpty) return;

    final newPlaylist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description,
      songs: [],
    );

    playlists.add(newPlaylist);
    await DatabaseHelper.instance.savePlaylist(newPlaylist);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final updated = playlists[index].copyWith(name: newName, updatedAt: DateTime.now());
    playlists[index] = updated;
    await DatabaseHelper.instance.savePlaylist(updated);
  }

  Future<void> deletePlaylist(String playlistId) async {
    playlists.removeWhere((p) => p.id == playlistId);
    await DatabaseHelper.instance.deletePlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final currentSongs = List<Song>.from(playlists[index].songs);
    if (!currentSongs.any((s) => s.id == song.id)) {
      currentSongs.add(song);
      final updated = playlists[index].copyWith(songs: currentSongs, updatedAt: DateTime.now());
      playlists[index] = updated;
      await DatabaseHelper.instance.savePlaylist(updated);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final currentSongs = List<Song>.from(playlists[index].songs);
    currentSongs.removeWhere((s) => s.id == songId);
    final updated = playlists[index].copyWith(songs: currentSongs, updatedAt: DateTime.now());
    playlists[index] = updated;
    await DatabaseHelper.instance.savePlaylist(updated);
  }

  Future<void> duplicatePlaylist(PlaylistModel playlist) async {
    final newPlaylist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: '${playlist.name} (Copy)',
      description: playlist.description,
      artwork: playlist.artwork,
      songs: List<Song>.from(playlist.songs),
    );

    playlists.add(newPlaylist);
    await DatabaseHelper.instance.savePlaylist(newPlaylist);
  }
}
