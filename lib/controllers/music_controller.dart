// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/music_model.dart';
import '../models/playlist_model.dart';
import '../services/music_library_service.dart';
import '../services/playlist_service.dart';
import '../services/equalizer_settings_service.dart';

class MusicController extends ChangeNotifier {
  final MusicLibraryService _libraryService = MusicLibraryService();
  final PlaylistService _playlistService = PlaylistService();
  final EqualizerSettingsService _equalizerSettings =
      EqualizerSettingsService();

  List<double> globalEqualizerGains = [];
  String globalEqualizerPreset = 'Normal';
  Map<String, List<double>> songEqualizerSettings = {};
  bool _equalizerSettingsLoaded = false;
  late final AndroidEqualizer equalizer;
  late final AudioPlayer player;
  AndroidEqualizerParameters? equalizerParameters;

  StreamSubscription<int?>? _indexSub;

  /// Seluruh lagu di library.
  List<MusicModel> songs = [];
  List<PlaylistModel> playlists = [];

  /// Antrean yang sedang dimuat di player (urutan sama dengan sumber audio).
  List<MusicModel> queue = [];

  MusicModel? _currentSong;
  int storageBytes = 0;
  bool isLoading = false;
  String? errorMessage;

MusicController() {
  equalizer = AndroidEqualizer();

  player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [equalizer],
    ),
  );

  // Lagu aktif selalu mengikuti posisi di antrean, termasuk saat
  // lagu berganti otomatis, shuffle, atau next/previous.
  _indexSub = player.currentIndexStream.listen((_) {
    _syncCurrent();
    unawaited(_applyEqualizerForCurrentSong());
  });

  unawaited(_prepareEqualizer());
}

Future<void> _prepareEqualizer() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  try {
    if (player.audioSources.isEmpty) {
      await player.setAudioSources(
        [
          AudioSource.uri(
            Uri.dataFromBytes(
              _createSilentWav(),
              mimeType: 'audio/wav',
            ),
            tag: MediaItem(
              id: '__musicvault_eq_silent__',
              title: 'MusicVault Equalizer',
              artist: 'Internal',
            ),
          ),
        ],
        initialIndex: 0,
      );
    }

    await _initializeEqualizer();
  } catch (e) {
    debugPrint('Gagal menyiapkan Equalizer: $e');
  }
}


  MusicModel? get currentSong => _currentSong;

  String get storageLabel {
    if (storageBytes < 1024 * 1024) {
      return '${(storageBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (storageBytes < 1024 * 1024 * 1024) {
      return '${(storageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(storageBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } 

Future<void> _initializeEqualizer() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  try {
    debugPrint("EQ TRACE 1: Mengambil parameter...");
    equalizerParameters ??= await equalizer.parameters;
    debugPrint("EQ TRACE 2: Parameter berhasil diambil.");

    final params = equalizerParameters!;

    if (!_equalizerSettingsLoaded) {
      globalEqualizerGains =
          await _equalizerSettings.loadGlobalGains() ??
          List<double>.filled(params.bands.length, 0.0);

      if (globalEqualizerGains.length != params.bands.length) {
        globalEqualizerGains =
            List<double>.filled(params.bands.length, 0.0);
      }

      globalEqualizerPreset =
          await _equalizerSettings.loadGlobalPreset();

      songEqualizerSettings =
          await _equalizerSettings.loadAllSongSettings();

      _equalizerSettingsLoaded = true;
      debugPrint("EQ TRACE 4: Pengaturan berhasil dimuat.");
    }

    debugPrint("EQ TRACE 5: Mengaktifkan Equalizer...");
    await equalizer.setEnabled(true);
    debugPrint("EQ TRACE 6: Equalizer aktif.");
    debugPrint("EQ TRACE 7: Menerapkan gain...");
    await _applyEqualizerForCurrentSong();
    debugPrint("EQ TRACE 8: Gain berhasil diterapkan.");

    debugPrint('========== MUSICVAULT EQUALIZER ==========');
    debugPrint('Status: Berhasil diinisialisasi');
    debugPrint('Jumlah band: ${params.bands.length}');
    debugPrint('Gain minimum: ${params.minDecibels} dB');
    debugPrint('Gain maksimum: ${params.maxDecibels} dB');

    for (final band in params.bands) {
      debugPrint(
        'Band ${band.index}: '
        '${band.centerFrequency.toStringAsFixed(1)} Hz | '
        'Gain: ${band.gain} dB',
      );
    }

    debugPrint('==========================================');

    notifyListeners();
  } catch (e) {
    debugPrint('Gagal menginisialisasi Equalizer: $e');
  }
}

Future<void> _applyEqualizerForCurrentSong() async {
  final params = equalizerParameters;
  if (params == null || params.bands.isEmpty) return;

  try {
    final song = _currentSong;
    final songGains =
        song == null ? null : songEqualizerSettings[song.path];

    final gains = songGains != null &&
            songGains.length == params.bands.length
        ? songGains
        : globalEqualizerGains;

    for (var i = 0; i < params.bands.length; i++) {
      final requestedGain =
          i < gains.length ? gains[i] : 0.0;

      final gain = requestedGain
          .clamp(params.minDecibels, params.maxDecibels)
          .toDouble();

      await params.bands[i].setGain(gain);
    }
  } catch (e) {
    debugPrint('Gagal menerapkan pengaturan EQ: $e');
  }
}

Future<void> setGlobalEqualizerGains(
  List<double> gains, {
  String? preset,
}) async {
  final params = equalizerParameters;

  if (params != null && gains.length != params.bands.length) {
    throw ArgumentError('Jumlah gain harus sama dengan jumlah band EQ.');
  }

  final normalized = params == null
      ? List<double>.of(gains)
      : gains.map((gain) {
          return gain
              .clamp(params.minDecibels, params.maxDecibels)
              .toDouble();
        }).toList();

  globalEqualizerGains = normalized;

  if (preset != null) {
    globalEqualizerPreset = preset;
    await _equalizerSettings.saveGlobalPreset(preset);
  }

  await _equalizerSettings.saveGlobalGains(normalized);

  final currentHasOverride = _currentSong != null &&
      songEqualizerSettings.containsKey(_currentSong!.path);

  if (!currentHasOverride) {
    await _applyEqualizerForCurrentSong();
  }

  notifyListeners();
}

Future<void> setSongEqualizerGains(
  String songPath,
  List<double> gains,
) async {
  final params = equalizerParameters;

  if (params != null && gains.length != params.bands.length) {
    throw ArgumentError('Jumlah gain harus sama dengan jumlah band EQ.');
  }

  final normalized = params == null
      ? List<double>.of(gains)
      : gains.map((gain) {
          return gain
              .clamp(params.minDecibels, params.maxDecibels)
              .toDouble();
        }).toList();

  songEqualizerSettings[songPath] = normalized;

  await _equalizerSettings.saveSongGains(songPath, normalized);

  if (_currentSong?.path == songPath) {
    await _applyEqualizerForCurrentSong();
  }

  notifyListeners();
}

Future<void> clearSongEqualizerSettings(String songPath) async {
  songEqualizerSettings.remove(songPath);

  await _equalizerSettings.removeSongSettings(songPath);

  if (_currentSong?.path == songPath) {
    await _applyEqualizerForCurrentSong();
  }

  notifyListeners();
}





  void _syncCurrent() {
    final i = player.currentIndex;
    if (i != null && i >= 0 && i < queue.length) {
      _currentSong = queue[i];
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Library
  // ---------------------------------------------------------------------------

  /// [silent] = true: muat ulang tanpa spinner
  /// (dipakai saat app kembali dari background).
  Future<void> loadSongs({bool silent = false}) async {
    final previousPath = _currentSong?.path;

    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      songs = await _libraryService.getSongs();
      storageBytes = await _libraryService.getStorageBytes();
      playlists = await _playlistService.loadPlaylists();

      if (previousPath != null &&
          !songs.any((song) => song.path == previousPath)) {
        await _clearPlayback();
      }
    } catch (e) {
      errorMessage = 'Gagal memuat musik MusicVault: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _clearPlayback() async {
    await player.stop();
    queue = [];
    _currentSong = null;
  }

  Future<int> importAudioFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (files.isEmpty) return 0;

      int imported = 0;

      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;

        await _libraryService.importAudio(file.name, bytes);
        imported++;
      }

      await loadSongs();
      return imported;
    } catch (e) {
      errorMessage = 'Gagal menambahkan musik: $e';
      notifyListeners();
      return 0;
    }
  }

  Future<bool> removeSong(MusicModel song) async {
    try {
      if (_currentSong?.path == song.path) {
        await _clearPlayback();
      } else {
        // Buang dari antrean (dari belakang supaya index tidak bergeser).
        for (var i = queue.length - 1; i >= 0; i--) {
          if (queue[i].path == song.path) {
            await removeFromQueue(i);
          }
        }
      }

      await _libraryService.deleteSong(song.path);
      await clearSongEqualizerSettings(song.path);
      await loadSongs();
      return true;
    } catch (e) {
      errorMessage = 'Gagal menghapus musik: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> openMusicVaultFolder() async {
    await _libraryService.openMusicVaultFolder();
  }

  // ---------------------------------------------------------------------------
  // Playlist
  // ---------------------------------------------------------------------------

  Future<void> loadPlaylists() async {
    playlists = await _playlistService.loadPlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    await _playlistService.savePlaylists(playlists);
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final playlist = PlaylistModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      songIds: [],
    );

    playlists = [...playlists, playlist];
    await _savePlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;

    playlists = playlists.map((playlist) {
      return playlist.id == id
          ? playlist.copyWith(name: trimmedName)
          : playlist;
    }).toList();

    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    playlists = playlists.where((playlist) => playlist.id != id).toList();

    await _savePlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    playlists = playlists.map((playlist) {
      if (playlist.id != playlistId || playlist.songIds.contains(songId)) {
        return playlist;
      }

      return playlist.copyWith(
        songIds: [...playlist.songIds, songId],
      );
    }).toList();

    await _savePlaylists();
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    int songId,
  ) async {
    playlists = playlists.map((playlist) {
      if (playlist.id != playlistId) return playlist;

      return playlist.copyWith(
        songIds: playlist.songIds.where((id) => id != songId).toList(),
      );
    }).toList();

    await _savePlaylists();
  }

  List<MusicModel> getPlaylistSongs(String playlistId) {
    final playlist = playlists.where((p) => p.id == playlistId);

    if (playlist.isEmpty) return [];

    final songIds = playlist.first.songIds;

    return songIds.map((id) {
      return songs.where((song) => song.id == id);
    }).expand((result) => result).toList();
  }

  // ---------------------------------------------------------------------------
  // Pemutaran + antrean
  // ---------------------------------------------------------------------------

  AudioSource _sourceFor(MusicModel song) {
    return AudioSource.uri(
      Uri.parse(song.path),
      tag: MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
        album: song.album,
      ),
    );
  }

  /// Muat [list] sebagai antrean baru dan mulai dari [startIndex].
  Future<void> playQueue(
    List<MusicModel> list,
    int startIndex, {
    bool shuffle = false,
  }) async {
    if (list.isEmpty || startIndex < 0 || startIndex >= list.length) return;

    try {
      queue = List.of(list);
      _currentSong = queue[startIndex];
      notifyListeners();

      await player.setAudioSources(
        queue.map(_sourceFor).toList(),
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );
      await _initializeEqualizer();


      if (shuffle) {
        await player.shuffle();
        await player.setShuffleModeEnabled(true);
      }

      unawaited(player.play());
    } catch (e) {
      errorMessage = 'Gagal memutar lagu: $e';
      notifyListeners();
    }
  }

  /// Putar lagu ke-[index] dari library (seluruh library jadi antrean).
  Future<void> playSong(int index) => playQueue(songs, index);

  /// Putar [list] dalam urutan acak.
  Future<void> playShuffled(List<MusicModel> list) async {
    if (list.isEmpty) return;
    await playQueue(list, Random().nextInt(list.length), shuffle: true);
  }

  /// Loncat ke item ke-[index] di antrean yang sedang aktif.
  Future<void> playQueueIndex(int index) async {
    if (index < 0 || index >= queue.length) return;
    await player.seek(Duration.zero, index: index);
    unawaited(player.play());
  }

  Future<void> addToQueue(MusicModel song) async {
    if (queue.isEmpty) {
      await playQueue([song], 0);
      return;
    }

    try {
      queue.add(song);
      notifyListeners();
      await player.addAudioSource(_sourceFor(song));
    } catch (e) {
      errorMessage = 'Gagal menambah ke antrean: $e';
      notifyListeners();
    }
  }

  /// Taruh [song] tepat setelah lagu yang sedang diputar.
  Future<void> playNext(MusicModel song) async {
    if (queue.isEmpty) {
      await playQueue([song], 0);
      return;
    }

    try {
      final at = (player.currentIndex ?? -1) + 1;
      queue.insert(at, song);
      notifyListeners();
      await player.insertAudioSource(at, _sourceFor(song));
    } catch (e) {
      errorMessage = 'Gagal menambah ke antrean: $e';
      notifyListeners();
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= queue.length) return;

    if (queue.length == 1) {
      await _clearPlayback();
      notifyListeners();
      return;
    }

    try {
      queue.removeAt(index);
      notifyListeners();
      await player.removeAudioSourceAt(index);
      _syncCurrent();
    } catch (e) {
      errorMessage = 'Gagal menghapus dari antrean: $e';
      notifyListeners();
    }
  }

  /// [newIndex] adalah posisi akhir item (sudah dikoreksi untuk
  /// ReorderableListView).
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= queue.length ||
        newIndex >= queue.length) {
      return;
    }

    try {
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
      notifyListeners();
      await player.moveAudioSource(oldIndex, newIndex);
      _syncCurrent();
    } catch (e) {
      errorMessage = 'Gagal mengurutkan antrean: $e';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else if (_currentSong != null) {
      unawaited(player.play());
    }
    notifyListeners();
  }

  Future<void> nextSong() async {
    if (queue.isEmpty) return;

    if (player.hasNext) {
      await player.seekToNext();
    } else {
      // Ujung antrean: kembali ke awal.
      final first = (player.effectiveIndices.isNotEmpty ? player.effectiveIndices.first : 0);
      await player.seek(Duration.zero, index: first);
    }
  }

  Future<void> previousSong() async {
    if (queue.isEmpty) return;

    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      final last = (player.effectiveIndices.isNotEmpty ? player.effectiveIndices.last : queue.length - 1);
      await player.seek(Duration.zero, index: last);
    }
  }

  // ---------------------------------------------------------------------------
  // Shuffle & repeat
  // ---------------------------------------------------------------------------

  Future<void> toggleShuffle() async {
    final enable = !player.shuffleModeEnabled;
    if (enable) await player.shuffle();
    await player.setShuffleModeEnabled(enable);
    notifyListeners();
  }

  /// Urutan: mati -> ulangi semua -> ulangi satu lagu -> mati.
  Future<void> cycleLoopMode() async {
    final next = switch (player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await player.setLoopMode(next);
    notifyListeners();
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    player.dispose();
    super.dispose();
  }
}

Uint8List _createSilentWav() {
  const sampleRate = 44100;
  const channels = 1;
  const bitsPerSample = 16;
  const dataLength = sampleRate * channels * (bitsPerSample ~/ 8);

  final bytes = Uint8List(44 + dataLength);
  final header = ByteData.sublistView(bytes);

  void writeText(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes[offset + i] = value.codeUnitAt(i);
    }
  }

  writeText(0, 'RIFF');
  header.setUint32(4, 36 + dataLength, Endian.little);
  writeText(8, 'WAVE');
  writeText(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * channels * (bitsPerSample ~/ 8), Endian.little);
  header.setUint16(32, channels * (bitsPerSample ~/ 8), Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  writeText(36, 'data');
  header.setUint32(40, dataLength, Endian.little);

  return bytes;
}
/// in the name of god, i dont even know what the actual fuck is going on