class MusicModel {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int? year;
  final int? duration;
  final String path;
  final int? albumId;

  const MusicModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    this.year,
    this.duration,
    required this.path,
    this.albumId,
  });
}
