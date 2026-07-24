import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import '../core/models/song_model.dart';
import '../core/services/audio_handler.dart';

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
  final Rxn<Duration> sleepTimer = Rxn<Duration>();

  StreamSubscription? _mediaSub;
  StreamSubscription? _playbackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _currentSongSub;
  StreamSubscription? _sleepTimerSub;

  @override
  void onInit() {
    super.onInit();
    _bindAudioHandler();
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
          source: sourceStr == 'network' ? AudioSourceType.network : AudioSourceType.local,
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

    _sleepTimerSub = _handler.sleepTimerStream.listen((timer) {
      sleepTimer.value = timer;
    });
  }

  // ================= CONTROLLER ACTIONS =================

  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) =>
      _handler.setQueue(songs, initialIndex: initialIndex);

  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    if (currentSong.value?.id == song.id) {
      if (!playing.value) {
        await play();
      }
      return;
    }

    if (contextQueue != null && contextQueue.isNotEmpty) {
      final index = contextQueue.indexWhere((s) => s.id == song.id);
      await _handler.setQueue(contextQueue, initialIndex: index >= 0 ? index : 0);
    } else {
      await _handler.setQueue([song], initialIndex: 0);
    }
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration duration) => _handler.seek(duration);
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();

  Future<void> skipToQueueItem(int index) => _handler.skipToQueueItem(index);

  Future<void> playNext(Song song) => _handler.playNext(song);
  Future<void> addToQueue(Song song) => _handler.addToQueue(song);
  Future<void> removeFromQueue(int index) => _handler.removeFromQueue(index);
  Future<void> reorderQueue(int oldIndex, int newIndex) => _handler.reorderQueue(oldIndex, newIndex);
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

  void setSleepTimer(Duration? duration) => _handler.setSleepTimer(duration);

  @override
  void onClose() {
    _mediaSub?.cancel();
    _playbackSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    _currentSongSub?.cancel();
    _sleepTimerSub?.cancel();
    super.onClose();
  }
}