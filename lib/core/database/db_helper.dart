import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rhythm_player.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        artwork TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Playlist tracks table
    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        song_json TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id, position),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL, -- 'song', 'album', 'artist', 'playlist'
        target_id TEXT NOT NULL,
        name TEXT NOT NULL,
        artwork TEXT,
        song_json TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Play History & Play Counts table
    await db.execute('''
      CREATE TABLE history (
        song_id TEXT PRIMARY KEY,
        song_json TEXT NOT NULL,
        play_count INTEGER DEFAULT 1,
        last_played INTEGER NOT NULL
      )
    ''');

    // Queue Session table
    await db.execute('''
      CREATE TABLE queue_session (
        id INTEGER PRIMARY KEY DEFAULT 1,
        queue_json TEXT NOT NULL,
        current_index INTEGER DEFAULT 0,
        position_ms INTEGER DEFAULT 0,
        repeat_mode TEXT DEFAULT 'none',
        shuffle_mode TEXT DEFAULT 'none',
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // ==================== FAVORITES METHODS ====================

  Future<void> toggleFavoriteSong(Song song) async {
    final db = await instance.database;
    final isFav = await isFavorite('song', song.id);
    if (isFav) {
      await db.delete('favorites', where: 'type = ? AND target_id = ?', whereArgs: ['song', song.id]);
    } else {
      await db.insert(
        'favorites',
        {
          'id': 'song_${song.id}',
          'type': 'song',
          'target_id': song.id,
          'name': song.title,
          'artwork': song.artwork,
          'song_json': jsonEncode(song.toJson()),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> isFavorite(String type, String targetId) async {
    final db = await instance.database;
    final res = await db.query(
      'favorites',
      where: 'type = ? AND target_id = ?',
      whereArgs: [type, targetId],
    );
    return res.isNotEmpty;
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await instance.database;
    final res = await db.query('favorites', where: 'type = ?', whereArgs: ['song'], orderBy: 'created_at DESC');
    return res.map((row) => Song.fromJson(jsonDecode(row['song_json'] as String))).toList();
  }

  Future<void> toggleFavoriteItem(String type, String targetId, String name, String? artwork) async {
    final db = await instance.database;
    final isFav = await isFavorite(type, targetId);
    if (isFav) {
      await db.delete('favorites', where: 'type = ? AND target_id = ?', whereArgs: [type, targetId]);
    } else {
      await db.insert('favorites', {
        'id': '${type}_$targetId',
        'type': type,
        'target_id': targetId,
        'name': name,
        'artwork': artwork,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getFavoritesByType(String type) async {
    final db = await instance.database;
    return await db.query('favorites', where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC');
  }

  // ==================== PLAYLIST METHODS ====================

  Future<List<PlaylistModel>> getPlaylists() async {
    final db = await instance.database;
    final pRows = await db.query('playlists', orderBy: 'updated_at DESC');
    
    List<PlaylistModel> playlists = [];
    for (var p in pRows) {
      final pId = p['id'] as String;
      final tRows = await db.query(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [pId],
        orderBy: 'position ASC',
      );
      List<Song> songs = tRows.map((tr) => Song.fromJson(jsonDecode(tr['song_json'] as String))).toList();
      playlists.add(PlaylistModel(
        id: pId,
        name: p['name'] as String,
        description: p['description'] as String?,
        artwork: p['artwork'] as String?,
        isFavorite: (p['is_favorite'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(p['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(p['updated_at'] as int),
        songs: songs,
      ));
    }
    return playlists;
  }

  Future<void> savePlaylist(PlaylistModel playlist) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'playlists',
        {
          'id': playlist.id,
          'name': playlist.name,
          'description': playlist.description,
          'artwork': playlist.artwork,
          'is_favorite': playlist.isFavorite ? 1 : 0,
          'created_at': playlist.createdAt.millisecondsSinceEpoch,
          'updated_at': playlist.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlist.id]);

      for (int i = 0; i < playlist.songs.length; i++) {
        await txn.insert('playlist_tracks', {
          'playlist_id': playlist.id,
          'song_id': playlist.songs[i].id,
          'song_json': jsonEncode(playlist.songs[i].toJson()),
          'position': i,
        });
      }
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await instance.database;
    await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  // ==================== HISTORY & PLAY COUNT METHODS ====================

  Future<void> recordPlay(Song song) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('history', where: 'song_id = ?', whereArgs: [song.id]);

    if (existing.isNotEmpty) {
      final count = (existing.first['play_count'] as int) + 1;
      await db.update(
        'history',
        {
          'play_count': count,
          'last_played': now,
          'song_json': jsonEncode(song.toJson()),
        },
        where: 'song_id = ?',
        whereArgs: [song.id],
      );
    } else {
      await db.insert('history', {
        'song_id': song.id,
        'song_json': jsonEncode(song.toJson()),
        'play_count': 1,
        'last_played': now,
      });
    }
  }

  Future<List<Song>> getRecentlyPlayed({int limit = 50}) async {
    final db = await instance.database;
    final res = await db.query('history', orderBy: 'last_played DESC', limit: limit);
    return res.map((row) => Song.fromJson(jsonDecode(row['song_json'] as String))).toList();
  }

  Future<List<Song>> getMostPlayed({int limit = 50}) async {
    final db = await instance.database;
    final res = await db.query('history', orderBy: 'play_count DESC', limit: limit);
    return res.map((row) => Song.fromJson(jsonDecode(row['song_json'] as String))).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('history');
  }

  // ==================== QUEUE SESSION PERSISTENCE ====================

  Future<void> saveQueueSession({
    required List<Song> queue,
    required int currentIndex,
    required int positionMs,
    required String repeatMode,
    required String shuffleMode,
  }) async {
    try {
      final db = await instance.database;
      final queueJson = jsonEncode(queue.map((s) => s.toJson()).toList());
      await db.insert(
        'queue_session',
        {
          'id': 1,
          'queue_json': queueJson,
          'current_index': currentIndex,
          'position_ms': positionMs,
          'repeat_mode': repeatMode,
          'shuffle_mode': shuffleMode,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving queue session: $e');
    }
  }

  Future<Map<String, dynamic>?> getQueueSession() async {
    final db = await instance.database;
    final res = await db.query('queue_session', where: 'id = 1');
    if (res.isEmpty) return null;
    return res.first;
  }
}
