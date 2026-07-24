import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song_model.dart';

class LocalAudioScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> checkAndRequestPermissions() async {
    try {
      bool status = await _audioQuery.permissionsStatus();
      if (!status) {
        status = await _audioQuery.permissionsRequest();
      }
      return status;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  Future<List<Song>> scanLocalSongs() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Permission denied for local audio scan.');
        return [];
      }

      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final List<Song> songs = [];
      for (var s in songModels) {
        if (s.data.isEmpty) continue;

        String artworkUri = '';
        if (s.albumId != null) {
          artworkUri = 'content://media/external/audio/albumart/${s.albumId}';
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
            year: s.getMap['year'] is int ? s.getMap['year'] : null,
          ),
        );
      }

      return songs;
    } catch (e) {
      debugPrint('❌ Error scanning local songs: $e');
      return [];
    }
  }

  Map<String, List<Song>> groupByAlbum(List<Song> songs) {
    final Map<String, List<Song>> albums = {};
    for (var song in songs) {
      final albumName = song.album.isEmpty ? 'Unknown Album' : song.album;
      albums.putIfAbsent(albumName, () => []).add(song);
    }
    return albums;
  }

  Map<String, List<Song>> groupByArtist(List<Song> songs) {
    final Map<String, List<Song>> artists = {};
    for (var song in songs) {
      final artistName = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
      artists.putIfAbsent(artistName, () => []).add(song);
    }
    return artists;
  }

  Map<String, List<Song>> groupByGenre(List<Song> songs) {
    final Map<String, List<Song>> genres = {};
    for (var song in songs) {
      final genreName = (song.genre == null || song.genre!.isEmpty) ? 'Unknown Genre' : song.genre!;
      genres.putIfAbsent(genreName, () => []).add(song);
    }
    return genres;
  }

  Map<String, List<Song>> groupByFolder(List<Song> songs) {
    final Map<String, List<Song>> folders = {};
    for (var song in songs) {
      if (song.localPath != null) {
        final parts = song.localPath!.split('/');
        final folderName = parts.length > 1 ? parts[parts.length - 2] : 'Root';
        folders.putIfAbsent(folderName, () => []).add(song);
      } else {
        folders.putIfAbsent('Unknown Folder', () => []).add(song);
      }
    }
    return folders;
  }
}
