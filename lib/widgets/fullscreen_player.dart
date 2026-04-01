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
  bool _isLoadingArt = true;

  @override
  void initState() {
    super.initState();
    _listenToMediaItemChanges();
  }

  void _listenToMediaItemChanges() {
    audioHandler.mediaItem.listen((item) {
      if (item != null) {
        if (mounted) {
          setState(() => _isLoadingArt = true);
        }
        _loadArtwork(item.id);
      }
    });
  }

  Future<void> _loadArtwork(String id) async {
    try {
      final art = await _audioQuery.queryArtwork(
        int.parse(id),
        ArtworkType.AUDIO,
        size: 800,
      );
      if (mounted) {
        setState(() {
          _albumArt = art;
          _isLoadingArt = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _albumArt = null;
          _isLoadingArt = false;
        });
      }
    }
  }

  void _showQueueSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                color: colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text("Playing Next", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<List<MediaItem>>(
                      stream: audioHandler.queue,
                      builder: (context, snapshot) {
                        final queue = snapshot.data ?? [];
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: queue.length,
                          separatorBuilder: (_, __) => Divider(color: colorScheme.onSurface.withValues(alpha: 0.05), indent: 70),
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            final isCurrent = item.id == audioHandler.mediaItem.value?.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  child: const Icon(CupertinoIcons.music_note),
                                ),
                              ),
                              title: Text(item.title, style: TextStyle(color: isCurrent ? colorScheme.primary : colorScheme.onSurface, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                              trailing: isCurrent ? Icon(CupertinoIcons.speaker_3_fill, color: colorScheme.primary, size: 18) : null,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox.shrink();

          return Stack(
            children: [
              // Background Blur (Only shows when art is ready)
              Positioned.fill(
                child: Container(
                  color: colorScheme.surface,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1000),
                    child: (!_isLoadingArt && _albumArt != null) 
                        ? Image.memory(_albumArt!, key: ValueKey(_albumArt!.hashCode), fit: BoxFit.cover, width: double.infinity, height: double.infinity) 
                        : const SizedBox.shrink(key: ValueKey('empty_bg')),
                  ),
                ),
              ),
              
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: isDark ? Colors.black.withValues(alpha: 0.5) : colorScheme.surface.withValues(alpha: 0.7)),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: Icon(CupertinoIcons.chevron_down, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
                          Text("Now Playing", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          IconButton(icon: Icon(CupertinoIcons.list_bullet, color: colorScheme.onSurface), onPressed: () => _showQueueSheet(context)),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // iOS 26 Style "Spring-In" Album Art
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      tween: Tween(begin: 0.0, end: _isLoadingArt ? 0.0 : 1.0),
                      builder: (context, opacity, child) {
                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            // Optional: slight slide up on entrance
                            offset: Offset(0, 20 * (1 - opacity)),
                            child: child,
                          ),
                        );
                      },
                      child: StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          
                          // FIX: If loading, keep scale small and neutral.
                          // Only allow the "Bouncy" logic once loading is false.
                          final targetScale = _isLoadingArt ? 0.85 : (isPlaying ? 1.0 : 0.85);

                          return AnimatedScale(
                            scale: targetScale,
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutBack, 
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              width: MediaQuery.of(context).size.width * 0.82,
                              height: MediaQuery.of(context).size.width * 0.82,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isPlaying ? 0.35 : 0.15),
                                    blurRadius: isPlaying ? 45 : 20,
                                    spreadRadius: isPlaying ? 5 : 0,
                                    offset: Offset(0, isPlaying ? 25 : 10),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: _albumArt != null
                                    ? Image.memory(_albumArt!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                    : Container(
                                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                                        child: Icon(Icons.music_note, size: 100, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(),

                    // Info, Slider, and Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mediaItem.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(mediaItem.artist ?? 'Unknown Artist', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.heart, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),

                    _buildSlider(mediaItem, colorScheme),
                    _buildControls(colorScheme),
                    _buildExtraControls(colorScheme),

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

  // ... (Helper widgets _buildSlider, _buildControls, _buildExtraControls, _formatDuration remain unchanged) ...
  Widget _buildSlider(MediaItem item, ColorScheme colorScheme) {
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
                  thumbColor: colorScheme.onSurface,
                  activeTrackColor: colorScheme.onSurface,
                  inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                ),
                child: Slider(
                  value: pos.inMilliseconds.toDouble().clamp(0, total.inMilliseconds.toDouble()),
                  max: total.inMilliseconds.toDouble() > 0 ? total.inMilliseconds.toDouble() : 1.0,
                  onChanged: (v) => audioHandler.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(pos), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                    Text(_formatDuration(total), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CupertinoButton(child: Icon(CupertinoIcons.backward_fill, color: colorScheme.onSurface, size: 35), onPressed: () => audioHandler.skipToPrevious()),
            CupertinoButton(padding: EdgeInsets.zero, onPressed: playing ? audioHandler.pause : audioHandler.play, child: Icon(playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: colorScheme.onSurface, size: 70)),
            CupertinoButton(child: Icon(CupertinoIcons.forward_fill, color: colorScheme.onSurface, size: 35), onPressed: () => audioHandler.skipToNext()),
          ],
        );
      },
    );
  }

  Widget _buildExtraControls(ColorScheme colorScheme) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final repeatMode = state?.repeatMode ?? AudioServiceRepeatMode.none;
        final shuffleEnabled = state?.shuffleMode == AudioServiceShuffleMode.all;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(CupertinoIcons.shuffle, color: shuffleEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3), size: 24), onPressed: () => audioHandler.setShuffleMode(shuffleEnabled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all)),
              IconButton(icon: Icon(repeatMode == AudioServiceRepeatMode.one ? CupertinoIcons.repeat_1 : CupertinoIcons.repeat, color: repeatMode == AudioServiceRepeatMode.none ? colorScheme.onSurface.withValues(alpha: 0.3) : colorScheme.primary, size: 24), onPressed: () {
                  final modes = [AudioServiceRepeatMode.none, AudioServiceRepeatMode.all, AudioServiceRepeatMode.one];
                  final nextIndex = (modes.indexOf(repeatMode) + 1) % modes.length;
                  audioHandler.setRepeatMode(modes[nextIndex]);
                }),
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