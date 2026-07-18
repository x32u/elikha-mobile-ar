import 'package:flutter/material.dart';

import '../app.dart';

class Header extends StatelessWidget {
  const Header({super.key, this.onNotificationsPressed});

  final VoidCallback? onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderSoft)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/elikhalogo.png', height: 34),
          const Spacer(),
          IconButton(
            onPressed: onNotificationsPressed,
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
