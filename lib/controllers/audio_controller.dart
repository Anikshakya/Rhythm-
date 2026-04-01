import 'dart:async';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:dhun/core/services/audio_handler.dart';

class AudioController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final Rxn<MediaItem> currentItem = Rxn<MediaItem>();
  final Rxn<Uint8List> albumArt = Rxn<Uint8List>();
  final RxBool playing = false.obs;
  final Rx<AudioServiceRepeatMode> repeatMode =
      AudioServiceRepeatMode.none.obs;
  final Rx<AudioServiceShuffleMode> shuffleMode =
      AudioServiceShuffleMode.none.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> bufferedPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxList<MediaItem> queue = <MediaItem>[].obs;

  final Map<String, Uint8List?> _artCache = {};

  StreamSubscription? _mediaSub;
  StreamSubscription? _playbackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _positionSub;

  @override
  void onInit() {
    super.onInit();
    _bindAudioHandler();
  }

  void _bindAudioHandler() {
    _mediaSub = audioHandler.mediaItem.listen((item) async {
      currentItem.value = item;

      if (item == null) {
        albumArt.value = null;
        totalDuration.value = Duration.zero;
        return;
      }

      totalDuration.value = item.duration ?? Duration.zero;

      await _loadArtworkIfNeeded(item.id);
    });

    _playbackSub = audioHandler.playbackState.listen((state) {
      playing.value = state.playing;
      repeatMode.value = state.repeatMode;
      shuffleMode.value = state.shuffleMode;
      bufferedPosition.value = state.bufferedPosition;
    });

    _queueSub = audioHandler.queue.listen((items) {
      queue.assignAll(items);
    });

    _positionSub = (audioHandler as AudioPlayerHandler).positionStream.listen((pos) {
      position.value = pos;
    });
  }

  Future<void> _loadArtworkIfNeeded(String id) async {
    if (_artCache.containsKey(id)) {
      albumArt.value = _artCache[id];
      return;
    }

    try {
      final art = await _audioQuery.queryArtwork(
        int.parse(id),
        ArtworkType.AUDIO,
        size: 800,
      );

      _artCache[id] = art;
      if (currentItem.value?.id == id) {
        albumArt.value = art;
      }
    } catch (e) {
      _artCache[id] = null;
      if (currentItem.value?.id == id) {
        albumArt.value = null;
      }
    }
  }

  Future<void> playSong(dynamic song) => audioHandler.play();
  Future<void> play() => audioHandler.play();
  Future<void> pause() => audioHandler.pause();
  Future<void> seek(Duration d) => audioHandler.seek(d);
  Future<void> next() => audioHandler.skipToNext();
  Future<void> previous() => audioHandler.skipToPrevious();

  Future<void> toggleShuffle() {
    final nextMode =
        shuffleMode.value == AudioServiceShuffleMode.all
            ? AudioServiceShuffleMode.none
            : AudioServiceShuffleMode.all;
    return audioHandler.setShuffleMode(nextMode);
  }

  Future<void> cycleRepeat() {
    final modes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.one,
    ];
    final current = repeatMode.value;
    final nextIndex = (modes.indexOf(current) + 1) % modes.length;
    return audioHandler.setRepeatMode(modes[nextIndex]);
  }

  @override
  void onClose() {
    _mediaSub?.cancel();
    _playbackSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    super.onClose();
  }
}