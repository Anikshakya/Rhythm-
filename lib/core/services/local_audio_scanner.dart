import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

class LocalAudioScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Checks and requests necessary storage/audio permissions based on the platform.
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isIOS) {
        return await _handleIOSPermissions();
      }

      if (Platform.isAndroid) {
        return await _handleAndroidPermissions();
      }

      return true;
    } catch (e) {
      debugPrint('❌ LocalAudioScanner: Permission error: $e');
      return false;
    }
  }

  /// Specialized Permission Flow for iOS
  Future<bool> _handleIOSPermissions() async {
    var status = await Permission.mediaLibrary.status;
    debugPrint('🔊 LocalAudioScanner: Initial iOS MediaLibrary status = $status');

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      debugPrint('⚠️ LocalAudioScanner: iOS Permission permanently denied. Redirecting to settings...');
      await openAppSettings();
      return false;
    }

    status = await Permission.mediaLibrary.request();
    debugPrint('🔊 LocalAudioScanner: Requested iOS status result = $status');

    return status.isGranted || status.isLimited;
  }

  /// Specialized Permission Flow for Android
  Future<bool> _handleAndroidPermissions() async {
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;

    if (audioStatus.isGranted || storageStatus.isGranted) {
      return true;
    }

    final statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    return statuses[Permission.audio]?.isGranted == true ||
        statuses[Permission.storage]?.isGranted == true;
  }

  /// Scans both System Media Library and File Directories for audio files.
  Future<List<Song>> scanLocalSongs() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ LocalAudioScanner: Permission denied for local audio scan.');
        return [];
      }

      final List<Song> allSongs = [];
      final Set<String> trackIdentifiers = {}; // Deduplication filter

      // ---------------------------------------------------------------------
      // 1. Scan System Media Library via OnAudioQuery
      // ---------------------------------------------------------------------
      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        // Omit UriType on iOS to avoid query failure
        uriType: Platform.isAndroid ? UriType.EXTERNAL : null,
        ignoreCase: true,
      );

      debugPrint('🔊 LocalAudioScanner: Raw query returned ${songModels.length} items from OS.');

      for (var s in songModels) {
        final String songUri = _resolveSongUri(s);
        if (songUri.isEmpty) continue;

        final String artworkUri = Platform.isAndroid && s.albumId != null
            ? 'content://media/external/audio/albumart/${s.albumId}'
            : '';

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

        final song = Song(
          id: s.id.toString(),
          title: (s.title.isNotEmpty && s.title != '<unknown>') ? s.title : 'Unknown Title',
          artist: (s.artist == null || s.artist == '<unknown>') ? 'Unknown Artist' : s.artist!,
          album: (s.album == null || s.album == '<unknown>') ? 'Unknown Album' : s.album!,
          artwork: artworkUri,
          duration: Duration(milliseconds: s.duration ?? 0),
          source: AudioSourceType.local,
          uri: songUri,
          localPath: Platform.isIOS ? songUri : s.data,
          genre: s.genre,
          year: parsedYear,
        );

        allSongs.add(song);
        trackIdentifiers.add(song.title.toLowerCase());
      }

      // ---------------------------------------------------------------------
      // 2. Scan Directory Storage (Files App / Documents) for standalone files
      // ---------------------------------------------------------------------
      final directoryFiles = await _scanFileSystemDirectories();
      for (var file in directoryFiles) {
        final fileName = file.path.split('/').last;
        final cleanTitle = fileName.replaceAll(RegExp(r'\.(mp3|m4a|wav|flac|aac|ogg)$', caseSensitive: false), '');

        // Avoid adding duplicate songs if already found in system media library
        if (trackIdentifiers.contains(cleanTitle.toLowerCase())) continue;

        allSongs.add(
          Song(
            id: file.path.hashCode.toString(),
            title: cleanTitle,
            artist: 'Local File',
            album: 'Files App',
            artwork: '',
            duration: Duration.zero,
            source: AudioSourceType.local,
            uri: file.path,
            localPath: file.path,
            genre: 'Unknown',
            year: null,
          ),
        );
      }

      debugPrint('✅ LocalAudioScanner: Successfully scanned ${allSongs.length} total songs.');
      return allSongs;
    } catch (e, stack) {
      debugPrint('❌ LocalAudioScanner: Error scanning local songs: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// Scans physical device directories for loose audio files
  Future<List<File>> _scanFileSystemDirectories() async {
    List<File> foundFiles = [];
    try {
      final List<Directory> targetDirs = [];

      // App Documents Directory
      final appDocDir = await getApplicationDocumentsDirectory();
      targetDirs.add(appDocDir);

      // System Downloads Directory (if supported)
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) targetDirs.add(downloadsDir);
      } catch (_) {}

      final validExtensions = ['.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg'];

      for (var dir in targetDirs) {
        if (!dir.existsSync()) continue;
        
        final List<FileSystemEntity> entities = dir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (validExtensions.any((ext) => path.endsWith(ext))) {
              foundFiles.add(entity);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LocalAudioScanner: Error scanning file directories: $e');
    }
    return foundFiles;
  }

  /// Resolve URI scheme correctly across Android and iOS
  String _resolveSongUri(SongModel s) {
    if (Platform.isIOS) {
      if (s.uri != null && s.uri!.isNotEmpty) {
        return s.uri!;
      }
      return 'ipod-library://item?id=${s.id}';
    }

    return s.data;
  }

  // ================= GROUPING HELPERS =================

  Map<String, List<Song>> groupByAlbum(List<Song> songs) {
    return groupByProperty(songs, (song) => song.album.isEmpty ? 'Unknown Album' : song.album);
  }

  Map<String, List<Song>> groupByArtist(List<Song> songs) {
    return groupByProperty(songs, (song) => song.artist.isEmpty ? 'Unknown Artist' : song.artist);
  }

  Map<String, List<Song>> groupByGenre(List<Song> songs) {
    return groupByProperty(
      songs,
      (song) => (song.genre == null || song.genre!.isEmpty) ? 'Unknown Genre' : song.genre!,
    );
  }

  Map<String, List<Song>> groupByFolder(List<Song> songs) {
    final Map<String, List<Song>> folders = {};
    for (var song in songs) {
      if (song.localPath != null && song.localPath!.isNotEmpty) {
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

  Map<String, List<Song>> groupByProperty(List<Song> songs, String Function(Song) keySelector) {
    final Map<String, List<Song>> groupedMap = {};
    for (var song in songs) {
      final key = keySelector(song);
      groupedMap.putIfAbsent(key, () => []).add(song);
    }
    return groupedMap;
  }
}