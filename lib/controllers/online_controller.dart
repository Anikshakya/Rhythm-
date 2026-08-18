import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/models/song_model.dart';
import '../core/services/online_audio_service.dart';

class OnlineController extends GetxController {
  final OnlineAudioService _onlineService = OnlineAudioService();

  final RxList<Song> trendingSongs = <Song>[].obs;
  final RxList<Song> newReleases = <Song>[].obs;
  final RxList<Song> searchResults = <Song>[].obs;

  final RxBool isLoadingTrending = false.obs;
  final RxBool isLoadingSearch = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch online music in background to avoid blocking startup
    _initializeOnlineContent();
  }

  Future<void> _initializeOnlineContent() async {
    try {
      debugPrint('🌐 OnlineController: Fetching online music...');
      await fetchOnlineMusic();
      debugPrint('✅ OnlineController: Online music loaded');
    } catch (e) {
      debugPrint('❌ OnlineController: Failed to fetch online music: $e');
    }
  }

  Future<void> fetchOnlineMusic() async {
    isLoadingTrending.value = true;
    try {
      final trending = await _onlineService.fetchTrendingSongs();
      final releases = await _onlineService.fetchNewReleases();
      trendingSongs.assignAll(trending);
      newReleases.assignAll(releases);
    } catch (e) {
      debugPrint('Error fetching online music: $e');
    } finally {
      isLoadingTrending.value = false;
    }
  }

  Future<void> searchOnline(String query) async {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isLoadingSearch.value = true;
    try {
      final results = await _onlineService.searchOnlineMusic(query);
      searchResults.assignAll(results);
    } catch (e) {
      debugPrint('Online search error: $e');
    } finally {
      isLoadingSearch.value = false;
    }
  }
}
