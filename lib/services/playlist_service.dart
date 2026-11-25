import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist_model.dart';

class PlaylistService {
  static const String _storageKey = 'musicvault_playlists';

  Future<List<PlaylistModel>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => PlaylistModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    final prefs = await SharedPreferences.getInstance();

    final data = jsonEncode(
      playlists.map((playlist) => playlist.toJson()).toList(),
    );

    await prefs.setString(_storageKey, data);
  }
}