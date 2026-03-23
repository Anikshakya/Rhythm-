import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dhun/core/services/audio_handler.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Uint8List? _albumArt;
  
  // Track the media item to listen for external changes (like notifications)
  @override
  void initState() {
    super.initState();
    _listenToMediaItemChanges();
  }

  // CRITICAL FIX: Listen to the mediaItem stream so artwork updates 
  // even if the song is skipped from the notification bar.
  void _listenToMediaItemChanges() {
    audioHandler.mediaItem.listen((item) {
      if (item != null) {
        _loadArtwork(item.id);
      }
    });
  }

  Future<void> _loadArtwork(String id) async {
    final art = await _audioQuery.queryArtwork(
      int.parse(id),
      ArtworkType.AUDIO,
      size: 800,
    );
    if (mounted) setState(() => _albumArt = art);
  }

  // --- Queue Bottom Sheet ---
  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text("Playing Next", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<List<MediaItem>>(
                      stream: audioHandler.queue,
                      builder: (context, snapshot) {
                        final queue = snapshot.data ?? [];
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: queue.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10, indent: 70),
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            final isCurrent = item.id == audioHandler.mediaItem.value?.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.white10,
                                  child: const Icon(CupertinoIcons.music_note, color: Colors.white30),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : Colors.white70,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                              ),
                              subtitle: Text(item.artist ?? '', style: const TextStyle(color: Colors.white38)),
                              trailing: isCurrent ? const Icon(CupertinoIcons.speaker_3_fill, color: Colors.white, size: 18) : null,
                              onTap: () {
                                audioHandler.skipToQueueItem(index);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox.shrink();

          return Stack(
            children: [
              // Background Blur
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: _albumArt != null ? Image.memory(_albumArt!, fit: BoxFit.cover) : null,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.chevron_down, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text("Now Playing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(CupertinoIcons.list_bullet, color: Colors.white70),
                            onPressed: () => _showQueueSheet(context),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Animated Album Art
                    StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data?.playing ?? false;
                        return AnimatedScale(
                          scale: isPlaying ? 1.0 : 0.85,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.width * 0.85,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _albumArt != null
                                  ? Image.memory(_albumArt!, fit: BoxFit.cover)
                                  : Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100, color: Colors.white24)),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Song Title & Artist
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mediaItem.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1),
                                Text(mediaItem.artist ?? 'Unknown Artist', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18)),
                              ],
                            ),
                          ),
                          const Icon(CupertinoIcons.heart, color: Colors.white70),
                        ],
                      ),
                    ),

                    _buildSlider(mediaItem),
                    _buildControls(),
                    _buildExtraControls(), // Repeat and Shuffle row

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlider(MediaItem item) {
    return StreamBuilder<Duration>(
      stream: (audioHandler as AudioPlayerHandler).positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final total = item.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbColor: Colors.white,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                ),
                child: Slider(
                  value: pos.inMilliseconds.toDouble().clamp(0, total.inMilliseconds.toDouble()),
                  max: total.inMilliseconds.toDouble() > 0 ? total.inMilliseconds.toDouble() : 1.0,
                  onChanged: (v) => audioHandler.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(pos), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    Text(_formatDuration(total), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.backward_fill, color: Colors.white, size: 40),
              onPressed: () => audioHandler.skipToPrevious(),
            ),
            IconButton(
              icon: Icon(playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: Colors.white, size: 75),
              onPressed: playing ? audioHandler.pause : audioHandler.play,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.forward_fill, color: Colors.white, size: 40),
              onPressed: () => audioHandler.skipToNext(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtraControls() {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final repeatMode = state?.repeatMode ?? AudioServiceRepeatMode.none;
        final shuffleEnabled = state?.shuffleMode == AudioServiceShuffleMode.all;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shuffle Button
              IconButton(
                icon: Icon(
                  shuffleEnabled ? CupertinoIcons.shuffle : CupertinoIcons.shuffle,
                  color: shuffleEnabled ? Colors.white : Colors.white24,
                  size: 22,
                ),
                onPressed: () {
                  audioHandler.setShuffleMode(
                    shuffleEnabled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                  );
                },
              ),

              // Repeat Button
              IconButton(
                icon: Icon(
                  repeatMode == AudioServiceRepeatMode.one 
                      ? CupertinoIcons.repeat_1 
                      : CupertinoIcons.repeat,
                  color: repeatMode == AudioServiceRepeatMode.none ? Colors.white24 : Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  AudioServiceRepeatMode nextMode;
                  if (repeatMode == AudioServiceRepeatMode.none) {
                    nextMode = AudioServiceRepeatMode.all;
                  } else if (repeatMode == AudioServiceRepeatMode.all) {
                    nextMode = AudioServiceRepeatMode.one;
                  } else {
                    nextMode = AudioServiceRepeatMode.none;
                  }
                  audioHandler.setRepeatMode(nextMode);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}