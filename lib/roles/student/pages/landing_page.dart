import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme_colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ThemeColors.primaryLight, ThemeColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/elikhalogo.png',
                    height: 90,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.palette, size: 80),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'e-Likha',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AR-Powered Arts and Crafts Simulator',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ThemeColors.primary,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
            _feature(
              'Interactive Learning',
              'Engage with hands-on art activities.',
            ),
            _feature('AR Technology', 'Make learning immersive and fun.'),
            _feature('Track Progress', 'Monitor your creative journey.'),
            _feature('Cultural Heritage', 'Explore traditional Filipino arts.'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _feature(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        color: ThemeColors.surface,
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(desc),
        ),
      ),
    );
  }
}
