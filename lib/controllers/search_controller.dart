import 'package:get/get.dart';
import 'library_controller.dart';
import 'online_controller.dart';
import '../core/models/song_model.dart';

class UnifiedSearchController extends GetxController {
  final LibraryController _libraryController = Get.find<LibraryController>();
  final OnlineController _onlineController = Get.find<OnlineController>();

  final RxString query = ''.obs;
  final RxList<Song> localResults = <Song>[].obs;
  final RxList<Song> onlineResults = <Song>[].obs;
  final RxMap<String, List<Song>> albumResults = <String, List<Song>>{}.obs;
  final RxMap<String, List<Song>> artistResults = <String, List<Song>>{}.obs;

  void search(String input) {
    query.value = input.trim();
    if (query.isEmpty) {
      localResults.clear();
      onlineResults.clear();
      albumResults.clear();
      artistResults.clear();
      return;
    }

    final q = query.value.toLowerCase();

    // 1. Search local songs
    localResults.assignAll(
      _libraryController.songs.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q);
      }).toList(),
    );

    // 2. Search local albums
    final matchingAlbums = <String, List<Song>>{};
    _libraryController.albums.forEach((albumName, songs) {
      if (albumName.toLowerCase().contains(q)) {
        matchingAlbums[albumName] = songs;
      }
    });
    albumResults.assignAll(matchingAlbums);

    // 3. Search local artists
    final matchingArtists = <String, List<Song>>{};
    _libraryController.artists.forEach((artistName, songs) {
      if (artistName.toLowerCase().contains(q)) {
        matchingArtists[artistName] = songs;
      }
    });
    artistResults.assignAll(matchingArtists);

    // 4. Search online tracks
    _onlineController.searchOnline(query.value);
  }
}
