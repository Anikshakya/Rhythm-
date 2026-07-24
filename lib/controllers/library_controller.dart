import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/database/db_helper.dart';
import '../core/models/song_model.dart';
import '../core/services/local_audio_scanner.dart';
import '../widgets/artwork_widget.dart';

class LibraryController extends GetxController {
  final LocalAudioScanner _scanner = LocalAudioScanner();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final RxList<Song> songs = <Song>[].obs;
  final RxMap<String, List<Song>> albums = <String, List<Song>>{}.obs;
  final RxMap<String, List<Song>> artists = <String, List<Song>>{}.obs;
  final RxMap<String, List<Song>> genres = <String, List<Song>>{}.obs;
  final RxMap<String, List<Song>> folders = <String, List<Song>>{}.obs;
  final RxList<Song> recentlyPlayed = <Song>[].obs;
  final RxList<Song> mostPlayed = <Song>[].obs;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    scanLibrary();
    loadHistory();
  }

  Future<void> scanLibrary() async {
    isLoading.value = true;
    error.value = '';
    try {
      final scannedSongs = await _scanner.scanLocalSongs();
      songs.assignAll(scannedSongs);

      albums.assignAll(_scanner.groupByAlbum(scannedSongs));
      artists.assignAll(_scanner.groupByArtist(scannedSongs));
      genres.assignAll(_scanner.groupByGenre(scannedSongs));
      folders.assignAll(_scanner.groupByFolder(scannedSongs));

      _preloadArtwork(scannedSongs);
    } catch (e) {
      error.value = 'Failed to scan library: $e';
      debugPrint(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  void _preloadArtwork(List<Song> songList) async {
    for (var song in songList) {
      final parsedId = int.tryParse(song.id);
      if (parsedId != null && parsedId > 0 && !artworkByteStore.containsKey(song.id)) {
        try {
          final bytes = await _audioQuery.queryArtwork(
            parsedId,
            ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG,
            size: 800,
            quality: 100,
          );
          artworkByteStore[song.id] = bytes;
        } catch (_) {}
      }
    }
  }

  Future<void> loadHistory() async {
    try {
      final recents = await DatabaseHelper.instance.getRecentlyPlayed();
      recentlyPlayed.assignAll(recents);

      final mosts = await DatabaseHelper.instance.getMostPlayed();
      mostPlayed.assignAll(mosts);
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }
}
