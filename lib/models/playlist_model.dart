class PlaylistModel {
  final String id;
  final String name;
  final List<int> songIds;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: (json['songIds'] as List)
          .map((id) => (id as num).toInt())
          .toList(),
    );
  }

  PlaylistModel copyWith({
    String? name,
    List<int>? songIds,
  }) {
    return PlaylistModel(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }
}