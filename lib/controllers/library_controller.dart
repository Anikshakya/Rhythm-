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

  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'title'.obs; // 'title', 'artist', 'album', 'duration', 'tracks'

  List<Song> get filteredSongs {
    List<Song> list = List.from(songs);
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((song) {
        return song.title.toLowerCase().contains(query) ||
               song.artist.toLowerCase().contains(query);
      }).toList();
    }

    if (sortBy.value == 'title') {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortBy.value == 'artist') {
      list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    } else if (sortBy.value == 'album') {
      list.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
    } else if (sortBy.value == 'duration') {
      list.sort((a, b) => a.duration.compareTo(b.duration));
    }
    return list;
  }

  List<MapEntry<String, List<Song>>> get filteredAlbums {
    var list = albums.entries.toList();
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((entry) {
        final albumName = entry.key.toLowerCase();
        final matchesAlbum = albumName.contains(query);
        final matchesSongs = entry.value.any((song) =>
            song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query));
        return matchesAlbum || matchesSongs;
      }).toList();
    }

    if (sortBy.value == 'title') {
      list.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    } else if (sortBy.value == 'artist') {
      list.sort((a, b) => a.value.first.artist.toLowerCase().compareTo(b.value.first.artist.toLowerCase()));
    } else if (sortBy.value == 'tracks') {
      list.sort((a, b) => b.value.length.compareTo(a.value.length));
    }
    return list;
  }

  List<MapEntry<String, List<Song>>> get filteredArtists {
    var list = artists.entries.toList();
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((entry) {
        final artistName = entry.key.toLowerCase();
        final matchesArtist = artistName.contains(query);
        final matchesSongs = entry.value.any((song) =>
            song.title.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query));
        return matchesArtist || matchesSongs;
      }).toList();
    }

    if (sortBy.value == 'title' || sortBy.value == 'artist') {
      list.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    } else if (sortBy.value == 'tracks') {
      list.sort((a, b) => b.value.length.compareTo(a.value.length));
    }
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    // Run library scanning in background to avoid blocking UI
    _initializeLibrary();
  }

  Future<void> _initializeLibrary() async {
    try {
      debugPrint('📚 LibraryController: Starting library initialization...');
      await scanLibrary();
      debugPrint('✅ LibraryController: Scan complete');
    } catch (e) {
      debugPrint('❌ LibraryController: Scan failed: $e');
      error.value = 'Failed to scan library: $e';
    }

    try {
      debugPrint('📚 LibraryController: Loading history...');
      await loadHistory();
      debugPrint('✅ LibraryController: History loaded');
    } catch (e) {
      debugPrint('❌ LibraryController: History load failed: $e');
    }
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

  Future<void> clearHistory() async {
    try {
      await DatabaseHelper.instance.clearHistory();
      recentlyPlayed.clear();
      mostPlayed.clear();
    } catch (e) {
      debugPrint('History clear error: $e');
    }
  }
}
