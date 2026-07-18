import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme_colors.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ThemeColors.background,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/elikhalogolarge.png',
                  height: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.palette),
                ),
                const SizedBox(width: 8),
                const Text(
                  'e-Likha',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(
              Icons.notifications_outlined,
              color: ThemeColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
