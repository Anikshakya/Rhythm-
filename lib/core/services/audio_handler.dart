// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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
    debugPrint('🔊 initAudioService: Starting initialization...');

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

    // Await native audio session allocation before allowing UI queue calls
    await (audioHandler as RhythmAudioHandler).initNativeSession();

    _isInitialized = true;
    debugPrint('✅ RhythmAudioHandler initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ AudioService init error: $e');
    debugPrint('Stack: $stack');
    rethrow;
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
    _setupListeners();
  }

  /// Explicit hardware configuration for iOS / Android physical devices.
  Future<void> initNativeSession() async {
    try {
      debugPrint('🔊 [HANDLER] Initializing audio hardware layers...');

      if (Platform.isIOS) {
        debugPrint('🔊 [HANDLER] Configuring iOS audio session overrides...');
        
        // Run audio session setup asynchronously to avoid deadlocking the native thread
        unawaited(
          AudioSession.instance.then((session) async {
            await session.configure(const AudioSessionConfiguration(
              avAudioSessionCategory: AVAudioSessionCategory.playback,
              avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
              avAudioSessionMode: AVAudioSessionMode.defaultMode,
              avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
              avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
            ));
            await session.setActive(true);
            debugPrint('✅ [HANDLER] iOS audio session activated & locked');
          }).catchError((e) {
            debugPrint('❌ [HANDLER] AudioSession config error: $e');
          }),
        );
      }

      // Set player audio source directly without blocking on AudioSession lock
      debugPrint('🔊 [HANDLER] Setting initial playlist audio source...');
      await _player.setAudioSource(_playlist, preload: false);
      await _player.setSpeed(_speed);
      debugPrint('✅ [HANDLER] Audio playback state ready');
    } catch (e, stack) {
      debugPrint('❌ [HANDLER] Error during initialization: $e');
      debugPrint('Stack: $stack');
    }
  }

  void _setupListeners() {
    try {
      debugPrint('🔊 [HANDLER] Setting up listeners...');

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

      debugPrint('✅ [HANDLER] Listeners set up');
    } catch (e) {
      debugPrint('❌ [HANDLER] Error setting up listeners: $e');
    }
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
    if (songs.isEmpty) {
      debugPrint('❌ [HANDLER] setQueue: No songs provided');
      return;
    }

    _isUpdatingQueue = true;
    try {
      debugPrint('🔊 [HANDLER] setQueue: Setting queue with ${songs.length} songs');

      _rawQueue.clear();
      _rawQueue.addAll(songs);

      final mediaItems = songs.map((s) => s.toMediaItem()).toList();
      queue.add(mediaItems);

      final validIndex = initialIndex.clamp(0, songs.length - 1);
      final selectedSong = _rawQueue[validIndex];
      _currentSongSubject.add(selectedSong);
      mediaItem.add(selectedSong.toMediaItem());

      final sources = <AudioSource>[];
      for (var song in songs) {
        try {
          sources.add(song.toAudioSource());
        } catch (e) {
          debugPrint('❌ [HANDLER] Failed to create audio source for ${song.title}: $e');
        }
      }

      if (sources.isEmpty) {
        debugPrint('❌ [HANDLER] No valid audio sources created!');
        _isUpdatingQueue = false;
        return;
      }

      await _playlist.clear();
      await _playlist.addAll(sources);

      // Re-assign audio source with target index directly for reliable iOS source binding
      await _player.setAudioSource(
        _playlist,
        initialIndex: validIndex,
        initialPosition: Duration.zero,
      );

      try {
        await _player.setSpeed(_speed);
      } catch (e) {
        debugPrint('⚠️  [HANDLER] Error re-applying speed: $e');
      }

      debugPrint('🔊 [HANDLER] Starting playback...');
      await _player.play();
      debugPrint('✅ [HANDLER] setQueue completed - now playing');
    } catch (e, stack) {
      debugPrint('❌ [HANDLER] setQueue error: $e');
      debugPrint('Stack: $stack');
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
    try {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
      debugPrint('✅ skipToQueueItem: Seeking to index $index and playing');
    } catch (e) {
      debugPrint('❌ skipToQueueItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    try {
      debugPrint('🎵 [HANDLER] play() called');
      await _player.play();
      debugPrint('✅ [HANDLER] play() succeeded');
    } catch (e) {
      debugPrint('❌ [HANDLER] play() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      debugPrint('⏸️  [HANDLER] pause() called');
      await _player.pause();
      debugPrint('✅ [HANDLER] pause() succeeded');
    } catch (e) {
      debugPrint('❌ [HANDLER] pause() failed: $e');
      rethrow;
    }
  }

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

  void _syncCurrentSongFromPlayer() {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _rawQueue.length) {
      _currentSongSubject.add(null);
      mediaItem.add(null);
      return;
    }

    final song = _rawQueue[index];
    _currentSongSubject.add(song);
    mediaItem.add(song.toMediaItem());
  }

  @override
  Future<void> skipToNext() async {
    try {
      debugPrint('⏭️  [HANDLER] skipToNext() called');
      final wasPlaying = _player.playing;

      if (_player.hasNext) {
        await _player.seekToNext();
        debugPrint('✅ [HANDLER] skipToNext() used seekToNext()');
      } else if (_player.shuffleModeEnabled && _rawQueue.isNotEmpty) {
        final shuffleIndices = _player.shuffleIndices;
        if (shuffleIndices.isNotEmpty) {
          await _player.seek(Duration.zero, index: shuffleIndices.first);
        } else {
          final randomVal = Random().nextInt(_rawQueue.length);
          await _player.seek(Duration.zero, index: randomVal);
        }
        debugPrint('✅ [HANDLER] skipToNext() used shuffle');
      } else if (playbackState.value.repeatMode == AudioServiceRepeatMode.all && _rawQueue.isNotEmpty) {
        await _player.seek(Duration.zero, index: 0);
        debugPrint('✅ [HANDLER] skipToNext() used repeat all');
      } else {
        debugPrint('⚠️  [HANDLER] skipToNext() no more songs');
        return;
      }

      _syncCurrentSongFromPlayer();
      if (wasPlaying) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('❌ [HANDLER] skipToNext() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      debugPrint('⏮️  [HANDLER] skipToPrevious() called');
      final wasPlaying = _player.playing;

      if (_player.position.inSeconds > 3) {
        await _player.seek(Duration.zero);
        debugPrint('✅ [HANDLER] skipToPrevious() rewound current track');
      } else if (_player.hasPrevious) {
        await _player.seekToPrevious();
        debugPrint('✅ [HANDLER] skipToPrevious() went to previous');
      } else if (_rawQueue.isNotEmpty) {
        await _player.seek(Duration.zero, index: _rawQueue.length - 1);
        debugPrint('✅ [HANDLER] skipToPrevious() went to last');
      } else {
        debugPrint('⚠️  [HANDLER] skipToPrevious() no previous song');
        return;
      }

      _syncCurrentSongFromPlayer();
      if (wasPlaying) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('❌ [HANDLER] skipToPrevious() failed: $e');
      rethrow;
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