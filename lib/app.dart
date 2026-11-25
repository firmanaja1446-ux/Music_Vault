import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'views/screens/home_screen.dart';

class MusicVaultApp extends StatelessWidget {
  const MusicVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MusicVault',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: AppColors.navBar,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
