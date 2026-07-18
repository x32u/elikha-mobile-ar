import 'package:flutter/material.dart';

import 'pages/activities_page.dart';
import 'pages/activity_details_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/homepage_page.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'routes.dart';
import 'theme_colors.dart';

class ElikhaStudentMobileApp extends StatelessWidget {
  const ElikhaStudentMobileApp({
    super.key,
    this.initialRoute = AppRoutes.landing,
    this.onLogout,
  });

  final String initialRoute;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ELIKHA_STUDENTMOBILE',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: ThemeColors.primary),
        scaffoldBackgroundColor: ThemeColors.background,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.landing) {
          return _buildRoute(const LandingPage());
        }
        if (settings.name == AppRoutes.login) {
          return _buildRoute(const LoginPage());
        }
        if (settings.name == AppRoutes.forgotPassword) {
          return _buildRoute(const ForgotPasswordPage());
        }
        if (settings.name == AppRoutes.homepage) {
          return _buildRoute(const HomepagePage());
        }
        if (settings.name == AppRoutes.activities) {
          return _buildRoute(const ActivitiesPage());
        }
        if (settings.name == AppRoutes.profile) {
          return _buildRoute(const ProfilePage());
        }
        if (settings.name == AppRoutes.settings) {
          return _buildRoute(SettingsPage(onLogout: onLogout));
        }
        if (settings.name == AppRoutes.notifications) {
          return _buildRoute(const NotificationsPage());
        }

        if (settings.name != null && settings.name!.startsWith('/activity/')) {
          final idRaw = settings.name!.split('/').last;
          final id = int.tryParse(idRaw) ?? 0;
          return _buildRoute(ActivityDetailsPage(activityId: id));
        }

        return _buildRoute(const LandingPage());
      },
      initialRoute: initialRoute,
    );
  }

  MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
