import 'dart:math';
import 'package:flutter/material.dart'; // Added for Color
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/playlist_model.dart';

late final AudioHandler audioHandler;
bool _isInitialized = false;

Future<void> initAudioService() async {
  if (_isInitialized) return;

  final OnAudioQuery audioQuery = OnAudioQuery();

  try {
    // 1️⃣ Check current permission
    bool hasPermission = await audioQuery.permissionsStatus();

    // 2️⃣ Request permission if not granted
    if (!hasPermission) {
      hasPermission = await audioQuery.permissionsRequest();
    }

    // 3️⃣ Stop initialization if permission denied
    if (!hasPermission) {
      debugPrint('❌ Audio permission denied');
      return;
    }

    // 4️⃣ Initialize AudioService
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'aniklinkin.np.dhun.channel.audio',
        androidNotificationChannelName: 'Rhythm Player',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_launcher',
      ),
    );

    _isInitialized = true;

    debugPrint('✅ AudioService initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ AudioService init error: $e');
    debugPrint(stack.toString());
  }
}

bool isAudioServiceInitialized() => _isInitialized;

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  final List<dynamic> _queue = [];
  int _currentIndex = 0;

  bool _shuffleEnabled = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  Stream<Duration> get positionStream => _player.positionStream;

  // Notification controls
  static const MediaControl shuffleControl = MediaControl(
    androidIcon: 'drawable/ic_shuffle',
    label: 'Shuffle',
    action: MediaAction.setShuffleMode,
  );

  static const MediaControl repeatControl = MediaControl(
    androidIcon: 'drawable/ic_repeat',
    label: 'Repeat',
    action: MediaAction.setRepeatMode,
  );

  AudioPlayerHandler() {
    _player.playerStateStream.listen(_updatePlaybackState);
    _player.positionStream.listen(_broadcastPosition);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _handleSongCompletion();
    });
  }

  // NEW: This triggers when the user swipes the app away from recent tasks
  @override
  Future<void> onTaskRemoved() async {
    await stop();
    return super.onTaskRemoved();
  }

  void _updatePlaybackState(PlayerState state) {
    final position = _player.position;

    playbackState.add(
      PlaybackState(
        controls: [
          shuffleControl,
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          repeatControl,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
          MediaAction.stop,
        },
        playing: state.playing,
        processingState: _mapState(state.processingState),
        repeatMode: _repeatMode,
        shuffleMode: _shuffleEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  void _broadcastPosition(Duration position) {
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
      ),
    );
  }

  Future<void> playSong(dynamic song) async {
    try {
      String path;
      String title;
      String artist;
      String album = '';
      int? durationMs;
      String id;
      Uri? artUri;

      if (song is SongModel) {
        path = song.data;
        title = song.title;
        artist = song.artist ?? 'Unknown Artist';
        album = song.album ?? '';
        durationMs = song.duration;
        id = song.id.toString();
        artUri = Uri.parse("content://media/external/audio/albumart/${song.albumId}");
      } else if (song is PlaylistSong) {
        path = song.data;
        title = song.title;
        artist = song.artist;
        durationMs = song.duration;
        id = song.id.toString();
      } else {
        throw Exception('Unsupported song type');
      }

      mediaItem.add(
        MediaItem(
          id: id,
          title: title,
          artist: artist,
          album: album,
          duration: Duration(milliseconds: durationMs ?? 0),
          artUri: artUri,
        ),
      );

      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error playing song: $e');
    }
  }

  /// ================= Queue Management =================
  
  void setQueue(List<dynamic> songs) {
    _queue.clear();
    _queue.addAll(songs);

    final mediaItems = _queue.map((song) {
      if (song is SongModel) {
        return MediaItem(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          album: song.album ?? '',
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: Uri.parse("content://media/external/audio/albumart/${song.albumId}"),
          extras: {'path': song.data},
        );
      } else if (song is PlaylistSong) {
        return MediaItem(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist,
          album: song.album ?? '',
          duration: Duration(milliseconds: song.duration ?? 0),
          extras: {'path': song.data},
        );
      } else {
        throw Exception('Unsupported song type');
      }
    }).toList();

    queue.add(List.unmodifiable(mediaItems));
    if (mediaItems.isNotEmpty) playSongAt(0);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await playSongAt(index);
  }

  Future<void> playSongAt(int index) async {
    if (_queue.isEmpty || index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await playSong(_queue[_currentIndex]);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == AudioServiceRepeatMode.one) {
      await playSongAt(_currentIndex);
      return;
    }
    if (_shuffleEnabled) {
      _currentIndex = _random.nextInt(_queue.length);
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }
    await playSongAt(_currentIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_shuffleEnabled) {
      _currentIndex = _random.nextInt(_queue.length);
    } else {
      _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    }
    await playSongAt(_currentIndex);
  }

  Future<void> _handleSongCompletion() async {
    if (_repeatMode == AudioServiceRepeatMode.one) {
      await playSongAt(_currentIndex);
    } else if (_shuffleEnabled) {
      _currentIndex = _random.nextInt(_queue.length);
      await playSongAt(_currentIndex);
    } else if (_currentIndex < _queue.length - 1) {
      await skipToNext();
    } else if (_repeatMode == AudioServiceRepeatMode.all) {
      await playSongAt(0);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleEnabled = shuffleMode == AudioServiceShuffleMode.all;
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
  }

  AudioProcessingState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }
}