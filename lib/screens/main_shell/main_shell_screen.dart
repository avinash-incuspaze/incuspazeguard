import 'package:flutter/material.dart';

import '../history/date_wise_history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../visitors_list/visitors_list_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _NavTab(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _NavTab(label: 'Visitors', icon: Icons.people_outline, selectedIcon: Icons.people),
    _NavTab(label: 'History', icon: Icons.history, selectedIcon: Icons.history),
    _NavTab(label: 'Profile', icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          VisitorsListScreen(showBackButton: false),
          DateWiseHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
