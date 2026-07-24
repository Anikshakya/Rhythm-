import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final String? artwork;
  final List<Song> songs;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.artwork,
    required this.songs,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get songCount => songs.length;

  Duration get totalDuration =>
      songs.fold(Duration.zero, (prev, song) => prev + song.duration);

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? artwork,
    List<Song>? songs,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artwork: artwork ?? this.artwork,
      songs: songs ?? this.songs,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artwork': artwork,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Untitled Playlist',
      description: json['description'],
      artwork: json['artwork'],
      isFavorite: json['isFavorite'] == 1 || json['isFavorite'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      songs: json['songs'] != null
          ? (json['songs'] as List).map((e) => Song.fromJson(e)).toList()
          : [],
    );
  }
}
