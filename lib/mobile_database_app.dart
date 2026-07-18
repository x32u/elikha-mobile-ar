import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ar_launcher.dart';

const _primary = Color(0xFF1800AD);
const _ink = Color(0xFF141217);
const _muted = Color(0xFF6B5A4D);
const _surface = Color(0xFFFFFCFA);
const _border = Color(0xFFE7DED8);
const _hostedWebOrigin = 'https://elikhaweb.vercel.app';

final _dateFormatter = DateFormat('MMM d, yyyy');
final _dateTimeFormatter = DateFormat('MMM d, yyyy h:mm a');

class StudentDatabaseShell extends StatefulWidget {
  const StudentDatabaseShell({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.gradeLabel,
    required this.onSignedOut,
  });

  final String userId;
  final String name;
  final String email;
  final String gradeLabel;
  final Future<void> Function() onSignedOut;

  @override
  State<StudentDatabaseShell> createState() => _StudentDatabaseShellState();
}

class _StudentDatabaseShellState extends State<StudentDatabaseShell> {
  int _index = 0;
  late Future<StudentBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadStudentBundle(widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.loadStudentBundle(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentBundle>(
      future: _future,
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        final tabs = [
          _StudentHomeTab(
            name: widget.name,
            gradeLabel: widget.gradeLabel,
            bundle: bundle,
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onOpenActivities: () => setState(() => _index = 1),
            onOpenProfile: () => setState(() => _index = 2),
            onRefresh: _refresh,
          ),
          _StudentActivitiesTab(
            bundle: bundle,
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _StudentProfileTab(
            name: widget.name,
            email: widget.email,
            gradeLabel: widget.gradeLabel,
            bundle: bundle,
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onRefresh: _refresh,
            onSignedOut: widget.onSignedOut,
          ),
        ];

        return _RoleShell(
          title: 'e-Likha Student',
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Activities',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
          child: tabs[_index],
        );
      },
    );
  }
}

class TeacherDatabaseShell extends StatefulWidget {
  const TeacherDatabaseShell({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.onSignedOut,
  });

  final String userId;
  final String name;
  final String email;
  final Future<void> Function() onSignedOut;

  @override
  State<TeacherDatabaseShell> createState() => _TeacherDatabaseShellState();
}

class _TeacherDatabaseShellState extends State<TeacherDatabaseShell> {
  int _index = 0;
  late Future<TeacherBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadTeacherBundle(widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.loadTeacherBundle(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeacherBundle>(
      future: _future,
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        final tabs = [
          _TeacherHomeTab(
            name: widget.name,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onSelectTab: (index) => setState(() => _index = index),
            onRefresh: _refresh,
          ),
          _TeacherClassesTab(
            teacherId: widget.userId,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _TeacherActivitiesTab(
            teacherId: widget.userId,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _TeacherReviewsTab(
            teacherId: widget.userId,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _TeacherAlertsTab(
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
        ];

        return _RoleShell(
          title: 'e-Likha Teacher',
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Activities',
            ),
            NavigationDestination(
              icon: Icon(Icons.rate_review_outlined),
              selectedIcon: Icon(Icons.rate_review_rounded),
              label: 'Reviews',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
          ],
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
            IconButton(
              onPressed: widget.onSignedOut,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            ),
          ],
          child: tabs[_index],
        );
      },
    );
  }
}

class ParentDatabaseShell extends StatefulWidget {
  const ParentDatabaseShell({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.onSignedOut,
  });

  final String userId;
  final String name;
  final String email;
  final Future<void> Function() onSignedOut;

  @override
  State<ParentDatabaseShell> createState() => _ParentDatabaseShellState();
}

class _ParentDatabaseShellState extends State<ParentDatabaseShell> {
  int _index = 0;
  late Future<ParentBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadParentBundle(widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.loadParentBundle(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParentBundle>(
      future: _future,
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        final tabs = [
          _ParentHomeTab(
            name: widget.name,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onOpenChildren: () => setState(() => _index = 1),
            onRefresh: _refresh,
          ),
          _ParentChildrenTab(
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _ParentSettingsTab(
            name: widget.name,
            email: widget.email,
            onSignedOut: widget.onSignedOut,
          ),
        ];

        return _RoleShell(
          title: 'e-Likha Parent',
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom_rounded),
              label: 'Children',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
          child: tabs[_index],
        );
      },
    );
  }
}

class _RoleShell extends StatelessWidget {
  const _RoleShell({
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        actions: actions,
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

class _StudentHomeTab extends StatelessWidget {
  const _StudentHomeTab({
    required this.name,
    required this.gradeLabel,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onOpenActivities,
    required this.onOpenProfile,
    required this.onRefresh,
  });

  final String name;
  final String gradeLabel;
  final StudentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenProfile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroPanel(
            title: 'Hi, $name',
            subtitle: gradeLabel,
            trailing: CircleAvatar(
              radius: 36,
              backgroundColor: _primary,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Your Progress',
            actionLabel: 'Activities',
            onAction: onOpenActivities,
          ),
          _MetricGrid(
            metrics: [
              _MetricData('Pending', bundle?.pendingActivities.length ?? 0),
              _MetricData('Submitted', bundle?.submittedActivities.length ?? 0),
              _MetricData('Reviewed', bundle?.reviewedActivities.length ?? 0),
              _MetricData('Artwork', bundle?.artworks.length ?? 0),
            ],
          ),
          const SizedBox(height: 18),
          _NotificationSection(
            userId: bundle?.studentId,
            notifications: bundle?.notifications ?? const <DbNotification>[],
            limit: 3,
            onChanged: onRefresh,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Recent Artworks',
            actionLabel: 'Profile',
            onAction: onOpenProfile,
          ),
          if ((bundle?.artworks ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.image_outlined,
              title: 'No artworks yet',
              body: 'Submitted projects will appear here after they are saved.',
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(bundle!.artworks.length, 6),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final artwork = bundle!.artworks[index];
                  return SizedBox(
                    width: 190,
                    child: _ArtworkCard(artwork: artwork),
                  );
                },
              ),
            ),
          const SizedBox(height: 18),
          _SectionHeader(title: 'Due Soon'),
          if ((bundle?.pendingActivities ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.task_alt_rounded,
              title: 'No pending work',
              body: 'Assigned activities from your class will show here.',
            )
          else
            ...bundle!.pendingActivities
                .take(3)
                .map(
                  (activity) => _ActivityListTile(
                    activity: activity,
                    onTap: () => _openStudentActivity(
                      context,
                      activity,
                      studentId: bundle!.studentId,
                      onChanged: onRefresh,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StudentActivitiesTab extends StatefulWidget {
  const _StudentActivitiesTab({
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final StudentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  State<_StudentActivitiesTab> createState() => _StudentActivitiesTabState();
}

class _StudentActivitiesTabState extends State<_StudentActivitiesTab> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final groups = [
      widget.bundle?.pendingActivities ?? [],
      widget.bundle?.submittedActivities ?? [],
      widget.bundle?.reviewedActivities ?? [],
    ];
    final selected = groups[_segment];

    return _DataSurface(
      loading: widget.loading,
      error: widget.error,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Activities'),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Pending')),
              ButtonSegment(value: 1, label: Text('Submitted')),
              ButtonSegment(value: 2, label: Text('Reviewed')),
            ],
            selected: {_segment},
            onSelectionChanged: (value) =>
                setState(() => _segment = value.first),
          ),
          const SizedBox(height: 16),
          if (selected.isEmpty)
            const _EmptyCard(
              icon: Icons.assignment_outlined,
              title: 'Nothing here',
              body: 'This list updates from your database assignments.',
            )
          else
            ...selected.map(
              (activity) => _ActivityListTile(
                activity: activity,
                onTap: () => _openStudentActivity(
                  context,
                  activity,
                  studentId: widget.bundle!.studentId,
                  onChanged: widget.onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentProfileTab extends StatelessWidget {
  const _StudentProfileTab({
    required this.name,
    required this.email,
    required this.gradeLabel,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onSignedOut,
  });

  final String name;
  final String email;
  final String gradeLabel;
  final StudentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;
  final Future<void> Function() onSignedOut;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroPanel(
            title: name,
            subtitle: '$email\n$gradeLabel',
            trailing: CircleAvatar(
              radius: 38,
              backgroundColor: _primary,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricData('Completed', bundle?.completedCount ?? 0),
              _MetricData('Average Score', bundle?.averageScoreLabel ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Scores and Feedback'),
          if ((bundle?.reviewedActivities ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.grade_outlined,
              title: 'No reviewed work yet',
              body: 'Teacher scores and feedback will show after review.',
            )
          else
            ...bundle!.reviewedActivities.map(
              (activity) => _ScoreCard(activity: activity),
            ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Artwork Gallery'),
          if ((bundle?.artworks ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.image_outlined,
              title: 'No saved artwork',
              body:
                  'The gallery uses rows from the artworks and submissions tables.',
            )
          else
            _ArtworkGrid(artworks: bundle!.artworks),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onSignedOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab({
    required this.name,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onSelectTab,
    required this.onRefresh,
  });

  final String name;
  final TeacherBundle? bundle;
  final bool loading;
  final Object? error;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroPanel(
            title: 'Teacher Dashboard',
            subtitle: 'Welcome, $name',
            trailing: const Icon(
              Icons.palette_rounded,
              color: _primary,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricData(
                'Students',
                bundle?.totalStudents ?? 0,
                onTap: () => onSelectTab(1),
              ),
              _MetricData(
                'Classes',
                bundle?.classes.length ?? 0,
                onTap: () => onSelectTab(1),
              ),
              _MetricData(
                'Activities',
                bundle?.activities.length ?? 0,
                onTap: () => onSelectTab(2),
              ),
              _MetricData(
                'Reviews',
                bundle?.pendingReviews.length ?? 0,
                onTap: () => onSelectTab(3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _NotificationSection(
            userId: bundle?.teacherId,
            notifications: bundle?.notifications ?? const <DbNotification>[],
            limit: 4,
            onChanged: onRefresh,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Recent Submissions',
            actionLabel: 'Reviews',
            onAction: () => onSelectTab(3),
          ),
          if ((bundle?.submissions ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.inbox_outlined,
              title: 'No submissions yet',
              body:
                  'Student submissions will appear here when they submit work.',
            )
          else
            ...bundle!.submissions
                .take(4)
                .map(
                  (submission) => _SubmissionTile(
                    submission: submission,
                    onTap: () => _reviewSubmissionDialog(
                      context: context,
                      teacherId: bundle!.teacherId,
                      submission: submission,
                      onSaved: onRefresh,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _TeacherClassesTab extends StatelessWidget {
  const _TeacherClassesTab({
    required this.teacherId,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final String teacherId;
  final TeacherBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _classDialog(
          context: context,
          teacherId: teacherId,
          onSaved: onRefresh,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Classes'),
          const SizedBox(height: 12),
          if ((bundle?.classes ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.groups_outlined,
              title: 'No classes',
              body: 'Create a class to assign students and activities.',
            )
          else
            ...bundle!.classes.map(
              (klass) => _ClassTile(
                klass: klass,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeacherClassDetailPage(
                      teacherId: teacherId,
                      classItem: klass,
                      onChanged: onRefresh,
                    ),
                  ),
                ),
                onEdit: () => _classDialog(
                  context: context,
                  teacherId: teacherId,
                  classItem: klass,
                  onSaved: onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherActivitiesTab extends StatelessWidget {
  const _TeacherActivitiesTab({
    required this.teacherId,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final String teacherId;
  final TeacherBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (bundle?.classes ?? []).isEmpty
            ? null
            : () => _activityDialog(
                context: context,
                teacherId: teacherId,
                classes: bundle!.classes,
                onSaved: onRefresh,
              ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Activity'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Activities'),
          const SizedBox(height: 12),
          if ((bundle?.activities ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.assignment_outlined,
              title: 'No activities',
              body: 'Activities are loaded from the activities table.',
            )
          else
            ...bundle!.activities.map(
              (activity) => _TeacherActivityTile(
                activity: activity,
                onEdit: () => _activityDialog(
                  context: context,
                  teacherId: teacherId,
                  classes: bundle!.classes,
                  activity: activity,
                  onSaved: onRefresh,
                ),
                onDelete: () =>
                    _confirmDeleteActivity(context, activity, onRefresh),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherReviewsTab extends StatelessWidget {
  const _TeacherReviewsTab({
    required this.teacherId,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final String teacherId;
  final TeacherBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Reviews'),
          const SizedBox(height: 12),
          if ((bundle?.submissions ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.rate_review_outlined,
              title: 'No submitted work',
              body: 'Submitted activities will appear here for scoring.',
            )
          else
            ...bundle!.submissions.map(
              (submission) => _SubmissionTile(
                submission: submission,
                onTap: () => _reviewSubmissionDialog(
                  context: context,
                  teacherId: teacherId,
                  submission: submission,
                  onSaved: onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherAlertsTab extends StatelessWidget {
  const _TeacherAlertsTab({
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final TeacherBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Gesture Alerts'),
          const SizedBox(height: 12),
          if ((bundle?.gestureAlerts ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.warning_amber_outlined,
              title: 'No gesture alerts',
              body: 'Alerts reported from AR are loaded from Supabase.',
            )
          else
            ...bundle!.gestureAlerts.map(
              (alert) => _GestureAlertTile(alert: alert),
            ),
        ],
      ),
    );
  }
}

class _ParentHomeTab extends StatelessWidget {
  const _ParentHomeTab({
    required this.name,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onOpenChildren,
    required this.onRefresh,
  });

  final String name;
  final ParentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onOpenChildren;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroPanel(
            title: 'Parent Dashboard',
            subtitle: 'Welcome, $name',
            trailing: const Icon(
              Icons.family_restroom_rounded,
              color: _primary,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricData(
                'Children',
                bundle?.children.length ?? 0,
                onTap: onOpenChildren,
              ),
              _MetricData(
                'Pending',
                bundle?.pendingCount ?? 0,
                onTap: onOpenChildren,
              ),
              _MetricData(
                'Submitted',
                bundle?.submittedCount ?? 0,
                onTap: onOpenChildren,
              ),
              _MetricData(
                'Reviewed',
                bundle?.reviewedCount ?? 0,
                onTap: onOpenChildren,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _NotificationSection(
            userId: bundle?.parentId,
            notifications: bundle?.notifications ?? const <DbNotification>[],
            limit: 4,
            onChanged: onRefresh,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Linked Children',
            actionLabel: 'View',
            onAction: onOpenChildren,
          ),
          if ((bundle?.children ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.link_off_rounded,
              title: 'No linked students',
              body:
                  'This parent account is not linked to a student in the database yet.',
            )
          else
            ...bundle!.children.map((child) => _ParentChildTile(child: child)),
        ],
      ),
    );
  }
}

class _ParentChildrenTab extends StatelessWidget {
  const _ParentChildrenTab({
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final ParentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Children'),
          const SizedBox(height: 12),
          if ((bundle?.children ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.family_restroom_outlined,
              title: 'No students linked',
              body:
                  'Add a parent-student link in Supabase to show progress here.',
            )
          else
            ...bundle!.children.map(
              (child) => _ParentChildDetailCard(child: child),
            ),
        ],
      ),
    );
  }
}

class _ParentSettingsTab extends StatelessWidget {
  const _ParentSettingsTab({
    required this.name,
    required this.email,
    required this.onSignedOut,
  });

  final String name;
  final String email;
  final Future<void> Function() onSignedOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _HeroPanel(
          title: name,
          subtitle: email,
          trailing: const Icon(
            Icons.settings_rounded,
            color: _primary,
            size: 46,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onSignedOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class StudentActivityDetailPage extends StatelessWidget {
  const StudentActivityDetailPage({
    super.key,
    required this.activity,
    required this.studentId,
    required this.onChanged,
  });

  final DbActivity activity;
  final String studentId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final submission = activity.submission;
    return Scaffold(
      appBar: AppBar(title: Text(activity.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ActivityHero(activity: activity),
          const SizedBox(height: 16),
          Text(
            activity.summary.isEmpty
                ? 'No description provided.'
                : activity.summary,
            style: const TextStyle(fontSize: 16, color: _muted),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            children: [
              _InfoRow('Due Date', _formatDate(activity.dueDate)),
              _InfoRow('Status', activity.studentStatusLabel),
              _InfoRow('Subject', activity.subjectLabel),
              _InfoRow('Grade', activity.gradeLabel),
            ],
          ),
          const SizedBox(height: 18),
          if (submission != null)
            _InfoCard(
              title: 'Submission',
              children: [
                _InfoRow('Submitted', _formatDateTime(submission.submittedAt)),
                _InfoRow('Score', submission.scoreLabel),
                _InfoRow(
                  'Feedback',
                  submission.feedback.isEmpty
                      ? 'No feedback yet'
                  : submission.feedback,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final submitted = await openArExperience(
                      context,
                      _arStartUrl(activity, studentId),
                    );
                    onChanged();
                    if (submitted && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.view_in_ar_rounded),
                  label: const Text('Start Project'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final submitted = await openArExperience(
                      context,
                      _arStartUrl(activity, studentId, vrMode: true),
                    );
                    onChanged();
                    if (submitted && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.view_week_rounded),
                  label: const Text('Start VR Mode'),
                ),
              ],
            ),
          if (submission != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                await openArExperience(
                  context,
                  _arStartUrl(activity, studentId, viewMode: true),
                );
                onChanged();
              },
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('View AR'),
            ),
          ],
        ],
      ),
    );
  }
}

class TeacherClassDetailPage extends StatefulWidget {
  const TeacherClassDetailPage({
    super.key,
    required this.teacherId,
    required this.classItem,
    required this.onChanged,
  });

  final String teacherId;
  final DbClass classItem;
  final VoidCallback onChanged;

  @override
  State<TeacherClassDetailPage> createState() => _TeacherClassDetailPageState();
}

class _TeacherClassDetailPageState extends State<TeacherClassDetailPage> {
  late Future<ClassDetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadClassDetail(widget.classItem.id);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.loadClassDetail(widget.classItem.id);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classItem.displayName),
        actions: [
          IconButton(
            onPressed: () => _classDialog(
              context: context,
              teacherId: widget.teacherId,
              classItem: widget.classItem,
              onSaved: _refresh,
            ),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit class',
          ),
        ],
      ),
      body: FutureBuilder<ClassDetailBundle>(
        future: _future,
        builder: (context, snapshot) {
          return _DataSurface(
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeroPanel(
                  title: widget.classItem.displayName,
                  subtitle: widget.classItem.subjectLabel,
                  trailing: const Icon(
                    Icons.groups_rounded,
                    color: _primary,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 18),
                _AddToClassCard(
                  classId: widget.classItem.id,
                  onSaved: _refresh,
                ),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Students'),
                if ((snapshot.data?.students ?? []).isEmpty)
                  const _EmptyCard(
                    icon: Icons.person_add_alt_rounded,
                    title: 'No students in this class',
                    body:
                        'Use Add to Class to connect an existing student account.',
                  )
                else
                  ...snapshot.data!.students.map(
                    (student) => _StudentEnrollmentTile(
                      student: student,
                      onRemove: () => _confirmRemoveStudent(
                        context,
                        widget.classItem.id,
                        student,
                        _refresh,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Activities'),
                if ((snapshot.data?.activities ?? []).isEmpty)
                  const _EmptyCard(
                    icon: Icons.assignment_outlined,
                    title: 'No activities',
                    body:
                        'Class activities created by the teacher appear here.',
                  )
                else
                  ...snapshot.data!.activities.map(
                    (activity) => _TeacherActivityTile(
                      activity: activity,
                      onEdit: () => _activityDialog(
                        context: context,
                        teacherId: widget.teacherId,
                        classes: [widget.classItem],
                        activity: activity,
                        onSaved: _refresh,
                      ),
                      onDelete: () =>
                          _confirmDeleteActivity(context, activity, _refresh),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddToClassCard extends StatefulWidget {
  const _AddToClassCard({required this.classId, required this.onSaved});

  final String classId;
  final VoidCallback onSaved;

  @override
  State<_AddToClassCard> createState() => _AddToClassCardState();
}

class _AddToClassCardState extends State<_AddToClassCard> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Class?'),
        content: Text('Add $email to this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await MobileDataService.addStudentToClassByEmail(
      widget.classId,
      email,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _isError = !result.success;
      _message = result.success ? 'Student added to class.' : result.error;
    });

    if (result.success) {
      _emailController.clear();
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add to Class',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Student email',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(
                color: _isError
                    ? const Color(0xFFB42318)
                    : const Color(0xFF067647),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataSurface extends StatelessWidget {
  const _DataSurface({
    required this.child,
    this.loading = false,
    this.error,
    this.onRefresh,
    this.floatingActionButton,
  });

  final Widget child;
  final bool loading;
  final Object? error;
  final VoidCallback? onRefresh;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => onRefresh?.call(),
            child: child,
          ),
          if (loading) const LinearProgressIndicator(minHeight: 3),
          if (error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _ErrorSnack(message: 'Unable to load data: $error'),
            ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final value = metric.value is num
        ? NumberFormat.compact().format(metric.value)
        : metric.value.toString();
    return InkWell(
      onTap: metric.onTap,
      borderRadius: BorderRadius.circular(20),
      child: _CardShell(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, {this.onTap});

  final String label;
  final Object value;
  final VoidCallback? onTap;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: _ink,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 34),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorSnack extends StatelessWidget {
  const _ErrorSnack({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB42318),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.userId,
    required this.notifications,
    required this.limit,
    required this.onChanged,
  });

  final String? userId;
  final List<DbNotification> notifications;
  final int limit;
  final VoidCallback onChanged;

  Future<void> _markAllRead() async {
    final id = userId;
    if (id == null || id.isEmpty) return;
    final unreadIds = notifications
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList();
    if (unreadIds.isEmpty) return;
    await MobileDataService.markNotificationsRead(id, unreadIds);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final visible = notifications.take(limit).toList();
    final hasUnread = visible.any((item) => !item.isRead);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Notifications',
          actionLabel: hasUnread ? 'Mark read' : null,
          onAction: _markAllRead,
        ),
        if (notifications.isEmpty)
          const _EmptyCard(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            body: 'Activity updates and reminders will appear here.',
          )
        else
          ...visible.map(
            (item) => _NotificationTile(
              userId: userId,
              notification: item,
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.userId,
    required this.notification,
    required this.onChanged,
  });

  final String? userId;
  final DbNotification notification;
  final VoidCallback onChanged;

  Future<void> _markRead() async {
    final id = userId;
    if (id == null || id.isEmpty || notification.isRead) return;
    await MobileDataService.markNotificationsRead(id, [notification.id]);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: _markRead,
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? const Color(0xFFF5F0EB)
              : const Color(0xFFF0EEFC),
          foregroundColor: notification.isRead ? _muted : _primary,
          child: Icon(_notificationIcon(notification.type)),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${notification.message}\n${_formatDateTime(notification.createdAt)}',
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, color: _primary, size: 10),
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({required this.activity, required this.onTap});

  final DbActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: _Thumbnail(
          url: activity.imageUrl,
          seed: activity.id,
          size: 62,
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Due ${_formatDate(activity.dueDate)}\n${activity.studentStatusLabel}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ActivityHero extends StatelessWidget {
  const _ActivityHero({required this.activity});

  final DbActivity activity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 210,
        decoration: BoxDecoration(gradient: _pastelGradient(activity.id)),
        child: Stack(
          children: [
            Positioned.fill(
              child: activity.imageUrl.isNotEmpty
                  ? Image.network(
                      activity.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Text(
                activity.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.activity});

  final DbActivity activity;

  @override
  Widget build(BuildContext context) {
    final submission = activity.submission;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _InfoRow('Score', submission?.scoreLabel ?? 'N/A'),
          _InfoRow(
            'Feedback',
            submission?.feedback.isEmpty ?? true
                ? 'No feedback yet'
                : submission!.feedback,
          ),
        ],
      ),
    );
  }
}

class _ArtworkGrid extends StatelessWidget {
  const _ArtworkGrid({required this.artworks});

  final List<DbArtwork> artworks;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artworks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) => _ArtworkCard(artwork: artworks[index]),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.artwork});

  final DbArtwork artwork;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Thumbnail(
                url: artwork.imageUrl,
                seed: artwork.id,
                size: double.infinity,
                square: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                artwork.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.seed,
    required this.size,
    this.square = true,
  });

  final String url;
  final String seed;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: _pastelGradient(seed),
      borderRadius: BorderRadius.circular(square ? 14 : 0),
    );

    final child = url.isEmpty
        ? const Icon(Icons.image_outlined, color: Colors.white, size: 34)
        : Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_outlined, color: Colors.white, size: 34),
          );

    if (!square) {
      return Container(decoration: decoration, child: child);
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.klass,
    required this.onTap,
    required this.onEdit,
  });

  final DbClass klass;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          child: Text(klass.initial),
        ),
        title: Text(
          klass.displayName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${klass.studentCount} students - ${klass.activityCount} activities',
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit',
        ),
      ),
    );
  }
}

class _TeacherActivityTile extends StatelessWidget {
  const _TeacherActivityTile({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  final DbActivity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
          Text(
            activity.className.isEmpty ? 'No class' : activity.className,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip('Due ${_formatDate(activity.dueDate)}'),
              _Chip('${activity.submissionCount} submitted'),
              _Chip('${activity.assignmentCount} assigned'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.submission, required this.onTap});

  final DbSubmission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: _Thumbnail(
          url: submission.artworkUrl,
          seed: submission.id,
          size: 58,
        ),
        title: Text(
          submission.activityTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${submission.studentName}\n${submission.reviewStatusLabel} - ${_formatDateTime(submission.submittedAt)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _GestureAlertTile extends StatelessWidget {
  const _GestureAlertTile({required this.alert});

  final DbGestureAlert alert;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.studentName,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(alert.activityTitle, style: const TextStyle(color: _muted)),
          const SizedBox(height: 8),
          _Chip(
            '${alert.gestureTypeLabel} - ${_formatDateTime(alert.createdAt)}',
          ),
        ],
      ),
    );
  }
}

class _StudentEnrollmentTile extends StatelessWidget {
  const _StudentEnrollmentTile({required this.student, required this.onRemove});

  final DbStudent student;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          child: Text(_initials(student.name)),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(student.email),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          tooltip: 'Remove',
        ),
      ),
    );
  }
}

class _ParentChildTile extends StatelessWidget {
  const _ParentChildTile({required this.child});

  final ParentChild child;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          child: Text(_initials(child.student.name)),
        ),
        title: Text(
          child.student.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${child.completionLabel} complete - ${child.pendingCount} pending - ${child.reviewedCount} reviewed',
        ),
      ),
    );
  }
}

class _ParentChildDetailCard extends StatelessWidget {
  const _ParentChildDetailCard({required this.child});

  final ParentChild child;

  @override
  Widget build(BuildContext context) {
    final nextDue = child.nextDueActivity;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            child.student.name,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 8),
          _InfoRow('Email', child.student.email),
          _InfoRow('Progress', child.completionLabel),
          _InfoRow('Total Activities', child.totalCount.toString()),
          _InfoRow('Pending', child.pendingCount.toString()),
          _InfoRow('Submitted', child.submittedCount.toString()),
          _InfoRow('Reviewed', child.reviewedCount.toString()),
          _InfoRow('Overdue', child.overdueCount.toString()),
          _InfoRow('Average Score', child.averageScoreLabel),
          if (nextDue != null)
            _InfoRow(
              'Next Due',
              '${nextDue.title} - ${_formatDate(nextDue.dueDate)}',
            ),
          if (child.reviewedActivities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recent feedback',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...child.reviewedActivities
                .take(2)
                .map(
                  (activity) => Text(
                    '- ${activity.title}: ${activity.submission?.scoreLabel ?? 'N/A'}',
                    style: const TextStyle(color: _muted),
                  ),
                ),
          ],
          if (child.activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recent activity',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...child.activities
                .take(3)
                .map(
                  (activity) => Text(
                    '- ${activity.title}: ${activity.studentStatusLabel}',
                    style: const TextStyle(color: _muted),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

Future<void> _classDialog({
  required BuildContext context,
  required String teacherId,
  DbClass? classItem,
  required VoidCallback onSaved,
}) async {
  final nameController = TextEditingController(text: classItem?.name ?? '');
  final gradeController = TextEditingController(text: classItem?.grade ?? '');
  final sectionController = TextEditingController(
    text: classItem?.section ?? '',
  );
  final subjectController = TextEditingController(
    text: classItem?.subject ?? '',
  );
  String? error;
  bool loading = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(classItem == null ? 'Add Class' : 'Edit Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Class name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    final result = classItem == null
                        ? await MobileDataService.createClass(
                            teacherId: teacherId,
                            name: nameController.text,
                            grade: gradeController.text,
                            section: sectionController.text,
                            subject: subjectController.text,
                          )
                        : await MobileDataService.updateClass(
                            classItem.id,
                            name: nameController.text,
                            grade: gradeController.text,
                            section: sectionController.text,
                            subject: subjectController.text,
                          );
                    if (!context.mounted) return;
                    if (result.success) {
                      Navigator.pop(context);
                      onSaved();
                    } else {
                      setState(() {
                        loading = false;
                        error = result.error;
                      });
                    }
                  },
            child: Text(classItem == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  nameController.dispose();
  gradeController.dispose();
  sectionController.dispose();
  subjectController.dispose();
}

Future<void> _activityDialog({
  required BuildContext context,
  required String teacherId,
  required List<DbClass> classes,
  DbActivity? activity,
  required VoidCallback onSaved,
}) async {
  final titleController = TextEditingController(text: activity?.title ?? '');
  final descriptionController = TextEditingController(
    text: activity?.summary ?? '',
  );
  final thumbnailController = TextEditingController(
    text: activity?.imageUrl ?? '',
  );
  DateTime? dueDate =
      activity?.dueDate ?? DateTime.now().add(const Duration(days: 7));
  String selectedClassId = activity?.classId.isNotEmpty == true
      ? activity!.classId
      : classes.first.id;
  String? error;
  bool loading = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(activity == null ? 'Add Activity' : 'Edit Activity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: thumbnailController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail image URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: classes
                    .map(
                      (klass) => DropdownMenuItem(
                        value: klass.id,
                        child: Text(klass.displayName),
                      ),
                    )
                    .toList(),
                onChanged: activity == null
                    ? (value) => selectedClassId = value ?? selectedClassId
                    : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(_formatDate(dueDate)),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                    initialDate: dueDate ?? DateTime.now(),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    final selectedClass = classes.firstWhere(
                      (klass) => klass.id == selectedClassId,
                    );
                    final result = activity == null
                        ? await MobileDataService.createActivityAndAssign(
                            teacherId: teacherId,
                            classItem: selectedClass,
                            title: titleController.text,
                            description: descriptionController.text,
                            imageUrl: thumbnailController.text,
                            dueDate: dueDate,
                          )
                        : await MobileDataService.updateActivity(
                            activity.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            imageUrl: thumbnailController.text,
                            dueDate: dueDate,
                          );
                    if (!context.mounted) return;
                    if (result.success) {
                      Navigator.pop(context);
                      onSaved();
                    } else {
                      setState(() {
                        loading = false;
                        error = result.error;
                      });
                    }
                  },
            child: Text(activity == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  titleController.dispose();
  descriptionController.dispose();
  thumbnailController.dispose();
}

Future<void> _reviewSubmissionDialog({
  required BuildContext context,
  required String teacherId,
  required DbSubmission submission,
  required VoidCallback onSaved,
}) async {
  final scoreController = TextEditingController(
    text: submission.score?.toString() ?? '',
  );
  final feedbackController = TextEditingController(text: submission.feedback);
  String? error;
  bool loading = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Review ${submission.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                submission.activityTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (submission.artworkUrl.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: _Thumbnail(
                    url: submission.artworkUrl,
                    seed: submission.id,
                    size: double.infinity,
                    square: false,
                  ),
                ),
              const SizedBox(height: 12),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Score',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    final scoreText = scoreController.text.trim();
                    final score = scoreText.isEmpty
                        ? null
                        : num.tryParse(scoreText);
                    if (scoreText.isNotEmpty && score == null) {
                      setState(() => error = 'Score must be a number.');
                      return;
                    }
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    final result = await MobileDataService.reviewSubmission(
                      submissionId: submission.id,
                      teacherId: teacherId,
                      score: score,
                      feedback: feedbackController.text,
                    );
                    if (!context.mounted) return;
                    if (result.success) {
                      Navigator.pop(context);
                      onSaved();
                    } else {
                      setState(() {
                        loading = false;
                        error = result.error;
                      });
                    }
                  },
            child: const Text('Save Review'),
          ),
        ],
      ),
    ),
  );

  scoreController.dispose();
  feedbackController.dispose();
}

Future<void> _confirmDeleteActivity(
  BuildContext context,
  DbActivity activity,
  VoidCallback onSaved,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Activity?'),
      content: Text(
        'Delete "${activity.title}"? This can affect existing assignments.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await MobileDataService.deleteActivity(activity.id);
  onSaved();
}

Future<void> _confirmRemoveStudent(
  BuildContext context,
  String classId,
  DbStudent student,
  VoidCallback onSaved,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove Student?'),
      content: Text('Remove ${student.name} from this class?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await MobileDataService.removeStudentFromClass(classId, student.id);
  onSaved();
}

void _openStudentActivity(
  BuildContext context,
  DbActivity activity, {
  required String studentId,
  required VoidCallback onChanged,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentActivityDetailPage(
        activity: activity,
        studentId: studentId,
        onChanged: onChanged,
      ),
    ),
  );
}

Uri _arStartUrl(
  DbActivity activity,
  String studentId, {
  bool vrMode = false,
  bool viewMode = false,
}) {
  final base = Uri.parse(_hostedWebOrigin);
  return base.replace(
    path: '/mobile/activity/${activity.id}/start',
    queryParameters: {
      'mobile': '1',
      'studentId': studentId,
      if (vrMode) 'vr': '1',
      if (viewMode) 'mode': 'view',
    },
  );
}

class MobileDataService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<StudentBundle> loadStudentBundle(String studentId) async {
    final activities = await fetchStudentActivities(studentId);
    final submissions = activities
        .map((item) => item.submission)
        .whereType<DbSubmission>()
        .toList();
    final artworks = await fetchStudentArtworks(studentId, submissions);
    final readIds = await fetchNotificationReadIds(studentId);
    final notifications = _applyNotificationReadState(
      _buildStudentNotifications(activities),
      readIds,
    );
    return StudentBundle(
      studentId: studentId,
      activities: activities,
      artworks: artworks,
      notifications: notifications,
    );
  }

  static Future<TeacherBundle> loadTeacherBundle(String teacherId) async {
    final classes = await fetchTeacherClasses(teacherId);
    final activities = await fetchTeacherActivities(teacherId, classes);
    final submissions = await fetchTeacherSubmissions(teacherId, activities);
    final alerts = await fetchTeacherGestureAlerts(teacherId);
    final readIds = await fetchNotificationReadIds(teacherId);
    final notifications = _applyNotificationReadState(
      _buildTeacherNotifications(submissions, alerts),
      readIds,
    );
    return TeacherBundle(
      teacherId: teacherId,
      classes: classes,
      activities: activities,
      submissions: submissions,
      gestureAlerts: alerts,
      notifications: notifications,
    );
  }

  static Future<ParentBundle> loadParentBundle(String parentId) async {
    final studentIds = await _fetchParentStudentIds(parentId);
    if (studentIds.isEmpty) {
      return ParentBundle(
        parentId: parentId,
        children: const [],
        notifications: const [],
      );
    }

    final users = await _fetchUsersByIds(studentIds);
    final children = <ParentChild>[];
    for (final student in users) {
      final activities = await fetchStudentActivities(student.id);
      children.add(ParentChild(student: student, activities: activities));
    }
    final readIds = await fetchNotificationReadIds(parentId);
    return ParentBundle(
      parentId: parentId,
      children: children,
      notifications: _applyNotificationReadState(
        _buildParentNotifications(children),
        readIds,
      ),
    );
  }

  static Future<ClassDetailBundle> loadClassDetail(String classId) async {
    final students = await fetchClassStudents(classId);
    final activities = await fetchClassActivities(classId);
    return ClassDetailBundle(students: students, activities: activities);
  }

  static Future<List<DbActivity>> fetchStudentActivities(
    String studentId,
  ) async {
    final assignmentRows = _rows(
      await _client
          .from('activity_assignments')
          .select('id, activity_id, student_id, status, assigned_at')
          .eq('student_id', studentId)
          .order('assigned_at', ascending: false),
    );

    final submissionRows = _rows(
      await _client
          .from('submissions')
          .select(
            'id, activity_id, student_id, artwork_url, description, status, submitted_at, reviewed_at, score, feedback',
          )
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false),
    );

    final activityIds = <String>{
      ...assignmentRows
          .map((row) => _string(row['activity_id']))
          .where((id) => id.isNotEmpty),
      ...submissionRows
          .map((row) => _string(row['activity_id']))
          .where((id) => id.isNotEmpty),
    }.toList();

    if (activityIds.isEmpty) return [];

    final activityRows = _rows(
      await _client
          .from('activities')
          .select(
            'id, teacher_id, title, description, due_date, status, image_url, class_id, grade, subject',
          )
          .inFilter('id', activityIds)
          .order('due_date', ascending: true),
    );

    final assignmentsByActivity = {
      for (final row in assignmentRows) _string(row['activity_id']): row,
    };

    final submissionsByActivity = <String, Map<String, dynamic>>{};
    for (final row in submissionRows) {
      final activityId = _string(row['activity_id']);
      if (activityId.isNotEmpty &&
          !submissionsByActivity.containsKey(activityId)) {
        submissionsByActivity[activityId] = row;
      }
    }

    final activities = activityRows.map((row) {
      final id = _string(row['id']);
      final assignment = assignmentsByActivity[id];
      final submissionRow = submissionsByActivity[id];
      final submission = submissionRow == null
          ? null
          : DbSubmission.fromRow(submissionRow);
      return DbActivity.fromRow(
        row,
        assignment: assignment,
        submission: submission,
      );
    }).toList();

    activities.sort((a, b) {
      final aDone = a.isSubmitted ? 1 : 0;
      final bDone = b.isSubmitted ? 1 : 0;
      if (aDone != bDone) return aDone.compareTo(bDone);
      return (a.dueDate ?? DateTime(2099)).compareTo(
        b.dueDate ?? DateTime(2099),
      );
    });
    return activities;
  }

  static Future<List<DbArtwork>> fetchStudentArtworks(
    String studentId,
    List<DbSubmission> submissions,
  ) async {
    final artworkRows = _rows(
      await _client
          .from('artworks')
          .select(
            'id, student_id, title, description, image_url, submission_id, created_at',
          )
          .eq('student_id', studentId)
          .order('created_at', ascending: false),
    );

    final items = artworkRows.map(DbArtwork.fromRow).toList();
    final existingSubmissionIds = items
        .map((item) => item.submissionId)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final submission in submissions) {
      if (submission.artworkUrl.isEmpty ||
          existingSubmissionIds.contains(submission.id)) {
        continue;
      }
      items.add(
        DbArtwork(
          id: 'submission-${submission.id}',
          title: submission.activityTitle,
          imageUrl: submission.artworkUrl,
          submissionId: submission.id,
          createdAt: submission.submittedAt,
        ),
      );
    }

    items.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return items;
  }

  static Future<List<DbClass>> fetchTeacherClasses(String teacherId) async {
    final classRows = _rows(
      await _client
          .from('classes')
          .select(
            'id, teacher_id, name, grade, section, subject, color, student_count, created_at',
          )
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false),
    );

    final classes = classRows.map(DbClass.fromRow).toList();
    if (classes.isEmpty) return classes;

    final classIds = classes.map((klass) => klass.id).toList();
    final studentRows = _rows(
      await _client
          .from('class_students')
          .select('class_id, student_id')
          .inFilter('class_id', classIds),
    );
    final activityRows = _rows(
      await _client
          .from('activities')
          .select('id, class_id')
          .inFilter('class_id', classIds),
    );

    final studentsByClass = <String, Set<String>>{};
    for (final row in studentRows) {
      final classId = _string(row['class_id']);
      final studentId = _string(row['student_id']);
      if (classId.isEmpty || studentId.isEmpty) continue;
      studentsByClass.putIfAbsent(classId, () => <String>{}).add(studentId);
    }

    final activitiesByClass = <String, int>{};
    for (final row in activityRows) {
      final classId = _string(row['class_id']);
      if (classId.isEmpty) continue;
      activitiesByClass[classId] = (activitiesByClass[classId] ?? 0) + 1;
    }

    return classes
        .map(
          (klass) => klass.copyWith(
            studentCount:
                studentsByClass[klass.id]?.length ?? klass.studentCount,
            activityCount: activitiesByClass[klass.id] ?? 0,
          ),
        )
        .toList();
  }

  static Future<List<DbStudent>> fetchClassStudents(String classId) async {
    final rows = _rows(
      await _client
          .from('class_students')
          .select(
            'id, class_id, student_id, student_name, student_email, enrolled_at',
          )
          .eq('class_id', classId)
          .order('enrolled_at', ascending: false),
    );
    return rows.map(DbStudent.fromEnrollmentRow).toList();
  }

  static Future<List<DbActivity>> fetchClassActivities(String classId) async {
    final rows = _rows(
      await _client
          .from('activities')
          .select(
            'id, teacher_id, title, description, due_date, status, image_url, class_id, grade, subject',
          )
          .eq('class_id', classId)
          .order('due_date', ascending: true),
    );
    return rows.map(DbActivity.fromRow).toList();
  }

  static Future<List<DbActivity>> fetchTeacherActivities(
    String teacherId,
    List<DbClass> classes,
  ) async {
    final rows = _rows(
      await _client
          .from('activities')
          .select(
            'id, teacher_id, title, description, due_date, status, image_url, class_id, grade, subject, created_at',
          )
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false),
    );
    if (rows.isEmpty) return [];

    final activities = rows.map(DbActivity.fromRow).toList();
    final ids = activities.map((activity) => activity.id).toList();

    final assignmentRows = _rows(
      await _client
          .from('activity_assignments')
          .select('activity_id, student_id')
          .inFilter('activity_id', ids),
    );
    final submissionRows = _rows(
      await _client
          .from('submissions')
          .select('activity_id, id')
          .inFilter('activity_id', ids),
    );

    final assignedCounts = _countBy(assignmentRows, 'activity_id');
    final submissionCounts = _countBy(submissionRows, 'activity_id');
    final classById = {for (final klass in classes) klass.id: klass};

    return activities
        .map(
          (activity) => activity.copyWith(
            assignmentCount: assignedCounts[activity.id] ?? 0,
            submissionCount: submissionCounts[activity.id] ?? 0,
            className: classById[activity.classId]?.displayName ?? '',
          ),
        )
        .toList();
  }

  static Future<List<DbSubmission>> fetchTeacherSubmissions(
    String teacherId,
    List<DbActivity> teacherActivities,
  ) async {
    if (teacherActivities.isEmpty) return [];
    final activityIds = teacherActivities
        .map((activity) => activity.id)
        .toList();
    final activityById = {
      for (final activity in teacherActivities) activity.id: activity,
    };

    final submissionRows = _rows(
      await _client
          .from('submissions')
          .select(
            'id, activity_id, student_id, artwork_url, description, status, submitted_at, reviewed_at, score, feedback',
          )
          .inFilter('activity_id', activityIds)
          .order('submitted_at', ascending: false),
    );
    if (submissionRows.isEmpty) return [];

    final studentIds = submissionRows
        .map((row) => _string(row['student_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final students = await _fetchUsersByIds(studentIds);
    final studentById = {for (final student in students) student.id: student};

    return submissionRows.map((row) {
      final activity = activityById[_string(row['activity_id'])];
      final student = studentById[_string(row['student_id'])];
      return DbSubmission.fromRow(row).copyWith(
        activityTitle: activity?.title ?? 'Untitled activity',
        studentName: student?.name ?? 'Student',
        studentEmail: student?.email ?? '',
      );
    }).toList();
  }

  static Future<List<DbGestureAlert>> fetchTeacherGestureAlerts(
    String teacherId,
  ) async {
    try {
      final result = await _client.rpc(
        'get_teacher_gesture_alerts',
        params: {'p_teacher_id': teacherId},
      );
      return _rows(result).map(DbGestureAlert.fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<DbResult> createClass({
    required String teacherId,
    required String name,
    required String grade,
    required String section,
    required String subject,
  }) async {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      return const DbResult.failure('Class name is required.');
    }
    try {
      await _client.from('classes').insert({
        'teacher_id': teacherId,
        'name': safeName,
        'grade': grade.trim(),
        'section': section.trim(),
        'subject': subject.trim(),
        'color': '#1800AD',
      });
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> updateClass(
    String classId, {
    required String name,
    required String grade,
    required String section,
    required String subject,
  }) async {
    if (name.trim().isEmpty) {
      return const DbResult.failure('Class name is required.');
    }
    try {
      await _client
          .from('classes')
          .update({
            'name': name.trim(),
            'grade': grade.trim(),
            'section': section.trim(),
            'subject': subject.trim(),
          })
          .eq('id', classId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> addStudentToClassByEmail(
    String classId,
    String email,
  ) async {
    final safeEmail = email.trim().toLowerCase();
    if (!safeEmail.contains('@')) {
      return const DbResult.failure('Enter a valid student email.');
    }

    try {
      await _client.rpc(
        'enroll_student_to_class',
        params: {'p_class_id': classId, 'p_student_email': safeEmail},
      );
      final student = await _fetchStudentByEmail(safeEmail);
      if (student != null) {
        await _syncClassAssignmentsForStudent(classId, student.id);
        await _updateClassStudentCount(classId);
      }
      return const DbResult.success();
    } catch (_) {
      try {
        final user = await _fetchStudentByEmail(safeEmail);
        if (user == null) {
          return const DbResult.failure('Student account not found.');
        }
        if (_normalizeRole(user.role) != 'student') {
          return const DbResult.failure('That email is not a student account.');
        }

        final existingRows = _rows(
          await _client
              .from('class_students')
              .select('student_id')
              .eq('class_id', classId)
              .eq('student_id', user.id),
        );
        if (existingRows.isEmpty) {
          await _client.from('class_students').insert({
            'class_id': classId,
            'student_id': user.id,
            'student_name': user.name,
            'student_email': user.email,
          });
        }
        await _syncClassAssignmentsForStudent(classId, user.id);
        await _updateClassStudentCount(classId);
        return const DbResult.success();
      } catch (error) {
        return DbResult.failure(error.toString());
      }
    }
  }

  static Future<DbResult> removeStudentFromClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _client
          .from('class_students')
          .delete()
          .eq('class_id', classId)
          .eq('student_id', studentId);
      await _removeClassAssignmentsForStudent(classId, studentId);
      await _updateClassStudentCount(classId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> createActivityAndAssign({
    required String teacherId,
    required DbClass classItem,
    required String title,
    required String description,
    String imageUrl = '',
    DateTime? dueDate,
  }) async {
    if (title.trim().isEmpty) {
      return const DbResult.failure('Activity title is required.');
    }
    try {
      final inserted = await _client
          .from('activities')
          .insert({
            'teacher_id': teacherId,
            'title': title.trim(),
            'description': _encodeActivityDescription(description.trim()),
            'class_id': classItem.id,
            'grade': classItem.grade,
            'subject': classItem.subject,
            'due_date': dueDate?.toIso8601String(),
            'image_url': imageUrl.trim(),
            'status': 'active',
          })
          .select('id')
          .single();

      final activityId = _string(inserted['id']);
      final students = await fetchClassStudents(classItem.id);
      if (activityId.isNotEmpty && students.isNotEmpty) {
        await _client
            .from('activity_assignments')
            .insert(
              students
                  .map(
                    (student) => {
                      'activity_id': activityId,
                      'student_id': student.id,
                      'status': 'pending',
                    },
                  )
                  .toList(),
            );
      }
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> updateActivity(
    String activityId, {
    required String title,
    required String description,
    String imageUrl = '',
    DateTime? dueDate,
  }) async {
    if (title.trim().isEmpty) {
      return const DbResult.failure('Activity title is required.');
    }
    try {
      await _client
          .from('activities')
          .update({
            'title': title.trim(),
            'description': _encodeActivityDescription(description.trim()),
            'image_url': imageUrl.trim(),
            'due_date': dueDate?.toIso8601String(),
          })
          .eq('id', activityId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> deleteActivity(String activityId) async {
    try {
      await _client
          .from('activity_assignments')
          .delete()
          .eq('activity_id', activityId);
      await _client.from('activities').delete().eq('id', activityId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> reviewSubmission({
    required String submissionId,
    required String teacherId,
    required num? score,
    required String feedback,
  }) async {
    try {
      await _client
          .from('submissions')
          .update({
            'score': score,
            'feedback': feedback.trim(),
            'status': 'reviewed',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': teacherId,
          })
          .eq('id', submissionId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static List<DbNotification> _buildStudentNotifications(
    List<DbActivity> activities,
  ) {
    final notifications = <DbNotification>[];
    for (final activity in activities) {
      if (!activity.isSubmitted && activity.assignedAt != null) {
        notifications.add(
          DbNotification(
            id: 'assigned-${activity.id}',
            type: 'assignment',
            title: 'New Activity Assigned',
            message: 'You have been assigned "${activity.title}".',
            createdAt: activity.assignedAt,
          ),
        );
      }

      final daysUntilDue = _daysUntil(activity.dueDate);
      if (!activity.isSubmitted &&
          daysUntilDue != null &&
          daysUntilDue >= 0 &&
          daysUntilDue <= 3) {
        notifications.add(
          DbNotification(
            id: 'due-${activity.id}',
            type: 'reminder',
            title: daysUntilDue == 0
                ? 'Activity Due Today'
                : 'Activity Due Soon',
            message:
                '"${activity.title}" is due ${_relativeDueText(daysUntilDue)}.',
            createdAt: activity.dueDate,
          ),
        );
      }

      final submission = activity.submission;
      if (submission?.isReviewed == true) {
        notifications.add(
          DbNotification(
            id: 'review-${submission!.id}',
            type: 'review',
            title: 'Submission Reviewed',
            message:
                '"${activity.title}" was reviewed. Score: ${submission.scoreLabel}.',
            createdAt: submission.reviewedAt ?? submission.submittedAt,
          ),
        );
      }
    }
    return _sortNotifications(notifications);
  }

  static List<DbNotification> _buildTeacherNotifications(
    List<DbSubmission> submissions,
    List<DbGestureAlert> alerts,
  ) {
    final notifications = <DbNotification>[];
    for (final submission in submissions.where((item) => !item.isReviewed)) {
      notifications.add(
        DbNotification(
          id: 'submission-${submission.id}',
          type: 'submission',
          title: 'New Submission',
          message:
              '${submission.studentName} submitted "${submission.activityTitle}".',
          createdAt: submission.submittedAt,
        ),
      );
    }
    for (final alert in alerts) {
      notifications.add(
        DbNotification(
          id: 'alert-${alert.id}',
          type: 'alert',
          title: 'Gesture Alert',
          message:
              '${alert.studentName} reported ${alert.gestureTypeLabel} during "${alert.activityTitle}".',
          createdAt: alert.createdAt,
        ),
      );
    }
    return _sortNotifications(notifications);
  }

  static List<DbNotification> _buildParentNotifications(
    List<ParentChild> children,
  ) {
    final notifications = <DbNotification>[];
    for (final child in children) {
      for (final activity in child.activities) {
        final submission = activity.submission;
        if (submission?.isReviewed == true) {
          notifications.add(
            DbNotification(
              id: 'parent-review-${child.student.id}-${submission!.id}',
              type: 'review',
              title: '${child.student.name} Received Feedback',
              message:
                  '"${activity.title}" was reviewed. Score: ${submission.scoreLabel}.',
              createdAt: submission.reviewedAt ?? submission.submittedAt,
            ),
          );
          continue;
        }

        if (activity.isSubmitted) {
          notifications.add(
            DbNotification(
              id: 'parent-submitted-${child.student.id}-${activity.id}',
              type: 'submission',
              title: '${child.student.name} Submitted Work',
              message: '"${activity.title}" is waiting for teacher review.',
              createdAt: submission?.submittedAt,
            ),
          );
          continue;
        }

        final daysUntilDue = _daysUntil(activity.dueDate);
        if (daysUntilDue != null && daysUntilDue >= 0 && daysUntilDue <= 3) {
          notifications.add(
            DbNotification(
              id: 'parent-due-${child.student.id}-${activity.id}',
              type: 'reminder',
              title: '${child.student.name} Has Work Due',
              message:
                  '"${activity.title}" is due ${_relativeDueText(daysUntilDue)}.',
              createdAt: activity.dueDate,
            ),
          );
        }
      }
    }
    return _sortNotifications(notifications);
  }

  static List<DbNotification> _sortNotifications(
    List<DbNotification> notifications,
  ) {
    notifications.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return notifications.take(12).toList();
  }

  static List<DbNotification> _applyNotificationReadState(
    List<DbNotification> notifications,
    Set<String> readIds,
  ) {
    if (readIds.isEmpty) return notifications;
    return notifications
        .map((item) => item.copyWith(isRead: readIds.contains(item.id)))
        .toList();
  }

  static Future<Set<String>> fetchNotificationReadIds(String userId) async {
    try {
      final settings = await _fetchUserSettings(userId);
      final rawIds = settings['mobileNotificationReadIds'];
      if (rawIds is! List) return <String>{};
      return rawIds.map(_string).where((id) => id.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<DbResult> markNotificationsRead(
    String userId,
    List<String> notificationIds,
  ) async {
    final ids = notificationIds.where((id) => id.isNotEmpty).toSet();
    if (userId.isEmpty || ids.isEmpty) return const DbResult.success();

    try {
      final settings = await _fetchUserSettings(userId);
      final existing = settings['mobileNotificationReadIds'];
      final readIds = <String>{
        if (existing is List)
          ...existing.map(_string).where((id) => id.isNotEmpty),
        ...ids,
      }.toList();
      settings['mobileNotificationReadIds'] = readIds.take(200).toList();

      await _client.from('user_settings').upsert({
        'user_id': userId,
        'settings': settings,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<Map<String, dynamic>> _fetchUserSettings(String userId) async {
    final row = await _client
        .from('user_settings')
        .select('settings')
        .eq('user_id', userId)
        .maybeSingle();
    final settings = row?['settings'];
    if (settings is Map) return Map<String, dynamic>.from(settings);
    return <String, dynamic>{};
  }

  static Future<void> _updateClassStudentCount(String classId) async {
    final rows = _rows(
      await _client
          .from('class_students')
          .select('student_id')
          .eq('class_id', classId),
    );
    final count = rows
        .map((row) => _string(row['student_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;
    await _client
        .from('classes')
        .update({'student_count': count})
        .eq('id', classId);
  }

  static Future<DbStudent?> _fetchStudentByEmail(String email) async {
    final row = await _client
        .from('users')
        .select('id, name, email, role')
        .eq('email', email)
        .maybeSingle();
    if (row == null) return null;
    return DbStudent.fromUserRow(row);
  }

  static Future<void> _syncClassAssignmentsForStudent(
    String classId,
    String studentId,
  ) async {
    final activities = await fetchClassActivities(classId);
    if (activities.isEmpty) return;

    final activityIds = activities.map((activity) => activity.id).toList();
    final existingRows = _rows(
      await _client
          .from('activity_assignments')
          .select('activity_id')
          .eq('student_id', studentId)
          .inFilter('activity_id', activityIds),
    );
    final existingActivityIds = existingRows
        .map((row) => _string(row['activity_id']))
        .where((id) => id.isNotEmpty)
        .toSet();
    final inserts = activityIds
        .where((activityId) => !existingActivityIds.contains(activityId))
        .map(
          (activityId) => {
            'activity_id': activityId,
            'student_id': studentId,
            'status': 'pending',
          },
        )
        .toList();
    if (inserts.isNotEmpty) {
      await _client.from('activity_assignments').insert(inserts);
    }
  }

  static Future<void> _removeClassAssignmentsForStudent(
    String classId,
    String studentId,
  ) async {
    final activities = await fetchClassActivities(classId);
    if (activities.isEmpty) return;
    await _client
        .from('activity_assignments')
        .delete()
        .eq('student_id', studentId)
        .inFilter(
          'activity_id',
          activities.map((activity) => activity.id).toList(),
        );
  }

  static Future<List<String>> _fetchParentStudentIds(String parentId) async {
    for (final spec in const [
      ('parent_students', 'parent_id', 'student_id'),
      ('student_parents', 'parent_id', 'student_id'),
    ]) {
      try {
        final rows = _rows(
          await _client.from(spec.$1).select(spec.$3).eq(spec.$2, parentId),
        );
        final ids = rows
            .map((row) => _string(row[spec.$3]))
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        if (ids.isNotEmpty) return ids;
      } catch (_) {
        // Try the next supported parent link shape.
      }
    }

    try {
      final rows = _rows(
        await _client.from('users').select('id').eq('parent_id', parentId),
      );
      return rows
          .map((row) => _string(row['id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<DbStudent>> _fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = _rows(
      await _client
          .from('users')
          .select('id, name, email, role')
          .inFilter('id', ids),
    );
    return rows.map(DbStudent.fromUserRow).toList();
  }
}

class StudentBundle {
  const StudentBundle({
    required this.studentId,
    required this.activities,
    required this.artworks,
    required this.notifications,
  });

  final String studentId;
  final List<DbActivity> activities;
  final List<DbArtwork> artworks;
  final List<DbNotification> notifications;

  List<DbActivity> get pendingActivities =>
      activities.where((item) => !item.isSubmitted).toList();
  List<DbActivity> get submittedActivities =>
      activities.where((item) => item.isSubmitted && !item.isReviewed).toList();
  List<DbActivity> get reviewedActivities =>
      activities.where((item) => item.isReviewed).toList();
  int get completedCount => activities.where((item) => item.isSubmitted).length;

  String get averageScoreLabel {
    final scores = reviewedActivities
        .map((item) => item.submission?.score)
        .whereType<num>()
        .toList();
    if (scores.isEmpty) return 'N/A';
    final total = scores.fold<num>(0, (sum, score) => sum + score);
    return (total / scores.length).toStringAsFixed(1);
  }
}

class TeacherBundle {
  const TeacherBundle({
    required this.teacherId,
    required this.classes,
    required this.activities,
    required this.submissions,
    required this.gestureAlerts,
    required this.notifications,
  });

  final String teacherId;
  final List<DbClass> classes;
  final List<DbActivity> activities;
  final List<DbSubmission> submissions;
  final List<DbGestureAlert> gestureAlerts;
  final List<DbNotification> notifications;

  int get totalStudents =>
      classes.fold<int>(0, (sum, klass) => sum + klass.studentCount);
  List<DbSubmission> get pendingReviews =>
      submissions.where((item) => !item.isReviewed).toList();
}

class ParentBundle {
  const ParentBundle({
    required this.parentId,
    required this.children,
    required this.notifications,
  });

  final String parentId;
  final List<ParentChild> children;
  final List<DbNotification> notifications;

  int get pendingCount =>
      children.fold<int>(0, (sum, child) => sum + child.pendingCount);
  int get submittedCount =>
      children.fold<int>(0, (sum, child) => sum + child.submittedCount);
  int get reviewedCount =>
      children.fold<int>(0, (sum, child) => sum + child.reviewedCount);
}

class ParentChild {
  const ParentChild({required this.student, required this.activities});

  final DbStudent student;
  final List<DbActivity> activities;

  int get pendingCount => activities.where((item) => !item.isSubmitted).length;
  int get submittedCount => activities.where((item) => item.isSubmitted).length;
  int get reviewedCount => activities.where((item) => item.isReviewed).length;
  int get totalCount => activities.length;
  int get overdueCount => activities.where((item) => item.isOverdue).length;

  List<DbActivity> get pendingActivities =>
      activities.where((item) => !item.isSubmitted).toList();
  List<DbActivity> get reviewedActivities =>
      activities.where((item) => item.isReviewed).toList();

  DbActivity? get nextDueActivity {
    final pending =
        pendingActivities.where((item) => item.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return pending.isEmpty ? null : pending.first;
  }

  String get completionLabel {
    if (totalCount == 0) return '0%';
    return '${(submittedCount / totalCount * 100).round()}%';
  }

  String get averageScoreLabel {
    final scores = reviewedActivities
        .map((item) => item.submission?.score)
        .whereType<num>()
        .toList();
    if (scores.isEmpty) return 'N/A';
    final total = scores.fold<num>(0, (sum, score) => sum + score);
    return (total / scores.length).toStringAsFixed(1);
  }
}

class ClassDetailBundle {
  const ClassDetailBundle({required this.students, required this.activities});

  final List<DbStudent> students;
  final List<DbActivity> activities;
}

class DbClass {
  const DbClass({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.subject,
    this.studentCount = 0,
    this.activityCount = 0,
  });

  final String id;
  final String name;
  final String grade;
  final String section;
  final String subject;
  final int studentCount;
  final int activityCount;

  factory DbClass.fromRow(Map<String, dynamic> row) {
    return DbClass(
      id: _string(row['id']),
      name: _string(row['name'], fallback: 'Class'),
      grade: _string(row['grade']),
      section: _string(row['section']),
      subject: _string(row['subject']),
      studentCount: _int(row['student_count']),
    );
  }

  DbClass copyWith({int? studentCount, int? activityCount}) {
    return DbClass(
      id: id,
      name: name,
      grade: grade,
      section: section,
      subject: subject,
      studentCount: studentCount ?? this.studentCount,
      activityCount: activityCount ?? this.activityCount,
    );
  }

  String get displayName {
    final parts = [
      grade,
      section,
    ].where((item) => item.trim().isNotEmpty).join(' - ');
    if (name.isNotEmpty && parts.isNotEmpty) return '$parts: $name';
    return name.isNotEmpty ? name : parts;
  }

  String get subjectLabel => subject.isEmpty ? 'No subject' : subject;
  String get initial =>
      displayName.trim().isEmpty ? 'C' : displayName.trim()[0].toUpperCase();
}

class DbStudent {
  const DbStudent({
    required this.id,
    required this.name,
    required this.email,
    this.role = '',
  });

  final String id;
  final String name;
  final String email;
  final String role;

  factory DbStudent.fromEnrollmentRow(Map<String, dynamic> row) {
    return DbStudent(
      id: _string(row['student_id'], fallback: _string(row['id'])),
      name: _string(row['student_name'], fallback: 'Student'),
      email: _string(row['student_email']),
      role: 'student',
    );
  }

  factory DbStudent.fromUserRow(Map<String, dynamic> row) {
    final email = _string(row['email']);
    return DbStudent(
      id: _string(row['id']),
      name: _string(
        row['name'],
        fallback: email.isEmpty ? 'Student' : email.split('@').first,
      ),
      email: email,
      role: _string(row['role']),
    );
  }
}

class DbActivity {
  const DbActivity({
    required this.id,
    required this.title,
    required this.summary,
    required this.dueDate,
    required this.status,
    required this.imageUrl,
    required this.classId,
    required this.grade,
    required this.subject,
    required this.assignmentStatus,
    required this.assignedAt,
    required this.submission,
    this.assignmentCount = 0,
    this.submissionCount = 0,
    this.className = '',
  });

  final String id;
  final String title;
  final String summary;
  final DateTime? dueDate;
  final String status;
  final String imageUrl;
  final String classId;
  final String grade;
  final String subject;
  final String assignmentStatus;
  final DateTime? assignedAt;
  final DbSubmission? submission;
  final int assignmentCount;
  final int submissionCount;
  final String className;

  factory DbActivity.fromRow(
    Map<String, dynamic> row, {
    Map<String, dynamic>? assignment,
    DbSubmission? submission,
  }) {
    final parsedDescription = _parseActivityDescription(
      _string(row['description']),
    );
    final title = _string(row['title'], fallback: 'Untitled Activity');
    return DbActivity(
      id: _string(row['id']),
      title: title,
      summary: parsedDescription,
      dueDate: _date(row['due_date']),
      status: _normalizeStatus(row['status']),
      imageUrl: submission?.artworkUrl.isNotEmpty == true
          ? submission!.artworkUrl
          : _string(row['image_url']),
      classId: _string(row['class_id']),
      grade: _string(row['grade']),
      subject: _string(row['subject']),
      assignmentStatus: _normalizeStatus(assignment?['status']),
      assignedAt: _date(assignment?['assigned_at']),
      submission: submission?.copyWith(activityTitle: title),
    );
  }

  DbActivity copyWith({
    int? assignmentCount,
    int? submissionCount,
    String? className,
  }) {
    return DbActivity(
      id: id,
      title: title,
      summary: summary,
      dueDate: dueDate,
      status: status,
      imageUrl: imageUrl,
      classId: classId,
      grade: grade,
      subject: subject,
      assignmentStatus: assignmentStatus,
      assignedAt: assignedAt,
      submission: submission,
      assignmentCount: assignmentCount ?? this.assignmentCount,
      submissionCount: submissionCount ?? this.submissionCount,
      className: className ?? this.className,
    );
  }

  bool get isReviewed => submission?.isReviewed ?? false;
  bool get isSubmitted => submission?.isSubmitted ?? false;
  bool get isOverdue =>
      !isSubmitted && dueDate != null && dueDate!.isBefore(DateTime.now());

  String get studentStatusLabel {
    if (isReviewed) return 'Reviewed';
    if (isSubmitted) return 'Submitted';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }

  String get subjectLabel => subject.isEmpty ? 'N/A' : subject;
  String get gradeLabel => grade.isEmpty ? 'N/A' : grade;
}

class DbSubmission {
  const DbSubmission({
    required this.id,
    required this.activityId,
    required this.studentId,
    required this.activityTitle,
    required this.studentName,
    required this.studentEmail,
    required this.artworkUrl,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
    required this.score,
    required this.feedback,
  });

  final String id;
  final String activityId;
  final String studentId;
  final String activityTitle;
  final String studentName;
  final String studentEmail;
  final String artworkUrl;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final num? score;
  final String feedback;

  factory DbSubmission.fromRow(Map<String, dynamic> row) {
    return DbSubmission(
      id: _string(row['id']),
      activityId: _string(row['activity_id']),
      studentId: _string(row['student_id']),
      activityTitle: 'Activity',
      studentName: 'Student',
      studentEmail: '',
      artworkUrl: _string(row['artwork_url']),
      status: _normalizeStatus(row['status']),
      submittedAt: _date(row['submitted_at']),
      reviewedAt: _date(row['reviewed_at']),
      score: _num(row['score']),
      feedback: _string(row['feedback']),
    );
  }

  DbSubmission copyWith({
    String? activityTitle,
    String? studentName,
    String? studentEmail,
  }) {
    return DbSubmission(
      id: id,
      activityId: activityId,
      studentId: studentId,
      activityTitle: activityTitle ?? this.activityTitle,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      artworkUrl: artworkUrl,
      status: status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      score: score,
      feedback: feedback,
    );
  }

  bool get isReviewed =>
      reviewedAt != null ||
      {'reviewed', 'graded', 'completed'}.contains(status);
  bool get isSubmitted =>
      submittedAt != null ||
      {'submitted', 'late', 'reviewed', 'graded', 'completed'}.contains(status);
  String get scoreLabel => score == null ? 'N/A' : score.toString();
  String get reviewStatusLabel => isReviewed ? 'Reviewed' : 'Needs review';
}

class DbArtwork {
  const DbArtwork({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.submissionId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String submissionId;
  final DateTime? createdAt;

  factory DbArtwork.fromRow(Map<String, dynamic> row) {
    return DbArtwork(
      id: _string(row['id']),
      title: _string(row['title'], fallback: 'Artwork'),
      imageUrl: _string(row['image_url']),
      submissionId: _string(row['submission_id']),
      createdAt: _date(row['created_at']),
    );
  }
}

class DbGestureAlert {
  const DbGestureAlert({
    required this.id,
    required this.studentName,
    required this.activityTitle,
    required this.gestureType,
    required this.createdAt,
  });

  final String id;
  final String studentName;
  final String activityTitle;
  final String gestureType;
  final DateTime? createdAt;

  factory DbGestureAlert.fromRow(Map<String, dynamic> row) {
    return DbGestureAlert(
      id: _string(row['id']),
      studentName: _string(row['student_name'], fallback: 'Student'),
      activityTitle: _string(row['activity_title'], fallback: 'Activity'),
      gestureType: _string(row['gesture_type'], fallback: 'gesture'),
      createdAt: _date(row['created_at']),
    );
  }

  String get gestureTypeLabel => gestureType.replaceAll('_', ' ');
}

class DbNotification {
  const DbNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  DbNotification copyWith({bool? isRead}) {
    return DbNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class DbResult {
  const DbResult._({required this.success, this.error});
  const DbResult.success() : this._(success: true);
  const DbResult.failure(String error) : this._(success: false, error: error);

  final bool success;
  final String? error;
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return [];
}

Map<String, int> _countBy(List<Map<String, dynamic>> rows, String key) {
  final counts = <String, int>{};
  for (final row in rows) {
    final id = _string(row[key]);
    if (id.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _normalizeStatus(Object? value) =>
    _string(value).toLowerCase().replaceAll(' ', '_');

String _normalizeRole(Object? value) {
  return _string(
    value,
  ).toLowerCase().replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

num? _num(Object? value) {
  if (value is num) return value;
  return num.tryParse(_string(value));
}

DateTime? _date(Object? value) {
  final text = _string(value);
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

String _formatDate(DateTime? date) =>
    date == null ? 'No due date' : _dateFormatter.format(date);

String _formatDateTime(DateTime? date) =>
    date == null ? 'N/A' : _dateTimeFormatter.format(date);

int? _daysUntil(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays;
}

String _relativeDueText(int days) {
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}

IconData _notificationIcon(String type) {
  switch (type) {
    case 'assignment':
      return Icons.assignment_turned_in_outlined;
    case 'review':
      return Icons.grade_outlined;
    case 'submission':
      return Icons.inbox_outlined;
    case 'alert':
      return Icons.warning_amber_outlined;
    case 'reminder':
    default:
      return Icons.notifications_none_rounded;
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'E';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

LinearGradient _pastelGradient(String seed) {
  const palettes = [
    [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
    [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
  ];
  final index =
      seed.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: palettes[index],
  );
}

String _parseActivityDescription(String description) {
  final text = description.trim();
  if (!text.startsWith('{')) return description;
  try {
    final parsed = Map<String, dynamic>.from(jsonDecode(text) as Map);
    if (parsed['tag'] == 'activity_ar_v1') {
      return _string(parsed['summary']);
    }
  } catch (_) {
    return description;
  }
  return description;
}

String _encodeActivityDescription(String summary) {
  return summary;
}
