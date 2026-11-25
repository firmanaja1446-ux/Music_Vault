import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EqualizerSettingsService {
  static const String _globalGainsKey = 'eq_global_gains_v1';
  static const String _globalPresetKey = 'eq_global_preset_v1';
  static const String _songSettingsKey = 'eq_song_settings_v1';

  Future<List<double>?> loadGlobalGains() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_globalGainsKey);

    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((value) => (value as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGlobalGains(List<double> gains) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalGainsKey, jsonEncode(gains));
  }

  Future<String> loadGlobalPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_globalPresetKey) ?? 'Normal';
  }

  Future<void> saveGlobalPreset(String preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalPresetKey, preset);
  }

  Future<Map<String, List<double>>> loadAllSongSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_songSettingsKey);

    if (data == null) return {};

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;

      return decoded.map((path, values) {
        final gains = (values as List)
            .map((value) => (value as num).toDouble())
            .toList();

        return MapEntry(path, gains);
      });
    } catch (_) {
      return {};
    }
  }

  Future<List<double>?> loadSongGains(String path) async {
    final settings = await loadAllSongSettings();
    return settings[path];
  }

  Future<void> saveSongGains(String path, List<double> gains) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await loadAllSongSettings();

    settings[path] = gains;

    await prefs.setString(_songSettingsKey, jsonEncode(settings));
  }

  Future<void> removeSongSettings(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await loadAllSongSettings();

    settings.remove(path);

    await prefs.setString(_songSettingsKey, jsonEncode(settings));
  }
}