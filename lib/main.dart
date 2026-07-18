import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mobile_database_app.dart';
import 'roles/student/services/session_service.dart' as student_session;
import 'roles/teacher/app.dart' as teacher_app;

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase configuration. Provide SUPABASE_URL and '
      'SUPABASE_ANON_KEY with --dart-define or --dart-define-from-file.',
    );
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const ElikhaMobileApp());
}

class ElikhaMobileApp extends StatefulWidget {
  const ElikhaMobileApp({super.key});

  @override
  State<ElikhaMobileApp> createState() => _ElikhaMobileAppState();
}

class _ElikhaMobileAppState extends State<ElikhaMobileApp> {
  Key _gateKey = UniqueKey();

  void _reloadGate() {
    setState(() {
      _gateKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Likha Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1800AD)),
        scaffoldBackgroundColor: const Color(0xFFF8F7F5),
      ),
      home: AuthGate(key: _gateKey, onAuthChanged: _reloadGate),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.onAuthChanged});

  final VoidCallback onAuthChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MobileUser?>(
      future: AuthService.currentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(onSignedIn: onAuthChanged);
        }

        return RoleHome(user: user, onSignedOut: onAuthChanged);
      },
    );
  }
}

class RoleHome extends StatelessWidget {
  const RoleHome({super.key, required this.user, required this.onSignedOut});

  final MobileUser user;
  final VoidCallback onSignedOut;

  Future<void> _signOut() async {
    await AuthService.signOut();
    onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case 'student':
        return StudentDatabaseShell(
          userId: user.id,
          name: user.name,
          email: user.email,
          gradeLabel: user.gradeLabel,
          onSignedOut: _signOut,
        );
      case 'teacher':
        return TeacherDatabaseShell(
          userId: user.id,
          name: user.name,
          email: user.email,
          onSignedOut: _signOut,
        );
      case 'parent':
        return ParentDatabaseShell(
          userId: user.id,
          name: user.name,
          email: user.email,
          onSignedOut: _signOut,
        );
      default:
        return UnsupportedRoleScreen(role: user.role, onSignedOut: _signOut);
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.error;
      });
      return;
    }

    widget.onSignedIn();
  }

  Future<void> _requestPasswordReset() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    var loading = false;
    String? message;
    var isError = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Password Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your registered email. A super admin must approve the request before a reset link is sent.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFB42318)
                        : const Color(0xFF067647),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        message = null;
                      });

                      final result = await AuthService.checkPasswordResetStatus(
                        emailController.text,
                      );
                      if (!context.mounted) return;

                      setState(() {
                        loading = false;
                        isError = !result.success;
                        message = result.success
                            ? result.message
                            : result.error;
                      });
                    },
              child: const Text('Check Status'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        message = null;
                      });

                      final result =
                          await AuthService.requestPasswordResetApproval(
                            emailController.text,
                          );
                      if (!context.mounted) return;

                      setState(() {
                        loading = false;
                        isError = !result.success;
                        message = result.success
                            ? 'Request submitted. Wait for super admin approval.'
                            : result.error;
                      });
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/elikhalogolarge.png',
                      height: 72,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sign in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF141217),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your dashboard opens based on your database role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B5A4D)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required.';
                        if (!email.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Password is required.';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1800AD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _requestPasswordReset,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({
    super.key,
    required this.role,
    required this.onSignedOut,
  });

  final String role;
  final Future<void> Function() onSignedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'The "$role" role does not have mobile access.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onSignedOut, child: const Text('Logout')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      final profile = await currentProfile();

      if (profile == null) {
        await signOut();
        return const AuthResult.failure(
          'Account profile not found in database.',
        );
      }

      if (!{'student', 'teacher', 'parent'}.contains(profile.role)) {
        await signOut();
        return AuthResult.failure(
          'Mobile access is only available for students, teachers, and parents.',
        );
      }

      return const AuthResult.success();
    } on AuthException catch (error) {
      return AuthResult.failure(error.message);
    } catch (error) {
      return AuthResult.failure('Sign in failed: $error');
    }
  }

  static Future<MobileUser?> currentProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final profile = await _client
        .from('users')
        .select('*')
        .eq('id', authUser.id)
        .maybeSingle();

    if (profile == null) return null;

    final role = MobileUser.normalizeRole(profile['role']);
    final gradeLabel = role == 'student'
        ? await _resolveStudentGradeLabel(authUser.id, profile)
        : null;

    return MobileUser.fromJson(profile, gradeLabel: gradeLabel);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
    await student_session.SessionService.logout();
    await teacher_app.AppSession.clear();
  }

  static Future<AuthResult> requestPasswordResetApproval(String email) async {
    final safeEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(safeEmail)) {
      return const AuthResult.failure('Enter a valid email address.');
    }

    try {
      await _client.from('password_reset_requests').insert({
        'email': safeEmail,
        'status': 'pending',
      });
      return const AuthResult.success();
    } catch (error) {
      final message = error.toString();
      if (message.contains('password_reset_requests') ||
          message.contains('42P01')) {
        return const AuthResult.failure(
          'Password reset approval table is not configured in Supabase.',
        );
      }
      return AuthResult.failure('Request failed: $error');
    }
  }

  static Future<AuthResult> checkPasswordResetStatus(String email) async {
    final safeEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(safeEmail)) {
      return const AuthResult.failure('Enter a valid email address.');
    }

    try {
      final result = await _client.rpc(
        'get_password_reset_request_status',
        params: {'p_email': safeEmail},
      );
      final rows = result is List
          ? result
          : result == null
          ? const []
          : [result];

      if (rows.isEmpty) {
        return const AuthResult.success(
          'No password reset request found for this email.',
        );
      }

      final row = Map<String, dynamic>.from(rows.first as Map);
      final status = _cleanText(row['status']).toLowerCase();
      final reason = _cleanText(row['rejection_reason']);
      final requestedAt = _formatStatusDate(row['requested_at']);
      final reviewedAt = _formatStatusDate(row['reviewed_at']);

      switch (status) {
        case 'approved':
          return AuthResult.success(
            'Approved${reviewedAt.isEmpty ? '' : ' on $reviewedAt'}. Check your registered email for the reset link.',
          );
        case 'rejected':
          return AuthResult.success(
            'Rejected${reviewedAt.isEmpty ? '' : ' on $reviewedAt'}${reason.isEmpty ? '.' : ': $reason'}',
          );
        case 'pending':
        default:
          return AuthResult.success(
            'Pending super admin approval${requestedAt.isEmpty ? '' : ' since $requestedAt'}.',
          );
      }
    } catch (error) {
      final message = error.toString();
      if (message.contains('get_password_reset_request_status') ||
          message.contains('password_reset_requests') ||
          message.contains('42P01') ||
          message.contains('PGRST202')) {
        return const AuthResult.failure(
          'Password reset status lookup is not configured in Supabase.',
        );
      }
      return AuthResult.failure('Unable to check status: $error');
    }
  }

  static Future<String> _resolveStudentGradeLabel(
    String studentId,
    Map<String, dynamic> profile,
  ) async {
    final directGrade = _cleanText(
      profile['grade'] ??
          profile['grade_level'] ??
          profile['gradeLevel'] ??
          profile['year_level'],
    );
    if (directGrade.isNotEmpty) return _formatGradeLabel(directGrade);

    try {
      final rows = await _client
          .from('class_students')
          .select('classes:class_id ( grade, section, name )')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        final item = Map<String, dynamic>.from(rows.first as Map);
        final klass = item['classes'];
        if (klass is Map) {
          final classMap = Map<String, dynamic>.from(klass);
          final grade = _cleanText(classMap['grade']);
          final section = _cleanText(classMap['section']);
          if (grade.isNotEmpty && section.isNotEmpty) {
            return '${_formatGradeLabel(grade)} - $section';
          }
          if (grade.isNotEmpty) return _formatGradeLabel(grade);
          final name = _cleanText(classMap['name']);
          if (name.isNotEmpty) return name;
        }
      }
    } catch (_) {
      // Keep sign-in working even if class joins are unavailable.
    }

    return 'Grade N/A';
  }
}

class AuthResult {
  const AuthResult._({required this.success, this.error, this.message});
  const AuthResult.success([String? message])
    : this._(success: true, message: message);
  const AuthResult.failure(String error) : this._(success: false, error: error);

  final bool success;
  final String? error;
  final String? message;
}

class MobileUser {
  const MobileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.gradeLabel,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String gradeLabel;

  factory MobileUser.fromJson(Map<String, dynamic> json, {String? gradeLabel}) {
    final email = (json['email'] as String?) ?? '';
    final role = normalizeRole(json['role']);
    return MobileUser(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? email.split('@').first,
      email: email,
      role: role,
      gradeLabel: gradeLabel ?? '',
    );
  }

  static String normalizeRole(Object? rawRole) {
    return rawRole
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }
}

String _cleanText(Object? value) => value?.toString().trim() ?? '';

String _formatGradeLabel(String grade) {
  final text = grade.trim();
  if (text.isEmpty) return 'Grade N/A';
  if (text.toLowerCase().startsWith('grade')) return text;
  return 'Grade $text';
}

String _formatStatusDate(Object? value) {
  final parsed = DateTime.tryParse(_cleanText(value));
  if (parsed == null) return '';
  final local = parsed.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}
