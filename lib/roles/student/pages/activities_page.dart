import 'package:flutter/material.dart';

import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../data/mock_data.dart';
import '../models/activity.dart';
import '../routes.dart';

enum ActivityFilter { upcoming, pastDue, completed }

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  ActivityFilter filter = ActivityFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final all = MockData.activities();
    final filtered = _filter(all);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activities', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Upcoming'),
                  selected: filter == ActivityFilter.upcoming,
                  onSelected: (_) => setState(() => filter = ActivityFilter.upcoming),
                ),
                ChoiceChip(
                  label: const Text('Past Due'),
                  selected: filter == ActivityFilter.pastDue,
                  onSelected: (_) => setState(() => filter = ActivityFilter.pastDue),
                ),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: filter == ActivityFilter.completed,
                  onSelected: (_) => setState(() => filter = ActivityFilter.completed),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No activities for this filter'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final activity = filtered[index];
                        return Card(
                          child: ListTile(
                            onTap: () => Navigator.pushNamed(context, '/activity/${activity.id}'),
                            title: Text(activity.title),
                            subtitle: Text(activity.description),
                            trailing: _statusChip(activity),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.activities),
    );
  }

  List<Activity> _filter(List<Activity> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((activity) {
      final due = DateTime(activity.dueDate.year, activity.dueDate.month, activity.dueDate.day);
      switch (filter) {
        case ActivityFilter.upcoming:
          return due.compareTo(today) >= 0 && !activity.completed;
        case ActivityFilter.pastDue:
          return due.compareTo(today) < 0 && !activity.completed;
        case ActivityFilter.completed:
          return activity.completed;
      }
    }).toList();
  }

  Widget _statusChip(Activity activity) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(activity.dueDate.year, activity.dueDate.month, activity.dueDate.day);

    if (activity.completed) {
      return const Chip(label: Text('Completed'));
    }
    if (due.compareTo(today) < 0) {
      return const Chip(label: Text('Overdue'));
    }
    return const Chip(label: Text('Upcoming'));
  }
}
