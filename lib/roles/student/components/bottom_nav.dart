import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme_colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const _items = [
    (AppRoutes.homepage, Icons.home_outlined, 'Home'),
    (AppRoutes.activities, Icons.assignment_outlined, 'Activities'),
    (AppRoutes.profile, Icons.person_outline, 'Profile'),
    (AppRoutes.settings, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _items.indexWhere((item) => item.$1 == currentRoute);
    final selectedIndex = index < 0 ? 0 : index;

    return NavigationBar(
      backgroundColor: ThemeColors.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: (value) {
        final route = _items[value].$1;
        if (route == currentRoute) return;
        Navigator.pushReplacementNamed(context, route);
      },
      destinations: _items
          .map((item) => NavigationDestination(icon: Icon(item.$2), label: item.$3))
          .toList(),
    );
  }
}
