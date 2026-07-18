import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const brandBlue = Color(0xFF1800AD);
const brandBlueDark = Color(0xFF13008C);
const brandBlueText = Color(0xFF2F4F90);
const brandBrown = Color(0xFF8A7561);
const textPrimary = Color(0xFF141217);
const textStrong = Color(0xFF0D141C);
const textMuted = Color(0xFF4B5563);
const textMutedBlue = Color(0xFF4D7399);
const borderColor = Color(0xFFE6E0DB);
const borderSoft = Color(0xFFF5F2F0);
const surfaceColor = Color(0xFFFFFFFF);
const pageBackgroundTop = Color(0xFFF7F5F3);
const pageBackgroundBottom = Color(0xFFF8F7F5);
const panelColor = Color(0xFFFDFCFB);
const pillBg = Color(0xFFF0EEFC);
const pillText = Color(0xFF1800AD);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ElikhaApp());
}

class ElikhaApp extends StatelessWidget {
  const ElikhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Likha',
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: brandBlue,
          secondary: brandBrown,
          surface: surfaceColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: surfaceColor,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          baseTheme.textTheme,
        ).apply(bodyColor: textPrimary, displayColor: textPrimary),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceColor,
          surfaceTintColor: surfaceColor,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF5C6CB)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF5C6CB), width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderColor),
          ),
          margin: EdgeInsets.zero,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return brandBlue;
            }
            return const Color(0xFFCBD5E1);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return pillBg;
            }
            return const Color(0xFFE5E7EB);
          }),
        ),
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AppSession.loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user != null) {
          return MainShell(user: user);
        }

        return LandingPage(
          onGetStarted: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LoginPage(
                  onSignedIn: (user) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => MainShell(user: user),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: brandBlue)),
    );
  }
}

class AppSession {
  static const String _userKey = 'userInfo';

  static Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser.fromJson(decoded);
  }

  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}

class AppUser {
  const AppUser({required this.name, required this.grade, required this.email});

  final String name;
  final int grade;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] as String? ?? '',
      grade: json['grade'] as int? ?? 1,
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'grade': grade, 'email': email};
  }
}

class ClassItem {
  const ClassItem({
    required this.id,
    required this.name,
    required this.grade,
    required this.students,
    required this.pending,
    required this.color,
    required this.icon,
    required this.studentList,
  });

  final int id;
  final String name;
  final String grade;
  final int students;
  final int pending;
  final Color color;
  final String icon;
  final List<StudentEntry> studentList;
}

class StudentEntry {
  const StudentEntry({
    required this.id,
    required this.name,
    required this.status,
  });

  final int id;
  final String name;
  final String status;
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.className,
    required this.dueDate,
    required this.status,
    required this.submissions,
    required this.pending,
    required this.chip,
    required this.description,
    required this.materials,
  });

  final int id;
  final String title;
  final String className;
  final String dueDate;
  final String status;
  final int submissions;
  final int pending;
  final String chip;
  final String description;
  final List<String> materials;
}

class SubmissionItem {
  const SubmissionItem({
    required this.title,
    required this.student,
    required this.klass,
    required this.status,
    required this.type,
    required this.time,
  });

  final String title;
  final String student;
  final String klass;
  final String status;
  final String type;
  final String time;
}

class ReviewItem {
  const ReviewItem({
    required this.student,
    required this.activity,
    required this.score,
    required this.status,
    required this.comment,
  });

  final String student;
  final String activity;
  final String score;
  final String status;
  final String comment;
}

enum StudentSortOption { nameAsc, nameDesc, classAsc, activityCountDesc }

class StudentDirectoryEntry {
  const StudentDirectoryEntry({
    required this.student,
    required this.className,
    required this.classColor,
    required this.present,
    required this.activities,
    required this.completedCount,
    required this.pendingCount,
    required this.lateCount,
    required this.progress,
    required this.artworkPaths,
  });

  final StudentEntry student;
  final String className;
  final Color classColor;
  final bool present;
  final List<ActivityItem> activities;
  final int completedCount;
  final int pendingCount;
  final int lateCount;
  final double progress;
  final List<String> artworkPaths;
}

List<StudentDirectoryEntry> buildStudentDirectoryEntries() {
  final activities = buildDemoActivities();
  final entries = <StudentDirectoryEntry>[];

  for (final classItem in demoClasses) {
    for (final student in classItem.studentList) {
      final seed = student.name.codeUnits.fold<int>(0, (sum, c) => sum + c);
      final activityCount = (seed % 3) + 1;
      final start = seed % activities.length;
      final completedCount = seed % (activityCount + 1);
      final remainingCount = activityCount - completedCount;
      final lateCount =
          remainingCount == 0 ? 0 : (seed ~/ 3) % (remainingCount + 1);
      final pendingCount = remainingCount - lateCount;
      final progress =
          activityCount == 0 ? 0.0 : completedCount / activityCount;
      final artworkPaths =
          seed % 2 == 0
          ? const ['assets/images/elikhalogo.png']
          : const [
              'assets/images/elikhalogolarge.png',
              'assets/images/elikhalogo.png',
            ];

      final assignedActivities = List<ActivityItem>.generate(activityCount, (
        index,
      ) {
        final activityIndex = (start + index) % activities.length;
        return activities[activityIndex];
      });

      entries.add(
        StudentDirectoryEntry(
          student: student,
          className: classItem.name,
          classColor: classItem.color,
          present: seed % 4 != 0,
          activities: assignedActivities,
          completedCount: completedCount,
          pendingCount: pendingCount,
          lateCount: lateCount,
          progress: progress,
          artworkPaths: artworkPaths,
        ),
      );
    }
  }

  return entries;
}

const demoUser = AppUser(
  name: 'Ms. Dela Cruz',
  grade: 1,
  email: 'teacher@elikha.com',
);

const demoClasses = <ClassItem>[
  ClassItem(
    id: 1,
    name: 'Grade 1 - 101',
    grade: 'Grade 1',
    students: 24,
    pending: 3,
    color: brandBlue,
    icon: 'G',
    studentList: [
      StudentEntry(id: 1, name: 'Liam', status: 'active'),
      StudentEntry(id: 2, name: 'Emma', status: 'active'),
      StudentEntry(id: 3, name: 'Noah', status: 'active'),
      StudentEntry(id: 4, name: 'Olivia', status: 'active'),
    ],
  ),
  ClassItem(
    id: 2,
    name: 'Grade 1 - 102',
    grade: 'Grade 1',
    students: 22,
    pending: 5,
    color: brandBrown,
    icon: 'G',
    studentList: [
      StudentEntry(id: 1, name: 'Sophia', status: 'active'),
      StudentEntry(id: 2, name: 'James', status: 'active'),
      StudentEntry(id: 3, name: 'Charlotte', status: 'active'),
    ],
  ),
  ClassItem(
    id: 3,
    name: 'Grade 2 - 201',
    grade: 'Grade 2',
    students: 18,
    pending: 1,
    color: Color(0xFF1C170D),
    icon: 'K',
    studentList: [
      StudentEntry(id: 1, name: 'Benjamin', status: 'active'),
      StudentEntry(id: 2, name: 'Amelia', status: 'active'),
    ],
  ),
];

List<ActivityItem> buildDemoActivities() {
  return const [
    ActivityItem(
      id: 1,
      title: 'Create Activity: Paper Mache Masks',
      className: 'Grade 3 - Art',
      dueDate: '2026-02-02',
      status: 'Needs review',
      submissions: 12,
      pending: 3,
      chip: 'Upcoming',
      description:
          'Create a paper mache mask inspired by Filipino festivals and mask traditions.',
      materials: ['Paper strips', 'Glue', 'Paint', 'Brushes'],
    ),
    ActivityItem(
      id: 2,
      title: 'Clay Sculpture Basics',
      className: 'Grade 5 - Crafts',
      dueDate: '2026-01-30',
      status: 'In review',
      submissions: 18,
      pending: 5,
      chip: 'Due soon',
      description:
          'Practice shaping simple forms with air-dry clay and texture tools.',
      materials: ['Air-dry clay', 'Sculpting tools', 'Mat'],
    ),
    ActivityItem(
      id: 3,
      title: 'Origami Creatures',
      className: 'Grade 1 - Studio',
      dueDate: '2026-01-25',
      status: 'Past due',
      submissions: 10,
      pending: 2,
      chip: 'Past due',
      description:
          'Fold origami animals and decorate them with patterns inspired by local crafts.',
      materials: ['Origami paper', 'Markers'],
    ),
    ActivityItem(
      id: 4,
      title: 'Mixed Media Collage',
      className: 'Grade 2 - Crafts',
      dueDate: '2026-02-07',
      status: 'Open',
      submissions: 0,
      pending: 0,
      chip: 'Upcoming',
      description:
          'Combine cut paper, paint, and texture to build a small mixed media collage.',
      materials: ['Paper', 'Glue', 'Paint', 'Scraps'],
    ),
  ];
}

const recentSubmissions = <SubmissionItem>[
  SubmissionItem(
    title: "Submitted 'Origami Crane'",
    student: 'Liam',
    klass: 'Grade 1 - Art',
    status: 'Needs review',
    type: 'submitted',
    time: '10m ago',
  ),
  SubmissionItem(
    title: "Completed 'Soap Carving'",
    student: 'Olivia',
    klass: 'Grade 2 - Crafts',
    status: 'Completed',
    type: 'completed',
    time: '1h ago',
  ),
  SubmissionItem(
    title: "Submitted 'Clay Sculpture'",
    student: 'Noah',
    klass: 'Kinder - Studio',
    status: 'Needs review',
    type: 'submitted',
    time: 'Today',
  ),
];

const reviewItems = <ReviewItem>[
  ReviewItem(
    student: 'Sophia Clark',
    activity: 'Watercolor Landscape',
    score: '95',
    status: 'completed',
    comment: 'Strong composition and confident brushwork.',
  ),
  ReviewItem(
    student: 'James Cruz',
    activity: 'Origami Fish',
    score: '88',
    status: 'pending',
    comment: 'Needs a short note on folding accuracy.',
  ),
  ReviewItem(
    student: 'Charlotte Reyes',
    activity: 'Paper Mache Mask',
    score: '91',
    status: 'completed',
    comment: 'Color palette matches the activity theme well.',
  ),
];

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [pageBackgroundTop, surfaceColor, pageBackgroundBottom],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/elikhalogo.png', height: 54),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F141217),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/elikhalogolarge.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'e-Likha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AR-Powered Arts & Crafts Simulator',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: textMutedBlue),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Immerse yourself in Filipino culture through interactive art and craft experiences',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: textMuted),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Why Choose e-Likha?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const _FeatureGrid(),
              const SizedBox(height: 28),
              const _AboutSection(),
              const SizedBox(height: 28),
              const _FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.palette_outlined,
        'Interactive Learning',
        'Engage with hands-on art activities that bring Filipino culture to life',
      ),
      (
        Icons.phone_iphone_outlined,
        'AR Technology',
        'Experience augmented reality that makes learning more immersive and fun',
      ),
      (
        Icons.emoji_events_outlined,
        'Track Progress',
        'Monitor your artistic journey and achievements as you create',
      ),
      (
        Icons.my_library_books_outlined,
        'Cultural Heritage',
        'Learn about traditional Filipino arts and crafts in a modern way',
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: features
          .map(
            (feature) => SizedBox(
              width: (MediaQuery.of(context).size.width - 62) / 2,
              child: _FeatureCard(
                icon: feature.$1,
                title: feature.$2,
                body: feature.$3,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C141217),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandBlue, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About e-Likha',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'e-Likha is an innovative educational platform that combines traditional Filipino arts and crafts with augmented reality. Its goal is to preserve and promote Filipino cultural heritage through interactive and engaging learning experiences for students of all ages.',
            style: TextStyle(fontSize: 15, color: textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'e-Likha',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Empowering creativity through technology',
            style: TextStyle(color: textMuted),
          ),
          SizedBox(height: 16),
          Text('info@elikha.com', style: TextStyle(color: textMutedBlue)),
          SizedBox(height: 4),
          Text(
            'Copyright 2026 e-Likha. All rights reserved.',
            style: TextStyle(color: textMuted),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSignedIn});

  final ValueChanged<AppUser> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    final rawEmail = _emailController.text.trim();
    final email = rawEmail.isEmpty ? 'student@elikha.com' : rawEmail;
    final user = AppUser(name: email.split('@').first, grade: 1, email: email);

    await AppSession.saveUser(user);
    if (!mounted) {
      return;
    }
    widget.onSignedIn(user);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [pageBackgroundTop, surfaceColor, pageBackgroundBottom],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Image.asset(
                    'assets/images/elikhalogo.png',
                    height: 58,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to continue your learning journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: textMutedBlue),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C141217),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textStrong,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'student@example.com',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textStrong,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Enter your password',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: brandBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Back to landing page',
                    style: TextStyle(color: textMutedBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the email address associated with your account.',
                    style: TextStyle(color: textMutedBlue),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'student@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user, this.onLogout});

  final AppUser user;
  final Future<void> Function()? onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _logout() async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
      return;
    }

    await AppSession.clear();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const BootstrapScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardTab(user: widget.user),
      ClassesTab(
        onOpenClass: (classItem) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ClassDetailsPage(classItem: classItem),
            ),
          );
        },
      ),
      ActivitiesTab(
        onOpenActivity: (activity) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ActivityDetailsPage(activity: activity),
            ),
          );
        },
      ),
      ReviewsTab(
        onOpenSettings: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => SettingsPage(onLogout: _logout)),
          );
        },
      ),
      ProfileTab(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        titleSpacing: 24,
        title: Image.asset('assets/images/elikhalogo.png', height: 32),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SettingsPage(onLogout: _logout)),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: textPrimary),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderSoft),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pageBackgroundTop, surfaceColor, pageBackgroundBottom],
          ),
        ),
        child: pages[_index],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: brandBlueDark,
          unselectedItemColor: brandBlueText,
          backgroundColor: surfaceColor,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              label: 'Classes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              label: 'Reviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final summary = [
      ('Total Students', '64'),
      ('Pending Reviews', '9'),
      ('Upcoming Deadlines', '4'),
      ('Parent Alerts', '2'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _PageHeader(
          eyebrow: 'Teacher',
          title: user.name,
          subtitle: 'Manage your classes and student submissions.',
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Classes', actionLabel: 'Manage classes'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 88,
            mainAxisSpacing: 12,
          ),
          itemCount: demoClasses.length,
          itemBuilder: (context, index) {
            final klass = demoClasses[index];
            return _ClassCard(classItem: klass);
          },
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Summary'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          physics: const NeverScrollableScrollPhysics(),
          children: summary
              .map((item) => _SummaryCard(label: item.$1, value: item.$2))
              .toList(),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Recent Submissions'),
        const SizedBox(height: 12),
        ...recentSubmissions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubmissionTile(item: item),
          ),
        ),
      ],
    );
  }
}

class ClassesTab extends StatelessWidget {
  const ClassesTab({super.key, required this.onOpenClass});

  final ValueChanged<ClassItem> onOpenClass;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _PageHeader(
          eyebrow: 'Classes',
          title: 'Manage Classes',
          subtitle: 'View and manage your classes, students, and activities.',
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New Class'),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...demoClasses.map(
          (classItem) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ClassListTile(
              classItem: classItem,
              onTap: () => onOpenClass(classItem),
            ),
          ),
        ),
      ],
    );
  }
}

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key, required this.onOpenActivity});

  final ValueChanged<ActivityItem> onOpenActivity;

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  late List<ActivityItem> _activities;
  String _activeFilter = 'upcoming';

  @override
  void initState() {
    super.initState();
    _activities = buildDemoActivities();
  }

  List<ActivityItem> get _filteredActivities {
    switch (_activeFilter) {
      case 'all':
        return _activities;
      case 'past-due':
        return _activities.where((item) => item.chip == 'Past due').toList();
      case 'review':
        return _activities
            .where(
              (item) =>
                  item.status == 'Needs review' || item.status == 'In review',
            )
            .toList();
      default:
        return _activities
            .where((item) => item.chip == 'Upcoming' || item.chip == 'Due soon')
            .toList();
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<ActivityItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return CreateActivitySheet(existingCount: _activities.length);
      },
    );

    if (created != null) {
      setState(() {
        _activities = [..._activities, created];
        _activeFilter = 'all';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _PageHeader(
          eyebrow: 'Teacher',
          title: 'Assignments',
          subtitle: 'Create, schedule, and review student submissions.',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _openCreateSheet,
          icon: const Icon(Icons.add),
          label: const Text('Create Activity'),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChip(
                label: 'Upcoming',
                selected: _activeFilter == 'upcoming',
                onTap: () => setState(() => _activeFilter = 'upcoming'),
              ),
              _FilterChip(
                label: 'In Review',
                selected: _activeFilter == 'review',
                onTap: () => setState(() => _activeFilter = 'review'),
              ),
              _FilterChip(
                label: 'Past Due',
                selected: _activeFilter == 'past-due',
                onTap: () => setState(() => _activeFilter = 'past-due'),
              ),
              _FilterChip(
                label: 'All',
                selected: _activeFilter == 'all',
                onTap: () => setState(() => _activeFilter = 'all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredActivities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActivityCard(
              activity: activity,
              onTap: () => widget.onOpenActivity(activity),
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _PageHeader(
          eyebrow: 'Teacher',
          title: 'Reviews',
          subtitle: 'Check submission quality and leave feedback.',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.tune),
          label: const Text('Open Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...reviewItems.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCard(review: review),
          ),
        ),
      ],
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.user});

  final AppUser user;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final TextEditingController _searchController = TextEditingController();
  late final List<StudentDirectoryEntry> _allStudents;

  String _search = '';
  String _selectedClass = 'All classes';
  String _presenceFilter = 'All';
  StudentSortOption _sortOption = StudentSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _allStudents = buildStudentDirectoryEntries();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentDirectoryEntry> get _filteredStudents {
    final filtered = _allStudents.where((entry) {
      final matchesSearch =
          _search.isEmpty ||
          entry.student.name.toLowerCase().contains(_search) ||
          entry.className.toLowerCase().contains(_search);

      final matchesClass =
          _selectedClass == 'All classes' || entry.className == _selectedClass;

      final matchesPresence =
          _presenceFilter == 'All' ||
          (_presenceFilter == 'Present' && entry.present) ||
          (_presenceFilter == 'Absent' && !entry.present);

      return matchesSearch && matchesClass && matchesPresence;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case StudentSortOption.nameAsc:
          return a.student.name.compareTo(b.student.name);
        case StudentSortOption.nameDesc:
          return b.student.name.compareTo(a.student.name);
        case StudentSortOption.classAsc:
          return a.className.compareTo(b.className);
        case StudentSortOption.activityCountDesc:
          return b.activities.length.compareTo(a.activities.length);
      }
    });

    return filtered;
  }

  List<String> get _classOptions {
    final classes = _allStudents.map((entry) => entry.className).toSet().toList()
      ..sort();
    return ['All classes', ...classes];
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _PageHeader(
          eyebrow: 'Profile',
          title: 'Student Profile',
          subtitle:
            'View students per class, check presence, and monitor activities, progress, and artwork.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Students',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name or class',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: _classOptions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedClass = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _presenceFilter,
                      decoration: const InputDecoration(labelText: 'Presence'),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'Present',
                          child: Text('Present'),
                        ),
                        DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _presenceFilter = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StudentSortOption>(
                initialValue: _sortOption,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(
                    value: StudentSortOption.nameAsc,
                    child: Text('Name (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: StudentSortOption.nameDesc,
                    child: Text('Name (Z-A)'),
                  ),
                  DropdownMenuItem(
                    value: StudentSortOption.classAsc,
                    child: Text('Class (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: StudentSortOption.activityCountDesc,
                    child: Text('Most Activities'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: brandBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email,
                style: const TextStyle(color: textMutedBlue),
              ),
              const SizedBox(height: 10),
              const _StatusPill(label: 'Teacher View', tone: _PillTone.neutral),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${students.length} student${students.length == 1 ? '' : 's'} found',
          style: const TextStyle(color: textMutedBlue, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (students.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: const Text(
              'No students match your current search/filter settings.',
              style: TextStyle(color: textMutedBlue),
            ),
          )
        else
          ...students.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StudentProfileCard(entry: entry),
            ),
          ),
      ],
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  const _StudentProfileCard({required this.entry});

  final StudentDirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          entry.student.name,
          style: const TextStyle(fontWeight: FontWeight.w700, color: textStrong),
        ),
        subtitle: Text(
          entry.className,
          style: const TextStyle(color: textMutedBlue),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: entry.classColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              entry.student.name[0],
              style: TextStyle(
                color: entry.classColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        trailing: _StatusPill(
          label: entry.present ? 'Present' : 'Absent',
          tone: entry.present ? _PillTone.success : _PillTone.warning,
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: 'Completed ${entry.completedCount}',
                tone: _PillTone.success,
              ),
              _StatusPill(
                label: 'Pending ${entry.pendingCount}',
                tone: _PillTone.neutral,
              ),
              _StatusPill(
                label: 'Late ${entry.lateCount}',
                tone: _PillTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textStrong,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(entry.progress * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textMutedBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: entry.progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(brandBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Artwork',
              style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.artworkPaths.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Container(
                  width: 88,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Image.asset(
                    entry.artworkPaths[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Student Activities',
              style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          ...entry.activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textStrong,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due ${activity.dueDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMutedBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: activity.status,
                      tone: _toneFromStatus(activity.status),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _musicOn = true;
  bool _sfxOn = true;
  bool _notificationsOn = true;
  bool _dataSaverOn = false;
  String _quality = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PageHeader(
            eyebrow: 'Settings',
            title: 'App Preferences',
            subtitle: 'Tune your learning experience and notifications.',
          ),
          const SizedBox(height: 16),
          _ToggleCard(
            title: 'Audio',
            subtitle: 'Background music and sound effects',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Music'),
                value: _musicOn,
                onChanged: (value) => setState(() => _musicOn = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound Effects'),
                value: _sfxOn,
                onChanged: (value) => setState(() => _sfxOn = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Notifications',
            subtitle: 'Control alerts and low-data mode',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                value: _notificationsOn,
                onChanged: (value) => setState(() => _notificationsOn = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data Saver'),
                value: _dataSaverOn,
                onChanged: (value) => setState(() => _dataSaverOn = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Quality',
            subtitle: 'Choose playback and asset quality',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _quality,
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _quality = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Clear the current session',
            onTap: () async {
              final onLogout = widget.onLogout;
              if (onLogout != null) {
                await onLogout();
              }
            },
          ),
        ],
      ),
    );
  }
}

class ClassDetailsPage extends StatelessWidget {
  const ClassDetailsPage({super.key, required this.classItem});

  final ClassItem classItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classItem.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: classItem.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      classItem.icon,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classItem.grade,
                        style: const TextStyle(color: textMutedBlue),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classItem.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Students',
                  value: '${classItem.students}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Pending',
                  value: '${classItem.pending}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Students'),
          const SizedBox(height: 12),
          ...classItem.studentList.map(
            (student) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StudentTile(student: student),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityDetailsPage extends StatelessWidget {
  const ActivityDetailsPage({super.key, required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(
                  label: activity.chip,
                  tone: _toneFromStatus(activity.status),
                ),
                const SizedBox(height: 12),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.className,
                  style: const TextStyle(color: textMutedBlue),
                ),
                const SizedBox(height: 12),
                Text(activity.description, style: const TextStyle(height: 1.6)),
                const SizedBox(height: 16),
                const Text(
                  'Materials',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activity.materials
                      .map((item) => Chip(label: Text(item)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(label: 'Due', value: activity.dueDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Submissions',
                  value: '${activity.submissions}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(label: 'Pending', value: '${activity.pending}'),
        ],
      ),
    );
  }
}

class CreateActivitySheet extends StatefulWidget {
  const CreateActivitySheet({super.key, required this.existingCount});

  final int existingCount;

  @override
  State<CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<CreateActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _classController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _classController.dispose();
    _dueDateController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      ActivityItem(
        id: widget.existingCount + 1,
        title: _titleController.text.trim(),
        className: _classController.text.trim(),
        dueDate: _dueDateController.text.trim().isEmpty
            ? '2026-02-15'
            : _dueDateController.text.trim(),
        status: 'Open',
        submissions: 0,
        pending: 0,
        chip: 'Upcoming',
        description: _descriptionController.text.trim().isEmpty
            ? _instructionsController.text.trim()
            : _descriptionController.text.trim(),
        materials: const ['Paper', 'Glue'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Create New Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Activity Title'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Activity Description',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _classController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a class name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Activity',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPill(label: eyebrow, tone: _PillTone.info),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: textMutedBlue,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: () {},
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classItem});

  final ClassItem classItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: classItem.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                classItem.icon,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  classItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${classItem.students} students',
                  style: const TextStyle(fontSize: 14, color: textMutedBlue),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: '${classItem.pending} pending',
            tone: _PillTone.warning,
          ),
        ],
      ),
    );
  }
}

class _ClassListTile extends StatelessWidget {
  const _ClassListTile({required this.classItem, required this.onTap});

  final ClassItem classItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: classItem.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  classItem.icon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classItem.students} students • ${classItem.pending} pending',
                    style: const TextStyle(color: textMutedBlue),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: textMutedBlue),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final ActivityItem activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusPill(
              label: activity.chip,
              tone: _toneFromChip(activity.chip),
            ),
            const SizedBox(height: 10),
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activity.className,
              style: const TextStyle(color: textMutedBlue),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniMeta(label: 'Due', value: activity.dueDate),
                const SizedBox(width: 14),
                _MiniMeta(
                  label: 'Submissions',
                  value: '${activity.submissions}',
                ),
                const SizedBox(width: 14),
                _MiniMeta(label: 'Pending', value: '${activity.pending}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.item});

  final SubmissionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.type == 'completed'
                  ? Icons.check
                  : Icons.file_upload_outlined,
              color: brandBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.student} · ${item.klass} · ${item.time}',
                  style: const TextStyle(color: textMutedBlue, fontSize: 14),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: item.status,
            tone: item.type == 'completed' ? _PillTone.success : _PillTone.info,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewItem review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.student,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.activity,
                      style: const TextStyle(color: textMutedBlue),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: review.status == 'completed' ? 'Completed' : 'Pending',
                tone: review.status == 'completed'
                    ? _PillTone.success
                    : _PillTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    review.score,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: brandBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.comment,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final StudentEntry student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: brandBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StatusPill(label: student.status, tone: _PillTone.neutral),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: textMutedBlue, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textMutedBlue),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: textMutedBlue)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: textMutedBlue)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: textMutedBlue),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PillTone { success, warning, neutral, info }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      _PillTone.success => (
        const Color(0xFFECFDF3),
        const Color(0xFF0F6B2D),
        const Color(0xFFBBF7D0),
      ),
      _PillTone.warning => (
        const Color(0xFFFFF7ED),
        const Color(0xFFB45309),
        const Color(0xFFFFEDD5),
      ),
      _PillTone.neutral => (
        const Color(0xFFEEF2FF),
        const Color(0xFF4338CA),
        const Color(0xFFE0E7FF),
      ),
      _PillTone.info => (pillBg, pillText, const Color(0xFFE5E7EB)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

_PillTone _toneFromChip(String chip) {
  switch (chip) {
    case 'Past due':
      return _PillTone.warning;
    case 'Due soon':
      return _PillTone.info;
    case 'Upcoming':
      return _PillTone.info;
    default:
      return _PillTone.neutral;
  }
}

_PillTone _toneFromStatus(String status) {
  if (status == 'Past due') {
    return _PillTone.warning;
  }
  if (status == 'Open') {
    return _PillTone.neutral;
  }
  return _PillTone.success;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: brandBlue,
      backgroundColor: panelColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : textMuted,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? brandBlue : borderColor),
      ),
    );
  }
}
