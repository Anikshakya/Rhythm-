import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/database/db_helper.dart';
import '../core/models/song_model.dart';

class FavoritesController extends GetxController {
  final RxList<Song> favoriteSongs = <Song>[].obs;
  final RxSet<String> favoriteSongIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final songs = await DatabaseHelper.instance.getFavoriteSongs();
      favoriteSongs.assignAll(songs);
      favoriteSongIds.assignAll(songs.map((s) => s.id));
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavoriteSong(Song song) async {
    await DatabaseHelper.instance.toggleFavoriteSong(song);
    await loadFavorites();
  }

  bool isFavorite(String songId) {
    return favoriteSongIds.contains(songId);
  }
}
