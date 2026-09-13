import 'package:flutter/material.dart';

import '../../main.dart' as canonical;

Future<void> main() => canonical.main();

class ElikhaParentApp extends StatelessWidget {
  const ElikhaParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-likha Parent',
      scrollBehavior: const _NoOverscrollStretchBehavior(),
      theme: ThemeData(
        colorSchemeSeed: AppPalette.primaryBlue,
        scaffoldBackgroundColor: Colors.white,
        splashFactory: InkRipple.splashFactory,
        useMaterial3: true,
      ),
      home: const ParentHome(),
    );
  }
}

class _NoOverscrollStretchBehavior extends MaterialScrollBehavior {
  const _NoOverscrollStretchBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  int _selectedTabIndex = 0;
  String _selectedChildName = sampleChildren.first.name;
  bool _activityUpdatesEnabled = false;

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => NotificationsScreen(
          onBack: () => Navigator.of(routeContext).pop(),
          onNavigateTab: (index) {
            Navigator.of(routeContext).pop();
            _selectTab(index);
          },
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedTabIndex) {
      case 0:
        return DashboardScreen(
          onOpenNotifications: _openNotifications,
          highlightedChildName: _selectedChildName,
        );
      case 1:
        return MyChildScreen(
          selectedChildName: _selectedChildName,
          onSelectChild: (childName) {
            setState(() {
              _selectedChildName = childName;
            });
          },
        );
      case 2:
        return SettingsScreen(
          activityUpdatesEnabled: _activityUpdatesEnabled,
          onActivityUpdatesChanged: (value) {
            setState(() {
              _activityUpdatesEnabled = value;
            });
          },
        );
      default:
        return DashboardScreen(
          onOpenNotifications: _openNotifications,
          highlightedChildName: _selectedChildName,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: ParentBottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _selectTab,
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenNotifications,
    required this.highlightedChildName,
  });

  final VoidCallback onOpenNotifications;
  final String highlightedChildName;

  ChildProfile get _featuredChild {
    final matches = sampleChildren.where(
      (child) => child.name.toLowerCase() == highlightedChildName.toLowerCase(),
    );

    if (matches.isNotEmpty) {
      return matches.first;
    }

    return sampleChildren.first;
  }

  @override
  Widget build(BuildContext context) {
    final featuredChild = _featuredChild;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const ValueKey('dashboard-notifications-button'),
                  onPressed: onOpenNotifications,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppPalette.titleText,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _DashboardHeroCard(child: featuredChild),
            ),
            const _SectionTitle('Summary'),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Activities\nCompleted',
                      value: '120',
                      icon: Icons.task_alt_rounded,
                      accentColor: AppPalette.success,
                      footer: 'This month',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Pending\nActivities',
                      value: '5',
                      icon: Icons.schedule_rounded,
                      accentColor: AppPalette.warmGold,
                      footer: 'Needs review',
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _WideSummaryCard(
                label: 'Past Due Activities',
                value: '2',
                accentColor: AppPalette.warning,
                caption: 'Follow up today',
              ),
            ),
            const _SectionTitle('Recent Activities'),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _ActivityTile(
                    icon: Icons.insert_drive_file_outlined,
                    title: "Completed 'Origami Crane'",
                    childName: 'Liam',
                    badgeLabel: 'Completed',
                  ),
                  SizedBox(height: 12),
                  _ActivityTile(
                    icon: Icons.check,
                    title: "Submitted 'Soap Carving'",
                    childName: 'Olivia',
                    badgeLabel: 'Submitted',
                  ),
                  SizedBox(height: 12),
                  _ActivityTile(
                    icon: Icons.check,
                    title: "Submitted 'Clay Sculpture'",
                    childName: 'Noah',
                    badgeLabel: 'Submitted',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.heroStart, AppPalette.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  child.avatarIcon,
                  color: child.avatarAccent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Featured Child',
                        style: TextStyle(
                          color: AppPalette.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      child.name,
                      style: const TextStyle(
                        color: AppPalette.titleText,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      child.ageLabel,
                      style: const TextStyle(
                        color: AppPalette.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child.gradeSectionLabel,
                      style: const TextStyle(
                        color: AppPalette.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'A quick look at your child\'s current projects and recent progress.',
            style: TextStyle(
              color: AppPalette.titleText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Upcoming',
                  value: '${child.upcomingProjects.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Past Due',
                  value: '${child.pastDueProjects.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Completed',
                  value: '${child.completedProjects.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.onBack,
    required this.onNavigateTab,
  });

  final VoidCallback onBack;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ScreenHeader(
              title: 'Notifications',
              leading: IconButton(
                key: const ValueKey('notifications-back-button'),
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppPalette.notificationsTitle,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sampleNotifications.length,
                itemBuilder: (context, index) {
                  final notification = sampleNotifications[index];

                  return _NotificationListTile(notification: notification);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ParentBottomNavigationBar(
        currentIndex: null,
        onTap: onNavigateTab,
      ),
    );
  }
}

class MyChildScreen extends StatefulWidget {
  const MyChildScreen({
    super.key,
    required this.selectedChildName,
    required this.onSelectChild,
  });

  final String selectedChildName;
  final ValueChanged<String> onSelectChild;

  @override
  State<MyChildScreen> createState() => _MyChildScreenState();
}

class _MyChildScreenState extends State<MyChildScreen> {
  ProjectStatusFilter _selectedFilter = ProjectStatusFilter.upcoming;
  String? _latestSearchedChildName;

  ChildProfile get _selectedChild {
    final matches = sampleChildren.where(
      (child) =>
          child.name.toLowerCase() == widget.selectedChildName.toLowerCase(),
    );

    if (matches.isNotEmpty) {
      return matches.first;
    }

    return sampleChildren.first;
  }

  List<ProjectItem> get _filteredProjects {
    final child = _selectedChild;

    switch (_selectedFilter) {
      case ProjectStatusFilter.upcoming:
        return child.upcomingProjects;
      case ProjectStatusFilter.pastDue:
        return child.pastDueProjects;
      case ProjectStatusFilter.completed:
        return child.completedProjects;
    }
  }

  List<ChildProfile> get _switcherChildren {
    final promotedChildName =
        _latestSearchedChildName ?? widget.selectedChildName;
    final children = List<ChildProfile>.of(sampleChildren);
    final promotedIndex = children.indexWhere(
      (child) => child.name.toLowerCase() == promotedChildName.toLowerCase(),
    );

    if (promotedIndex <= 0) {
      return children;
    }

    final promotedChild = children.removeAt(promotedIndex);
    return [promotedChild, ...children];
  }

  void _handleSearch(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    final matches = sampleChildren.where(
      (child) => child.name.toLowerCase().contains(query),
    );

    if (matches.isEmpty) {
      return;
    }

    final matchedChild = matches.first;

    setState(() {
      _latestSearchedChildName = matchedChild.name;
      _selectedFilter = ProjectStatusFilter.upcoming;
    });

    widget.onSelectChild(matchedChild.name);
  }

  void _selectChild(String childName) {
    if (childName == widget.selectedChildName) {
      return;
    }

    setState(() {
      _selectedFilter = ProjectStatusFilter.upcoming;
    });

    widget.onSelectChild(childName);
  }

  @override
  Widget build(BuildContext context) {
    final child = _selectedChild;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ChildSearchField(
                initialHint: 'search for child name',
                onChanged: _handleSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ChildSwitcher(
                children: _switcherChildren,
                selectedChildName: child.name,
                onSelectChild: _selectChild,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Center(
                child: _ChildProfileCard(
                  name: child.name,
                  ageLabel: child.ageLabel,
                  gradeSectionLabel: child.gradeSectionLabel,
                  avatarColor: child.avatarColor,
                  avatarAccent: child.avatarAccent,
                  avatarIcon: child.avatarIcon,
                ),
              ),
            ),
            const _SectionTitle('Projects'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ProjectFilterBar(
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: _filteredProjects
                    .map((project) => _ProjectListTile(project: project))
                    .toList(),
              ),
            ),
            const _SectionTitle('Projects'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: child.galleryProjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return _ProjectGalleryTile(
                    project: child.galleryProjects[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.activityUpdatesEnabled,
    required this.onActivityUpdatesChanged,
  });

  final bool activityUpdatesEnabled;
  final ValueChanged<bool> onActivityUpdatesChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsSectionTitle('Account'),
            _SettingsActionRow(
              label: 'Change Password',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            _SettingsActionRow(
              label: 'Update Email',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UpdateEmailScreen(),
                  ),
                );
              },
            ),
            const _SettingsSectionTitle('Notifications'),
            _SettingsToggleRow(
              title: 'Activity Updates',
              description:
                  "Receive updates on your child's activity and progress.",
              value: activityUpdatesEnabled,
              onChanged: onActivityUpdatesChanged,
            ),
            const _SettingsSectionTitle('Help & Support'),
            _SettingsActionRow(
              label: 'FAQ',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
                );
              },
            ),
            _SettingsActionRow(
              label: 'Contact Support',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactSupportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppPalette.titleText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.27,
        ),
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppPalette.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.titleText,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _savePassword() {
    final messenger = ScaffoldMessenger.of(context);

    if (_currentPassword.isEmpty ||
        _newPassword.isEmpty ||
        _confirmPassword.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fill in all password fields.')),
      );
      return;
    }

    if (_newPassword != _confirmPassword) {
      messenger.showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Password updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSubpageScaffold(
      title: 'Change Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsHeroCard(
            icon: Icons.lock_outline_rounded,
            title: 'Keep your account secure',
            description:
                'Update your password regularly and use a strong combination of letters, numbers, and symbols.',
          ),
          const SizedBox(height: 24),
          _SettingsInputField(
            label: 'Current Password',
            hintText: 'Enter current password',
            obscureText: _obscureCurrent,
            onChanged: (value) => _currentPassword = value,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
              icon: Icon(
                _obscureCurrent
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppPalette.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsInputField(
            label: 'New Password',
            hintText: 'Create new password',
            obscureText: _obscureNew,
            onChanged: (value) => _newPassword = value,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppPalette.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsInputField(
            label: 'Confirm Password',
            hintText: 'Re-enter new password',
            obscureText: _obscureConfirm,
            onChanged: (value) => _confirmPassword = value,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppPalette.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsTipCard(
            title: 'Password tips',
            tips: [
              'Use at least 8 characters.',
              'Include uppercase, lowercase, and numbers.',
              'Avoid reusing old passwords.',
            ],
          ),
          const SizedBox(height: 24),
          _PrimaryActionButton(
            label: 'Save Password',
            onPressed: _savePassword,
          ),
        ],
      ),
    );
  }
}

class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  String _newEmail = '';
  String _confirmEmail = '';

  void _sendVerificationLink() {
    final messenger = ScaffoldMessenger.of(context);

    if (_newEmail.isEmpty || _confirmEmail.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fill in both email fields.')),
      );
      return;
    }

    if (_newEmail != _confirmEmail) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email addresses do not match.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Verification link sent to $_newEmail.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSubpageScaffold(
      title: 'Update Email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsHeroCard(
            icon: Icons.email_outlined,
            title: 'Update your email address',
            description:
                'Use an active email account so you can receive important updates and password recovery links.',
          ),
          const SizedBox(height: 20),
          const _InfoTile(
            label: 'Current Email',
            value: 'parent.elikha@example.com',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
          _SettingsInputField(
            label: 'New Email Address',
            hintText: 'Enter new email address',
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _newEmail = value,
          ),
          const SizedBox(height: 16),
          _SettingsInputField(
            label: 'Confirm New Email',
            hintText: 'Re-enter new email address',
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _confirmEmail = value,
          ),
          const SizedBox(height: 20),
          const _SettingsTipCard(
            title: 'What happens next?',
            tips: [
              'We will send a verification link to your new email.',
              'Your current email stays active until verification is complete.',
              'Check your spam folder if the email does not arrive quickly.',
            ],
          ),
          const SizedBox(height: 24),
          _PrimaryActionButton(
            label: 'Send Verification Link',
            onPressed: _sendVerificationLink,
          ),
        ],
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsSubpageScaffold(
      title: 'FAQ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: AppPalette.titleText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quick answers to the most common parent concerns in E-likha.',
            style: TextStyle(
              color: AppPalette.secondaryText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...sampleFaqs.map((faq) => _FaqCard(item: faq)),
        ],
      ),
    );
  }
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  String _selectedTopic = supportTopics.first;
  String _message = '';

  void _sendSupportMessage() {
    final messenger = ScaffoldMessenger.of(context);

    if (_message.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a message before sending.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Support message sent for $_selectedTopic.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSubpageScaffold(
      title: 'Contact Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsHeroCard(
            icon: Icons.headset_mic_outlined,
            title: 'How can we help?',
            description:
                'Choose a topic, describe the issue, and our support team will get back to you.',
          ),
          const SizedBox(height: 20),
          const _SupportChannelCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email Support',
            subtitle: 'support@elikha.app',
          ),
          const SizedBox(height: 12),
          const _SupportChannelCard(
            icon: Icons.call_outlined,
            title: 'Hotline',
            subtitle: '+63 900 123 4567',
          ),
          const SizedBox(height: 20),
          const Text(
            'Issue Topic',
            style: TextStyle(
              color: AppPalette.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: supportTopics.map((topic) {
              final isSelected = topic == _selectedTopic;

              return ChoiceChip(
                label: Text(topic),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedTopic = topic;
                  });
                },
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppPalette.primaryBlue
                      : AppPalette.titleText,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                selectedColor: AppPalette.primaryBlue.withValues(alpha: 0.12),
                side: BorderSide(
                  color: isSelected
                      ? AppPalette.primaryBlue
                      : AppPalette.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _SettingsInputField(
            label: 'Message',
            hintText: 'Tell us what happened and what help you need.',
            maxLines: 6,
            onChanged: (value) => _message = value,
          ),
          const SizedBox(height: 24),
          _PrimaryActionButton(
            label: 'Send Message',
            onPressed: _sendSupportMessage,
          ),
        ],
      ),
    );
  }
}

class _SettingsSubpageScaffold extends StatelessWidget {
  const _SettingsSubpageScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: AppPalette.titleText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.searchBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppPalette.titleText),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppPalette.secondaryText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsInputField extends StatelessWidget {
  const _SettingsInputField({
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.titleText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          obscureText: obscureText,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          minLines: 1,
          style: const TextStyle(color: AppPalette.titleText, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppPalette.secondaryText,
              fontSize: 15,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SettingsTipCard extends StatelessWidget {
  const _SettingsTipCard({required this.title, required this.tips});

  final String title;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppPalette.secondaryText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppPalette.titleText),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppPalette.titleText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.item});

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            item.question,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: const TextStyle(
                color: AppPalette.secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChannelCard extends StatelessWidget {
  const _SupportChannelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppPalette.titleText),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppPalette.titleText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppPalette.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppPalette.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ActivityUpdatesToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActivityUpdatesToggle extends StatelessWidget {
  const _ActivityUpdatesToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Activity Updates',
      button: true,
      toggled: value,
      child: GestureDetector(
        key: const ValueKey('activity-updates-toggle'),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 51,
          height: 31,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value
                ? AppPalette.primaryBlue.withValues(alpha: 0.18)
                : AppPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(15.5),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: value ? AppPalette.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(13.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppPalette.titleText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (leading != null)
              Align(alignment: Alignment.centerLeft, child: leading!),
          ],
        ),
      ),
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppPalette.searchBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              notification.icon,
              color: AppPalette.notificationsTitle,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppPalette.notificationsTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.timeLabel,
                  style: const TextStyle(
                    color: AppPalette.searchText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppPalette.titleText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.footer,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppPalette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: const TextStyle(
              color: AppPalette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideSummaryCard extends StatelessWidget {
  const _WideSummaryCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.caption,
  });

  final String label;
  final String value;
  final Color accentColor;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.warning_amber_rounded, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppPalette.titleText,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    color: AppPalette.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.titleText,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.childName,
    required this.badgeLabel,
  });

  final IconData icon;
  final String title;
  final String childName;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppPalette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppPalette.titleText, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  childName,
                  style: const TextStyle(
                    color: AppPalette.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.searchBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: AppPalette.searchText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.secondaryText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildSearchField extends StatelessWidget {
  const _ChildSearchField({required this.initialHint, required this.onChanged});

  final String initialHint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppPalette.searchBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            color: AppPalette.searchText,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: AppPalette.titleText, fontSize: 16),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: initialHint,
                hintStyle: const TextStyle(
                  color: AppPalette.searchText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ChildSwitcher extends StatelessWidget {
  const _ChildSwitcher({
    required this.children,
    required this.selectedChildName,
    required this.onSelectChild,
  });

  final List<ChildProfile> children;
  final String selectedChildName;
  final ValueChanged<String> onSelectChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Switch child',
          style: TextStyle(
            color: AppPalette.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChildSwitchChip(
                    child: child,
                    isSelected: child.name == selectedChildName,
                    onTap: () => onSelectChild(child.name),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildSwitchChip extends StatelessWidget {
  const _ChildSwitchChip({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final ChildProfile child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? Colors.white : AppPalette.titleText;
    final supportingColor = isSelected
        ? Colors.white.withValues(alpha: 0.78)
        : AppPalette.secondaryText;

    return InkWell(
      key: ValueKey('child-selector-${child.name.toLowerCase()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.primaryBlue
              : AppPalette.searchBackground,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: AppPalette.border),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1F1800AD),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: Icon(
                child.avatarIcon,
                color: isSelected ? Colors.white : child.avatarAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  child.gradeSectionLabel,
                  style: TextStyle(
                    color: supportingColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({
    required this.name,
    required this.ageLabel,
    required this.gradeSectionLabel,
    required this.avatarColor,
    required this.avatarAccent,
    required this.avatarIcon,
  });

  final String name;
  final String ageLabel;
  final String gradeSectionLabel;
  final Color avatarColor;
  final Color avatarAccent;
  final IconData avatarIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: 74,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: avatarAccent.withValues(alpha: 0.2)),
              ),
              child: Icon(avatarIcon, size: 42, color: avatarAccent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            color: AppPalette.titleText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ageLabel,
          style: const TextStyle(
            color: AppPalette.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          gradeSectionLabel,
          style: const TextStyle(
            color: AppPalette.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProjectFilterBar extends StatelessWidget {
  const _ProjectFilterBar({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final ProjectStatusFilter selectedFilter;
  final ValueChanged<ProjectStatusFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProjectFilterChip(
              label: 'Upcoming',
              isSelected: selectedFilter == ProjectStatusFilter.upcoming,
              onTap: () => onFilterSelected(ProjectStatusFilter.upcoming),
            ),
          ),
          Expanded(
            child: _ProjectFilterChip(
              label: 'Past Due',
              isSelected: selectedFilter == ProjectStatusFilter.pastDue,
              onTap: () => onFilterSelected(ProjectStatusFilter.pastDue),
            ),
          ),
          Expanded(
            child: _ProjectFilterChip(
              label: 'Completed',
              isSelected: selectedFilter == ProjectStatusFilter.completed,
              onTap: () => onFilterSelected(ProjectStatusFilter.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectFilterChip extends StatelessWidget {
  const _ProjectFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppPalette.titleText
                  : AppPalette.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [project.startColor, project.endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(project.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    color: AppPalette.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  project.subtitle,
                  style: const TextStyle(
                    color: AppPalette.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectGalleryTile extends StatelessWidget {
  const _ProjectGalleryTile({required this.project});

  final ProjectGalleryItem project;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [project.startColor, project.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              project.icon,
              size: 54,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              project.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParentBottomNavigationBar extends StatelessWidget {
  const ParentBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int? currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF5F2F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_filled,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.people_alt_rounded,
                label: 'My Child',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppPalette.titleText : AppPalette.secondaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(27),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppPalette {
  static const Color primaryBlue = Color(0xFF1800AD);
  static const Color titleText = Color(0xFF171412);
  static const Color notificationsTitle = Color(0xFF1C170D);
  static const Color secondaryText = Color(0xFF8A7861);
  static const Color heroStart = Color(0xFFF7EFE8);
  static const Color heroEnd = Color(0xFFECE7FB);
  static const Color border = Color(0xFFE6E0DB);
  static const Color surfaceSoft = Color(0xFFF5F2F0);
  static const Color searchBackground = Color(0xFFF5EDE8);
  static const Color searchText = Color(0xFF9C7A4A);
  static const Color success = Color(0xFF2F8F5B);
  static const Color warmGold = Color(0xFFB8802F);
  static const Color warning = Color(0xFFC26442);
}

enum ProjectStatusFilter { upcoming, pastDue, completed }

class ChildProfile {
  const ChildProfile({
    required this.name,
    required this.ageLabel,
    required this.gradeSectionLabel,
    required this.avatarColor,
    required this.avatarAccent,
    required this.avatarIcon,
    required this.upcomingProjects,
    required this.pastDueProjects,
    required this.completedProjects,
    required this.galleryProjects,
  });

  final String name;
  final String ageLabel;
  final String gradeSectionLabel;
  final Color avatarColor;
  final Color avatarAccent;
  final IconData avatarIcon;
  final List<ProjectItem> upcomingProjects;
  final List<ProjectItem> pastDueProjects;
  final List<ProjectItem> completedProjects;
  final List<ProjectGalleryItem> galleryProjects;
}

class ProjectItem {
  const ProjectItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}

class ProjectGalleryItem {
  const ProjectGalleryItem({
    required this.label,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String label;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String timeLabel;
  final IconData icon;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

const List<NotificationItem> sampleNotifications = [
  NotificationItem(
    title: 'New Activity Assigned',
    timeLabel: '10:30 AM',
    icon: Icons.notifications_none_rounded,
  ),
  NotificationItem(
    title: 'Your project was graded',
    timeLabel: 'Yesterday',
    icon: Icons.favorite_border_rounded,
  ),
];

const List<FaqItem> sampleFaqs = [
  FaqItem(
    question: 'How do I track my child\'s activity?',
    answer:
        'Open the Dashboard or My Child tab to view assigned, completed, and upcoming projects along with recent activity updates.',
  ),
  FaqItem(
    question: 'Can I receive notifications for new assignments?',
    answer:
        'Yes. Turn on Activity Updates in Settings so you get notified when new work is assigned or graded.',
  ),
  FaqItem(
    question: 'What should I do if my child forgot their project details?',
    answer:
        'Check the My Child screen for project titles, due dates, and progress. If something is missing, contact support from Settings.',
  ),
  FaqItem(
    question: 'How do I change my account information?',
    answer:
        'Go to Settings and choose Change Password or Update Email. Each option opens its own account-management screen.',
  ),
];

const List<String> supportTopics = [
  'Account',
  'Projects',
  'Notifications',
  'Technical Issue',
];

const List<ChildProfile> sampleChildren = [
  ChildProfile(
    name: 'Juan',
    ageLabel: 'Age 6',
    gradeSectionLabel: 'Grade 1 - Sampaguita',
    avatarColor: Color(0xFFF4E9DF),
    avatarAccent: Color(0xFFC7A06B),
    avatarIcon: Icons.accessibility_new_rounded,
    upcomingProjects: [
      ProjectItem(
        title: 'Origami Dog',
        subtitle: 'Due in 2 days',
        icon: Icons.pets_rounded,
        startColor: Color(0xFFE2A73A),
        endColor: Color(0xFFF5D17E),
      ),
      ProjectItem(
        title: 'Clay Sculptures',
        subtitle: 'Due in 5 days',
        icon: Icons.emoji_objects_outlined,
        startColor: Color(0xFFB57C4F),
        endColor: Color(0xFFD2AA7D),
      ),
      ProjectItem(
        title: 'Paper Mache Masks',
        subtitle: 'Due in 7 days',
        icon: Icons.masks_outlined,
        startColor: Color(0xFF2A2A2A),
        endColor: Color(0xFF6B6B6B),
      ),
    ],
    pastDueProjects: [
      ProjectItem(
        title: 'Soap Carving',
        subtitle: 'Past due by 1 day',
        icon: Icons.spa_outlined,
        startColor: Color(0xFFD0896A),
        endColor: Color(0xFFEAB39A),
      ),
      ProjectItem(
        title: 'String Art',
        subtitle: 'Past due by 3 days',
        icon: Icons.interests_outlined,
        startColor: Color(0xFF7A5C46),
        endColor: Color(0xFFA37E62),
      ),
    ],
    completedProjects: [
      ProjectItem(
        title: 'Leaf Printing',
        subtitle: 'Completed yesterday',
        icon: Icons.eco_outlined,
        startColor: Color(0xFF5B925E),
        endColor: Color(0xFF8BB98D),
      ),
      ProjectItem(
        title: 'Paper Lantern',
        subtitle: 'Completed last week',
        icon: Icons.light_outlined,
        startColor: Color(0xFF7A6AE6),
        endColor: Color(0xFFAA9CF4),
      ),
    ],
    galleryProjects: [
      ProjectGalleryItem(
        label: 'Origami Dog',
        icon: Icons.pets_rounded,
        startColor: Color(0xFFE2A73A),
        endColor: Color(0xFFF4CC72),
      ),
      ProjectGalleryItem(
        label: 'Clay Art',
        icon: Icons.emoji_objects_outlined,
        startColor: Color(0xFFA96C48),
        endColor: Color(0xFFD3AC83),
      ),
      ProjectGalleryItem(
        label: 'Mask Making',
        icon: Icons.masks_outlined,
        startColor: Color(0xFF2F2F2F),
        endColor: Color(0xFF6D6D6D),
      ),
      ProjectGalleryItem(
        label: 'Painted Pot',
        icon: Icons.brush_outlined,
        startColor: Color(0xFF4B687A),
        endColor: Color(0xFF89A6B7),
      ),
    ],
  ),
  ChildProfile(
    name: 'Olivia',
    ageLabel: 'Age 7',
    gradeSectionLabel: 'Grade 2 - Rosal',
    avatarColor: Color(0xFFF6E9F1),
    avatarAccent: Color(0xFFC278A6),
    avatarIcon: Icons.face_3_outlined,
    upcomingProjects: [
      ProjectItem(
        title: 'Bead Bracelet',
        subtitle: 'Due in 1 day',
        icon: Icons.auto_awesome_outlined,
        startColor: Color(0xFFB06AC2),
        endColor: Color(0xFFE3A4F0),
      ),
      ProjectItem(
        title: 'Soap Carving',
        subtitle: 'Due in 4 days',
        icon: Icons.spa_outlined,
        startColor: Color(0xFFC77F66),
        endColor: Color(0xFFF0B8A8),
      ),
    ],
    pastDueProjects: [
      ProjectItem(
        title: 'Puppet Theater',
        subtitle: 'Past due by 2 days',
        icon: Icons.theater_comedy_outlined,
        startColor: Color(0xFF85553D),
        endColor: Color(0xFFC58D68),
      ),
    ],
    completedProjects: [
      ProjectItem(
        title: 'Flower Collage',
        subtitle: 'Completed 2 days ago',
        icon: Icons.local_florist_outlined,
        startColor: Color(0xFF5E936B),
        endColor: Color(0xFF9AC3A2),
      ),
    ],
    galleryProjects: [
      ProjectGalleryItem(
        label: 'Bead Bracelet',
        icon: Icons.auto_awesome_outlined,
        startColor: Color(0xFFB06AC2),
        endColor: Color(0xFFE3A4F0),
      ),
      ProjectGalleryItem(
        label: 'Soap Carving',
        icon: Icons.spa_outlined,
        startColor: Color(0xFFC77F66),
        endColor: Color(0xFFF0B8A8),
      ),
      ProjectGalleryItem(
        label: 'Collage',
        icon: Icons.collections_outlined,
        startColor: Color(0xFF69838E),
        endColor: Color(0xFFA7C0CB),
      ),
      ProjectGalleryItem(
        label: 'Paper Flowers',
        icon: Icons.local_florist_outlined,
        startColor: Color(0xFF5E936B),
        endColor: Color(0xFF9AC3A2),
      ),
    ],
  ),
  ChildProfile(
    name: 'Noah',
    ageLabel: 'Age 5',
    gradeSectionLabel: 'Kinder - Narra',
    avatarColor: Color(0xFFE9EFF8),
    avatarAccent: Color(0xFF6E8EC5),
    avatarIcon: Icons.sentiment_satisfied_alt_outlined,
    upcomingProjects: [
      ProjectItem(
        title: 'Clay Sculpture',
        subtitle: 'Due in 3 days',
        icon: Icons.emoji_objects_outlined,
        startColor: Color(0xFF7B8FB2),
        endColor: Color(0xFFACC0DE),
      ),
      ProjectItem(
        title: 'Paper Rocket',
        subtitle: 'Due in 6 days',
        icon: Icons.rocket_launch_outlined,
        startColor: Color(0xFF4A74B3),
        endColor: Color(0xFF86A7DE),
      ),
    ],
    pastDueProjects: [
      ProjectItem(
        title: 'Animal Mask',
        subtitle: 'Past due by 1 day',
        icon: Icons.masks_outlined,
        startColor: Color(0xFF4E4E4E),
        endColor: Color(0xFF868686),
      ),
    ],
    completedProjects: [
      ProjectItem(
        title: 'Origami Plane',
        subtitle: 'Completed today',
        icon: Icons.flight_outlined,
        startColor: Color(0xFF5E88C5),
        endColor: Color(0xFF8FB6EE),
      ),
    ],
    galleryProjects: [
      ProjectGalleryItem(
        label: 'Clay Sculpture',
        icon: Icons.emoji_objects_outlined,
        startColor: Color(0xFF7B8FB2),
        endColor: Color(0xFFACC0DE),
      ),
      ProjectGalleryItem(
        label: 'Paper Rocket',
        icon: Icons.rocket_launch_outlined,
        startColor: Color(0xFF4A74B3),
        endColor: Color(0xFF86A7DE),
      ),
      ProjectGalleryItem(
        label: 'Animal Mask',
        icon: Icons.masks_outlined,
        startColor: Color(0xFF4E4E4E),
        endColor: Color(0xFF868686),
      ),
      ProjectGalleryItem(
        label: 'Origami Plane',
        icon: Icons.flight_outlined,
        startColor: Color(0xFF5E88C5),
        endColor: Color(0xFF8FB6EE),
      ),
    ],
  ),
];
