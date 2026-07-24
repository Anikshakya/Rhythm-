import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

enum AudioSourceType { local, network }

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? artwork;
  final Duration duration;
  final AudioSourceType source;
  final String uri;
  final String? localPath;
  final String? streamUrl;
  final String? lyrics;
  final String? genre;
  final int? year;
  final int? bitrate;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayed;
  final List<String> playlistIds;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.artwork,
    required this.duration,
    required this.source,
    required this.uri,
    this.localPath,
    this.streamUrl,
    this.lyrics,
    this.genre,
    this.year,
    this.bitrate,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed,
    this.playlistIds = const [],
  });

  bool get isLocal => source == AudioSourceType.local;
  bool get isNetwork => source == AudioSourceType.network;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artwork,
    Duration? duration,
    AudioSourceType? source,
    String? uri,
    String? localPath,
    String? streamUrl,
    String? lyrics,
    String? genre,
    int? year,
    int? bitrate,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayed,
    List<String>? playlistIds,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artwork: artwork ?? this.artwork,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      uri: uri ?? this.uri,
      localPath: localPath ?? this.localPath,
      streamUrl: streamUrl ?? this.streamUrl,
      lyrics: lyrics ?? this.lyrics,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      bitrate: bitrate ?? this.bitrate,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playlistIds: playlistIds ?? this.playlistIds,
    );
  }

  MediaItem toMediaItem() {
    Uri? artUri;
    if (artwork != null && artwork!.isNotEmpty) {
      if (artwork!.startsWith('http://') || artwork!.startsWith('https://') || artwork!.startsWith('content://') || artwork!.startsWith('file://')) {
        artUri = Uri.tryParse(artwork!);
      } else {
        artUri = Uri.file(artwork!);
      }
    }

    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: artUri,
      extras: {
        'source': source.name,
        'uri': uri,
        'isFavorite': isFavorite,
        'genre': genre,
      },
    );
  }

  AudioSource toAudioSource() {
    final tag = toMediaItem();
    if (source == AudioSourceType.local || uri.startsWith('/') || uri.startsWith('file://')) {
      final cleanPath = uri.startsWith('file://') ? Uri.parse(uri).path : uri;
      return AudioSource.uri(Uri.file(cleanPath), tag: tag);
    } else {
      return AudioSource.uri(Uri.parse(uri), tag: tag);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'artwork': artwork,
      'durationMs': duration.inMilliseconds,
      'source': source.name,
      'uri': uri,
      'localPath': localPath,
      'streamUrl': streamUrl,
      'lyrics': lyrics,
      'genre': genre,
      'year': year,
      'bitrate': bitrate,
      'isFavorite': isFavorite ? 1 : 0,
      'playCount': playCount,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'playlistIds': playlistIds.join(','),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      artwork: json['artwork'],
      duration: Duration(milliseconds: json['durationMs'] ?? json['duration'] ?? 0),
      source: json['source'] == 'network' ? AudioSourceType.network : AudioSourceType.local,
      uri: json['uri'] ?? json['data'] ?? '',
      localPath: json['localPath'],
      streamUrl: json['streamUrl'],
      lyrics: json['lyrics'],
      genre: json['genre'],
      year: json['year'],
      bitrate: json['bitrate'],
      isFavorite: json['isFavorite'] == 1 || json['isFavorite'] == true,
      playCount: json['playCount'] ?? 0,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayed'])
          : null,
      playlistIds: json['playlistIds'] != null && (json['playlistIds'] as String).isNotEmpty
          ? (json['playlistIds'] as String).split(',')
          : [],
    );
  }
}
