import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/services/audio_handler.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final handler = audioHandler as AudioPlayerHandler;

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        if (mediaItem == null) return const SizedBox();

        return Material(
          elevation: 8,
          color: Theme.of(context).cardColor,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 70,
              child: Row(
                children: [
                  const SizedBox(width: 10),

                  QueryArtworkWidget(
                    id: int.parse(mediaItem.id),
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(6),
                    nullArtworkWidget: const Icon(Icons.music_note),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          mediaItem.artist ?? "Unknown Artist",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  StreamBuilder<PlaybackState>(
                    stream: handler.playbackState,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;

                      return IconButton(
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          playing ? handler.pause() : handler.play();
                        },
                      );
                    },
                  ),

                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}