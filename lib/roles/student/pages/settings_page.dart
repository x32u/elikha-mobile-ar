import 'package:flutter/material.dart';

import '../components/bottom_nav.dart';
import '../components/header_bar.dart';
import '../routes.dart';
import '../theme_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(child: HeaderBar()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _card(
            'Audio',
            [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Background Music'),
                subtitle: const Text('Play music during activities.'),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Sound Effects'),
                subtitle: const Text('Button clicks and notifications.'),
              ),
            ],
          ),
          _card(
            'Notifications',
            [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Push Notifications'),
              ),
              SwitchListTile(
                value: false,
                onChanged: (_) {},
                title: const Text('Data Saver'),
              ),
            ],
          ),
          Card(
            child: ListTile(
              title: const Text('Streaming Quality'),
              trailing: DropdownButton<String>(
                value: 'auto',
                onChanged: (_) {},
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ThemeColors.primary),
            onPressed: () async {
              if (onLogout != null) {
                await onLogout!();
                return;
              }
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.login);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentRoute: AppRoutes.settings),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
