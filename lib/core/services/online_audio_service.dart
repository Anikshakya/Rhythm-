import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class OnlineAudioService {
  static String? _discoveryProvider;

  Future<String> _getDiscoveryProvider() async {
    if (_discoveryProvider != null) {
      return _discoveryProvider!;
    }

    final response = await http.get(
      Uri.parse(
        'https://api.audius.co',
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final providers = List<String>.from(
        json['data'] ?? [],
      );

      _discoveryProvider = providers.first;
      return _discoveryProvider!;
    }

    throw Exception('Unable to connect to Audius');
  }

  Future<List<Song>> fetchTrendingSongs() async {
    try {
      final provider = await _getDiscoveryProvider();

      final response = await http.get(
        Uri.parse(
          '$provider/v1/tracks/trending?limit=25',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      final List tracks = json['data'];

      return tracks.map<Song>((track) {
        return _songFromAudius(provider, track);
      }).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<Song>> fetchNewReleases() async {
    try {
      final provider = await _getDiscoveryProvider();

      final response = await http.get(
        Uri.parse(
          '$provider/v1/tracks?sort=date&limit=25',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      final List tracks = json['data'];

      return tracks.map<Song>((track) {
        return _songFromAudius(provider, track);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> searchOnlineMusic(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final provider = await _getDiscoveryProvider();

      final response = await http.get(
        Uri.parse(
          '$provider/v1/tracks/search?query=${Uri.encodeComponent(query)}&limit=30',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      final List tracks = json['data'];

      return tracks.map<Song>((track) {
        return _songFromAudius(provider, track);
      }).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Song _songFromAudius(String provider, Map track) {
    final artwork = track['artwork'];

    String? image;

    if (artwork != null) {
      image = artwork['1000x1000'] ??
          artwork['480x480'] ??
          artwork['150x150'];
    }

    return Song(
      id: 'audius_${track['id']}',
      title: track['title'] ?? 'Unknown',
      artist: track['user']?['name'] ?? 'Unknown Artist',
      album: track['genre'] ?? '',
      artwork: image,
      duration: Duration(seconds: track['duration'] ?? 0),
      source: AudioSourceType.network,
      uri: '$provider/v1/tracks/${track['id']}/stream',
      streamUrl: '$provider/v1/tracks/${track['id']}/stream',
      genre: track['genre'],
    );
  }
}