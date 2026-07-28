import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

class LocalAudioScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Checks and requests necessary storage/audio permissions based on the platform.
  Future<bool> checkAndRequestPermissions() async {
    try {
      // 1. Check if we already have platform-level permissions
      if (await _hasPlatformPermissions()) {
        debugPrint('LocalAudioScanner: Platform permissions already granted.');
        return true;
      }

      // 2. Try on_audio_query built-in check
      final bool status = await _audioQuery.checkAndRequest(retryRequest: true);
      debugPrint('LocalAudioScanner: on_audio_query checkAndRequest = $status');
      if (status) return true;

      // 3. Try fallback via permission_handler
      if (await _requestPlatformPermissions()) {
        debugPrint('LocalAudioScanner: permission_handler fallback granted.');
        return true;
      }

      debugPrint('LocalAudioScanner: Permissions denied after all attempts.');
      return false;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  /// Verifies platform-specific permissions without triggering prompts.
  Future<bool> _hasPlatformPermissions() async {
    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.status;
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      // Android 13+ uses Permission.audio; older versions use Permission.storage
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;

      return audioStatus.isGranted || storageStatus.isGranted;
    }

    return true;
  }

  /// Requests appropriate platform-specific permissions dynamically.
  Future<bool> _requestPlatformPermissions() async {
    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      // Determine SDK version or request both modern and legacy permissions safely.
      // On Android 13+, requesting storage will return denied/restricted, 
      // while Permission.audio will prompt the user correctly.
      final statuses = await [
        Permission.audio,
        Permission.storage,
      ].request();

      return statuses[Permission.audio]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true;
    }

    return true;
  }

  /// Scans device local storage for audio files and maps them to [Song] models.
  Future<List<Song>> scanLocalSongs() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Permission denied for local audio scan.');
        return [];
      }

      // Query songs from external storage
      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final List<Song> songs = [];
      for (var s in songModels) {
        if (s.data.isEmpty) continue;

        // Build artwork URI safely if albumId exists
        final String artworkUri = s.albumId != null
            ? 'content://media/external/audio/albumart/${s.albumId}'
            : '';

        // Extract year safely from map if available
        int? parsedYear;
        try {
          final yearVal = s.getMap['year'];
          if (yearVal is int) {
            parsedYear = yearVal;
          } else if (yearVal is String) {
            parsedYear = int.tryParse(yearVal);
          }
        } catch (_) {
          parsedYear = null;
        }

        songs.add(
          Song(
            id: s.id.toString(),
            title: s.title,
            artist: s.artist ?? 'Unknown Artist',
            album: s.album ?? 'Unknown Album',
            artwork: artworkUri,
            duration: Duration(milliseconds: s.duration ?? 0),
            source: AudioSourceType.local,
            uri: s.data,
            localPath: s.data,
            genre: s.genre,
            year: parsedYear,
          ),
        );
      }

      debugPrint('✅ Successfully scanned ${songs.length} local songs.');
      return songs;
    } catch (e) {
      debugPrint('❌ Error scanning local songs: $e');
      return [];
    }
  }

  /// Groups a list of songs by their Album name.
  Map<String, List<Song>> groupByAlbum(List<Song> songs) {
    return groupByProperty(songs, (song) => song.album.isEmpty ? 'Unknown Album' : song.album);
  }

  /// Groups a list of songs by their Artist name.
  Map<String, List<Song>> groupByArtist(List<Song> songs) {
    return groupByProperty(songs, (song) => song.artist.isEmpty ? 'Unknown Artist' : song.artist);
  }

  /// Groups a list of songs by their Genre.
  Map<String, List<Song>> groupByGenre(List<Song> songs) {
    return groupByProperty(songs, (song) => (song.genre == null || song.genre!.isEmpty) ? 'Unknown Genre' : song.genre!);
  }

  /// Groups a list of songs by their parent folder name.
  Map<String, List<Song>> groupByFolder(List<Song> songs) {
    final Map<String, List<Song>> folders = {};
    for (var song in songs) {
      if (song.localPath != null && song.localPath!.isNotEmpty) {
        // Cross-platform path separation safeguard
        final normalizedPath = song.localPath!.replaceAll('\\', '/');
        final parts = normalizedPath.split('/');
        final folderName = parts.length > 1 ? parts[parts.length - 2] : 'Root';
        folders.putIfAbsent(folderName, () => []).add(song);
      } else {
        folders.putIfAbsent('Unknown Folder', () => []).add(song);
      }
    }
    return folders;
  }

  /// Helper utility to DRY (Don't Repeat Yourself) up grouping logic.
  Map<String, List<Song>> groupByProperty(List<Song> songs, String Function(Song) keySelector) {
    final Map<String, List<Song>> groupedMap = {};
    for (var song in songs) {
      final key = keySelector(song);
      groupedMap.putIfAbsent(key, () => []).add(song);
    }
    return groupedMap;
  }
}