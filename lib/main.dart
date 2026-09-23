import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ar_launcher.dart';
import 'hosted_web_security.dart';
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

class ElikhaMobileApp extends StatelessWidget {
  const ElikhaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme =
        FlexColorScheme.light(
          colors: FlexSchemeColor.from(
            primary: const Color(0xFFE8576C),
            secondary: const Color(0xFF2A2A45),
          ),
          surface: Colors.white,
          scaffoldBackground: const Color(0xFFF7F7F9),
          appBarStyle: FlexAppBarStyle.scaffoldBackground,
          subThemesData: const FlexSubThemesData(
            defaultRadius: 10,
            inputDecoratorRadius: 10,
            navigationBarIndicatorSchemeColor: SchemeColor.primary,
          ),
        ).toTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFECECEF),
            thickness: 1,
            space: 1,
          ),
        );
    final shadTheme = ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadZincColorScheme.light(
        background: Color(0xFFF7F7F9),
        foreground: Color(0xFF2A2A45),
        card: Colors.white,
        cardForeground: Color(0xFF2A2A45),
        primary: Color(0xFFE8576C),
        primaryForeground: Colors.white,
        secondary: Color(0xFFF1F1F4),
        secondaryForeground: Color(0xFF2A2A45),
        muted: Color(0xFFF1F1F4),
        mutedForeground: Color(0xFF747482),
        accent: Color(0xFFE8576C),
        accentForeground: Colors.white,
        border: Color(0xFFECECEF),
        input: Color(0xFFECECEF),
        ring: Color(0xFFE8576C),
      ),
      radius: const BorderRadius.all(Radius.circular(10)),
      textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
    );
    return ShadApp.custom(
      theme: shadTheme,
      appBuilder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'e-Likha Mobile',
        theme: materialTheme,
        builder: (context, child) => ShadAppBuilder(child: child!),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<MobileUser?> _profileFuture;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initializing = true;
  bool _passwordRecoveryActive = false;
  String? _verifiedRecoveryEmail;

  @override
  void initState() {
    super.initState();
    _profileFuture = Future<MobileUser?>.value(null);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      if (!mounted || _initializing || _passwordRecoveryActive) return;
      _reloadProfile();
    });
    _initializeGate();
  }

  Future<void> _initializeGate() async {
    final recoveryEmail = await AuthService.restorePasswordRecovery();
    if (!mounted) return;

    setState(() {
      _initializing = false;
      _verifiedRecoveryEmail = recoveryEmail;
      _passwordRecoveryActive = recoveryEmail != null;
      if (!_passwordRecoveryActive) {
        _profileFuture = AuthService.currentProfile();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _reloadProfile() {
    if (!mounted) return;
    setState(() {
      _profileFuture = AuthService.currentProfile();
    });
  }

  void _startPasswordRecovery() {
    setState(() {
      _verifiedRecoveryEmail = null;
      _passwordRecoveryActive = true;
    });
  }

  void _finishPasswordRecovery() {
    setState(() {
      _passwordRecoveryActive = false;
      _verifiedRecoveryEmail = null;
      _profileFuture = AuthService.currentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) return const _LoadingScreen();

    if (_passwordRecoveryActive) {
      return PasswordRecoveryScreen(
        initialVerifiedEmail: _verifiedRecoveryEmail,
        onFinished: _finishPasswordRecovery,
      );
    }

    return FutureBuilder<MobileUser?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(
            onSignedIn: _reloadProfile,
            onForgotPassword: _startPasswordRecovery,
          );
        }

        return RoleHome(user: user, onSignedOut: _reloadProfile);
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
      case 'admin':
      case 'superadmin':
        return HostedRoleHome(user: user, onSignedOut: _signOut);
      default:
        return UnsupportedRoleScreen(role: user.role, onSignedOut: _signOut);
    }
  }
}

class HostedRoleHome extends StatefulWidget {
  const HostedRoleHome({
    super.key,
    required this.user,
    required this.onSignedOut,
  });

  final MobileUser user;
  final Future<void> Function() onSignedOut;

  @override
  State<HostedRoleHome> createState() => _HostedRoleHomeState();
}

class _HostedRoleHomeState extends State<HostedRoleHome> {
  int _selectedIndex = 0;

  bool get _isSuperAdmin => widget.user.role == 'superadmin';

  List<({String label, String path, IconData icon})> get _primarySections => [
    (
      label: 'Dashboard',
      path: _isSuperAdmin ? '/superadmin' : '/admin',
      icon: Icons.dashboard_rounded,
    ),
    (
      label: 'Users',
      path: _isSuperAdmin ? '/superadmin/users' : '/admin/users',
      icon: Icons.people_rounded,
    ),
    (
      label: '3D Models',
      path: _isSuperAdmin ? '/superadmin/models' : '/admin/models',
      icon: Icons.view_in_ar_rounded,
    ),
    (
      label: 'Reports',
      path: _isSuperAdmin ? '/superadmin/reports' : '/admin/reports',
      icon: Icons.analytics_rounded,
    ),
  ];

  Future<void> _openSection(BuildContext context, String path, String label) =>
      openHostedWebExperience(
        context,
        trustedHostedWebBaseUri.replace(path: path),
        title: label,
      );

  @override
  Widget build(BuildContext context) {
    final workspaceName = _isSuperAdmin
        ? 'Super Admin Workspace'
        : 'Admin Workspace';
    final sections = _primarySections;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: Text(
                  widget.user.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(widget.user.email),
              ),
              const Divider(),
              if (!_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: const Text('Classes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openSection(context, '/admin/classes', 'Classes');
                  },
                ),
              if (_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Audit trail'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openSection(context, '/superadmin/audit', 'Audit trail');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSection(
                    context,
                    _isSuperAdmin ? '/superadmin/settings' : '/admin/settings',
                    'Settings',
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('e-Likha Mobile'),
        actions: [
          IconButton(
            onPressed: widget.onSignedOut,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 64,
                        color: Color(0xFF1800AD),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        workspaceName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.user.name}\n${widget.user.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B5A4D)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Account management, disabled classes, Blender model uploads, reports, settings, and audit tools use the complete secure web workspace inside the app.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _openSection(
                          context,
                          sections[_selectedIndex].path,
                          sections[_selectedIndex].label,
                        ),
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: Text('Open $workspaceName'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: sections
            .map(
              (section) => NavigationDestination(
                icon: Icon(section.icon),
                label: section.label,
              ),
            )
            .toList(),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _openSection(context, sections[index].path, sections[index].label);
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignedIn,
    required this.onForgotPassword,
  });

  final VoidCallback onSignedIn;
  final VoidCallback onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
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
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () => setState(() {
                            _showPassword = !_showPassword;
                          }),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
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
                      onPressed: _isLoading ? null : widget.onForgotPassword,
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

enum PasswordRecoveryStep { request, verify, update, success }

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    required this.onFinished,
    this.initialVerifiedEmail,
  });

  final VoidCallback onFinished;
  final String? initialVerifiedEmail;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  static const _cooldownSeconds = 60;
  static const _maximumOtpAttempts = 5;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Timer? _cooldownTimer;
  late PasswordRecoveryStep _step;
  String _submittedEmail = '';
  String? _error;
  String? _notice;
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  int _cooldown = 0;
  int _failedOtpAttempts = 0;

  @override
  void initState() {
    super.initState();
    final restoredEmail = normalizePasswordResetEmail(
      widget.initialVerifiedEmail,
    );
    _submittedEmail = restoredEmail;
    _emailController.text = restoredEmail;
    _step = restoredEmail.isEmpty
        ? PasswordRecoveryStep.request
        : PasswordRecoveryStep.update;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    final email = normalizePasswordResetEmail(
      resend ? _submittedEmail : _emailController.text,
    );
    if (!isValidPasswordResetEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final result = await AuthService.requestPasswordResetOtp(email);
    if (!mounted) return;

    setState(() => _busy = false);
    if (!result.success) {
      setState(() => _error = result.error);
      return;
    }

    setState(() {
      _submittedEmail = email;
      _emailController.text = email;
      _otpController.clear();
      _failedOtpAttempts = 0;
      _step = PasswordRecoveryStep.verify;
      _notice = resend
          ? 'A new code was requested. Use only the latest email.'
          : result.message;
    });
    _startCooldown();
  }

  Future<void> _verifyCode() async {
    if (_failedOtpAttempts >= _maximumOtpAttempts) {
      setState(() {
        _error = 'Too many incorrect attempts. Request a new code.';
      });
      return;
    }

    final otp = normalizePasswordResetOtp(_otpController.text);
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AuthService.verifyPasswordResetOtp(
      email: _submittedEmail,
      otp: otp,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (!result.success) {
      final attempts = result.code == 'invalid_or_expired'
          ? _failedOtpAttempts + 1
          : _failedOtpAttempts;
      setState(() {
        _failedOtpAttempts = attempts;
        _error = attempts >= _maximumOtpAttempts
            ? 'Too many incorrect attempts. Request a new code.'
            : result.error;
      });
      return;
    }

    _cooldownTimer?.cancel();
    setState(() {
      _step = PasswordRecoveryStep.update;
      _error = null;
      _notice = null;
    });
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;
    final validationError = validateRecoveredPassword(password, confirmation);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AuthService.updateRecoveredPassword(password);
    if (!mounted) return;

    setState(() => _busy = false);
    if (!result.success) {
      setState(() => _error = result.error);
      return;
    }

    setState(() => _step = PasswordRecoveryStep.success);
  }

  Future<void> _cancelRecovery() async {
    if (_step == PasswordRecoveryStep.update) return;
    await AuthService.cancelPasswordRecovery();
    if (mounted) widget.onFinished();
  }

  Future<void> _startOver() async {
    await AuthService.cancelPasswordRecovery();
    if (!mounted) return;
    setState(() {
      _step = PasswordRecoveryStep.request;
      _submittedEmail = '';
      _emailController.clear();
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _failedOtpAttempts = 0;
      _cooldown = 0;
      _error = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _cancelRecovery(),
      child: Scaffold(
        appBar: AppBar(
          leading: _step == PasswordRecoveryStep.update
              ? null
              : IconButton(
                  tooltip: 'Back to login',
                  onPressed: _busy ? null : _cancelRecovery,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
          title: const Text('Reset Password'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/elikhalogolarge.png',
                          height: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B5A4D)),
                        ),
                        const SizedBox(height: 24),
                        _buildStep(),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (_notice != null && _error == null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _notice!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF067647),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (_step) {
      case PasswordRecoveryStep.request:
        return 'Forgot Password?';
      case PasswordRecoveryStep.verify:
        return 'Enter Your Reset Code';
      case PasswordRecoveryStep.update:
        return 'Choose a New Password';
      case PasswordRecoveryStep.success:
        return 'Password Updated';
    }
  }

  String get _subtitle {
    switch (_step) {
      case PasswordRecoveryStep.request:
        return 'Enter your account email. We will send a 6-digit code—no administrator approval is needed.';
      case PasswordRecoveryStep.verify:
        return 'Enter the 6-digit code sent to $_submittedEmail.';
      case PasswordRecoveryStep.update:
        return 'Your code is verified. Enter a new password for $_submittedEmail.';
      case PasswordRecoveryStep.success:
        return 'You can now sign in using your new password.';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case PasswordRecoveryStep.request:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _busy ? null : _sendCode(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _sendCode,
              child: _busy
                  ? const _ButtonSpinner()
                  : const Text('Email Reset Code'),
            ),
          ],
        );
      case PasswordRecoveryStep.verify:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
              decoration: const InputDecoration(
                labelText: '6-Digit Code',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final normalized = normalizePasswordResetOtp(value);
                if (normalized != value) {
                  _otpController.value = TextEditingValue(
                    text: normalized,
                    selection: TextSelection.collapsed(
                      offset: normalized.length,
                    ),
                  );
                }
                setState(() => _error = null);
              },
              onSubmitted: (_) => _busy ? null : _verifyCode(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verifyCode,
              child: _busy ? const _ButtonSpinner() : const Text('Verify Code'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy || _cooldown > 0
                  ? null
                  : () => _sendCode(resend: true),
              child: Text(
                _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _step = PasswordRecoveryStep.request;
                      _otpController.clear();
                      _failedOtpAttempts = 0;
                      _error = null;
                      _notice = null;
                    }),
              child: const Text('Use a different email'),
            ),
          ],
        );
      case PasswordRecoveryStep.update:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'New Password',
                helperText: 'Use at least 8 characters.',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() {
                    _showPassword = !_showPassword;
                  }),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmation,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _showConfirmation
                      ? 'Hide confirmation'
                      : 'Show confirmation',
                  onPressed: () => setState(() {
                    _showConfirmation = !_showConfirmation;
                  }),
                  icon: Icon(
                    _showConfirmation
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _busy ? null : _updatePassword(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _updatePassword,
              child: _busy
                  ? const _ButtonSpinner()
                  : const Text('Update Password'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _startOver,
              child: const Text('Request a new code'),
            ),
          ],
        );
      case PasswordRecoveryStep.success:
        return FilledButton.icon(
          onPressed: widget.onFinished,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Go to Login'),
        );
    }
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
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

      if (!{
        'student',
        'teacher',
        'parent',
        'admin',
        'superadmin',
      }.contains(profile.role)) {
        await signOut();
        return AuthResult.failure(
          'This account role is not supported by e-Likha.',
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
    User? authUser;
    try {
      final response = await _client.auth.getUser();
      authUser = response.user;
    } on AuthException {
      return null;
    }
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
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } finally {
      await _clearLocalSessionState();
    }
  }

  static Future<AuthResult> requestPasswordResetOtp(String email) async {
    final safeEmail = normalizePasswordResetEmail(email);
    if (!isValidPasswordResetEmail(safeEmail)) {
      return const AuthResult.failure('Enter a valid email address.');
    }

    try {
      await _client.auth.resetPasswordForEmail(safeEmail);
      return const AuthResult.success(
        'If an account uses that email, a 6-digit reset code has been sent.',
      );
    } on AuthException catch (error) {
      if (_isUnknownAccountError(error)) {
        return const AuthResult.success(
          'If an account uses that email, a 6-digit reset code has been sent.',
        );
      }
      if (_isRateLimitError(error)) {
        return const AuthResult.failure(
          'Please wait about a minute before requesting another code.',
          code: 'rate_limited',
        );
      }
      return const AuthResult.failure(
        'We could not send a reset code right now. Please try again later.',
      );
    } catch (_) {
      return const AuthResult.failure(
        'We could not send a reset code right now. Please try again later.',
      );
    }
  }

  static Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final safeEmail = normalizePasswordResetEmail(email);
    final safeOtp = normalizePasswordResetOtp(otp);
    if (!isValidPasswordResetEmail(safeEmail)) {
      return const AuthResult.failure('Enter a valid email address.');
    }
    if (safeOtp.length != 6) {
      return const AuthResult.failure(
        'Enter the 6-digit code from your email.',
      );
    }

    try {
      final response = await _client.auth.verifyOTP(
        email: safeEmail,
        token: safeOtp,
        type: OtpType.recovery,
      );
      if (response.session == null || response.user == null) {
        return const AuthResult.failure(
          'That code is invalid or expired. Request a new code.',
          code: 'invalid_or_expired',
        );
      }

      final stored = await PasswordRecoverySessionStore.save(safeEmail);
      if (!stored) {
        await _client.auth.signOut(scope: SignOutScope.local);
        return const AuthResult.failure(
          'The code was verified, but this device could not secure the reset session. Try again.',
        );
      }

      return const AuthResult.success();
    } on AuthException {
      return const AuthResult.failure(
        'That code is invalid or expired. Check the latest email or request a new code.',
        code: 'invalid_or_expired',
      );
    } catch (_) {
      return const AuthResult.failure(
        'We could not verify the code right now. Please try again.',
      );
    }
  }

  static Future<AuthResult> updateRecoveredPassword(String password) async {
    final recoveryEmail = await restorePasswordRecovery();
    if (recoveryEmail == null) {
      return const AuthResult.failure(
        'Your reset session is missing or expired. Request a new code.',
        code: 'invalid_or_expired',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: password));

      var allSessionsRevoked = true;
      try {
        await _client.auth.signOut(scope: SignOutScope.global);
      } catch (_) {
        allSessionsRevoked = false;
        try {
          await _client.auth.signOut(scope: SignOutScope.local);
        } catch (_) {
          // Local Supabase storage is still cleared below.
        }
      }

      await _clearLocalSessionState();
      return AuthResult.success(
        allSessionsRevoked
            ? 'Password updated. Sign in again on every device.'
            : 'Password updated. Sign in again on this device.',
      );
    } on AuthException catch (error) {
      return AuthResult.failure(
        error.message.isEmpty
            ? 'Your reset session expired. Request a new code.'
            : error.message,
      );
    } catch (_) {
      return const AuthResult.failure(
        'We could not update your password right now. Please try again.',
      );
    }
  }

  static Future<String?> restorePasswordRecovery() async {
    final hadRecoveryMarker = await PasswordRecoverySessionStore.hasMarker();
    final recovery = await PasswordRecoverySessionStore.load();
    if (recovery == null) {
      if (hadRecoveryMarker) await cancelPasswordRecovery();
      return null;
    }

    try {
      final response = await _client.auth.getUser();
      final authenticatedEmail = normalizePasswordResetEmail(
        response.user?.email,
      );
      if (authenticatedEmail == recovery.email) return recovery.email;
    } catch (_) {
      // The cleanup below removes an expired or mismatched local reset session.
    }

    await cancelPasswordRecovery();
    return null;
  }

  static Future<void> cancelPasswordRecovery() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Continue clearing app-owned session state even when offline.
    } finally {
      await _clearLocalSessionState();
    }
  }

  static Future<void> _clearLocalSessionState() async {
    try {
      await PasswordRecoverySessionStore.clear();
    } catch (_) {
      // Continue clearing the other local session stores.
    }
    try {
      await student_session.SessionService.logout();
    } catch (_) {
      // Legacy student preferences must not block a real Supabase logout.
    }
    try {
      await teacher_app.AppSession.clear();
    } catch (_) {
      // Legacy teacher preferences are best-effort cleanup only.
    }
  }

  static bool _isRateLimitError(AuthException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == '429' ||
        message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('only request this after');
  }

  static bool _isUnknownAccountError(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('user not found') ||
        message.contains('email not found');
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
          .select('classes:class_id ( grade, section, name, is_active )')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false);
      for (final rawItem in rows) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final klass = item['classes'];
        if (klass is Map) {
          final classMap = Map<String, dynamic>.from(klass);
          if (classMap['is_active'] == false) continue;
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
  const AuthResult._({
    required this.success,
    this.error,
    this.message,
    this.code,
  });
  const AuthResult.success([String? message])
    : this._(success: true, message: message);
  const AuthResult.failure(String error, {String? code})
    : this._(success: false, error: error, code: code);

  final bool success;
  final String? error;
  final String? message;
  final String? code;
}

class PasswordRecoverySession {
  const PasswordRecoverySession({
    required this.email,
    required this.verifiedAt,
  });

  final String email;
  final DateTime verifiedAt;
}

class PasswordRecoverySessionStore {
  static const _emailKey = 'elikha_password_recovery_email';
  static const _verifiedAtKey = 'elikha_password_recovery_verified_at';
  static const _maximumAge = Duration(minutes: 30);

  static Future<bool> save(String email) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedEmail = await preferences.setString(
        _emailKey,
        normalizePasswordResetEmail(email),
      );
      final savedTime = await preferences.setInt(
        _verifiedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return savedEmail && savedTime;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasMarker() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.containsKey(_emailKey) ||
          preferences.containsKey(_verifiedAtKey);
    } catch (_) {
      return false;
    }
  }

  static Future<PasswordRecoverySession?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final email = normalizePasswordResetEmail(
        preferences.getString(_emailKey),
      );
      final verifiedAtMilliseconds = preferences.getInt(_verifiedAtKey);
      if (!isValidPasswordResetEmail(email) || verifiedAtMilliseconds == null) {
        await clear();
        return null;
      }

      final verifiedAt = DateTime.fromMillisecondsSinceEpoch(
        verifiedAtMilliseconds,
      );
      final age = DateTime.now().difference(verifiedAt);
      if (age.isNegative || age > _maximumAge) {
        await clear();
        return null;
      }

      return PasswordRecoverySession(email: email, verifiedAt: verifiedAt);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_emailKey);
      await preferences.remove(_verifiedAtKey);
    } catch (_) {
      // The Supabase session cleanup still runs if local preferences are unavailable.
    }
  }
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

String normalizePasswordResetEmail(Object? email) =>
    email?.toString().trim().toLowerCase() ?? '';

bool isValidPasswordResetEmail(Object? email) => RegExp(
  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
).hasMatch(normalizePasswordResetEmail(email));

String normalizePasswordResetOtp(Object? value) {
  final digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
  return digits.length <= 6 ? digits : digits.substring(0, 6);
}

String? validateRecoveredPassword(String password, String confirmation) {
  if (password.length < 8) return 'Password must be at least 8 characters.';
  if (password.length > 128) return 'Password must be 128 characters or fewer.';
  if (password != confirmation) return 'Passwords do not match.';
  return null;
}

String _formatGradeLabel(String grade) {
  final text = grade.trim();
  if (text.isEmpty) return 'Grade N/A';
  if (text.toLowerCase().startsWith('grade')) return text;
  return 'Grade $text';
}
