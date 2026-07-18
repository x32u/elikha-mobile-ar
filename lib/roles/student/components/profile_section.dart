import 'package:flutter/material.dart';

import '../theme_colors.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.userName,
    required this.grade,
  });

  final String userName;
  final int grade;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ThemeColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: ThemeColors.primaryLight,
              child: Text(
                userName.isEmpty ? 'U' : userName[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'hi, $userName!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text('Grade $grade'),
              ],
            )
          ],
        ),
      ),
    );
  }
}
