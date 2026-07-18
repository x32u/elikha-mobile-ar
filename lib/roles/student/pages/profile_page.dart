import 'package:flutter/material.dart';

import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../routes.dart';
import '../theme_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool showFavorites = false;

  final items = const [
    ('Paper art project', '📄', true),
    ('Perfect day to read', '📚', false),
    ('New stitches', '🧵', true),
    ('Monochrome mood', '🎨', false),
    ('Warm palette', '🌅', true),
    ('Glazed clay', '🏺', false),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = showFavorites ? items.where((e) => e.$3).toList() : items;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const CircleAvatar(radius: 38, child: Text('N', style: TextStyle(fontSize: 28))),
            const SizedBox(height: 10),
            const Text('Juan', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const Text('Grade 1'),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Activities')),
                ButtonSegment(value: true, label: Text('Favorites')),
              ],
              selected: {showFavorites},
              onSelectionChanged: (set) => setState(() => showFavorites = set.first),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final item = visible[index];
                  return Card(
                    color: ThemeColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2, style: const TextStyle(fontSize: 26)),
                          const Spacer(),
                          Text(item.$1),
                          if (item.$3)
                            const Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(Icons.star, color: ThemeColors.primary),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.profile),
    );
  }
}
