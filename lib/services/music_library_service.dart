
import 'package:flutter/services.dart';

import '../models/music_model.dart';

class MusicLibraryService {
  static const MethodChannel _channel =
      MethodChannel('music_vault/storage');

  Future<List<MusicModel>> getSongs() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('getSongs');

    return (result ?? []).map((item) {
      final data = Map<String, dynamic>.from(item as Map);

      return MusicModel(
        id: (data['id'] as num).toInt(),
        title: data['title'] as String? ?? 'Unknown Title',
        artist: data['artist'] as String? ?? 'Unknown Artist',
        album: data['album'] as String? ?? 'Unknown Album',
        genre: 'Unknown Genre',
        duration: (data['duration'] as num?)?.toInt(),
        path: data['path'] as String,
      );
    }).toList();
  }

  Future<void> importAudio(String name, Uint8List bytes) async {
    await _channel.invokeMethod('importAudio', {
      'name': name,
      'bytes': bytes,
    });
  }

  Future<void> deleteSong(String path) async {
    await _channel.invokeMethod('deleteSong', {
      'path': path,
    });
  }

  Future<int> getStorageBytes() async {
    final result =
        await _channel.invokeMethod<int>('getStorageBytes');
    return result ?? 0;
  }

  Future<void> openMusicVaultFolder() async {
    await _channel.invokeMethod('openMusicVaultFolder');
  }
}


