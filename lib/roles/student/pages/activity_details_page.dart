import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../data/mock_data.dart';
import '../models/activity.dart';
import '../routes.dart';
import '../theme_colors.dart';

class ActivityDetailsPage extends StatefulWidget {
  const ActivityDetailsPage({super.key, required this.activityId});

  final int activityId;

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  double completion = 25;

  @override
  Widget build(BuildContext context) {
    final activity = _findActivity(widget.activityId);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: activity == null
          ? Center(
              child: FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.activities),
                child: const Text('Back to Activities'),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.activities),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  Text('Due on ${DateFormat('MMM d, y').format(activity.dueDate)}'),
                  const SizedBox(height: 16),
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [ThemeColors.primaryLight, ThemeColors.primary],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(activity.category, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 16),
                  Text(activity.fullDescription),
                  const SizedBox(height: 16),
                  const Text('Materials', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...activity.materials.map((m) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(m))),
                  const SizedBox(height: 12),
                  const Text('Project Progress', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: completion / 100),
                  const SizedBox(height: 6),
                  Text('${completion.toInt()}% Complete'),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => setState(() => completion = (completion + 25).clamp(0, 100)),
                    style: FilledButton.styleFrom(backgroundColor: ThemeColors.primary),
                    child: const Text('Start Project'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.activities),
    );
  }

  Activity? _findActivity(int id) {
    try {
      return MockData.activities().firstWhere((activity) => activity.id == id);
    } catch (_) {
      return null;
    }
  }
}
