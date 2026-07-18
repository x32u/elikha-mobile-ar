import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../theme_colors.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onTap});

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueTomorrow = _isDueTomorrow(activity.dueDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dueTomorrow ? ThemeColors.urgentBackground : ThemeColors.surface,
          border: Border.all(color: ThemeColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.description),
                  const SizedBox(height: 6),
                  Text('Due: ${DateFormat('MMM d, y').format(activity.dueDate)}'),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ThemeColors.panelTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_outlined),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDueTomorrow(DateTime dueDate) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due == tomorrow;
  }
}
