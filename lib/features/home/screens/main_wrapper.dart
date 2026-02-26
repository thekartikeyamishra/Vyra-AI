import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- SCREENS (Tabs) ---
import 'home_screen.dart'; // Tab 0: Dashboard
import '../../creation/screens/create_thumbnail_screen.dart'; // Tab 1: Viral Studio
import '../../profile/screens/profile_screen.dart'; // Tab 2: Command Center

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  // Current selected tab index
  int _currentIndex = 0;

  // List of screens for the Bottom Navigation
  // We use 'const' constructors where possible for performance optimization
  final List<Widget> _screens = [
    const HomeScreen(),          // Dashboard (Stats & Passive Revenue)
    const CreateThumbnailScreen(), // Viral Studio (The Core Tool)
    const ProfileScreen(),       // Profile (Growth & Secrets)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each tab 
      // (so you don't lose your place when switching tabs)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Material 3 Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Viral Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}