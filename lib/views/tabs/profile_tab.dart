import 'package:flutter/material.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../screens/equalizer_screen.dart';

class ProfileTab extends StatelessWidget {
  final MusicController controller;

  const ProfileTab({super.key, required this.controller});

  Widget _profileItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.accentDark,
          child: Icon(Icons.person, size: 52, color: AppColors.accent),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'MusicVault User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Center(
          child: Text(
            'Offline Music Player',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        const SizedBox(height: 32),
        _profileItem(Icons.info_outline, 'About MusicVault', 'Version 1.0.0'),
        Card(
          color: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.equalizer_rounded,
              color: AppColors.accent,
            ),
            title: const Text(
              'Equalizer',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Atur kualitas suara semua lagu',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.white54,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EqualizerScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          color: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storage_outlined, color: AppColors.accent),
                    SizedBox(width: 12),
                    Text(
                      'Storage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  controller.storageLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Ruang yang digunakan oleh musik MusicVault',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await controller.openMusicVaultFolder();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal membuka folder: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Buka Folder Musik'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _profileItem(Icons.wifi_off, 'Mode', 'Offline'),
      ],
    );
  }
}
