import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../../models/music_model.dart';

class EqualizerScreen extends StatefulWidget {
  final MusicModel? song;

  const EqualizerScreen({super.key, this.song});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  static const List<String> _presets = [
    'Normal',
    'Bass Boost',
    'Treble',
    'Rock',
  ];

  List<double> _draftGains = [];
  String? _draftKey;

  List<double> _gainsForPreset(
    String preset,
    List<dynamic> bands,
    double minimum,
    double maximum,
  ) {
    return bands.map((band) {
      final frequency = band.centerFrequency as double;
      double gain;

      switch (preset) {
        case 'Bass Boost':
          if (frequency <= 150) {
            gain = 7;
          } else if (frequency <= 500) {
            gain = 5;
          } else if (frequency <= 2000) {
            gain = 1;
          } else if (frequency <= 8000) {
            gain = 2;
          } else {
            gain = 3;
          }
          break;
        case 'Treble':
          if (frequency <= 150) {
            gain = -2;
          } else if (frequency <= 500) {
            gain = -1;
          } else if (frequency <= 2000) {
            gain = 1;
          } else if (frequency <= 8000) {
            gain = 5;
          } else {
            gain = 6;
          }
          break;
        case 'Rock':
          if (frequency <= 150) {
            gain = 4;
          } else if (frequency <= 500) {
            gain = 2;
          } else if (frequency <= 2000) {
            gain = -1;
          } else if (frequency <= 8000) {
            gain = 3;
          } else {
            gain = 4;
          }
          break;
        default:
          gain = 0;
      }

      return gain.clamp(minimum, maximum).toDouble();
    }).toList();
  }

  String? _detectPreset(
    List<double> gains,
    List<dynamic> bands,
    double minimum,
    double maximum,
  ) {
    for (final preset in _presets) {
      final presetGains = _gainsForPreset(
        preset,
        bands,
        minimum,
        maximum,
      );

      if (gains.length != presetGains.length) continue;

      final matches = List.generate(
        gains.length,
        (index) => (gains[index] - presetGains[index]).abs() < 0.05,
      ).every((match) => match);

      if (matches) return preset;
    }

    return null;
  }

  String _frequencyLabel(double frequency) {
    if (frequency >= 1000) {
      final value = frequency / 1000;
      return '${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}k';
    }
    return '${frequency.round()}';
  }

  void _saveGains(MusicController controller, List<double> gains) {
    final song = widget.song;
    if (song == null) {
      unawaited(controller.setGlobalEqualizerGains(gains, preset: 'Manual'));
    } else {
      unawaited(controller.setSongEqualizerGains(song.path, gains));
    }
  }

  void _selectPreset(
    MusicController controller,
    List<dynamic> bands,
    double minimum,
    double maximum,
    String preset,
  ) {
    final gains = _gainsForPreset(preset, bands, minimum, maximum);
    setState(() {
      _draftGains = gains;
    });

    final song = widget.song;
    if (song == null) {
      unawaited(controller.setGlobalEqualizerGains(gains, preset: preset));
    } else {
      unawaited(controller.setSongEqualizerGains(song.path, gains));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        final params = controller.equalizerParameters;
        final song = widget.song;
        final isSongMode = song != null;
        final songHasOverride = isSongMode &&
            controller.songEqualizerSettings.containsKey(song.path);

        if (params == null || params.bands.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.bg,
              foregroundColor: Colors.white,
              title: const Text('Equalizer'),
            ),
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 16),
                  Text(
                    'Menyiapkan Equalizer perangkat...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }

        final minimum = params.minDecibels.toDouble();
        final maximum = params.maxDecibels.toDouble();
        final storedGains = isSongMode
            ? (controller.songEqualizerSettings[song.path] ??
                controller.globalEqualizerGains)
            : controller.globalEqualizerGains;
        final baseGains = storedGains.length == params.bands.length
            ? storedGains
            : List<double>.filled(params.bands.length, 0);
        final draftKey = isSongMode ? song.path : '__global__';

        if (_draftKey != draftKey || _draftGains.length != params.bands.length) {
          _draftKey = draftKey;
          _draftGains = List<double>.of(baseGains);
        }

        final selectedPreset = isSongMode
            ? _detectPreset(baseGains, params.bands, minimum, maximum)
            : controller.globalEqualizerPreset;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            foregroundColor: Colors.white,
            title: Text(isSongMode ? 'EQ Khusus Lagu' : 'Equalizer'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                if (isSongMode) ...[
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    song.artist,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 18),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSongMode
                            ? (songHasOverride
                                ? 'Pengaturan khusus lagu'
                                : 'Mengikuti EQ global')
                            : 'Equalizer global',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSongMode
                            ? 'Perubahan di sini hanya berlaku untuk lagu ini.'
                            : 'Pengaturan ini berlaku untuk semua lagu tanpa EQ khusus.',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PRESET',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    final selected = selectedPreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: selected,
                      onSelected: (_) => _selectPreset(
                        controller,
                        params.bands,
                        minimum,
                        maximum,
                        preset,
                      ),
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.panel,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.accent : Colors.white12,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PENGATURAN MANUAL',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    Text(
                      '${minimum.toStringAsFixed(0)} hingga ${maximum.toStringAsFixed(0)} dB',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(params.bands.length, (index) {
                      final band = params.bands[index];
                      final gain = _draftGains[index]
                          .clamp(minimum, maximum)
                          .toDouble();
                      final divisions = ((maximum - minimum) * 2)
                          .round()
                          .clamp(1, 120);

                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 174,
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SizedBox(
                                    width: 150,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppColors.accent,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: AppColors.accent,
                                        overlayColor: AppColors.accent.withValues(alpha: 0.16),
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                      ),
                                      child: Slider(
                                        value: gain,
                                        min: minimum,
                                        max: maximum,
                                        divisions: divisions,
                                        onChanged: (value) {
                                          final next = List<double>.of(_draftGains);
                                          next[index] = value;
                                          setState(() {
                                            _draftGains = next;
                                          });
                                          _saveGains(controller, next);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _frequencyLabel(band.centerFrequency.toDouble()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Hz',
                              style: TextStyle(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 22),
                if (isSongMode)
                  OutlinedButton.icon(
                    onPressed: songHasOverride
                        ? () async {
                            await controller.clearSongEqualizerSettings(song.path);
                            if (!mounted) return;
                            setState(() {
                              _draftGains = List<double>.of(
                                controller.globalEqualizerGains,
                              );
                            });
                          }
                        : null,
                    icon: const Icon(Icons.settings_backup_restore_rounded),
                    label: const Text('Gunakan EQ Global'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white30,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      final normal = List<double>.filled(params.bands.length, 0);
                      setState(() {
                        _draftGains = normal;
                      });
                      unawaited(
                        controller.setGlobalEqualizerGains(
                          normal,
                          preset: 'Normal',
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Equalizer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}





