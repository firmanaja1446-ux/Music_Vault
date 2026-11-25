import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/music_controller.dart';
import '../../core/app_colors.dart';
import '../tabs/albums_tab.dart';
import '../tabs/home_tab.dart';
import '../tabs/profile_tab.dart';
import '../widgets/mini_player.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int selectedTab = 0;

  final List<String> titles = [
    'Home',
    'Albums',
    'Library',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicController>().loadSongs();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload diam-diam, tanpa spinner, supaya tab tidak dibongkar.
      context.read<MusicController>().loadSongs(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            title: Text(
              titles[selectedTab],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => controller.loadSongs(),
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : controller.errorMessage != null
                  ? Center(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : IndexedStack(
                      index: selectedTab,
                      children: [
                        HomeTab(controller: controller),
                        AlbumsTab(controller: controller),
                        const LibraryScreen(),
                        ProfileTab(controller: controller),
                      ],
                    ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.currentSong != null)
                MiniPlayer(controller: controller),
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBar,
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: NavigationBar(
        height: 68,
        backgroundColor: AppColors.navBar,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.album_outlined),
            selectedIcon: Icon(Icons.album, color: AppColors.accent),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music, color: AppColors.accent),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.accent),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
