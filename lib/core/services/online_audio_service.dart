// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import '../models/song_model.dart';

// class OnlineAudioService {
//   // Curated online streaming sources with high quality public audio & cover art
//   static final List<Song> _sampleTrendingSongs = [
//     Song(
//       id: 'online_1',
//       title: 'Starlight Dream',
//       artist: 'Aetheria',
//       album: 'Cosmic Journeys',
//       artwork: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
//       duration: const Duration(minutes: 3, seconds: 45),
//       source: AudioSourceType.network,
//       uri: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3',
//       streamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3',
//       genre: 'Lofi Chill',
//     ),
//     Song(
//       id: 'online_2',
//       title: 'Neon Horizon',
//       artist: 'Synthwave Knights',
//       album: 'Retro Future',
//       artwork: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
//       duration: const Duration(minutes: 4, seconds: 12),
//       source: AudioSourceType.network,
//       uri: 'https://cdn.pixabay.com/download/audio/2022/03/15/audio_c8c8a73467.mp3?filename=synthwave-80s-110045.mp3',
//       streamUrl: 'https://cdn.pixabay.com/download/audio/2022/03/15/audio_c8c8a73467.mp3?filename=synthwave-80s-110045.mp3',
//       genre: 'Electronic',
//     ),
//     Song(
//       id: 'online_3',
//       title: 'Midnight Rain',
//       artist: 'Luna Acoustic',
//       album: 'Unplugged Sessions',
//       artwork: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&auto=format&fit=crop&q=80',
//       duration: const Duration(minutes: 3, seconds: 20),
//       source: AudioSourceType.network,
//       uri: 'https://cdn.pixabay.com/download/audio/2022/10/14/audio_9939f7e510.mp3?filename=acoustic-guitar-chill-124584.mp3',
//       streamUrl: 'https://cdn.pixabay.com/download/audio/2022/10/14/audio_9939f7e510.mp3?filename=acoustic-guitar-chill-124584.mp3',
//       genre: 'Acoustic',
//     ),
//     Song(
//       id: 'online_4',
//       title: 'Cyberpunk Odyssey',
//       artist: 'Vortex Protocol',
//       album: 'Neo Tokyo 2099',
//       artwork: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
//       duration: const Duration(minutes: 5, seconds: 02),
//       source: AudioSourceType.network,
//       uri: 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=cyberpunk-2099-10701.mp3',
//       streamUrl: 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=cyberpunk-2099-10701.mp3',
//       genre: 'Cyberpunk',
//     ),
//     Song(
//       id: 'online_5',
//       title: 'Ocean Breeze',
//       artist: 'Solaris Beats',
//       album: 'Summer Sunset',
//       artwork: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
//       duration: const Duration(minutes: 2, seconds: 55),
//       source: AudioSourceType.network,
//       uri: 'https://cdn.pixabay.com/download/audio/2021/09/06/audio_993b9542a1.mp3?filename=summer-chill-pop-9689.mp3',
//       streamUrl: 'https://cdn.pixabay.com/download/audio/2021/09/06/audio_993b9542a1.mp3?filename=summer-chill-pop-9689.mp3',
//       genre: 'Pop',
//     ),
//   ];

//   Future<List<Song>> fetchTrendingSongs() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _sampleTrendingSongs;
//   }

//   Future<List<Song>> fetchNewReleases() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _sampleTrendingSongs.reversed.toList();
//   }

//   Future<List<Song>> searchOnlineMusic(String query) async {
//     if (query.isEmpty) return [];

//     // Try live iTunes Search API for real world track preview searching
//     try {
//       final url = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=25');
//       final response = await http.get(url).timeout(const Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final results = data['results'] as List<dynamic>? ?? [];

//         final List<Song> onlineSongs = [];
//         for (var item in results) {
//           final previewUrl = item['previewUrl'] as String?;
//           if (previewUrl == null || previewUrl.isEmpty) continue;

//           final trackId = item['trackId']?.toString() ?? UniqueKey().toString();
//           final title = item['trackName'] ?? 'Unknown Track';
//           final artist = item['artistName'] ?? 'Unknown Artist';
//           final album = item['collectionName'] ?? 'Unknown Album';
//           final artwork = (item['artworkUrl100'] as String?)?.replaceAll('100x100bb', '600x600bb');
//           final durationMs = item['trackTimeMillis'] ?? 30000;
//           final genre = item['primaryGenreName'];

//           onlineSongs.add(
//             Song(
//               id: 'itunes_$trackId',
//               title: title,
//               artist: artist,
//               album: album,
//               artwork: artwork,
//               duration: Duration(milliseconds: durationMs),
//               source: AudioSourceType.network,
//               uri: previewUrl,
//               streamUrl: previewUrl,
//               genre: genre,
//             ),
//           );
//         }

//         if (onlineSongs.isNotEmpty) return onlineSongs;
//       }
//     } catch (e) {
//       debugPrint('Live online search fallback to local mock data: $e');
//     }

//     // Fallback search in sample list
//     final q = query.toLowerCase();
//     return _sampleTrendingSongs.where((s) {
//       return s.title.toLowerCase().contains(q) ||
//           s.artist.toLowerCase().contains(q) ||
//           s.album.toLowerCase().contains(q) ||
//           (s.genre != null && s.genre!.toLowerCase().contains(q));
//     }).toList();
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class OnlineAudioService {
  // App name required by Audius API guidelines
  static const String _appName = 'FlutterMusicApp';
  static const String _audiusHost = 'https://discoveryprovider.audius.co';

  // Sample trending backup songs
  static final List<Song> _sampleTrendingSongs = [
    Song(
      id: 'online_1',
      title: 'Starlight Dream',
      artist: 'Aetheria',
      album: 'Cosmic Journeys',
      artwork: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      duration: const Duration(minutes: 3, seconds: 45),
      source: AudioSourceType.network,
      uri: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3',
      streamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3',
      genre: 'Lofi Chill',
    ),
  ];

  Future<List<Song>> fetchTrendingSongs() async {
    return _fetchAudiusTracks('https://$_audiusHost/v1/tracks/trending?app_name=$_appName&limit=15');
  }

  Future<List<Song>> fetchNewReleases() async {
    return fetchTrendingSongs();
  }

  Future<List<Song>> searchOnlineMusic(String query) async {
    if (query.isEmpty) return [];

    final searchUrl = '$_audiusHost/v1/tracks/search?query=${Uri.encodeComponent(query)}&app_name=$_appName&limit=25';
    return _fetchAudiusTracks(searchUrl);
  }

  // Private helper to parse full-length Audius tracks
  Future<List<Song>> _fetchAudiusTracks(String endpoint) async {
    try {
      final url = Uri.parse(endpoint);
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['data'] as List<dynamic>? ?? [];

        final List<Song> onlineSongs = [];
        for (var item in tracks) {
          final trackId = item['id']?.toString();
          if (trackId == null) continue;

          final title = item['title'] ?? 'Unknown Track';
          final artist = item['user']?['name'] ?? 'Unknown Artist';
          final durationSec = item['duration'] as int? ?? 180;
          final genre = item['genre'] as String?;

          // DIRECT FULL-LENGTH AUDIO STREAM URL
          final streamUrl = '$_audiusHost/v1/tracks/$trackId/stream?app_name=$_appName';

          // High-res cover art
          final artworkMap = item['artwork'] as Map<String, dynamic>?;
          final artwork = artworkMap?['480x480'] ??
              artworkMap?['150x150'] ??
              'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';

          onlineSongs.add(
            Song(
              id: 'audius_$trackId',
              title: title,
              artist: artist,
              album: 'Audius Release',
              artwork: artwork,
              duration: Duration(seconds: durationSec),
              source: AudioSourceType.network,
              uri: streamUrl,
              streamUrl: streamUrl,
              genre: genre,
            ),
          );
        }

        if (onlineSongs.isNotEmpty) return onlineSongs;
      }
    } catch (e) {
      debugPrint('Audius API fetch error: $e');
    }

    return _sampleTrendingSongs;
  }
}
