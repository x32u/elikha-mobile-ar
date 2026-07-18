import 'package:flutter/material.dart';

import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../data/mock_data.dart';
import '../models/notification_item.dart';
import '../routes.dart';
import '../theme_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<NotificationItem> items;

  @override
  void initState() {
    super.initState();
    items = MockData.notifications();
  }

  void _markAllRead() {
    setState(() {
      items = items.map((item) => item.copyWith(unread: false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    color: item.unread ? ThemeColors.notificationUnread : ThemeColors.surface,
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text(item.time),
                      trailing: item.unread
                          ? const Icon(Icons.brightness_1, size: 10, color: ThemeColors.primary)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.notifications),
    );
  }
}
