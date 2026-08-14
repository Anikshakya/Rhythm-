import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../controllers/audio_controller.dart';
import '../database/db_helper.dart';
import '../models/song_model.dart';

late final AudioHandler audioHandler;
bool _isInitialized = false;

Future<void> initAudioService() async {
  if (_isInitialized) return;

  try {
    audioHandler = await AudioService.init(
      builder: () => RhythmAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'aniklinkin.np.melo.channel.audio',
        androidNotificationChannelName: 'Rhythm Player',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_launcher',
      ),
    );
    _isInitialized = true;
    debugPrint('✅ RhythmAudioHandler initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ AudioService init error: $e');
    debugPrint(stack.toString());
  }
}

bool isAudioServiceInitialized() => _isInitialized;

class RhythmAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<Song> _rawQueue = [];

  bool _isUpdatingQueue = false;
  double _speed = 1.0;

  Timer? _sleepTimer;
  final _sleepTimerSubject = BehaviorSubject<Duration?>.seeded(null);
  Stream<Duration?> get sleepTimerStream => _sleepTimerSubject.stream;

  final _currentSongSubject = BehaviorSubject<Song?>.seeded(null);
  Stream<Song?> get currentSongStream => _currentSongSubject.stream;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get speedStream => _player.speedStream;

  RhythmAudioHandler() {
    _initPlayer();
  }

  void _initPlayer() async {
    try {
      await _player.setAudioSource(_playlist);
      await _player.setSpeed(_speed);
    } catch (e) {
      debugPrint("Error setting initial audio source or speed: $e");
    }

    _player.playerStateStream.listen((playerState) {
      _broadcastState(playerState);
    });

    _player.currentIndexStream.listen((index) {
      if (_isUpdatingQueue) return;

      if (index != null && index >= 0 && index < _rawQueue.length) {
        final currentSong = _rawQueue[index];
        _currentSongSubject.add(currentSong);
        mediaItem.add(currentSong.toMediaItem());
        DatabaseHelper.instance.recordPlay(currentSong);
        _persistSession();
        _checkAndAppendAutoplay();
      } else {
        _currentSongSubject.add(null);
        mediaItem.add(null);
      }
    });


    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });
  }

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

  void _broadcastState(PlayerState playerState) {
    final playing = playerState.playing;
    final processingState = playerState.processingState;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          shuffleControl,
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
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
        playing: playing,
        processingState: _mapProcessingState(processingState),
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ================= UNIFIED QUEUE & PLAYBACK API =================

  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _isUpdatingQueue = true;
    try {
      _rawQueue.clear();
      _rawQueue.addAll(songs);

      final mediaItems = songs.map((s) => s.toMediaItem()).toList();
      queue.add(mediaItems);

      final validIndex = initialIndex.clamp(0, songs.length - 1);
      final selectedSong = _rawQueue[validIndex];
      _currentSongSubject.add(selectedSong);
      mediaItem.add(selectedSong.toMediaItem());

      final sources = songs.map((s) => s.toAudioSource()).toList();
      await _playlist.clear();
      await _playlist.addAll(sources);
      await _player.seek(Duration.zero, index: validIndex);
      
      try {
        await _player.setSpeed(_speed);
      } catch (e) {
        debugPrint('Error re-applying speed on player: $e');
      }
      
      // Start playing in background without blocking this Future's completion
      _player.play();
    } finally {
      _isUpdatingQueue = false;
    }

    _persistSession();
  }

  Future<void> addToQueue(Song song) async {
    _rawQueue.add(song);
    queue.add(_rawQueue.map((s) => s.toMediaItem()).toList());
    await _playlist.add(song.toAudioSource());
    _persistSession();
  }

  Future<void> playNext(Song song) async {
    final currentIndex = _player.currentIndex ?? 0;
    final insertIndex = min(currentIndex + 1, _rawQueue.length);
    _rawQueue.insert(insertIndex, song);
    queue.add(_rawQueue.map((s) => s.toMediaItem()).toList());
    await _playlist.insert(insertIndex, song.toAudioSource());
    _persistSession();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _rawQueue.length) return;
    _rawQueue.removeAt(index);
    queue.add(_rawQueue.map((s) => s.toMediaItem()).toList());
    await _playlist.removeAt(index);
    _persistSession();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _rawQueue.length || newIndex < 0 || newIndex >= _rawQueue.length) return;
    final item = _rawQueue.removeAt(oldIndex);
    _rawQueue.insert(newIndex, item);
    queue.add(_rawQueue.map((s) => s.toMediaItem()).toList());
    await _playlist.move(oldIndex, newIndex);
    _persistSession();
  }

  Future<void> clearQueue() async {
    _rawQueue.clear();
    queue.add([]);
    await _playlist.clear();
    await _player.stop();
    _currentSongSubject.add(null);
    mediaItem.add(null);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _rawQueue.length) return;
    await _player.seek(Duration.zero, index: index);
    _player.play();
  }

  @override
  Future<void> play() async {
    _player.play();
  }

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
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.shuffleModeEnabled && _rawQueue.isNotEmpty) {
      final shuffleIndices = _player.shuffleIndices;
      if (shuffleIndices.isNotEmpty) {
        await _player.seek(Duration.zero, index: shuffleIndices.first);
      } else {
        final randomVal = Random().nextInt(_rawQueue.length);
        await _player.seek(Duration.zero, index: randomVal);
      }
    } else if (playbackState.value.repeatMode == AudioServiceRepeatMode.all && _rawQueue.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_rawQueue.isNotEmpty) {
      await _player.seek(Duration.zero, index: _rawQueue.length - 1);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    _persistSession();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    _persistSession();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      debugPrint('Error setting speed on player: $e');
    }
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      _sleepTimerSubject.add(null);
      return;
    }

    _sleepTimerSubject.add(duration);
    _sleepTimer = Timer(duration, () async {
      await pause();
      _sleepTimerSubject.add(null);
    });
  }

  void _checkAndAppendAutoplay() async {
    try {
      final audioController = Get.find<AudioController>();
      if (!audioController.autoplayEnabled.value) return;

      final currentIndex = _player.currentIndex;
      if (currentIndex == null) return;

      // If we are playing the last item in the queue, pre-append the first autoplay song
      if (currentIndex == _rawQueue.length - 1) {
        final autoplayQueue = audioController.autoplayQueue;
        if (autoplayQueue.isNotEmpty) {
          final nextSong = autoplayQueue.first;
          await addToQueue(nextSong);
        }
      }
    } catch (e) {
      debugPrint('Error in _checkAndAppendAutoplay: $e');
    }
  }

  Future<void> _persistSession() async {

    try {
      final idx = _player.currentIndex ?? 0;
      final posMs = _player.position.inMilliseconds;
      final repMode = playbackState.value.repeatMode.name;
      final shufMode = playbackState.value.shuffleMode.name;

      await DatabaseHelper.instance.saveQueueSession(
        queue: _rawQueue,
        currentIndex: idx,
        positionMs: posMs,
        repeatMode: repMode,
        shuffleMode: shufMode,
      );
    } catch (e) {
      debugPrint('Error persisting session: $e');
    }
  }

  Future<void> restoreSession() async {
    try {
      final session = await DatabaseHelper.instance.getQueueSession();
      if (session == null) return;
      debugPrint('Queue session restored successfully');
    } catch (e) {
      debugPrint("Session restore error: $e");
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
}