import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/models/song_model.dart';
import '../core/services/audio_handler.dart';
import 'library_controller.dart';

class AudioController extends GetxController {
  RhythmAudioHandler get _handler => audioHandler as RhythmAudioHandler;

  final Rxn<Song> currentSong = Rxn<Song>();
  final RxBool playing = false.obs;
  final Rx<AudioServiceRepeatMode> repeatMode = AudioServiceRepeatMode.none.obs;
  final Rx<AudioServiceShuffleMode> shuffleMode = AudioServiceShuffleMode.none.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> bufferedPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxList<Song> queue = <Song>[].obs;
  final RxDouble speed = 1.0.obs;
  final RxBool autoplayEnabled = true.obs;
  final RxList<Song> autoplayQueue = <Song>[].obs;

  /// Remaining sleep time. `null` = timer off.
  /// Updated every second while active.
  final Rxn<Duration> sleepTimer = Rxn<Duration>();


  StreamSubscription? _mediaSub;
  StreamSubscription? _playbackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _currentSongSub;
  StreamSubscription? _sleepTimerSub;

  Timer? _sleepCountdownTimer;

  @override
  void onInit() {
    super.onInit();
    try {
      debugPrint('🎵 AudioController: Binding audio handler...');
      _bindAudioHandler();
      debugPrint('✅ AudioController: Audio handler bound');
    } catch (e) {
      debugPrint('❌ AudioController: Failed to bind audio handler: $e');
    }

    try {
      debugPrint('🎵 AudioController: Initializing autoplay listener...');
      _initAutoplayListener();
      debugPrint('✅ AudioController: Autoplay listener initialized');
    } catch (e) {
      debugPrint('❌ AudioController: Failed to init autoplay listener: $e');
    }
  }

  void _bindAudioHandler() {
    _currentSongSub = _handler.currentSongStream.listen((song) {
      currentSong.value = song;
      if (song != null) {
        totalDuration.value = song.duration;
      } else {
        totalDuration.value = Duration.zero;
      }
    });

    _playbackSub = _handler.playbackState.listen((state) {
      playing.value = state.playing;
      repeatMode.value = state.repeatMode;
      shuffleMode.value = state.shuffleMode;
      bufferedPosition.value = state.bufferedPosition;
      speed.value = state.speed;
    });

    _queueSub = _handler.queue.listen((items) {
      final songs = items.map((item) {
        final extras = item.extras ?? {};
        final sourceStr = extras['source'] as String? ?? 'local';
        return Song(
          id: item.id,
          title: item.title,
          artist: item.artist ?? 'Unknown Artist',
          album: item.album ?? 'Unknown Album',
          artwork: item.artUri?.toString(),
          duration: item.duration ?? Duration.zero,
          source: sourceStr == 'network'
              ? AudioSourceType.network
              : AudioSourceType.local,
          uri: extras['uri'] as String? ?? '',
          genre: extras['genre'] as String?,
          isFavorite: extras['isFavorite'] as bool? ?? false,
        );
      }).toList();
      queue.assignAll(songs);
    });

    _positionSub = _handler.positionStream.listen((pos) {
      position.value = pos;
    });

    // Keep listening to handler stream (in case handler also emits)
    _sleepTimerSub = _handler.sleepTimerStream.listen((timer) {
      // Only accept external updates when we don't have an active local countdown
      if (_sleepCountdownTimer == null || !_sleepCountdownTimer!.isActive) {
        sleepTimer.value = timer;
      }
    });
  }

  // ================= CONTROLLER ACTIONS =================

  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) =>
      _handler.setQueue(songs, initialIndex: initialIndex);

  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    try {
      debugPrint('🎵 [CONTROLLER] playSong() called for: ${song.title}');
      
      if (currentSong.value?.id == song.id) {
        debugPrint('🎵 [CONTROLLER] Song already playing, just resuming if paused');
        if (!playing.value) {
          await play();
        }
        return;
      }

      // Update UI immediately so player opens with the selected song
      currentSong.value = song;
      totalDuration.value = song.duration;
      debugPrint('🎵 [CONTROLLER] UI updated with song: ${song.title}');

      if (contextQueue != null && contextQueue.isNotEmpty) {
        final index = contextQueue.indexWhere((s) => s.id == song.id);
        debugPrint('🎵 [CONTROLLER] Setting queue with ${contextQueue.length} songs at index $index');
        await _handler.setQueue(
          contextQueue,
          initialIndex: index >= 0 ? index : 0,
        );
      } else {
        debugPrint('🎵 [CONTROLLER] Setting single song queue');
        await _handler.setQueue([song], initialIndex: 0);
      }
      debugPrint('✅ [CONTROLLER] playSong() completed');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] playSong() failed: $e');
    }
  }

  Future<void> play() async {
    try {
      debugPrint('🎵 [CONTROLLER] play() called');
      await _handler.play();
      debugPrint('✅ [CONTROLLER] play() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] play() failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      debugPrint('⏸️  [CONTROLLER] pause() called');
      await _handler.pause();
      debugPrint('✅ [CONTROLLER] pause() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] pause() failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      debugPrint('⏹️  [CONTROLLER] stop() called');
      await _handler.stop();
      debugPrint('✅ [CONTROLLER] stop() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] stop() failed: $e');
    }
  }

  Future<void> seek(Duration duration) async {
    try {
      debugPrint('⏱️  [CONTROLLER] seek() called with ${duration.inSeconds}s');
      await _handler.seek(duration);
      debugPrint('✅ [CONTROLLER] seek() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] seek() failed: $e');
    }
  }

  Future<void> next() async {
    try {
      debugPrint('⏭️  [CONTROLLER] next() called');
      await _handler.skipToNext();
      debugPrint('✅ [CONTROLLER] next() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] next() failed: $e');
    }
  }

  Future<void> previous() async {
    try {
      debugPrint('⏮️  [CONTROLLER] previous() called');
      await _handler.skipToPrevious();
      debugPrint('✅ [CONTROLLER] previous() succeeded');
    } catch (e) {
      debugPrint('❌ [CONTROLLER] previous() failed: $e');
    }
  }

  Future<void> skipToQueueItem(int index) => _handler.skipToQueueItem(index);

  Future<void> playNext(Song song) => _handler.playNext(song);
  Future<void> addToQueue(Song song) => _handler.addToQueue(song);
  Future<void> removeFromQueue(int index) => _handler.removeFromQueue(index);
  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _handler.reorderQueue(oldIndex, newIndex);
  Future<void> clearQueue() => _handler.clearQueue();

  Future<void> toggleShuffle() {
    final nextMode = shuffleMode.value == AudioServiceShuffleMode.all
        ? AudioServiceShuffleMode.none
        : AudioServiceShuffleMode.all;
    return _handler.setShuffleMode(nextMode);
  }

  Future<void> cycleRepeat() {
    final modes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.one,
    ];
    final nextIndex = (modes.indexOf(repeatMode.value) + 1) % modes.length;
    return _handler.setRepeatMode(modes[nextIndex]);
  }

  Future<void> setSpeed(double newSpeed) => _handler.setSpeed(newSpeed);

  /// Sets (or clears) the sleep timer and starts a live countdown.
  void setSleepTimer(Duration? duration) {
    // Cancel any existing countdown
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = null;

    // Notify the audio handler
    _handler.setSleepTimer(duration);

    if (duration == null || duration <= Duration.zero) {
      sleepTimer.value = null;
      return;
    }

    // Start live countdown
    sleepTimer.value = duration;

    _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = sleepTimer.value;
      if (current == null || current <= const Duration(seconds: 1)) {
        // Time's up
        timer.cancel();
        _sleepCountdownTimer = null;
        sleepTimer.value = null;

        // Pause playback when timer finishes
        if (playing.value) {
          pause();
        }
        return;
      }

      sleepTimer.value = current - const Duration(seconds: 1);
    });
  }

  void _initAutoplayListener() {
    ever(currentSong, (_) => updateAutoplayQueue());
    ever(queue, (_) => updateAutoplayQueue());
    ever(autoplayEnabled, (_) => updateAutoplayQueue());
  }

  void updateAutoplayQueue() {
    if (!autoplayEnabled.value || currentSong.value == null) {
      autoplayQueue.clear();
      return;
    }

    try {
      final libraryController = Get.find<LibraryController>();
      final allSongs = libraryController.songs;

      if (allSongs.isEmpty) {
        autoplayQueue.clear();
        return;
      }

      final current = currentSong.value!;
      final queueIds = queue.map((s) => s.id).toSet();

      // Filter out songs that are already in the manual queue or are current
      final availableSongs = allSongs.where((s) => s.id != current.id && !queueIds.contains(s.id)).toList();

      if (availableSongs.isEmpty) {
        autoplayQueue.clear();
        return;
      }

      // Rank/sort songs by similarity: same genre first, then same artist, then same album
      final similarSongs = availableSongs.where((s) =>
          (s.genre != null && current.genre != null && s.genre == current.genre) ||
          s.artist == current.artist ||
          s.album == current.album).toList();

      similarSongs.shuffle();
      final otherSongs = availableSongs.where((s) => !similarSongs.contains(s)).toList();
      otherSongs.shuffle();

      final List<Song> results = [...similarSongs, ...otherSongs];
      autoplayQueue.assignAll(results.take(15).toList());
    } catch (e) {
      debugPrint('Error updating autoplay queue: $e');
    }
  }

  @override

  void onClose() {
    _sleepCountdownTimer?.cancel();
    _mediaSub?.cancel();
    _playbackSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    _currentSongSub?.cancel();
    _sleepTimerSub?.cancel();
    super.onClose();
  }
}