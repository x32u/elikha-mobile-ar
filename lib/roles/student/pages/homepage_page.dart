import 'package:flutter/material.dart';

import '../components/activity_card.dart';
import '../components/artwork_carousel.dart';
import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../components/profile_section.dart';
import '../data/mock_data.dart';
import '../routes.dart';
import '../services/session_service.dart';

class HomepagePage extends StatefulWidget {
  const HomepagePage({super.key});

  @override
  State<HomepagePage> createState() => _HomepagePageState();
}

class _HomepagePageState extends State<HomepagePage> {
  String userName = 'Juan';
  int grade = 1;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final info = await SessionService.getUserInfo();
    if (info == null || !mounted) return;
    setState(() {
      userName = (info['name'] as String?) ?? 'Juan';
      grade = (info['grade'] as int?) ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activities = MockData.activities().take(3).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ProfileSection(userName: userName, grade: grade),
            const SizedBox(height: 8),
            ArtworkCarousel(artworks: MockData.artworks()),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Pending Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: activities
                    .map(
                      (activity) => ActivityCard(
                        activity: activity,
                        onTap: () => Navigator.pushNamed(context, '/activity/${activity.id}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.homepage),
    );
  }
}
