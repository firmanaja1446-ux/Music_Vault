import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/music_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicvault.audio',
    androidNotificationChannelName: 'MusicVault Playback',
    androidNotificationOngoing: true,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => MusicController(),
      child: const MusicVaultApp(),
    ),
  );
}
