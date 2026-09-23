import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ar_launcher.dart';
import 'hosted_web_security.dart';
import 'r2_media_service.dart';

const _primary = Color(0xFFE8576C);
const _ink = Color(0xFF2A2A45);
const _muted = Color(0xFF747482);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFECECEF);
const _teacherBackground = Color(0xFFF7F7F9);

const _studentCream = Color(0xFFFAF7F3);
const _studentRaspberry = Color(0xFFE8576C);
const _studentCosmicBlue = Color(0xFF3D6FAE);
const _studentPlum = Color(0xFF4A3F5C);
const _studentMarigold = Color(0xFFF4A72E);
const _studentInk = Color(0xFF2A2A45);
const _studentSoftGrey = Color(0xFFD7D4D8);

final _dateFormatter = DateFormat('MMM d, yyyy');
final _dateTimeFormatter = DateFormat('MMM d, yyyy h:mm a');

const _sandboxModelApiBase = String.fromEnvironment(
  'ELIKHA_MODEL_API_URL',
  defaultValue: 'https://elikha-r2-models.elikha-r2-models-worker.workers.dev',
);

class SandboxModelOption {
  const SandboxModelOption({
    required this.id,
    required this.label,
    required this.fileType,
    this.description = '',
    this.isBuiltIn = false,
    this.isCustom = false,
    this.storageProvider = '',
    this.fileName = '',
    this.source = '',
    this.license = '',
    this.attribution = '',
  });

  final String id;
  final String label;
  final String fileType;
  final String description;
  final bool isBuiltIn;
  final bool isCustom;
  final String storageProvider;
  final String fileName;
  final String source;
  final String license;
  final String attribution;

  bool get isArReady => fileType != 'blend';
  bool get canManage => isCustom && storageProvider == 'r2';

  static SandboxModelOption? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = (value['id'] ?? '').toString().trim();
    final label = (value['label'] ?? '').toString().trim();
    final fileType = (value['fileType'] ?? '').toString().trim().toLowerCase();
    if (id.isEmpty ||
        label.isEmpty ||
        !const {'obj', '3ds', 'glb', 'gltf', 'blend'}.contains(fileType)) {
      return null;
    }
    final isBuiltIn = value['isBuiltIn'] == true || value['isCustom'] == false;
    final isCustom = !isBuiltIn;
    return SandboxModelOption(
      id: id,
      label: label,
      fileType: fileType,
      description: (value['description'] ?? '').toString().trim(),
      isBuiltIn: isBuiltIn,
      isCustom: isCustom,
      storageProvider: (value['storageProvider'] ?? 'r2').toString().trim(),
      fileName: (value['fileName'] ?? '').toString().trim(),
      source: (value['source'] ?? '').toString().trim(),
      license: (value['license'] ?? '').toString().trim(),
      attribution: (value['attribution'] ?? '').toString().trim(),
    );
  }
}

class FreeModelCatalogItem {
  const FreeModelCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.downloadUrl,
    required this.creator,
    required this.category,
    required this.license,
    required this.attribution,
    required this.source,
  });

  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final String downloadUrl;
  final String creator;
  final String category;
  final String license;
  final String attribution;
  final String source;

  factory FreeModelCatalogItem.fromJson(Map<String, dynamic> json) {
    return FreeModelCatalogItem(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Untitled model'),
      description: _string(json['description']),
      thumbnailUrl: _string(json['thumbnailUrl']),
      downloadUrl: _string(json['downloadUrl']),
      creator: _string(json['creator']),
      category: _string(json['category']),
      license: _string(json['license']),
      attribution: _string(json['attribution']),
      source: _string(json['source'], fallback: 'Poly Pizza'),
    );
  }
}

const sandboxFallbackModels = <SandboxModelOption>[
  SandboxModelOption(
    id: 'bottle',
    label: 'Bottle',
    fileType: '3ds',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'button',
    label: 'Button',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'cactus',
    label: 'Cactus',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'flower',
    label: 'Flower',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'lion',
    label: 'Lion',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'paper-cup',
    label: 'Paper Cup',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'popsicle-stick',
    label: 'Popsicle Stick',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'sakura-tree',
    label: 'Sakura Tree',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'sarcophagus',
    label: 'Sarcophagus',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'sphinx',
    label: 'Sphinx',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'torii-shrine',
    label: 'Torii Shrine',
    fileType: 'glb',
    isBuiltIn: true,
  ),
  SandboxModelOption(
    id: 'tree',
    label: 'Tree',
    fileType: 'glb',
    isBuiltIn: true,
  ),
];

const _activityObjectOptions = <({String id, String label, IconData icon})>[
  (id: 'cube', label: 'Cube', icon: Icons.crop_square_rounded),
  (id: 'sphere', label: 'Sphere', icon: Icons.circle_outlined),
  (id: 'cone', label: 'Cone', icon: Icons.change_history_rounded),
  (id: 'cylinder', label: 'Cylinder', icon: Icons.storage_rounded),
  (id: 'rectangle', label: 'Rectangle', icon: Icons.rectangle_outlined),
];

const _activityColorOptions = <({String hex, String name})>[
  (hex: '#FF0000', name: 'Red'),
  (hex: '#FFFF00', name: 'Yellow'),
  (hex: '#0000FF', name: 'Blue'),
  (hex: '#00A651', name: 'Green'),
  (hex: '#FF8C00', name: 'Orange'),
  (hex: '#7B2CFF', name: 'Violet'),
  (hex: '#8B5A2B', name: 'Brown'),
  (hex: '#F2C29B', name: 'Skin tone'),
  (hex: '#FFFFFF', name: 'White'),
  (hex: '#000000', name: 'Black'),
];

const _rubricBeginningDescription =
    'Shows the skill with guidance and is still building confidence.';
const _rubricDevelopingDescription =
    'Shows the skill with some support and growing independence.';
const _rubricConsistentDescription =
    'Shows the skill independently and consistently.';

String _normalizeRubricCode(Object? value) {
  final code = _string(value).toUpperCase();
  return const {'B': 'BG', 'D': 'DV', 'C': 'CO'}[code] ?? code;
}

Future<List<SandboxModelOption>> fetchSandboxModels({
  http.Client? client,
}) async {
  final ownsClient = client == null;
  final requestClient = client ?? http.Client();
  try {
    final apiBase = _sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '');
    final response = await requestClient
        .get(Uri.parse('$apiBase/models'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Model library returned ${response.statusCode}.');
    }
    final payload = jsonDecode(response.body);
    final data = payload is Map ? payload['data'] : null;
    if (data is! List) {
      throw const FormatException('Invalid model library response.');
    }

    final byId = <String, SandboxModelOption>{
      for (final model in sandboxFallbackModels) model.id: model,
    };
    for (final entry in data) {
      final model = SandboxModelOption.fromJson(entry);
      if (model != null) byId[model.id] = model;
    }
    final models = byId.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return models;
  } catch (_) {
    final models = [...sandboxFallbackModels]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return models;
  } finally {
    if (ownsClient) requestClient.close();
  }
}

class MobileModelLibraryService {
  static const _supportedExtensions = {'obj', '3ds', 'glb', 'blend'};
  static const maxFileBytes = 50 * 1024 * 1024;

  static String validateFile(PlatformFile? file, {bool required = true}) {
    if (file == null) return required ? 'Select a 3D model file.' : '';
    final extension = (file.extension ?? '').trim().toLowerCase();
    if (!_supportedExtensions.contains(extension)) {
      return 'Only .obj, .3ds, .glb, and .blend files are supported.';
    }
    if (file.size > maxFileBytes) {
      return 'The file is larger than the 50 MB limit.';
    }
    if (file.bytes == null) return 'The selected model file could not be read.';
    return '';
  }

  static Future<void> upload({
    required String label,
    required String description,
    required PlatformFile file,
    http.Client? client,
    String? accessToken,
  }) async {
    final token =
        accessToken ??
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient.post(
        _modelsUri(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/octet-stream',
          'X-Model-Name': Uri.encodeComponent(label.trim()),
          'X-Model-Description': Uri.encodeComponent(description.trim()),
          'X-Model-File-Name': Uri.encodeComponent(file.name),
        },
        body: file.bytes,
      );
      _requireSuccess(response);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<void> update({
    required SandboxModelOption model,
    required String label,
    required String description,
    PlatformFile? replacement,
    http.Client? client,
    String? accessToken,
  }) async {
    final token =
        accessToken ??
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final requestClient = client ?? http.Client();
    try {
      late http.Response response;
      if (replacement != null) {
        response = await requestClient.put(
          _modelUri(model.id, suffix: 'file'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/octet-stream',
            'X-Model-Name': Uri.encodeComponent(label.trim()),
            'X-Model-Description': Uri.encodeComponent(description.trim()),
            'X-Model-File-Name': Uri.encodeComponent(replacement.name),
          },
          body: replacement.bytes,
        );
      } else {
        response = await requestClient.patch(
          _modelUri(model.id),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'label': label.trim(),
            'description': description.trim(),
          }),
        );
      }
      _requireSuccess(response);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<void> delete(
    SandboxModelOption model, {
    http.Client? client,
    String? accessToken,
  }) async {
    final token =
        accessToken ??
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient.delete(
        _modelUri(model.id),
        headers: {'Authorization': 'Bearer $token'},
      );
      _requireSuccess(response);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<List<FreeModelCatalogItem>> searchFreeCatalog(
    String query, {
    int page = 1,
    http.Client? client,
    String? accessToken,
  }) async {
    final search = query.trim();
    if (search.isEmpty) {
      throw StateError('Enter a keyword to search free models.');
    }
    final token =
        accessToken ??
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final requestClient = client ?? http.Client();
    try {
      final base = _sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '');
      final response = await requestClient.get(
        Uri.parse('$base/models/search').replace(
          queryParameters: {'q': search, 'page': math.max(1, page).toString()},
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = _requireSuccess(response);
      if (data is! Map) return const [];
      return _rows(data['results'])
          .map(FreeModelCatalogItem.fromJson)
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.name.isNotEmpty &&
                item.downloadUrl.isNotEmpty,
          )
          .toList();
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<void> importFreeModel(
    FreeModelCatalogItem item, {
    http.Client? client,
    String? accessToken,
  }) async {
    final token =
        accessToken ??
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final requestClient = client ?? http.Client();
    try {
      final base = _sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '');
      final response = await requestClient.post(
        Uri.parse('$base/models/import'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sourceUrl': item.downloadUrl,
          'label': item.name,
          'description': item.description.isEmpty
              ? '${item.source} · ${item.license}'
              : item.description,
          'fileName': '${item.id}.glb',
          'source': item.source,
          'license': item.license,
          'attribution': item.attribution,
        }),
      );
      _requireSuccess(response);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Uri _modelsUri() {
    final base = _sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/models');
  }

  static Uri _modelUri(String id, {String suffix = ''}) {
    final tail = suffix.isEmpty ? '' : '/$suffix';
    return Uri.parse('${_modelsUri()}/${Uri.encodeComponent(id)}$tail');
  }

  static Object? _requireSuccess(http.Response response) {
    Object? payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      payload = null;
    }
    final failedPayload = payload is Map && payload['success'] == false;
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        !failedPayload) {
      return payload is Map ? payload['data'] : null;
    }
    final message = payload is Map ? _string(payload['error']) : '';
    throw StateError(
      message.isEmpty
          ? 'The 3D model storage returned ${response.statusCode}.'
          : message,
    );
  }
}

int normalizeMobileStarRating(num? value) {
  if (value == null || value <= 0) return 0;
  final starScaleValue = value > 5 ? value / 20 : value.toDouble();
  return starScaleValue.round().clamp(0, 5);
}

String mobileStarRatingLabel(num? value) {
  final rating = normalizeMobileStarRating(value);
  return rating == 0 ? 'Not rated' : '$rating/5 stars';
}

RealtimeChannel _subscribeToNotifications(
  String userId,
  VoidCallback onChanged,
) {
  return Supabase.instance.client
      .channel('mobile-notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: userId,
        ),
        callback: (_) => onChanged(),
      )
      .subscribe();
}

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
  RealtimeChannel? _notificationChannel;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadStudentBundle(widget.userId);
    _notificationChannel = _subscribeToNotifications(widget.userId, _refresh);
    _lifecycleListener = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    final channel = _notificationChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
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
            userId: widget.userId,
            name: widget.name,
            gradeLabel: widget.gradeLabel,
            bundle: bundle,
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onOpenActivities: () => setState(() => _index = 1),
            onOpenSandbox: () => setState(() => _index = 2),
            onOpenProfile: () => setState(() => _index = 3),
            onRefresh: _refresh,
          ),
          _StudentActivitiesTab(
            bundle: bundle,
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _StudentSandboxTab(onRefresh: _refresh),
          _StudentProfileTab(
            userId: widget.userId,
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
          studentStyle: true,
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: _StudentNavMark(icon: Icons.home_outlined),
              selectedIcon: _StudentNavMark(
                icon: Icons.home_rounded,
                selected: true,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _StudentNavMark(icon: Icons.assignment_outlined),
              selectedIcon: _StudentNavMark(
                icon: Icons.assignment_rounded,
                selected: true,
              ),
              label: 'Activities',
            ),
            NavigationDestination(
              icon: _StudentNavMark(icon: Icons.science_outlined),
              selectedIcon: _StudentNavMark(
                icon: Icons.science_rounded,
                selected: true,
              ),
              label: 'Sandbox',
            ),
            NavigationDestination(
              icon: _StudentNavMark(icon: Icons.person_outline_rounded),
              selectedIcon: _StudentNavMark(
                icon: Icons.person_rounded,
                selected: true,
              ),
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
  int _bottomIndex = 0;
  late Future<TeacherBundle> _future;
  RealtimeChannel? _notificationChannel;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadTeacherBundle(widget.userId);
    _notificationChannel = _subscribeToNotifications(widget.userId, _refresh);
    _lifecycleListener = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    final channel = _notificationChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = MobileDataService.loadTeacherBundle(widget.userId);
    });
  }

  void _openTeacherPage(int pageIndex) {
    const bottomForPage = {0: 0, 1: 1, 2: 2, 4: 3};
    setState(() {
      _index = pageIndex;
      final bottom = bottomForPage[pageIndex];
      if (bottom != null) _bottomIndex = bottom;
    });
  }

  void _selectTeacherBottom(int bottomIndex) {
    const pageForBottom = [0, 1, 2, 4];
    setState(() {
      _bottomIndex = bottomIndex;
      _index = pageForBottom[bottomIndex];
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
            userId: widget.userId,
            name: widget.name,
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onSelectTab: _openTeacherPage,
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
          _TeacherStudentsTab(
            students: bundle?.students ?? const [],
            activities: bundle?.activities ?? const [],
            submissions: bundle?.submissions ?? const [],
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
          _TeacherReportsTab(
            bundle: bundle,
            loading: loading,
            error: snapshot.error,
            onRefresh: _refresh,
          ),
          _TeacherRubricsTab(
            teacherId: widget.userId,
            activities: bundle?.activities ?? const [],
            onChanged: _refresh,
          ),
          const _TeacherModelsTab(),
          _TeacherSettingsTab(userId: widget.userId),
        ];

        return _RoleShell(
          title: 'e-Likha Teacher',
          teacherStyle: true,
          selectedIndex: _bottomIndex,
          onDestinationSelected: _selectTeacherBottom,
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
          ],
          drawer: _TeacherOverflowDrawer(
            name: widget.name,
            email: widget.email,
            selectedPage: _index,
            onSelectPage: _openTeacherPage,
          ),
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

class _TeacherOverflowDrawer extends StatelessWidget {
  const _TeacherOverflowDrawer({
    required this.name,
    required this.email,
    required this.selectedPage,
    required this.onSelectPage,
  });

  final String name;
  final String email;
  final int selectedPage;
  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context) {
    const items = <({int page, IconData icon, String label})>[
      (page: 3, icon: Icons.school_outlined, label: 'Students'),
      (page: 5, icon: Icons.analytics_outlined, label: 'Reports'),
      (page: 6, icon: Icons.fact_check_outlined, label: 'Rubrics'),
      (page: 7, icon: Icons.view_in_ar_outlined, label: '3D Models'),
      (page: 8, icon: Icons.settings_outlined, label: 'Settings'),
    ];
    final selectedIndex = items.indexWhere((item) => item.page == selectedPage);
    return NavigationDrawer(
      backgroundColor: _surface,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        onSelectPage(items[index].page);
      },
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 10),
        ...items.indexed.expand((entry) sync* {
          if (entry.$1 == 4) {
            yield const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            );
          }
          final item = entry.$2;
          yield NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.icon, color: _primary),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                item.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
      ],
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
  RealtimeChannel? _notificationChannel;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.loadParentBundle(widget.userId);
    _notificationChannel = _subscribeToNotifications(widget.userId, _refresh);
    _lifecycleListener = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    final channel = _notificationChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
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
            userId: widget.userId,
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

class _StudentWordmark extends StatelessWidget {
  const _StudentWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -.12,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: _studentRaspberry,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.brush_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('e-Likha', style: _studentHeading(24)),
      ],
    );
  }
}

class _StudentNavMark extends StatelessWidget {
  const _StudentNavMark({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Icon(icon, color: _studentSoftGrey, size: 26);
    }
    return Transform.rotate(
      angle: -.08,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: _studentMarigold,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x224A3F5C),
              blurRadius: 0,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: .08,
          child: Icon(icon, color: _studentInk, size: 25),
        ),
      ),
    );
  }
}

class _RoleShell extends StatefulWidget {
  const _RoleShell({
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
    this.actions = const [],
    this.drawer,
    this.studentStyle = false,
    this.teacherStyle = false,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget child;
  final List<Widget> actions;
  final Widget? drawer;
  final bool studentStyle;
  final bool teacherStyle;

  @override
  State<_RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<_RoleShell> {
  @override
  Widget build(BuildContext context) {
    assert(widget.destinations.length <= 4);
    final baseTheme = Theme.of(context);
    final content = Scaffold(
      backgroundColor: widget.studentStyle
          ? _studentCream
          : widget.teacherStyle
          ? _teacherBackground
          : null,
      drawer: widget.drawer,
      appBar: AppBar(
        title: widget.studentStyle
            ? const _StudentWordmark()
            : Text(
                widget.title,
                style: widget.teacherStyle
                    ? const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.2,
                      )
                    : null,
              ),
        backgroundColor: widget.studentStyle
            ? _studentCream
            : widget.teacherStyle
            ? _teacherBackground
            : _surface,
        foregroundColor: widget.studentStyle ? _studentInk : _ink,
        elevation: 0,
        actions: widget.actions,
      ),
      body: SafeArea(child: widget.child),
      bottomNavigationBar: NavigationBar(
        height: widget.studentStyle ? 72 : 68,
        backgroundColor: widget.studentStyle
            ? const Color(0xFFFFFCF8)
            : _surface,
        indicatorColor: widget.studentStyle ? Colors.transparent : null,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: widget.destinations,
      ),
    );
    if (!widget.studentStyle) return content;
    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: _studentCream,
        textTheme: GoogleFonts.nunitoSansTextTheme(
          baseTheme.textTheme,
        ).apply(bodyColor: _studentInk, displayColor: _studentInk),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: _studentPlum,
          secondary: _studentMarigold,
          surface: Colors.white,
        ),
      ),
      child: content,
    );
  }
}

class _StudentHomeTab extends StatelessWidget {
  const _StudentHomeTab({
    required this.userId,
    required this.name,
    required this.gradeLabel,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onOpenActivities,
    required this.onOpenSandbox,
    required this.onOpenProfile,
    required this.onRefresh,
  });

  final String userId;
  final String name;
  final String gradeLabel;
  final StudentBundle? bundle;
  final bool loading;
  final Object? error;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSandbox;
  final VoidCallback onOpenProfile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataSurface(
      backgroundColor: _studentCream,
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StudentHeroCard(
            name: name,
            className: bundle?.classItem?.displayName ?? gradeLabel,
            onOpenActivities: onOpenActivities,
          ),
          const SizedBox(height: 14),
          _StudentPromoCard(
            title: 'Practice your next idea',
            subtitle: 'Try colors and shapes without affecting your grade.',
            icon: Icons.palette_rounded,
            onPressed: onOpenSandbox,
          ),
          const SizedBox(height: 18),
          _StudentProgressStrip(
            onOpenActivities: onOpenActivities,
            items: [
              ('To do', bundle?.pendingActivities.length ?? 0),
              ('Sent', bundle?.submittedActivities.length ?? 0),
              ('Checked', bundle?.reviewedActivities.length ?? 0),
              ('Art', bundle?.artworks.length ?? 0),
            ],
          ),
          const SizedBox(height: 18),
          _StudentNotificationNotebook(
            userId: bundle?.studentId,
            notifications: bundle?.notifications ?? const <DbNotification>[],
            limit: 3,
            onChanged: onRefresh,
            onSeeAll: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(userId: userId),
                ),
              );
              onRefresh();
            },
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
                  final activity = _activityForArtwork(bundle, artwork);
                  return SizedBox(
                    width: 190,
                    child: _ArtworkCard(
                      artwork: artwork,
                      onTap: activity == null
                          ? null
                          : () => _openStudentActivity(
                              context,
                              activity,
                              studentId: bundle!.studentId,
                              onChanged: onRefresh,
                            ),
                    ),
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
                  (activity) => _StudentActivityRow(
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

class _StudentSandboxTab extends StatefulWidget {
  const _StudentSandboxTab({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  State<_StudentSandboxTab> createState() => _StudentSandboxTabState();
}

class _StudentSandboxTabState extends State<_StudentSandboxTab> {
  String _difficulty = 'easy';
  bool _opening = false;
  bool _loadingModels = true;
  List<SandboxModelOption> _models = sandboxFallbackModels;
  SandboxModelOption _selectedModel = sandboxFallbackModels.firstWhere(
    (model) => model.id == 'cactus',
  );

  static const _levels =
      <
        ({String id, String title, String subtitle, IconData icon, Color color})
      >[
        (
          id: 'easy',
          title: 'Easy',
          subtitle: 'Color only',
          icon: Icons.palette_outlined,
          color: Color(0xFF10B981),
        ),
        (
          id: 'medium',
          title: 'Medium',
          subtitle: 'Puzzle only',
          icon: Icons.extension_outlined,
          color: Color(0xFF0EA5E9),
        ),
        (
          id: 'advanced',
          title: 'Advanced',
          subtitle: 'Color and puzzle',
          icon: Icons.auto_awesome_outlined,
          color: Color(0xFF7C3AED),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final models = (await fetchSandboxModels())
          .where((model) => model.isArReady)
          .toList();
      if (!mounted) return;
      setState(() {
        _models = models;
        _selectedModel = models.firstWhere(
          (model) => model.id == _selectedModel.id,
          orElse: () => models.first,
        );
        _loadingModels = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _chooseModel() async {
    final selected = await showModalBottomSheet<SandboxModelOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      builder: (context) => _SandboxModelPickerSheet(
        models: _models,
        selectedId: _selectedModel.id,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedModel = selected);
    }
  }

  Future<void> _start() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await openArExperience(
        context,
        trustedHostedWebBaseUri.replace(
          path: '/sandbox',
          queryParameters: {
            'mobile': '1',
            'autostart': '1',
            'difficulty': _difficulty,
            'model': _selectedModel.id,
          },
        ),
      );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _HeroPanel(
          title: 'Practice Sandbox',
          subtitle: 'Explore safely without grades or submissions.',
          trailing: Icon(Icons.view_in_ar_rounded, color: _primary, size: 46),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Choose a 3D model'),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Selected 3D model: ${_selectedModel.label}. Browse models.',
          child: Material(
            color: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _chooseModel,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEDE9FE),
                      foregroundColor: _primary,
                      child: Icon(Icons.view_in_ar_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedModel.label,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _loadingModels
                                ? 'Updating model library…'
                                : '${_models.length} models available • ${_selectedModel.fileType.toUpperCase()}',
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                    if (_loadingModels)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.search_rounded, color: _primary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Choose a practice level'),
        const SizedBox(height: 8),
        ..._levels.map((level) {
          final selected = _difficulty == level.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected ? level.color.withValues(alpha: .10) : _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selected ? level.color : _border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _difficulty = level.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: level.color.withValues(alpha: .14),
                        foregroundColor: level.color,
                        child: Icon(level.icon),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              level.subtitle,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? level.color : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _opening ? null : _start,
          icon: _opening
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(_opening ? 'Opening sandbox…' : 'Start practice'),
        ),
        const SizedBox(height: 12),
        const Text(
          'The sandbox opens directly in the fullscreen AR workspace using the front camera. Your practice work is temporary.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.4),
        ),
      ],
    );
  }
}

class _SandboxModelPickerSheet extends StatefulWidget {
  const _SandboxModelPickerSheet({
    required this.models,
    required this.selectedId,
  });

  final List<SandboxModelOption> models;
  final String selectedId;

  @override
  State<_SandboxModelPickerSheet> createState() =>
      _SandboxModelPickerSheetState();
}

class _SandboxModelPickerSheetState extends State<_SandboxModelPickerSheet> {
  final _searchController = TextEditingController();
  late String _selectedId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  List<SandboxModelOption> get _filteredModels {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.models;
    return widget.models.where((model) {
      return model.label.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query) ||
          model.description.toLowerCase().contains(query) ||
          model.fileType.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredModels;
    final selected = widget.models.firstWhere(
      (model) => model.id == _selectedId,
      orElse: () => widget.models.first,
    );

    return FractionallySizedBox(
      heightFactor: .88,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          math.max(16.0, MediaQuery.viewInsetsOf(context).bottom + 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a 3D model',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Search the shared e-Likha model library.',
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search by model name or file type',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${filtered.length} ${filtered.length == 1 ? 'model' : 'models'}',
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No models match that search.',
                        style: TextStyle(color: _muted),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final model = filtered[index];
                        final isSelected = model.id == _selectedId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isSelected
                                ? _primary.withValues(alpha: .08)
                                : _surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected ? _primary : _border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  setState(() => _selectedId = model.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.view_in_ar_outlined,
                                        color: _primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${model.fileType.toUpperCase()}${model.isBuiltIn ? ' • Built in' : ''}',
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? _primary
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, selected),
                icon: const Icon(Icons.check_rounded),
                label: Text('Use ${selected.label}'),
              ),
            ),
          ],
        ),
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
      backgroundColor: _studentCream,
      loading: widget.loading,
      error: widget.error,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _StudentActivityBanner(),
          const SizedBox(height: 18),
          SegmentedButton<int>(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : _studentPlum,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? _studentPlum
                    : Colors.white,
              ),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFFE7DFDA)),
              ),
            ),
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
              (activity) => _StudentActivityRow(
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
    required this.userId,
    required this.name,
    required this.email,
    required this.gradeLabel,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onSignedOut,
  });

  final String userId;
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
      backgroundColor: _studentCream,
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StudentProfileHero(
            name: name,
            completed: bundle?.completedCount ?? 0,
            averageScore: bundle?.averageScoreLabel ?? 'N/A',
          ),
          const SizedBox(height: 14),
          _StudentIdentityRow(
            userId: userId,
            name: name,
            email: email,
            className: bundle?.classItem?.displayName ?? gradeLabel,
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Submitted Work'),
          if ((bundle?.artworks ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.image_outlined,
              title: 'No saved artwork',
              body:
                  'The gallery uses rows from the artworks and submissions tables.',
            )
          else
            _ArtworkGrid(
              artworks: bundle!.artworks,
              onArtworkTap: (artwork) {
                final activity = _activityForArtwork(bundle, artwork);
                if (activity == null) return;
                _openStudentActivity(
                  context,
                  activity,
                  studentId: bundle!.studentId,
                  onChanged: onRefresh,
                );
              },
            ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AccountSettingsPage(userId: userId),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Voice & Notification Settings'),
          ),
          const SizedBox(height: 10),
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

class _TeacherDashboardHeader extends StatelessWidget {
  const _TeacherDashboardHeader({
    required this.userId,
    required this.name,
    required this.pendingReviews,
    required this.onOpenReviews,
  });

  final String userId;
  final String name;
  final int pendingReviews;
  final VoidCallback onOpenReviews;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final identity = Row(
          children: [
            _PrivateR2Image(
              kind: R2MediaKind.avatars,
              ownerId: userId,
              size: 54,
              borderRadius: 12,
              fallback: const Icon(
                Icons.person_outline_rounded,
                color: _ink,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          ],
        );
        final action = ShadButton(
          onPressed: onOpenReviews,
          leading: const Icon(Icons.rate_review_outlined, size: 18),
          child: Text(
            pendingReviews == 0
                ? 'Open reviews'
                : 'Review queue ($pendingReviews)',
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [identity, const SizedBox(height: 16), action],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 20),
            action,
          ],
        );
      },
    );
  }
}

class _TeacherStatRail extends StatelessWidget {
  const _TeacherStatRail({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : metrics.length;
        final width = constraints.maxWidth / columns;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Wrap(
            children: metrics.indexed.map((entry) {
              final index = entry.$1;
              final metric = entry.$2;
              final value = metric.value is num
                  ? NumberFormat.compact().format(metric.value)
                  : metric.value.toString();
              final isRightEdge = (index + 1) % columns == 0;
              final hasRowBelow = index + columns < metrics.length;
              return SizedBox(
                width: width - (1 / columns),
                child: InkWell(
                  onTap: metric.onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 17, 12, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        right: isRightEdge
                            ? BorderSide.none
                            : const BorderSide(color: _border),
                        bottom: hasRowBelow
                            ? const BorderSide(color: _border)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          value,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _TeacherNotificationPanel extends StatelessWidget {
  const _TeacherNotificationPanel({
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
    final ids = notifications
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList();
    if (ids.isEmpty) return;
    await MobileDataService.markNotificationsRead(id, ids);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final visible = notifications.take(limit).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 8, 11),
            child: Row(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 20),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Updates',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (visible.any((item) => !item.isRead))
                  ShadButton.ghost(
                    onPressed: _markAllRead,
                    child: const Text('Mark read'),
                  ),
              ],
            ),
          ),
          const Divider(),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No new updates.', style: TextStyle(color: _muted)),
              ),
            )
          else
            ...visible.indexed.map(
              (entry) => _TeacherNotificationRow(
                userId: userId,
                notification: entry.$2,
                showDivider: entry.$1 > 0,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherNotificationRow extends StatelessWidget {
  const _TeacherNotificationRow({
    required this.userId,
    required this.notification,
    required this.showDivider,
    required this.onChanged,
  });

  final String? userId;
  final DbNotification notification;
  final bool showDivider;
  final VoidCallback onChanged;

  Future<void> _open(BuildContext context) async {
    final id = userId;
    if (id != null && id.isNotEmpty && !notification.isRead) {
      await MobileDataService.markNotificationsRead(id, [notification.id]);
      onChanged();
    }
    final action = notification.actionUri;
    if (action == null || !context.mounted) return;
    await _openHostedPage(
      context,
      path: action.path,
      title: notification.title,
      queryParameters: action.queryParameters,
      onClosed: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider) const Divider(indent: 52),
        InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
            child: Row(
              children: [
                Icon(
                  _notificationIcon(notification.type),
                  color: notification.isRead ? _muted : _primary,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${notification.message}  ${_formatDateTime(notification.createdAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (notification.actionUri != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.chevron_right_rounded, color: _muted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherSubmissionQueue extends StatelessWidget {
  const _TeacherSubmissionQueue({
    required this.submissions,
    required this.onOpen,
  });

  final List<DbSubmission> submissions;
  final ValueChanged<DbSubmission> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: submissions.indexed.map((entry) {
          final index = entry.$1;
          final submission = entry.$2;
          return Column(
            children: [
              if (index > 0) const Divider(indent: 76),
              InkWell(
                onTap: () => onOpen(submission),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _Thumbnail(
                        url: submission.artworkUrl,
                        seed: submission.id,
                        size: 46,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              submission.activityTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${submission.studentName} · ${_formatDateTime(submission.submittedAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        submission.isReviewed ? 'Reviewed' : 'Needs review',
                        style: TextStyle(
                          color: submission.isReviewed ? _muted : _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: _muted),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab({
    required this.userId,
    required this.name,
    required this.bundle,
    required this.loading,
    required this.error,
    required this.onSelectTab,
    required this.onRefresh,
  });

  final String userId;
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
          _TeacherDashboardHeader(
            userId: userId,
            name: name,
            pendingReviews: bundle?.pendingReviews.length ?? 0,
            onOpenReviews: () => onSelectTab(4),
          ),
          const SizedBox(height: 24),
          _TeacherStatRail(
            metrics: [
              _MetricData(
                'Students',
                bundle?.totalStudents ?? 0,
                onTap: () => onSelectTab(3),
              ),
              _MetricData(
                'Classes',
                bundle?.activeClasses.length ?? 0,
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
                onTap: () => onSelectTab(4),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TeacherNotificationPanel(
            userId: bundle?.teacherId,
            notifications: bundle?.notifications ?? const <DbNotification>[],
            limit: 4,
            onChanged: onRefresh,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Review queue',
            actionLabel: 'Open reviews',
            onAction: () => onSelectTab(4),
          ),
          if ((bundle?.submissions ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.inbox_outlined,
              title: 'No submissions yet',
              body:
                  'Student submissions will appear here when they submit work.',
            )
          else
            _TeacherSubmissionQueue(
              submissions: bundle!.submissions.take(4).toList(),
              onOpen: (submission) => _reviewSubmissionDialog(
                context: context,
                teacherId: bundle!.teacherId,
                submission: submission,
                onSaved: onRefresh,
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
          if ((bundle?.activeClasses ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.groups_outlined,
              title: 'No active classes',
              body: 'Create a class to assign students and activities.',
            )
          else
            ...bundle!.activeClasses.map(
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
                onToggleActive: () =>
                    _confirmToggleClass(context, klass, onRefresh),
              ),
            ),
          if ((bundle?.inactiveClasses ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Disabled Classes'),
            const SizedBox(height: 8),
            ...bundle!.inactiveClasses.map(
              (klass) => _ClassTile(
                klass: klass,
                onTap: () => _confirmToggleClass(context, klass, onRefresh),
                onEdit: () => _confirmToggleClass(context, klass, onRefresh),
                onToggleActive: () =>
                    _confirmToggleClass(context, klass, onRefresh),
              ),
            ),
          ],
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
        onPressed: (bundle?.activeClasses ?? []).isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherActivityEditorPage(
                    teacherId: teacherId,
                    classes: bundle!.activeClasses,
                    onSaved: onRefresh,
                  ),
                ),
              ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Activity'),
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
                onView: () => _showTeacherActivityOverview(context, activity),
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeacherActivityEditorPage(
                      teacherId: teacherId,
                      classes: bundle!.activeClasses,
                      activity: activity,
                      onSaved: onRefresh,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherStudentsTab extends StatefulWidget {
  const _TeacherStudentsTab({
    required this.students,
    required this.activities,
    required this.submissions,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final List<DbStudent> students;
  final List<DbActivity> activities;
  final List<DbSubmission> submissions;
  final bool loading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  State<_TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<_TeacherStudentsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final students = widget.students.where((student) {
      return query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query);
    }).toList();

    return _DataSurface(
      loading: widget.loading,
      error: widget.error,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _HeroPanel(
            title: 'My Students',
            subtitle: 'Find learners and review their activity progress.',
            trailing: Icon(Icons.school_rounded, color: _primary, size: 46),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          if (students.isEmpty)
            _EmptyCard(
              icon: query.isEmpty
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              title: query.isEmpty ? 'No enrolled students' : 'No matches',
              body: query.isEmpty
                  ? 'Students added to your active classes appear here.'
                  : 'Try a different name or email.',
            )
          else
            ...students.map(
              (student) => _CardShell(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: _PrivateR2Image(
                    kind: R2MediaKind.avatars,
                    ownerId: student.id,
                    legacyPath: student.avatarPath,
                    size: 52,
                    fallback: CircleAvatar(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      child: Text(_initials(student.name)),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(student.email),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeacherStudentDetailPage(
                        student: student,
                        teacherActivities: widget.activities,
                        teacherSubmissions: widget.submissions,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherStudentDetailPage extends StatefulWidget {
  const TeacherStudentDetailPage({
    super.key,
    required this.student,
    required this.teacherActivities,
    required this.teacherSubmissions,
  });

  final DbStudent student;
  final List<DbActivity> teacherActivities;
  final List<DbSubmission> teacherSubmissions;

  @override
  State<TeacherStudentDetailPage> createState() =>
      _TeacherStudentDetailPageState();
}

class _TeacherStudentDetailPageState extends State<TeacherStudentDetailPage> {
  late Future<List<DbActivity>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.fetchTeacherStudentActivities(
      widget.student.id,
      widget.teacherActivities,
      widget.teacherSubmissions,
    );
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.fetchTeacherStudentActivities(
        widget.student.id,
        widget.teacherActivities,
        widget.teacherSubmissions,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student details')),
      body: FutureBuilder<List<DbActivity>>(
        future: _future,
        builder: (context, snapshot) {
          final activities = snapshot.data ?? const <DbActivity>[];
          final submitted = activities.where((item) => item.isSubmitted).length;
          final reviewed = activities.where((item) => item.isReviewed).length;
          final overdue = activities.where((item) => item.isOverdue).length;
          return _DataSurface(
            loading: snapshot.connectionState != ConnectionState.done,
            error: snapshot.error,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeroPanel(
                  title: widget.student.name,
                  subtitle: widget.student.email,
                  trailing: _PrivateR2Image(
                    kind: R2MediaKind.avatars,
                    ownerId: widget.student.id,
                    legacyPath: widget.student.avatarPath,
                    size: 72,
                    fallback: CircleAvatar(
                      radius: 36,
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      child: Text(_initials(widget.student.name)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _MetricGrid(
                  metrics: [
                    _MetricData('Assigned', activities.length),
                    _MetricData('Submitted', submitted),
                    _MetricData('Reviewed', reviewed),
                    _MetricData('Overdue', overdue),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Activities'),
                if (activities.isEmpty)
                  const _EmptyCard(
                    icon: Icons.assignment_outlined,
                    title: 'No assigned activities',
                    body: 'This learner has no active assigned work.',
                  )
                else
                  ...activities.map(
                    (activity) => _CardShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${activity.studentStatusLabel} • Due ${_formatDate(activity.dueDate)}',
                            style: const TextStyle(color: _muted),
                          ),
                          if (activity.submission?.score != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Rating: ${activity.submission!.scoreLabel}/5',
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
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

class TeacherActivityEditorPage extends StatefulWidget {
  const TeacherActivityEditorPage({
    super.key,
    required this.teacherId,
    required this.classes,
    required this.onSaved,
    this.activity,
  });

  final String teacherId;
  final List<DbClass> classes;
  final DbActivity? activity;
  final VoidCallback onSaved;

  @override
  State<TeacherActivityEditorPage> createState() =>
      _TeacherActivityEditorPageState();
}

class _TeacherActivityEditorPageState extends State<TeacherActivityEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;
  late String _classId;
  late DateTime _dueDate;
  late List<String> _allowedObjects;
  late List<String> _modelIds;
  late int _puzzlePieces;
  late List<String> _allowedColors;
  late Map<String, String> _allowedColorNames;
  late List<ActivityColorRequirement> _colorRequirements;
  List<SandboxModelOption> _models = sandboxFallbackModels;
  List<ActivityRubricOption> _rubrics = const [];
  String _rubricId = '';
  String _originalRubricId = '';
  bool _rubricLocked = false;
  String? _rubricMessage;
  Uint8List? _thumbnailBytes;
  String _thumbnailName = '';
  String _imageUrl = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final draft = ActivityArDraft.parse(widget.activity?.rawDescription ?? '');
    _titleController = TextEditingController(
      text: widget.activity?.title ?? '',
    );
    _descriptionController = TextEditingController(text: draft.summary);
    _instructionsController = TextEditingController(text: draft.instructions);
    _classId = widget.activity?.classId.isNotEmpty == true
        ? widget.activity!.classId
        : widget.classes.first.id;
    _dueDate =
        widget.activity?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _allowedObjects = [...draft.allowedObjectIds];
    _modelIds = [...draft.modelIds];
    _puzzlePieces = draft.puzzlePieces;
    _allowedColors = [...draft.allowedColors];
    _allowedColorNames = {...draft.allowedColorNames};
    _colorRequirements = [...draft.colorRequirements];
    _imageUrl = widget.activity?.imageUrl ?? '';
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait<Object>([
        fetchSandboxModels(),
        MobileDataService.fetchActivityRubricOptions(widget.teacherId),
        if (_editing)
          MobileDataService.fetchActivityRubricState(widget.activity!.id),
      ]);
      if (!mounted) return;
      final models = (results[0] as List<SandboxModelOption>)
          .where((model) => model.isArReady)
          .toList();
      final rubrics = results[1] as List<ActivityRubricOption>;
      final rubricState = _editing
          ? results[2] as ActivityRubricManagementState
          : const ActivityRubricManagementState();
      setState(() {
        _models = models;
        _rubrics = rubrics;
        _modelIds = _modelIds
            .where((id) => models.any((model) => model.id == id))
            .toList();
        if (_modelIds.isEmpty) _modelIds = ['cactus'];
        _rubricId = rubricState.rubricId;
        _originalRubricId = rubricState.rubricId;
        _rubricLocked = rubricState.changeLocked;
        _rubricMessage = rubricState.lockReason;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Some builder options could not load: $error';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;
    if (file!.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Choose a thumbnail smaller than 5 MB.');
      return;
    }
    setState(() {
      _thumbnailBytes = file.bytes;
      _thumbnailName = file.name;
      _error = null;
    });
  }

  Future<void> _chooseModels() async {
    final ids = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      builder: (_) =>
          _ActivityModelsSheet(models: _models, selectedIds: _modelIds),
    );
    if (ids != null && ids.isNotEmpty && mounted) {
      setState(() => _modelIds = ids);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _dueDate.isBefore(today) ? today : _dueDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (date != null && mounted) setState(() => _dueDate = date);
  }

  Future<void> _editColorPalette() async {
    final result = await showModalBottomSheet<ActivityPaletteResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      builder: (_) => _ActivityColorPaletteSheet(
        colors: _allowedColors,
        names: _allowedColorNames,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _allowedColors = result.colors;
      _allowedColorNames = result.names;
      _colorRequirements.removeWhere(
        (item) => !_allowedColors.contains(item.colorHex),
      );
      _error = null;
    });
  }

  Future<void> _editColorRequirements() async {
    if (_allowedColors.isEmpty) {
      setState(() => _error = 'Choose at least one activity color first.');
      return;
    }
    final requirements =
        await showModalBottomSheet<List<ActivityColorRequirement>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: _surface,
          builder: (_) => _ActivityColorRequirementsSheet(
            allowedObjectIds: _allowedObjects,
            modelIds: _modelIds,
            models: _models,
            allowedColors: _allowedColors,
            allowedColorNames: _allowedColorNames,
            value: _colorRequirements,
          ),
        );
    if (requirements != null && mounted) {
      setState(() {
        _colorRequirements = requirements;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var imageUrl = _imageUrl;
      if (_thumbnailBytes != null) {
        imageUrl = await MobileDataService.uploadActivityThumbnail(
          teacherId: widget.teacherId,
          bytes: _thumbnailBytes!,
          fileName: _thumbnailName,
        );
      }
      final selectedModels = _modelIds
          .map(
            (id) => _models.firstWhere(
              (model) => model.id == id,
              orElse: () => sandboxFallbackModels.firstWhere(
                (model) => model.id == 'cactus',
              ),
            ),
          )
          .toList();
      final encodedDescription = encodeMobileActivityDescription(
        _descriptionController.text.trim(),
        existingDescription: widget.activity?.rawDescription ?? '',
        instructions: _instructionsController.text.trim(),
        allowedObjectIds: _allowedObjects,
        models: selectedModels,
        puzzlePieces: _puzzlePieces,
        allowedColors: _allowedColors,
        allowedColorNames: _allowedColorNames,
        colorRequirements: _colorRequirements,
      );
      final selectedClass = widget.classes.firstWhere(
        (item) => item.id == _classId,
      );
      final result = _editing
          ? await MobileDataService.updateActivity(
              widget.activity!.id,
              title: _titleController.text,
              description: _descriptionController.text,
              existingDescription: encodedDescription,
              imageUrl: imageUrl,
              dueDate: _dueDate,
              rubricAction: _rubricId == _originalRubricId
                  ? 'keep'
                  : _rubricId.isEmpty
                  ? 'remove'
                  : 'set',
              rubricId: _rubricId,
            )
          : await MobileDataService.createActivityAndAssign(
              teacherId: widget.teacherId,
              classItem: selectedClass,
              title: _titleController.text,
              description: encodedDescription,
              imageUrl: imageUrl,
              dueDate: _dueDate,
              rubricId: _rubricId,
            );
      if (!mounted) return;
      if (result.success) {
        widget.onSaved();
        Navigator.pop(context, true);
      } else {
        setState(() {
          _saving = false;
          _error = result.error ?? 'Could not save activity.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _previewAr() async {
    final activity = widget.activity;
    if (activity == null) return;
    await openArExperience(
      context,
      trustedHostedWebBaseUri.replace(
        path: '/activity/${activity.id}/start',
        queryParameters: const {'mobile': '1'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit activity' : 'Create activity'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit activity' : 'Create activity'),
        actions: [
          if (_editing)
            IconButton(
              onPressed: _previewAr,
              tooltip: 'Open AR preview',
              icon: const Icon(Icons.view_in_ar_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            const _HeroPanel(
              title: 'Build the learning task',
              subtitle:
                  'Set the class, instructions, AR materials, rubric, and due date here.',
              trailing: Icon(
                Icons.architecture_rounded,
                color: _primary,
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Activity details'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _classId,
              decoration: const InputDecoration(labelText: 'Class'),
              items: widget.classes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.displayName),
                    ),
                  )
                  .toList(),
              onChanged: _editing
                  ? null
                  : (value) => setState(() => _classId = value ?? _classId),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Activity title'),
              validator: (value) => value?.trim().isEmpty == true
                  ? 'Enter an activity title.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsController,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Student instructions',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'AR material kit'),
            const SizedBox(height: 8),
            _CardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shape tools',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activityObjectOptions.map((item) {
                      final selected = _allowedObjects.contains(item.id);
                      return FilterChip(
                        avatar: Icon(item.icon, size: 18),
                        label: Text(item.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            if (selected && _allowedObjects.length > 1) {
                              _allowedObjects.remove(item.id);
                            } else if (!selected) {
                              _allowedObjects.add(item.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            _CardShell(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.view_in_ar_rounded, color: _primary),
                title: Text(
                  '${_modelIds.length} base model${_modelIds.length == 1 ? '' : 's'}',
                ),
                subtitle: Text(
                  _modelIds
                      .map(
                        (id) =>
                            _models
                                .where((model) => model.id == id)
                                .map((model) => model.label)
                                .firstOrNull ??
                            id,
                      )
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.search_rounded),
                onTap: _chooseModels,
              ),
            ),
            DropdownButtonFormField<int>(
              initialValue: _puzzlePieces,
              decoration: const InputDecoration(labelText: 'Puzzle pieces'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Off')),
                DropdownMenuItem(value: 3, child: Text('3 pieces')),
                DropdownMenuItem(value: 4, child: Text('4 pieces')),
              ],
              onChanged: (value) => setState(() => _puzzlePieces = value ?? 0),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Color palette'),
            const SizedBox(height: 4),
            _CardShell(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _PalettePreview(colors: _allowedColors),
                title: Text(
                  _allowedColors.isEmpty
                      ? 'Choose activity colors'
                      : '${_allowedColors.length}/10 colors selected',
                ),
                subtitle: const Text(
                  'Pick any color and control its order in the learner’s AR toolbar.',
                ),
                trailing: const Icon(Icons.tune_rounded),
                onTap: _editColorPalette,
              ),
            ),
            const SizedBox(height: 10),
            _CardShell(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.colorize_rounded, color: _primary),
                title: const Text('Required colors'),
                subtitle: Text(
                  _colorRequirements.isEmpty
                      ? 'Optional: require a color on a specific model or shape'
                      : '${_colorRequirements.length} color requirement${_colorRequirements.length == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.edit_rounded),
                onTap: _editColorRequirements,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Assessment and schedule'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _rubricId,
              decoration: InputDecoration(
                labelText: 'Rubric (optional)',
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  enabled: true,
                  child: Text(
                    'No rubric',
                  ),
                ),
                ..._rubrics.map(
                  (rubric) => DropdownMenuItem(
                    value: rubric.id,
                    child: Text('${rubric.title} (${rubric.criteriaCount})'),
                  ),
                ),
              ],
              onChanged: _rubricLocked
                  ? null
                  : (value) => setState(() => _rubricId = value ?? ''),
            ),
            if (_rubricMessage?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(_rubricMessage!, style: const TextStyle(color: _muted)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('Due ${_formatDate(_dueDate)}'),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Activity thumbnail'),
            const SizedBox(height: 8),
            if (_thumbnailBytes != null || _imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _thumbnailBytes != null
                    ? Image.memory(
                        _thumbnailBytes!,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : Image.network(_imageUrl, height: 180, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _thumbnailBytes == null && _imageUrl.isEmpty
                    ? 'Choose thumbnail'
                    : 'Replace thumbnail',
              ),
            ),
            if (_thumbnailBytes != null || _imageUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  _thumbnailBytes = null;
                  _thumbnailName = '';
                  _imageUrl = '';
                }),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove thumbnail'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _saving
                    ? 'Saving activity…'
                    : _editing
                    ? 'Save changes'
                    : 'Create and assign',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityModelsSheet extends StatefulWidget {
  const _ActivityModelsSheet({required this.models, required this.selectedIds});

  final List<SandboxModelOption> models;
  final List<String> selectedIds;

  @override
  State<_ActivityModelsSheet> createState() => _ActivityModelsSheetState();
}

class _ActivityModelsSheetState extends State<_ActivityModelsSheet> {
  final _searchController = TextEditingController();
  late final List<String> _ids = widget.selectedIds.toSet().toList();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.models.where((model) {
      final query = _query.toLowerCase().trim();
      return query.isEmpty || model.label.toLowerCase().contains(query);
    }).toList();
    return FractionallySizedBox(
      heightFactor: .9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Base 3D models',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose models students can add from their AR toolbar.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search models',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return ListTile(
                    leading: const Icon(Icons.view_in_ar_outlined),
                    title: Text(model.label),
                    subtitle: Text(model.fileType.toUpperCase()),
                    trailing: Checkbox(
                      value: _ids.contains(model.id),
                      semanticLabel: model.label,
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          _ids.add(model.id);
                        } else {
                          _ids.remove(model.id);
                        }
                      }),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _ids.isEmpty
                    ? null
                    : () => Navigator.pop(context, _ids),
                child: Text(
                  'Use ${_ids.length} model${_ids.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityPaletteResult {
  const ActivityPaletteResult({required this.colors, required this.names});

  final List<String> colors;
  final Map<String, String> names;
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.colors});

  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    final preview = colors.isEmpty
        ? const ['#7F56D9']
        : colors.take(3).toList();
    return SizedBox(
      width: 48,
      height: 34,
      child: Stack(
        children: [
          for (var index = 0; index < preview.length; index++)
            Positioned(
              left: index * 10,
              top: index * 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _colorFromHex(preview[index]),
                  shape: BoxShape.circle,
                  border: Border.all(color: _surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityColorPaletteSheet extends StatefulWidget {
  const _ActivityColorPaletteSheet({required this.colors, required this.names});

  final List<String> colors;
  final Map<String, String> names;

  @override
  State<_ActivityColorPaletteSheet> createState() =>
      _ActivityColorPaletteSheetState();
}

class _ActivityColorPaletteSheetState
    extends State<_ActivityColorPaletteSheet> {
  late final List<String> _colors = [...widget.colors];
  late final Map<String, String> _names = {...widget.names};
  late HSVColor _hsv = HSVColor.fromColor(_colorFromHex('#7F56D9'));
  late final TextEditingController _hexController = TextEditingController(
    text: '#7F56D9',
  );
  final TextEditingController _nameController = TextEditingController();
  double _opacity = 1;
  String? _notice;

  String get _hex =>
      '#${_hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  void dispose() {
    _hexController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hexController.text = _hex;
      _notice = null;
    });
  }

  void _setHex(String value) {
    final normalized = _normalizedHex(value);
    setState(() {
      _notice = null;
      if (normalized != null) {
        _hsv = HSVColor.fromColor(_colorFromHex(normalized));
      }
    });
  }

  void _load(String hex) {
    setState(() {
      _hsv = HSVColor.fromColor(_colorFromHex(hex));
      _hexController.text = hex;
      _nameController.text = _names[hex] ?? '';
      _notice = null;
    });
  }

  void _add() {
    final hex = _normalizedHex(_hexController.text);
    if (hex == null) {
      setState(() => _notice = 'Enter a valid six-digit hex color.');
      return;
    }
    if (_colors.contains(hex)) {
      setState(() => _notice = 'That color is already in this palette.');
      return;
    }
    if (_colors.length >= 10) {
      setState(() => _notice = 'Remove a color before adding another.');
      return;
    }
    final fallbackName = _activityColorOptions
        .where((color) => color.hex == hex)
        .map((color) => color.name)
        .firstOrNull;
    setState(() {
      _colors.add(hex);
      final name = _nameController.text.trim();
      if (name.isNotEmpty || fallbackName != null) {
        _names[hex] = name.isNotEmpty ? name : fallbackName!;
      }
      _notice = 'Color added.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 16 + keyboard),
        child: ListView(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity color palette',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Choose up to 10 colors. Their order becomes the AR toolbar.',
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text('${_colors.length}/10')),
              ],
            ),
            const SizedBox(height: 16),
            _ColorSelectionSquare(hsv: _hsv, onChanged: _setHsv),
            const SizedBox(height: 12),
            const Text('Hue', style: TextStyle(fontWeight: FontWeight.w800)),
            Slider(
              value: _hsv.hue,
              min: 0,
              max: 359,
              onChanged: (hue) => _setHsv(_hsv.withHue(hue)),
            ),
            const Text(
              'Preview opacity',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Slider(
              value: _opacity,
              onChanged: (value) => setState(() => _opacity = value),
            ),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _hsv.toColor().withValues(alpha: _opacity),
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    maxLength: 7,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Hex',
                      counterText: '',
                    ),
                    onChanged: _setHex,
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(_opacity * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Color name (optional)',
                hintText: 'e.g. Ocean blue',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _colors.length >= 10 ? null : _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add color'),
              ),
            ),
            if (_notice != null)
              Text(
                _notice!,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Added colors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (_colors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No colors added. The complete default palette will be used.',
                  style: TextStyle(color: _muted),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _colors.length,
                onReorderItem: (oldIndex, newIndex) => setState(() {
                  final color = _colors.removeAt(oldIndex);
                  _colors.insert(newIndex, color);
                }),
                itemBuilder: (context, index) {
                  final hex = _colors[index];
                  return ListTile(
                    key: ValueKey(hex),
                    contentPadding: EdgeInsets.zero,
                    leading: InkWell(
                      onTap: () => _load(hex),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(backgroundColor: _colorFromHex(hex)),
                    ),
                    title: Text(
                      _names[hex]?.isNotEmpty == true ? _names[hex]! : hex,
                    ),
                    subtitle: _names[hex]?.isNotEmpty == true
                        ? Text(hex)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Remove color',
                          onPressed: () => setState(() {
                            _colors.remove(hex);
                            _names.remove(hex);
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const Icon(Icons.drag_handle_rounded),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ActivityPaletteResult(
                  colors: [..._colors],
                  names: {
                    for (final color in _colors)
                      if (_names[color]?.isNotEmpty == true)
                        color: _names[color]!,
                  },
                ),
              ),
              child: const Text('Use this palette'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSelectionSquare extends StatelessWidget {
  const _ColorSelectionSquare({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void update(Offset position) {
          final saturation = (position.dx / constraints.maxWidth).clamp(
            0.0,
            1.0,
          );
          final value = (1 - position.dy / 230).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          onTapDown: (event) => update(event.localPosition),
          onPanUpdate: (event) => update(event.localPosition),
          child: SizedBox(
            height: 230,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.saturation * constraints.maxWidth - 12,
                    top: (1 - hsv.value) * 230 - 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String? _normalizedHex(String value) {
  final text = value.trim().toUpperCase();
  final normalized = text.startsWith('#') ? text : '#$text';
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized) ? normalized : null;
}

class _ActivityColorRequirementsSheet extends StatefulWidget {
  const _ActivityColorRequirementsSheet({
    required this.allowedObjectIds,
    required this.modelIds,
    required this.models,
    required this.allowedColors,
    required this.allowedColorNames,
    required this.value,
  });

  final List<String> allowedObjectIds;
  final List<String> modelIds;
  final List<SandboxModelOption> models;
  final List<String> allowedColors;
  final Map<String, String> allowedColorNames;
  final List<ActivityColorRequirement> value;

  @override
  State<_ActivityColorRequirementsSheet> createState() =>
      _ActivityColorRequirementsSheetState();
}

class _ActivityColorRequirementsSheetState
    extends State<_ActivityColorRequirementsSheet> {
  late final List<ActivityColorRequirement> _items = [...widget.value];
  late String _target = _targets.first.$1;
  late String _color = widget.allowedColors.first;

  List<(String, String)> get _targets {
    final targets = <(String, String)>[];
    for (final id in widget.allowedObjectIds) {
      final label =
          _activityObjectOptions
              .where((item) => item.id == id)
              .map((item) => item.label)
              .firstOrNull ??
          id;
      targets.add(('object:$id', label));
    }
    for (final id in widget.modelIds.toSet()) {
      final label =
          widget.models
              .where((model) => model.id == id)
              .map((model) => model.label)
              .firstOrNull ??
          id;
      targets.add(('model:$id', label));
    }
    return targets;
  }

  void _add() {
    final parts = _target.split(':');
    final targetType = parts.first;
    final targetId = parts.sublist(1).join(':');
    final targetLabel = _targets
        .where((target) => target.$1 == _target)
        .map((target) => target.$2)
        .first;
    final colorName = _string(widget.allowedColorNames[_color]).isNotEmpty
        ? _string(widget.allowedColorNames[_color])
        : _activityColorOptions
                  .where((item) => item.hex == _color)
                  .map((item) => item.name)
                  .firstOrNull ??
              _color;
    final duplicate = _items.any(
      (item) =>
          item.targetType == targetType &&
          item.targetId == targetId &&
          item.colorHex == _color,
    );
    if (duplicate || _items.length >= 24) return;
    setState(() {
      _items.add(
        ActivityColorRequirement(
          targetType: targetType,
          targetId: targetId,
          targetLabel: targetLabel,
          colorHex: _color,
          colorName: colorName,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .85,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required colors',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect a palette color to a model or shape students must paint.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _target,
              decoration: const InputDecoration(labelText: 'Target'),
              items: _targets
                  .map(
                    (target) => DropdownMenuItem(
                      value: target.$1,
                      child: Text(target.$2),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _target = value ?? _target),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _color,
              decoration: const InputDecoration(labelText: 'Required color'),
              items: widget.allowedColors.map((hex) {
                final name = _string(widget.allowedColorNames[hex]).isNotEmpty
                    ? _string(widget.allowedColorNames[hex])
                    : _activityColorOptions
                              .where((item) => item.hex == hex)
                              .map((item) => item.name)
                              .firstOrNull ??
                          hex;
                return DropdownMenuItem(value: hex, child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => _color = value ?? _color),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add requirement'),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No required colors yet.'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorFromHex(item.colorHex),
                          ),
                          title: Text('${item.targetLabel}: ${item.colorName}'),
                          subtitle: Text(item.colorHex),
                          trailing: IconButton(
                            tooltip: 'Remove requirement',
                            onPressed: () =>
                                setState(() => _items.removeAt(index)),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _items),
                child: const Text('Save requirements'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherReviewsTab extends StatefulWidget {
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
  State<_TeacherReviewsTab> createState() => _TeacherReviewsTabState();
}

class _TeacherReviewsTabState extends State<_TeacherReviewsTab> {
  final _searchController = TextEditingController();
  String _status = 'pending';
  String _activity = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissions = widget.bundle?.submissions ?? const <DbSubmission>[];
    final activities =
        submissions.map((item) => item.activityTitle).toSet().toList()..sort();
    final activityFilter = _activity == 'all' || activities.contains(_activity)
        ? _activity
        : 'all';
    final query = _searchController.text.trim().toLowerCase();
    final visible = submissions.where((submission) {
      final statusMatches =
          _status == 'all' ||
          (_status == 'reviewed'
              ? submission.isReviewed
              : !submission.isReviewed);
      final activityMatches =
          activityFilter == 'all' || submission.activityTitle == activityFilter;
      final searchMatches =
          query.isEmpty ||
          submission.studentName.toLowerCase().contains(query) ||
          submission.activityTitle.toLowerCase().contains(query);
      return statusMatches && activityMatches && searchMatches;
    }).toList();
    return _DataSurface(
      loading: widget.loading,
      error: widget.error,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Reviews'),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search learner or activity',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Needs review')),
                ButtonSegment(value: 'reviewed', label: Text('Reviewed')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_status},
              onSelectionChanged: (value) =>
                  setState(() => _status = value.first),
            ),
          ),
          if (activities.length > 1) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(activityFilter),
              initialValue: activityFilter,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All activities'),
                ),
                ...activities.map(
                  (activity) =>
                      DropdownMenuItem(value: activity, child: Text(activity)),
                ),
              ],
              onChanged: (value) => setState(() => _activity = value ?? 'all'),
            ),
          ],
          const SizedBox(height: 14),
          if (submissions.isEmpty)
            const _EmptyCard(
              icon: Icons.rate_review_outlined,
              title: 'No submitted work',
              body: 'Submitted activities will appear here for scoring.',
            )
          else if (visible.isEmpty)
            const _EmptyCard(
              icon: Icons.filter_alt_off_outlined,
              title: 'No matching submissions',
              body: 'Change the search or review filter to see more work.',
            )
          else
            ...visible.map(
              (submission) => _SubmissionTile(
                submission: submission,
                onTap: () => _reviewSubmissionDialog(
                  context: context,
                  teacherId: widget.teacherId,
                  submission: submission,
                  onSaved: widget.onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherRubricsTab extends StatefulWidget {
  const _TeacherRubricsTab({
    required this.teacherId,
    required this.activities,
    required this.onChanged,
  });

  final String teacherId;
  final List<DbActivity> activities;
  final VoidCallback onChanged;

  @override
  State<_TeacherRubricsTab> createState() => _TeacherRubricsTabState();
}

class _TeacherRubricsTabState extends State<_TeacherRubricsTab> {
  late Future<List<TeacherRubricDefinition>> _future =
      MobileDataService.fetchTeacherRubrics(widget.teacherId);

  Future<void> _refresh() async {
    final future = MobileDataService.fetchTeacherRubrics(widget.teacherId);
    setState(() => _future = future);
    await future;
    widget.onChanged();
  }

  List<_RubricCriterionDraft> _starterCriteria(String activityType) {
    final names = switch (activityType) {
      'paint' => const [
        'Follows the activity’s color instructions',
        'Applies color carefully to the intended areas',
        'Completes the requested coloring details',
      ],
      'scene' => const [
        'Selects objects that fit the activity instructions',
        'Arranges objects in the requested positions',
        'Creates a complete and recognizable scene',
      ],
      'puzzle' => const [
        'Matches each puzzle piece to its correct location',
        'Positions and connects the puzzle pieces accurately',
        'Completes the puzzle with growing independence',
      ],
      _ => const [''],
    };
    return names.map(_RubricCriterionDraft.new).toList();
  }

  Future<void> _editorDialog([TeacherRubricDefinition? source]) async {
    final titleController = TextEditingController(
      text: source == null ? '' : '${source.title} (copy)',
    );
    var activityType = source?.activityType ?? 'general';
    var criteria = source?.criteria.isNotEmpty == true
        ? source!.criteria.map(_RubricCriterionDraft.fromCriterion).toList()
        : _starterCriteria(activityType);
    var selectedActivityId = '';
    var busy = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final title = titleController.text.trim();
            final valid = criteria
                .where((criterion) => criterion.name.text.trim().isNotEmpty)
                .toList();
            if (title.isEmpty || valid.isEmpty) {
              setDialogState(
                () => error =
                    'Enter a rubric name and at least one observable skill.',
              );
              return;
            }
            final hasIncompleteLevels = valid.any(
              (criterion) =>
                  criterion.beginning.text.trim().isEmpty ||
                  criterion.developing.text.trim().isEmpty ||
                  criterion.consistent.text.trim().isEmpty,
            );
            if (hasIncompleteLevels) {
              setDialogState(
                () => error =
                    'Describe Beginning, Developing, and Consistent for every skill.',
              );
              return;
            }
            setDialogState(() {
              busy = true;
              error = null;
            });
            final created = await MobileDataService.createTeacherRubric(
              teacherId: widget.teacherId,
              title: title,
              activityType: activityType,
              criteria: valid.map((criterion) => criterion.toJson()).toList(),
            );
            if (!created.result.success) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  busy = false;
                  error = _cleanDatabaseError(created.result.error);
                });
              }
              return;
            }
            String? attachmentError;
            if (selectedActivityId.isNotEmpty) {
              final attached = await MobileDataService.attachTeacherRubric(
                selectedActivityId,
                created.rubricId,
              );
              if (!attached.success) {
                attachmentError = _cleanDatabaseError(attached.error);
              }
            }
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            await _refresh();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  attachmentError == null
                      ? selectedActivityId.isEmpty
                            ? 'Rubric saved.'
                            : 'Rubric saved and attached.'
                      : 'Rubric saved, but attachment failed: $attachmentError',
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text(source == null ? 'Create rubric' : 'Use as copy'),
            content: SizedBox(
              width: 720,
              height: math.min(MediaQuery.sizeOf(context).height * 0.68, 720),
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: activityType,
                    decoration: const InputDecoration(
                      labelText: 'Activity type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('General / not specified'),
                      ),
                      DropdownMenuItem(
                        value: 'paint',
                        child: Text('Painting / coloring'),
                      ),
                      DropdownMenuItem(
                        value: 'scene',
                        child: Text('Creative scene building'),
                      ),
                      DropdownMenuItem(
                        value: 'puzzle',
                        child: Text('Puzzle assembly'),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) {
                            if (value == null) return;
                            for (final criterion in criteria) {
                              criterion.dispose();
                            }
                            setDialogState(() {
                              activityType = value;
                              criteria = _starterCriteria(value);
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Rubric name',
                      hintText: 'e.g. Cactus Coloring',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Rubric criteria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Describe what Beginning, Developing, and Consistent look like for each skill.',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 10),
                  ...criteria.indexed.map((entry) {
                    final index = entry.$1;
                    final criterion = entry.$2;
                    return _CardShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Criterion ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (criteria.length > 1)
                                IconButton(
                                  onPressed: busy
                                      ? null
                                      : () => setDialogState(() {
                                          criteria.removeAt(index).dispose();
                                        }),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  tooltip: 'Remove criterion',
                                ),
                            ],
                          ),
                          TextField(
                            controller: criterion.name,
                            enabled: !busy,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observable skill',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: criterion.beginning,
                            enabled: !busy,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Beginning',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: criterion.developing,
                            enabled: !busy,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Developing',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: criterion.consistent,
                            enabled: !busy,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Consistent',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => setDialogState(
                              () => criteria.add(_RubricCriterionDraft()),
                            ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add criterion'),
                    ),
                  ),
                  if (widget.activities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedActivityId,
                      decoration: const InputDecoration(
                        labelText: 'Attach now (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Attach later'),
                        ),
                        ...widget.activities.map(
                          (activity) => DropdownMenuItem(
                            value: activity.id,
                            child: Text(activity.title),
                          ),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => setDialogState(
                              () => selectedActivityId = value ?? '',
                            ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'Saving…' : 'Save rubric'),
              ),
            ],
          );
        },
      ),
    );
    titleController.dispose();
    for (final criterion in criteria) {
      criterion.dispose();
    }
  }

  Future<void> _attachDialog(
    List<TeacherRubricDefinition> rubrics, [
    TeacherRubricDefinition? initial,
  ]) async {
    if (widget.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an activity before attaching a rubric.'),
        ),
      );
      return;
    }
    var activityId = widget.activities.first.id;
    var rubricId = initial?.id ?? rubrics.first.id;
    var busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Attach saved rubric'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: activityId,
                decoration: const InputDecoration(labelText: 'Activity'),
                items: widget.activities
                    .map(
                      (activity) => DropdownMenuItem(
                        value: activity.id,
                        child: Text(activity.title),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setDialogState(
                        () => activityId = value ?? activityId,
                      ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: rubricId,
                decoration: const InputDecoration(labelText: 'Saved rubric'),
                items: rubrics
                    .map(
                      (rubric) => DropdownMenuItem(
                        value: rubric.id,
                        child: Text(rubric.title),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) =>
                          setDialogState(() => rubricId = value ?? rubricId),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final result =
                          await MobileDataService.attachTeacherRubric(
                            activityId,
                            rubricId,
                          );
                      if (!dialogContext.mounted) return;
                      if (!result.success) {
                        setDialogState(() {
                          busy = false;
                          error = _cleanDatabaseError(result.error);
                        });
                        return;
                      }
                      Navigator.pop(dialogContext);
                      widget.onChanged();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rubric attached.')),
                        );
                      }
                    },
              child: Text(busy ? 'Attaching…' : 'Attach'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRubric(TeacherRubricDefinition rubric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unused rubric?'),
        content: Text(
          'Delete ${rubric.title}? Rubrics attached to activities are protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await MobileDataService.deleteTeacherRubric(rubric.id);
    if (result.success) await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Rubric deleted.'
              : _cleanDatabaseError(result.error),
        ),
      ),
    );
  }

  String _cleanDatabaseError(String? error) {
    return (error ?? 'The request could not be completed.')
        .replaceFirst(RegExp(r'^(PostgrestException|Exception):\s*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TeacherRubricDefinition>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error!, onRetry: _refresh);
        }
        final rubrics = snapshot.data ?? const [];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const _PageTitle('Rubrics'),
              const SizedBox(height: 5),
              const Text(
                'Create criteria for activity scoring and final teacher review.',
                style: TextStyle(color: _muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  if (rubrics.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _attachDialog(rubrics),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Attach rubric'),
                    ),
                  FilledButton.icon(
                    onPressed: () => _editorDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create rubric'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Saved rubrics'),
              if (rubrics.isEmpty)
                const _EmptyCard(
                  icon: Icons.fact_check_outlined,
                  title: 'No saved rubrics yet',
                  body:
                      'Create one to guide activity checks and teacher review.',
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: rubrics.indexed.map((entry) {
                      final rubric = entry.$2;
                      return Column(
                        children: [
                          if (entry.$1 > 0) const Divider(indent: 54),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fact_check_outlined,
                                  color: _muted,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rubric.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        rubric.criteriaSummary.isEmpty
                                            ? 'No criteria'
                                            : rubric.criteriaSummary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Manage ${rubric.title}',
                                  onSelected: (action) {
                                    if (action == 'copy') {
                                      _editorDialog(rubric);
                                    } else if (action == 'attach') {
                                      _attachDialog(rubrics, rubric);
                                    } else if (action == 'delete') {
                                      _deleteRubric(rubric);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'copy',
                                      child: Text('Use as copy'),
                                    ),
                                    PopupMenuItem(
                                      value: 'attach',
                                      child: Text('Attach to activity'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RubricCriterionDraft {
  _RubricCriterionDraft([String name = ''])
    : name = TextEditingController(text: name),
      beginning = TextEditingController(text: _rubricBeginningDescription),
      developing = TextEditingController(text: _rubricDevelopingDescription),
      consistent = TextEditingController(text: _rubricConsistentDescription);

  _RubricCriterionDraft.fromCriterion(TeacherRubricCriterion criterion)
    : name = TextEditingController(text: criterion.name),
      beginning = TextEditingController(text: criterion.beginning),
      developing = TextEditingController(text: criterion.developing),
      consistent = TextEditingController(text: criterion.consistent);

  final TextEditingController name;
  final TextEditingController beginning;
  final TextEditingController developing;
  final TextEditingController consistent;

  Map<String, dynamic> toJson() => {
    'name': name.text.trim(),
    'levels': [
      {
        'code': 'BG',
        'label': 'Beginning',
        'description': beginning.text.trim(),
      },
      {
        'code': 'DV',
        'label': 'Developing',
        'description': developing.text.trim(),
      },
      {
        'code': 'CO',
        'label': 'Consistent',
        'description': consistent.text.trim(),
      },
    ],
  };

  void dispose() {
    name.dispose();
    beginning.dispose();
    developing.dispose();
    consistent.dispose();
  }
}

class _TeacherModelsTab extends StatefulWidget {
  const _TeacherModelsTab();

  @override
  State<_TeacherModelsTab> createState() => _TeacherModelsTabState();
}

class _TeacherModelsTabState extends State<_TeacherModelsTab> {
  final _searchController = TextEditingController();
  final _catalogSearchController = TextEditingController();
  late Future<List<SandboxModelOption>> _future = fetchSandboxModels();
  List<FreeModelCatalogItem> _catalogResults = const [];
  bool _catalogSearching = false;
  String _importingCatalogId = '';
  String? _catalogMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _catalogSearchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = fetchSandboxModels();
    setState(() => _future = future);
    await future;
  }

  Future<void> _searchFreeCatalog() async {
    final query = _catalogSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _catalogResults = const [];
        _catalogMessage = 'Enter a keyword such as animal, fruit, or mask.';
      });
      return;
    }
    setState(() {
      _catalogSearching = true;
      _catalogMessage = null;
    });
    try {
      final results = await MobileModelLibraryService.searchFreeCatalog(query);
      if (!mounted) return;
      setState(() {
        _catalogResults = results;
        _catalogSearching = false;
        _catalogMessage = results.isEmpty
            ? 'No matching free models found.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogResults = const [];
        _catalogSearching = false;
        _catalogMessage = _friendlyModelError(error);
      });
    }
  }

  Future<void> _importFreeModel(FreeModelCatalogItem item) async {
    if (_importingCatalogId.isNotEmpty) return;
    setState(() {
      _importingCatalogId = item.id;
      _catalogMessage = null;
    });
    try {
      await MobileModelLibraryService.importFreeModel(item);
      await _refresh();
      if (!mounted) return;
      setState(() => _importingCatalogId = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} imported with attribution.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _importingCatalogId = '';
        _catalogMessage = _friendlyModelError(error);
      });
    }
  }

  Future<PlatformFile?> _pickModelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['obj', '3ds', 'glb', 'blend'],
      withData: true,
    );
    return result?.files.singleOrNull;
  }

  Future<void> _modelEditorDialog([SandboxModelOption? model]) async {
    final nameController = TextEditingController(text: model?.label ?? '');
    final descriptionController = TextEditingController(
      text: model?.description ?? '',
    );
    PlatformFile? selectedFile;
    var busy = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: !busy,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final label = nameController.text.trim();
            if (label.isEmpty) {
              setDialogState(() => error = 'Model name is required.');
              return;
            }
            final validation = MobileModelLibraryService.validateFile(
              selectedFile,
              required: model == null,
            );
            if (validation.isNotEmpty) {
              setDialogState(() => error = validation);
              return;
            }
            setDialogState(() {
              busy = true;
              error = null;
            });
            try {
              if (model == null) {
                await MobileModelLibraryService.upload(
                  label: label,
                  description: descriptionController.text,
                  file: selectedFile!,
                );
              } else {
                await MobileModelLibraryService.update(
                  model: model,
                  label: label,
                  description: descriptionController.text,
                  replacement: selectedFile,
                );
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _refresh();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    model == null ? '3D model added.' : '3D model updated.',
                  ),
                ),
              );
            } catch (saveError) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                busy = false;
                error = _friendlyModelError(saveError);
              });
            }
          }

          return AlertDialog(
            title: Text(model == null ? 'Add 3D model' : 'Edit 3D model'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !busy,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      enabled: !busy,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final file = await _pickModelFile();
                              if (file != null && dialogContext.mounted) {
                                setDialogState(() {
                                  selectedFile = file;
                                  error = null;
                                });
                              }
                            },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        selectedFile?.name ??
                            (model == null
                                ? 'Choose model file'
                                : 'Replace file (optional)'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '.obj, .3ds, .glb, or .blend · maximum 50 MB',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    if (selectedFile?.extension?.toLowerCase() == 'blend')
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Blender files are stored as source files. Convert to .glb before using them in AR.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Saving…'
                      : model == null
                      ? 'Add model'
                      : 'Save',
                ),
              ),
            ],
          );
        },
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _removeModel(SandboxModelOption model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove 3D model?'),
        content: Text(
          'Remove ${model.label} from the shared library? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MobileModelLibraryService.delete(model);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('3D model removed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyModelError(error))));
    }
  }

  String _friendlyModelError(Object error) {
    return error.toString().replaceFirst(
      RegExp(r'^(StateError|Exception):\s*'),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SandboxModelOption>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final query = _searchController.text.trim().toLowerCase();
        final models = (snapshot.data ?? sandboxFallbackModels).where((model) {
          return query.isEmpty ||
              model.label.toLowerCase().contains(query) ||
              model.description.toLowerCase().contains(query) ||
              model.fileType.toLowerCase().contains(query);
        }).toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const _HeroPanel(
                title: '3D Model Library',
                subtitle: 'Search and manage models shared with activities.',
                trailing: Icon(
                  Icons.view_in_ar_rounded,
                  color: _primary,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _modelEditorDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add model'),
                ),
              ),
              const SizedBox(height: 12),
              _CardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find Free Models (Poly Pizza)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search and import free CC-BY or CC0 models. Creator attribution is saved with every import.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _catalogSearchController,
                      enabled: !_catalogSearching,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchFreeCatalog(),
                      decoration: InputDecoration(
                        hintText: 'Try mask, bottle, fruit, or animal',
                        prefixIcon: const Icon(Icons.travel_explore_rounded),
                        suffixIcon: IconButton(
                          onPressed: _catalogSearching
                              ? null
                              : _searchFreeCatalog,
                          tooltip: 'Search Poly Pizza',
                          icon: _catalogSearching
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    if (_catalogMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _catalogMessage!,
                        style: TextStyle(
                          color: _catalogResults.isEmpty
                              ? const Color(0xFF8A2B21)
                              : _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_catalogResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._catalogResults.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CardShell(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FreeModelThumbnail(url: item.thumbnailUrl),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        [
                                          if (item.category.isNotEmpty)
                                            item.category,
                                          if (item.creator.isNotEmpty)
                                            item.creator,
                                          if (item.license.isNotEmpty)
                                            item.license,
                                        ].join(' · '),
                                        style: const TextStyle(color: _muted),
                                      ),
                                      if (item.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: _importingCatalogId.isEmpty
                                      ? () => _importFreeModel(item)
                                      : null,
                                  child: Text(
                                    _importingCatalogId == item.id
                                        ? 'Importing…'
                                        : 'Import',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Shared model library'),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search models or file type',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Refresh models',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (models.isEmpty)
                const _EmptyCard(
                  icon: Icons.search_off_rounded,
                  title: 'No matching models',
                  body: 'Try a model name such as cactus, tree, or bottle.',
                )
              else
                ...models.map(
                  (model) => _CardShell(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF0EEFC),
                        foregroundColor: _primary,
                        child: const Icon(Icons.view_in_ar_rounded),
                      ),
                      title: Text(
                        model.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        [
                          model.fileType.toUpperCase(),
                          if (model.description.isNotEmpty) model.description,
                          if (model.source.isNotEmpty && !model.isBuiltIn)
                            [
                              model.source,
                              model.license,
                            ].where((item) => item.isNotEmpty).join(' · '),
                        ].join(' · '),
                      ),
                      trailing: model.canManage
                          ? PopupMenuButton<String>(
                              tooltip: 'Manage ${model.label}',
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _modelEditorDialog(model);
                                } else if (action == 'remove') {
                                  _removeModel(model);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                    ),
                                    title: Text('Remove'),
                                  ),
                                ),
                              ],
                            )
                          : Chip(
                              label: Text(
                                model.fileType == 'blend'
                                    ? 'Source'
                                    : model.isBuiltIn
                                    ? 'Built in'
                                    : 'Shared',
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FreeModelThumbnail extends StatelessWidget {
  const _FreeModelThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        uri.toString(),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFFF0EEFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.view_in_ar_rounded, color: _primary),
  );
}

class _TeacherSettingsTab extends StatefulWidget {
  const _TeacherSettingsTab({required this.userId});

  final String userId;

  @override
  State<_TeacherSettingsTab> createState() => _TeacherSettingsTabState();
}

class _TeacherSettingsTabState extends State<_TeacherSettingsTab> {
  bool _loading = true;
  bool _saving = false;
  TeacherMobileSettings _settings = const TeacherMobileSettings();
  String? _message;
  String _avatarPath = '';
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        MobileDataService.fetchTeacherSettings(widget.userId),
        MobileDataService.fetchUserAvatarPath(widget.userId),
      ]);
      final settings = results[0] as TeacherMobileSettings;
      if (mounted) {
        setState(() {
          _settings = settings;
          _avatarPath = results[1] as String;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Settings could not sync. Default settings are shown.';
        });
      }
    }
  }

  Future<void> _chooseAvatar() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    final contentType = _pickedImageMimeType(file);
    if (file.size > r2MediaMaxUploadBytes ||
        bytes == null ||
        contentType == null) {
      setState(() {
        _message = file.size > r2MediaMaxUploadBytes
            ? 'Image is too large. Maximum size is 20 MB.'
            : 'Use a PNG, JPG, or WebP image.';
      });
      return;
    }

    setState(() {
      _avatarBusy = true;
      _message = null;
    });
    try {
      final path = await R2MediaService.upload(
        R2MediaKind.avatars,
        widget.userId,
        bytes,
        contentType,
      );
      final result = await MobileDataService.setUserAvatarPath(
        widget.userId,
        path,
      );
      if (!result.success) {
        await R2MediaService.delete(
          R2MediaKind.avatars,
          widget.userId,
        ).catchError((_) {});
        throw R2MediaException(
          result.error ?? 'Unable to save the profile picture.',
        );
      }
      if (mounted) {
        setState(() {
          _avatarPath = path;
          _message = 'Profile picture updated.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _avatarBusy = true;
      _message = null;
    });
    try {
      final result = await MobileDataService.setUserAvatarPath(
        widget.userId,
        null,
      );
      if (!result.success) {
        throw R2MediaException(
          result.error ?? 'Unable to remove the profile picture.',
        );
      }
      await R2MediaService.delete(
        R2MediaKind.avatars,
        widget.userId,
      ).catchError((_) {});
      if (mounted) {
        setState(() {
          _avatarPath = '';
          _message = 'Profile picture removed.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final result = await MobileDataService.saveTeacherSettings(
      widget.userId,
      _settings,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = result.success
          ? 'Settings saved.'
          : result.error ?? 'Settings could not be saved.';
    });
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    TeacherMobileSettings Function(bool value) update,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (value) => setState(() => _settings = update(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _HeroPanel(
          title: 'Settings',
          subtitle: 'Control classroom alerts and AR guidance.',
          trailing: Icon(Icons.settings_rounded, color: _primary, size: 46),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Profile picture'),
        _CardShell(
          child: Row(
            children: [
              _PrivateR2Image(
                key: ValueKey('teacher-avatar-${widget.userId}-$_avatarPath'),
                kind: R2MediaKind.avatars,
                ownerId: widget.userId,
                legacyPath: _avatarPath,
                size: 76,
                fallback: const CircleAvatar(
                  radius: 38,
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 38),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _avatarBusy ? null : _chooseAvatar,
                      icon: _avatarBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(
                        _avatarPath.isEmpty ? 'Upload photo' : 'Change photo',
                      ),
                    ),
                    if (_avatarPath.isNotEmpty)
                      TextButton(
                        onPressed: _avatarBusy ? null : _removeAvatar,
                        child: const Text('Remove photo'),
                      ),
                    const Text(
                      'PNG, JPG, or WebP up to 20 MB. Stored privately in Cloudflare R2.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'AR experience'),
        _CardShell(
          child: Column(
            children: [
              _toggle(
                'Voice instructions',
                'Read guidance aloud during AR activities.',
                _settings.voiceInstructions,
                (value) => _settings.copyWith(voiceInstructions: value),
              ),
              _toggle(
                'Sound effects',
                'Play interaction and completion sounds.',
                _settings.soundEffects,
                (value) => _settings.copyWith(soundEffects: value),
              ),
              _toggle(
                'Background music',
                'Play music in supported learning scenes.',
                _settings.backgroundMusic,
                (value) => _settings.copyWith(backgroundMusic: value),
              ),
              _toggle(
                'Data saver',
                'Reduce rich media when possible.',
                _settings.dataSaver,
                (value) => _settings.copyWith(dataSaver: value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _settings.quality,
                decoration: const InputDecoration(labelText: 'Visual quality'),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Automatic')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) => setState(
                  () =>
                      _settings = _settings.copyWith(quality: value ?? 'auto'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Notifications'),
        _CardShell(
          child: Column(
            children: [
              _toggle(
                'In-app notifications',
                'Show classroom updates inside e-Likha.',
                _settings.inAppEnabled,
                (value) => _settings.copyWith(inAppEnabled: value),
              ),
              _toggle(
                'Email notifications',
                'Send important classroom updates by email.',
                _settings.emailEnabled,
                (value) => _settings.copyWith(emailEnabled: value),
              ),
              _toggle(
                'Activity updates',
                'Notify when activities are assigned.',
                _settings.activityAssigned,
                (value) => _settings.copyWith(activityAssigned: value),
              ),
              _toggle(
                'Review updates',
                'Notify when reviewed work is posted.',
                _settings.gradePosted,
                (value) => _settings.copyWith(gradePosted: value),
              ),
              _toggle(
                'Due soon and missing work',
                'Show deadline and missing-work reminders.',
                _settings.dueSoon && _settings.missingWork,
                (value) =>
                    _settings.copyWith(dueSoon: value, missingWork: value),
              ),
              _toggle(
                'Account updates',
                'Show important account and security notices.',
                _settings.accountUpdates,
                (value) => _settings.copyWith(accountUpdates: value),
              ),
            ],
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: TextStyle(
              color:
                  _message == 'Settings saved.' ||
                      _message == 'Profile picture updated.' ||
                      _message == 'Profile picture removed.'
                  ? _ink
                  : const Color(0xFF8A2B21),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Saving…' : 'Save settings'),
        ),
      ],
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(child: _TeacherSettingsTab(userId: userId)),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.userId});

  final String userId;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<DbNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileDataService.fetchNotifications(widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.fetchNotifications(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<DbNotification>>(
        future: _future,
        builder: (context, snapshot) => _DataSurface(
          loading: snapshot.connectionState != ConnectionState.done,
          error: snapshot.error,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _NotificationSection(
                userId: widget.userId,
                notifications: snapshot.data ?? const [],
                limit: 100,
                onChanged: _refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherReportsTab extends StatelessWidget {
  const _TeacherReportsTab({
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
    final data = bundle;
    final assigned =
        data?.activities.fold<int>(
          0,
          (sum, item) => sum + item.assignmentCount,
        ) ??
        0;
    final submitted = data?.submissions.length ?? 0;
    final reviewed =
        data?.submissions.where((item) => item.isReviewed).length ?? 0;
    final completion = assigned == 0 ? 0.0 : submitted / assigned;
    final reviewRate = submitted == 0 ? 0.0 : reviewed / submitted;
    final scores =
        data?.submissions
            .where((item) => item.isReviewed)
            .map((item) => item.score)
            .whereType<num>()
            .toList() ??
        const <num>[];
    final averageStars = scores.isEmpty
        ? null
        : scores.fold<double>(0, (sum, item) => sum + item.toDouble()) /
              scores.length;
    final insights = _buildMobileTeacherInsights(
      data?.submissions ?? const [],
      data?.students ?? const [],
      data?.rubricEvidence ?? const [],
    );

    return _DataSurface(
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PageTitle('Reports'),
          const SizedBox(height: 5),
          const Text(
            'Completion, review pace, and evidence across your classes.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _TeacherStatRail(
            metrics: [
              _MetricData('Completion', '${(completion * 100).round()}%'),
              _MetricData('Reviewed', '${(reviewRate * 100).round()}%'),
              _MetricData(
                'Average stars',
                averageStars == null ? 'N/A' : averageStars.toStringAsFixed(1),
              ),
              _MetricData('Needs review', data?.pendingReviews.length ?? 0),
            ],
          ),
          const SizedBox(height: 20),
          _TeacherReportChart(
            completion: completion,
            reviewRate: reviewRate,
            pendingRate: submitted == 0
                ? 0
                : (data?.pendingReviews.length ?? 0) / submitted,
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'Student insights'),
          const SizedBox(height: 4),
          const Text(
            'Rankings use saved AR activity data and reviewed teacher ratings. Tap evidence to see the source.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 580
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: insights
                    .map(
                      (insight) => SizedBox(
                        width: width,
                        child: _MobileInsightCard(insight: insight),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'Gesture alerts'),
          const SizedBox(height: 8),
          if ((data?.gestureAlerts ?? []).isEmpty)
            const _EmptyCard(
              icon: Icons.verified_outlined,
              title: 'No gesture alerts',
              body: 'No AR safety alerts need attention.',
            )
          else
            ...data!.gestureAlerts
                .take(5)
                .map((alert) => _GestureAlertTile(alert: alert)),
        ],
      ),
    );
  }
}

class _TeacherReportChart extends StatelessWidget {
  const _TeacherReportChart({
    required this.completion,
    required this.reviewRate,
    required this.pendingRate,
  });

  final double completion;
  final double reviewRate;
  final double pendingRate;

  @override
  Widget build(BuildContext context) {
    final values = [
      completion,
      reviewRate,
      pendingRate,
    ].map((value) => (value.clamp(0, 1) * 100).toDouble()).toList();
    const labels = ['Complete', 'Reviewed', 'Pending'];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow health',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share of assigned or submitted work',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: _border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: values.indexed
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.$1,
                        barRods: [
                          BarChartRodData(
                            toY: entry.$2,
                            width: 24,
                            color: _primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: const Color(0xFFF1F1F4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileTeacherInsight {
  const _MobileTeacherInsight({
    required this.title,
    required this.student,
    required this.value,
    required this.progress,
    required this.description,
    required this.evidenceCount,
    required this.rankings,
    this.evidence = const [],
  });
  final String title;
  final String student;
  final String value;
  final double? progress;
  final String description;
  final int evidenceCount;
  final List<_MobileInsightRanking> rankings;
  final List<String> evidence;
}

class _MobileInsightRanking {
  const _MobileInsightRanking({
    required this.rank,
    required this.student,
    required this.value,
    required this.evidenceCount,
    required this.qualified,
  });

  final int? rank;
  final String student;
  final String value;
  final int evidenceCount;
  final bool qualified;
}

class _MobileStudentInsightStats {
  const _MobileStudentInsightStats({
    required this.name,
    required this.fastestSeconds,
    required this.fastestEvidence,
    required this.colorScore,
    required this.colorEvidence,
    required this.puzzleScore,
    required this.puzzleEvidence,
    required this.consistency,
    required this.consistencyEvidence,
    required this.improvementStars,
    required this.improvementEvidence,
    required this.improvementDetails,
    required this.overallScore,
    required this.overallEvidence,
  });

  final String name;
  final double? fastestSeconds;
  final int fastestEvidence;
  final double? colorScore;
  final int colorEvidence;
  final double? puzzleScore;
  final int puzzleEvidence;
  final double? consistency;
  final int consistencyEvidence;
  final double? improvementStars;
  final int improvementEvidence;
  final List<String> improvementDetails;
  final double? overallScore;
  final int overallEvidence;
}

List<_MobileTeacherInsight> _buildMobileTeacherInsights(
  List<DbSubmission> submissions,
  List<DbStudent> students,
  List<TeacherRubricEvidence> rubricEvidence,
) {
  final byStudent = <String, List<DbSubmission>>{};
  final names = <String, String>{};
  for (final student in students) {
    names[student.id] = student.name;
    byStudent.putIfAbsent(student.id, () => []);
  }
  final enrolledStudentIds = students.map((student) => student.id).toSet();
  for (final submission in submissions) {
    if (enrolledStudentIds.isNotEmpty &&
        !enrolledStudentIds.contains(submission.studentId)) {
      continue;
    }
    final currentName = names[submission.studentId] ?? '';
    if (_isGenericStudentName(currentName) &&
        !_isGenericStudentName(submission.studentName)) {
      names[submission.studentId] = submission.studentName;
    }
    byStudent.putIfAbsent(submission.studentId, () => []).add(submission);
  }
  final stats = <_MobileStudentInsightStats>[];

  for (final entry in byStudent.entries) {
    final rows = entry.value;
    final name = names[entry.key] ?? 'Student';
    final studentRubric = rubricEvidence
        .where((item) => item.studentId == entry.key && item.value != null)
        .toList();
    final colorRubric = studentRubric
        .where((item) => item.category == 'coloring')
        .map((item) => item.value!)
        .toList();
    final puzzleRubric = studentRubric
        .where((item) => item.category == 'puzzle')
        .map((item) => item.value!)
        .toList();
    final colorValues = <double>[];
    final puzzleAccuracy = <double>[];
    final puzzleSpeed = <double>[];
    final qualifyingDurations = <double>[];
    for (final row in rows) {
      final analytics = _submissionAnalytics(row.rawDescription);
      final color = _nestedNum(analytics, 'coloring', 'accuracyPercent');
      final puzzle = _nestedNum(analytics, 'puzzle', 'accuracyPercent');
      final puzzleSeconds = _nestedNum(
        analytics,
        'puzzle',
        'completionSeconds',
      );
      final duration = _asDouble(analytics['activeDurationSeconds']);
      if (color != null) colorValues.add(color / 100);
      if (puzzle != null) puzzleAccuracy.add(puzzle / 100);
      if (puzzleSeconds != null && puzzleSeconds > 0) {
        puzzleSpeed.add(1 / (1 + puzzleSeconds / 60));
      }
      if (duration != null &&
          duration > 0 &&
          row.isReviewed &&
          (row.score?.toDouble() ?? 0) >= 4) {
        qualifyingDurations.add(duration);
      }
    }
    final colorScore = _mobileAverage([...colorValues, ...colorRubric]);
    final puzzleParts = <double?>[
      _mobileAverage(puzzleAccuracy),
      _mobileAverage(puzzleRubric),
      _mobileAverage(puzzleSpeed),
    ].whereType<double>().toList();
    final puzzleScore = _mobileAverage(puzzleParts);
    final reviewedRows =
        rows
            .where(
              (row) =>
                  row.isReviewed && row.score != null && row.reviewedAt != null,
            )
            .toList()
          ..sort((a, b) => a.reviewedAt!.compareTo(b.reviewedAt!));
    double? consistencyScore;
    double? improvementStars;
    var improvementDetails = const <String>[];
    if (reviewedRows.length >= 2) {
      final values = reviewedRows.map((row) => row.score!.toDouble()).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values
              .map((value) => math.pow(value - mean, 2).toDouble())
              .reduce((a, b) => a + b) /
          values.length;
      consistencyScore = (1 - math.sqrt(variance) / 5).clamp(0, 1).toDouble();
      final first = reviewedRows.first;
      final recent = reviewedRows.last;
      improvementStars = recent.score!.toDouble() - first.score!.toDouble();
      improvementDetails = [
        'Earlier: ${first.activityTitle} — ${first.score!.toDouble().toStringAsFixed(1)}/5 stars — ${_formatDate(first.reviewedAt)}',
        'Recent: ${recent.activityTitle} — ${recent.score!.toDouble().toStringAsFixed(1)}/5 stars — ${_formatDate(recent.reviewedAt)}',
        'Calculation: ${recent.score!.toDouble().toStringAsFixed(1)} − ${first.score!.toDouble().toStringAsFixed(1)} = ${improvementStars >= 0 ? '+' : ''}${improvementStars.toStringAsFixed(1)} stars',
      ];
    }
    final reviewedAverage = _mobileAverage(
      reviewedRows.map((row) => row.score!.toDouble() / 5).toList(),
    );
    final overallActivityIds = <String>{
      ...rows
          .where(
            (row) =>
                row.isReviewed ||
                _submissionAnalytics(row.rawDescription).isNotEmpty,
          )
          .map((row) => row.activityId),
      ...studentRubric.map((item) => item.activityId),
    }..removeWhere((id) => id.isEmpty);
    final combinedOverall = _mobileAverage(
      <double?>[
        reviewedAverage,
        colorScore,
        puzzleScore,
      ].whereType<double>().toList(),
    );
    final overallScore = overallActivityIds.length >= 2
        ? combinedOverall
        : null;
    stats.add(
      _MobileStudentInsightStats(
        name: name,
        fastestSeconds: qualifyingDurations.isEmpty
            ? null
            : qualifyingDurations.reduce(math.min),
        fastestEvidence: qualifyingDurations.length,
        colorScore: colorScore,
        colorEvidence: colorValues.length + colorRubric.length,
        puzzleScore: puzzleScore,
        puzzleEvidence: puzzleAccuracy.length + puzzleRubric.length,
        consistency: consistencyScore,
        consistencyEvidence: reviewedRows.length,
        improvementStars: improvementStars,
        improvementEvidence: reviewedRows.length,
        improvementDetails: improvementDetails,
        overallScore: overallScore,
        overallEvidence: overallActivityIds.length,
      ),
    );
  }

  _MobileTeacherInsight item(
    String title,
    _MobileStudentInsightStats? winner,
    String Function(_MobileStudentInsightStats) value,
    double? Function(_MobileStudentInsightStats) progress,
    String description,
    int Function(_MobileStudentInsightStats) evidenceCount,
    List<_MobileInsightRanking> rankings, {
    List<String> Function(_MobileStudentInsightStats)? evidence,
  }) {
    if (winner == null) {
      return _MobileTeacherInsight(
        title: title,
        student: 'Not enough data yet',
        value: '—',
        progress: null,
        description:
            'There is not enough verified evidence yet to explain a leader in this category.',
        evidenceCount: 0,
        rankings: rankings,
      );
    }
    final result = value(winner);
    final count = evidenceCount(winner);
    _MobileInsightRanking? runnerUp;
    for (final item in rankings) {
      if (item.qualified && item.student != winner.name) {
        runnerUp = item;
        break;
      }
    }
    final comparison = runnerUp == null
        ? 'No other learner currently has enough comparable evidence to place above this result.'
        : 'The next ranked learner is ${runnerUp.student} at ${runnerUp.value}.';
    return _MobileTeacherInsight(
      title: title,
      student: winner.name,
      value: result,
      progress: progress(winner),
      description:
          '${winner.name} leads with $result, calculated from $count qualifying evidence record${count == 1 ? '' : 's'}. $comparison $description',
      evidenceCount: count,
      rankings: rankings,
      evidence: evidence?.call(winner) ?? const [],
    );
  }

  _MobileStudentInsightStats? winnerFor(
    double? Function(_MobileStudentInsightStats) score, {
    bool ascending = false,
    bool positiveOnly = false,
  }) {
    final candidates =
        stats.where((item) {
          final value = score(item);
          return value != null && (!positiveOnly || value > 0);
        }).toList()..sort((left, right) {
          final a = score(left)!;
          final b = score(right)!;
          final comparison = ascending ? a.compareTo(b) : b.compareTo(a);
          return comparison != 0 ? comparison : left.name.compareTo(right.name);
        });
    return candidates.isEmpty ? null : candidates.first;
  }

  List<_MobileInsightRanking> rankingsFor(
    double? Function(_MobileStudentInsightStats) score,
    String Function(double) value,
    int Function(_MobileStudentInsightStats) evidenceCount, {
    bool ascending = false,
  }) {
    final qualified = stats.where((item) => score(item) != null).toList()
      ..sort((left, right) {
        final a = score(left)!;
        final b = score(right)!;
        final comparison = ascending ? a.compareTo(b) : b.compareTo(a);
        return comparison != 0 ? comparison : left.name.compareTo(right.name);
      });
    final unavailable = stats.where((item) => score(item) == null).toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return [
      for (var index = 0; index < qualified.length; index++)
        _MobileInsightRanking(
          rank: index + 1,
          student: qualified[index].name,
          value: value(score(qualified[index])!),
          evidenceCount: evidenceCount(qualified[index]),
          qualified: true,
        ),
      for (final item in unavailable)
        _MobileInsightRanking(
          rank: null,
          student: item.name,
          value: 'Not enough data',
          evidenceCount: 0,
          qualified: false,
        ),
    ];
  }

  String percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
  String improvement(double value) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)} stars';
  final fastest = winnerFor((item) => item.fastestSeconds, ascending: true);
  final coloring = winnerFor((item) => item.colorScore);
  final puzzle = winnerFor((item) => item.puzzleScore);
  final consistent = winnerFor((item) => item.consistency);
  final improved = winnerFor(
    (item) => item.improvementStars,
    positiveOnly: true,
  );
  final overall = winnerFor((item) => item.overallScore);
  return [
    item(
      'Fastest high-quality finish',
      fastest,
      (item) => '${math.max(1, (item.fastestSeconds! / 60).round())} min',
      (_) => null,
      'Requires a reviewed rating of at least 4/5.',
      (item) => item.fastestEvidence,
      rankingsFor(
        (item) => item.fastestSeconds,
        (value) => '${math.max(1, (value / 60).round())} min',
        (item) => item.fastestEvidence,
        ascending: true,
      ),
    ),
    item(
      'Strongest in coloring',
      coloring,
      (item) => percent(item.colorScore!),
      (item) => item.colorScore,
      'Based on expected-color accuracy saved by AR.',
      (item) => item.colorEvidence,
      rankingsFor(
        (item) => item.colorScore,
        percent,
        (item) => item.colorEvidence,
      ),
    ),
    item(
      'Strongest in puzzle',
      puzzle,
      (item) => percent(item.puzzleScore!),
      (item) => item.puzzleScore,
      'Based on puzzle connections, attempts, and completion.',
      (item) => item.puzzleEvidence,
      rankingsFor(
        (item) => item.puzzleScore,
        percent,
        (item) => item.puzzleEvidence,
      ),
    ),
    item(
      'Most consistent',
      consistent,
      (item) => percent(item.consistency!),
      (item) => item.consistency,
      'Variation across separate reviewed activities.',
      (item) => item.consistencyEvidence,
      rankingsFor(
        (item) => item.consistency,
        percent,
        (item) => item.consistencyEvidence,
      ),
    ),
    item(
      'Most improved',
      improved,
      (item) => improvement(item.improvementStars!),
      (item) => (item.improvementStars! / 5).clamp(0, 1),
      'Earliest versus latest reviewed activity.',
      (item) => item.improvementEvidence,
      rankingsFor(
        (item) => item.improvementStars,
        improvement,
        (item) => item.improvementEvidence,
      ),
      evidence: (item) => item.improvementDetails,
    ),
    item(
      'Overall performance',
      overall,
      (item) => percent(item.overallScore!),
      (item) => item.overallScore,
      'Combines reviewed teacher ratings, coloring, and puzzle performance.',
      (item) => item.overallEvidence,
      rankingsFor(
        (item) => item.overallScore,
        percent,
        (item) => item.overallEvidence,
      ),
    ),
  ];
}

double? _mobileAverage(List<double> values) => values.isEmpty
    ? null
    : values.reduce((left, right) => left + right) / values.length;

Map<String, dynamic> _submissionAnalytics(String description) {
  try {
    final parsed = jsonDecode(description);
    if (parsed is Map && parsed['analytics'] is Map) {
      return Map<String, dynamic>.from(parsed['analytics'] as Map);
    }
  } catch (_) {}
  return const {};
}

String _submissionSummary(String description) {
  try {
    final parsed = jsonDecode(description);
    if (parsed is Map) {
      return _string(
        parsed['summary'] ?? parsed['description'],
        fallback: 'Saved AR workspace evidence is available in View AR.',
      );
    }
  } catch (_) {}
  return description.trim();
}

double? _nestedNum(Map<String, dynamic> source, String group, String key) {
  final nested = source[group];
  return nested is Map ? _asDouble(nested[key]) : null;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

class _MobileInsightCard extends StatelessWidget {
  const _MobileInsightCard({required this.insight});
  final _MobileTeacherInsight insight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showMobileInsightLeaderboard(context, insight),
      child: _CardShell(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: insight.progress,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFE8E9F3),
                    color: _primary,
                    strokeCap: StrokeCap.round,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        insight.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.student,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    insight.description,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${insight.evidenceCount} qualifying record${insight.evidenceCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'View ranking',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (insight.evidence.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Evidence',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...insight.evidence.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      line,
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('View evidence'),
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

void _showMobileInsightLeaderboard(
  BuildContext context,
  _MobileTeacherInsight insight,
) {
  final qualified = insight.rankings.where((item) => item.qualified).length;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .84,
      minChildSize: .55,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            insight.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            insight.description,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            '${insight.rankings.length} students · $qualified with enough evidence',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (insight.rankings.isEmpty)
            const _EmptyCard(
              icon: Icons.people_outline_rounded,
              title: 'No students available',
              body: 'Students in the selected classes will appear here.',
            )
          else
            ...insight.rankings.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.qualified
                      ? const Color(0xFFF7F7F9)
                      : const Color(0xFFF1F1F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        item.rank == null ? '—' : '#${item.rank}',
                        style: TextStyle(
                          color: item.qualified ? _primary : _muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.student,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.qualified
                                ? '${item.evidenceCount} evidence record${item.evidenceCount == 1 ? '' : 's'}'
                                : 'Awaiting enough evidence',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: item.qualified ? _primary : _muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (insight.evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Top learner evidence',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...insight.evidence.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line, style: const TextStyle(height: 1.4)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
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
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationsPage(userId: userId),
            ),
          ),
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('All Notifications'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountSettingsPage(userId: userId),
            ),
          ),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Notification Preferences'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onSignedOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class StudentActivityDetailPage extends StatefulWidget {
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
  State<StudentActivityDetailPage> createState() =>
      _StudentActivityDetailPageState();
}

class _StudentActivityDetailPageState extends State<StudentActivityDetailPage> {
  late Future<StudentActivityAssessment> _assessmentFuture;

  @override
  void initState() {
    super.initState();
    _assessmentFuture = MobileDataService.fetchStudentActivityAssessment(
      widget.activity.id,
    );
  }

  void _reloadAssessment() {
    if (!mounted) return;
    setState(() {
      _assessmentFuture = MobileDataService.fetchStudentActivityAssessment(
        widget.activity.id,
      );
    });
  }

  Future<void> _viewAr() async {
    await openArExperience(
      context,
      _arStartUrl(widget.activity, widget.studentId, viewMode: true),
    );
    widget.onChanged();
    _reloadAssessment();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final studentId = widget.studentId;
    final onChanged = widget.onChanged;
    final submission = activity.submission;
    return Scaffold(
      backgroundColor: _studentCream,
      appBar: AppBar(
        title: Text('Activity', style: _studentHeading(23)),
        backgroundColor: _studentCream,
        foregroundColor: _studentInk,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ActivityHero(activity: activity),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE9E1DC)),
            ),
            child: Text(
              activity.summary.isEmpty
                  ? 'No description provided.'
                  : activity.summary,
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                height: 1.5,
                color: _studentPlum,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (submission == null) ...[
            _StudentLessonSteps(steps: _studentActivitySteps(activity)),
            const SizedBox(height: 18),
          ],
          FutureBuilder<StudentActivityAssessment>(
            future: _assessmentFuture,
            builder: (context, snapshot) => _StudentAssessmentSection(
              assessment: snapshot.data,
              loading: snapshot.connectionState != ConnectionState.done,
              error: snapshot.error,
              onRetry: _reloadAssessment,
            ),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            children: [
              _InfoRow('Due Date', _formatDate(activity.dueDate)),
              _InfoRow('Status', activity.studentStatusLabel),
              _InfoRow('Subject', activity.subjectLabel),
              _InfoRow('Grade level', activity.gradeLabel),
            ],
          ),
          const SizedBox(height: 18),
          if (submission != null)
            _InfoCard(
              title: activity.isReviewed ? 'Reviewed Work' : 'Submitted Work',
              children: [
                _InfoRow('Submitted', _formatDateTime(submission.submittedAt)),
                const SizedBox(height: 4),
                _StarRating(score: submission.score),
                const SizedBox(height: 4),
                _InfoRow(
                  'Feedback',
                  submission.feedback.isEmpty
                      ? 'No feedback yet'
                      : submission.feedback,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _viewAr,
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('View AR'),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _studentPlum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () async {
                    final submitted = await openArExperience(
                      context,
                      _arStartUrl(activity, studentId),
                    );
                    onChanged();
                    _reloadAssessment();
                    if (submitted && context.mounted) {
                      await _showActivityCompletionCelebration(context);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.view_in_ar_rounded),
                  label: const Text('Start Project'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _studentPlum,
                    side: const BorderSide(color: _studentPlum),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () async {
                    final submitted = await openArExperience(
                      context,
                      _arStartUrl(activity, studentId, vrMode: true),
                    );
                    onChanged();
                    _reloadAssessment();
                    if (submitted && context.mounted) {
                      await _showActivityCompletionCelebration(context);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.view_week_rounded),
                  label: const Text('Start VR Mode'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

List<String> _studentActivitySteps(DbActivity activity) {
  final instructions = ActivityArDraft.parse(
    activity.rawDescription,
  ).instructions.trim();
  if (instructions.isEmpty) {
    return const [
      'Find a clear, well-lit space.',
      'Allow camera access and scan a flat surface.',
      'Place the model and follow the activity prompts.',
      'Check your work, then submit when you are ready.',
    ];
  }
  final normalized = instructions.replaceAllMapped(
    RegExp(r'\s+(?=\d+[.)]\s*)'),
    (_) => '\n',
  );
  final steps = normalized
      .split(RegExp(r'\n+'))
      .map((line) => line.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
  return steps.isEmpty ? [instructions] : steps;
}

class _StudentLessonSteps extends StatelessWidget {
  const _StudentLessonSteps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your steps', style: _studentHeading(24)),
        const SizedBox(height: 8),
        ...steps.indexed.map((entry) {
          final color = entry.$1.isEven ? _studentMarigold : _studentCosmicBlue;
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9E1DC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.$1 + 1}',
                    style: TextStyle(
                      color: color == _studentMarigold
                          ? _studentInk
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      entry.$2,
                      style: GoogleFonts.nunitoSans(
                        color: _studentInk,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

Future<void> _showActivityCompletionCelebration(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _studentCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/activity_complete.json',
            width: 220,
            height: 165,
            repeat: false,
          ),
          Text(
            'Activity complete!',
            textAlign: TextAlign.center,
            style: _studentHeading(29),
          ),
          const SizedBox(height: 6),
          Text(
            'Your work was sent to your teacher.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: _studentPlum,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _studentPlum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StudentAssessmentSection extends StatelessWidget {
  const _StudentAssessmentSection({
    required this.assessment,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final StudentActivityAssessment? assessment;
  final bool loading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _CardShell(
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Loading rubric and review details...')),
          ],
        ),
      );
    }
    if (error != null) {
      return _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rubric details are temporarily unavailable.',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final rubric = assessment?.rubric;
    final review = assessment?.finalReview;
    if (rubric == null && review == null) {
      return const _CardShell(
        child: Text(
          'No private activity rubric is attached to this activity.',
          style: TextStyle(color: _muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rubric != null) _StudentRubricCard(rubric: rubric),
        if (rubric != null && review != null) const SizedBox(height: 14),
        if (review != null) _StudentFinalReviewCard(review: review),
      ],
    );
  }
}

class _StudentRubricCard extends StatelessWidget {
  const _StudentRubricCard({required this.rubric});

  final StudentRubric rubric;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW YOUR WORK WILL BE CHECKED',
            style: TextStyle(
              color: _primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rubric.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          if (rubric.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rubric.description, style: const TextStyle(color: _muted)),
          ],
          const SizedBox(height: 12),
          ...rubric.criteria.map(
            (criterion) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criterion.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  ...criterion.levels.map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${level.label}: ${level.description}',
                        style: const TextStyle(color: _muted),
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

class _StudentFinalReviewCard extends StatelessWidget {
  const _StudentFinalReviewCard({required this.review});

  final StudentFinalReview review;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.teacherConfirmedAt == null
                ? 'TEACHER REVIEW'
                : 'TEACHER-CONFIRMED RUBRIC REVIEW',
            style: const TextStyle(
              color: Color(0xFF16723A),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _StarRating(score: review.score),
          if (review.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.feedback),
          ],
          if (review.overallComment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.overallComment),
          ],
          if (review.criteria.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...review.criteria.map(
              (criterion) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criterion.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      criterion.ratingLabel,
                      style: const TextStyle(color: _primary),
                    ),
                    if (criterion.teacherNote.isNotEmpty)
                      Text(
                        criterion.teacherNote,
                        style: const TextStyle(color: _muted),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (review.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Next steps: ${review.nextSteps}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          if (review.colorSuggestion != null) ...[
            const SizedBox(height: 14),
            Text(
              review.colorSuggestion!.message,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            if (review.colorSuggestion!.rationale.isNotEmpty)
              Text(
                review.colorSuggestion!.rationale,
                style: const TextStyle(color: _muted),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.colorSuggestion!.colors
                  .map(
                    (color) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: _colorFromHex(color.hex),
                      ),
                      label: Text(color.name),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (review.evidenceUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(review.evidenceUrl);
                if (uri == null || !{'https', 'http'}.contains(uri.scheme)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The evidence link is invalid. Ask your teacher to update it.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to open the evidence. Check your connection and try again.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('View Teacher Evidence'),
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
  late DbClass _currentClass;

  @override
  void initState() {
    super.initState();
    _currentClass = widget.classItem;
    _future = MobileDataService.loadClassDetail(widget.classItem.id);
  }

  void _refresh() {
    setState(() {
      _future = MobileDataService.loadClassDetail(widget.classItem.id);
    });
    _future.then((detail) {
      if (mounted && detail.classItem != null) {
        setState(() => _currentClass = detail.classItem!);
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClass.displayName),
        actions: [
          IconButton(
            onPressed: () => _classDialog(
              context: context,
              teacherId: widget.teacherId,
              classItem: _currentClass,
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
                  title:
                      snapshot.data?.classItem?.displayName ??
                      _currentClass.displayName,
                  subtitle:
                      snapshot.data?.classItem?.subjectLabel ??
                      _currentClass.subjectLabel,
                  trailing: _PrivateR2Image(
                    kind: R2MediaKind.classes,
                    ownerId: widget.classItem.id,
                    legacyPath:
                        snapshot.data?.classItem?.imagePath ??
                        _currentClass.imagePath,
                    size: 54,
                    borderRadius: 14,
                    fallback: const Icon(
                      Icons.groups_rounded,
                      color: _primary,
                      size: 46,
                    ),
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
                _SectionHeader(
                  title: 'Activities',
                  actionLabel: 'New activity',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeacherActivityEditorPage(
                        teacherId: widget.teacherId,
                        classes: [widget.classItem],
                        onSaved: _refresh,
                      ),
                    ),
                  ),
                ),
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
                      onView: () =>
                          _showTeacherActivityOverview(context, activity),
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherActivityEditorPage(
                            teacherId: widget.teacherId,
                            classes: [widget.classItem],
                            activity: activity,
                            onSaved: _refresh,
                          ),
                        ),
                      ),
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
    this.backgroundColor,
  });

  final Widget child;
  final bool loading;
  final Object? error;
  final VoidCallback? onRefresh;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? _teacherBackground,
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

TextStyle _studentHeading(double size, {Color color = _studentInk}) =>
    GoogleFonts.baloo2(
      fontSize: size,
      height: 1.05,
      fontWeight: FontWeight.w800,
      color: color,
    );

class _StudentHeroCard extends StatelessWidget {
  const _StudentHeroCard({
    required this.name,
    required this.className,
    required this.onOpenActivities,
  });

  final String name;
  final String className;
  final VoidCallback onOpenActivities;

  @override
  Widget build(BuildContext context) {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? name : nameParts.first;
    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.fromLTRB(22, 22, 16, 18),
      decoration: BoxDecoration(
        color: _studentRaspberry,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to create,\n$firstName?',
                  style: _studentHeading(31, color: Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  className,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    color: Colors.white.withValues(alpha: .9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onOpenActivities,
                  style: FilledButton.styleFrom(
                    backgroundColor: _studentPlum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('See activities'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(flex: 4, child: _LearningIllustration()),
        ],
      ),
    );
  }
}

class _LearningIllustration extends StatelessWidget {
  const _LearningIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -.12,
            child: Container(
              width: 112,
              height: 126,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7C2),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          const Icon(Icons.menu_book_rounded, size: 72, color: _studentPlum),
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _studentMarigold,
              size: 34,
            ),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _studentCosmicBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.brush_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPromoCard extends StatelessWidget {
  const _StudentPromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 18, 16, 18),
      decoration: BoxDecoration(
        color: _studentCosmicBlue,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _studentHeading(21, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 13),
                FilledButton.icon(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: _studentMarigold,
                    foregroundColor: _studentInk,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text('Open sandbox'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PalettePostcard(icon: icon),
        ],
      ),
    );
  }
}

class _PalettePostcard extends StatelessWidget {
  const _PalettePostcard({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 4,
            top: 5,
            child: Transform.rotate(
              angle: .1,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7C2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: _studentPlum, size: 42),
              ),
            ),
          ),
          const Positioned(
            left: 4,
            top: 2,
            child: _PaintDot(color: _studentRaspberry, size: 24),
          ),
          const Positioned(
            left: 13,
            bottom: 4,
            child: _PaintDot(color: _studentMarigold, size: 17),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: _PaintDot(color: Colors.white, size: 13),
          ),
        ],
      ),
    );
  }
}

class _PaintDot extends StatelessWidget {
  const _PaintDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StudentProgressStrip extends StatelessWidget {
  const _StudentProgressStrip({
    required this.items,
    required this.onOpenActivities,
  });

  final List<(String, Object)> items;
  final VoidCallback onOpenActivities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Creative trail', style: _studentHeading(24))),
            TextButton(
              onPressed: onOpenActivities,
              child: const Text('View activities'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 126,
          child: CustomPaint(
            painter: _CreativeTrailPainter(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.indexed.map((entry) {
                final index = entry.$1;
                final item = entry.$2;
                const colors = [
                  _studentRaspberry,
                  _studentMarigold,
                  _studentCosmicBlue,
                  _studentPlum,
                ];
                const icons = [
                  Icons.auto_awesome_rounded,
                  Icons.send_rounded,
                  Icons.verified_rounded,
                  Icons.brush_rounded,
                ];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: index.isOdd ? 29 : 4),
                    child: Column(
                      children: [
                        Transform.rotate(
                          angle: index.isEven ? -.08 : .08,
                          child: Container(
                            width: 57,
                            height: 57,
                            decoration: BoxDecoration(
                              color: colors[index],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 6,
                                  top: 5,
                                  child: Icon(
                                    icons[index],
                                    size: 17,
                                    color: Colors.white.withValues(alpha: .68),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    item.$2.toString(),
                                    style: _studentHeading(
                                      24,
                                      color: index == 1
                                          ? _studentInk
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.$1,
                          maxLines: 1,
                          style: const TextStyle(
                            color: _studentPlum,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreativeTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .11, 36)
      ..cubicTo(
        size.width * .28,
        88,
        size.width * .38,
        89,
        size.width * .52,
        55,
      )
      ..cubicTo(
        size.width * .67,
        19,
        size.width * .77,
        25,
        size.width * .89,
        61,
      );
    final paint = Paint()
      ..color = _studentCosmicBlue.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StudentActivityBanner extends StatelessWidget {
  const _StudentActivityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _studentCosmicBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your activity trail',
                  style: _studentHeading(27, color: Colors.white),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Choose the next lesson and keep creating.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7C2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.route_rounded,
              size: 48,
              color: _studentRaspberry,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProfileHero extends StatelessWidget {
  const _StudentProfileHero({
    required this.name,
    required this.completed,
    required this.averageScore,
  });

  final String name;
  final int completed;
  final String averageScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _studentRaspberry,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name\'s creative journey',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _studentHeading(27, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StudentBadge(
                      icon: Icons.task_alt_rounded,
                      label: '$completed complete',
                    ),
                    _StudentBadge(
                      icon: Icons.star_rounded,
                      label: '$averageScore average',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.emoji_events_rounded,
            color: _studentMarigold,
            size: 76,
          ),
        ],
      ),
    );
  }
}

class _StudentBadge extends StatelessWidget {
  const _StudentBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _studentMarigold,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _studentInk),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _studentInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentIdentityRow extends StatelessWidget {
  const _StudentIdentityRow({
    required this.userId,
    required this.name,
    required this.email,
    required this.className,
  });

  final String userId;
  final String name;
  final String email;
  final String className;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9E1DC)),
      ),
      child: Row(
        children: [
          _PrivateR2Image(
            kind: R2MediaKind.avatars,
            ownerId: userId,
            size: 62,
            fallback: CircleAvatar(
              radius: 31,
              backgroundColor: _studentPlum,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _studentHeading(20)),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _studentPlum),
                ),
                Text(
                  className,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _studentCosmicBlue,
                    fontWeight: FontWeight.w800,
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
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
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
        borderRadius: BorderRadius.circular(12),
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

class _StudentNotificationNotebook extends StatelessWidget {
  const _StudentNotificationNotebook({
    required this.userId,
    required this.notifications,
    required this.limit,
    required this.onChanged,
    required this.onSeeAll,
  });

  final String? userId;
  final List<DbNotification> notifications;
  final int limit;
  final VoidCallback onChanged;
  final VoidCallback onSeeAll;

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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFFE8DDD5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 8,
                child: ColoredBox(color: _studentRaspberry),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 17, 12, 10),
                    child: Row(
                      children: [
                        Transform.rotate(
                          angle: -.08,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE7C2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: _studentPlum,
                              size: 21,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('What’s new', style: _studentHeading(23)),
                        ),
                        if (hasUnread)
                          TextButton(
                            onPressed: _markAllRead,
                            child: const Text('Mark read'),
                          ),
                      ],
                    ),
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'You’re all caught up. New activity updates will appear here.',
                          style: TextStyle(color: _studentPlum, height: 1.4),
                        ),
                      ),
                    )
                  else
                    ...visible.indexed.map(
                      (entry) => _StudentNotificationLine(
                        userId: userId,
                        notification: entry.$2,
                        showRule: entry.$1 > 0,
                        onChanged: onChanged,
                      ),
                    ),
                  InkWell(
                    onTap: onSeeAll,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 13, 18, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'Open notification notebook',
                            style: TextStyle(
                              color: _studentPlum,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _studentRaspberry,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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

class _StudentNotificationLine extends StatelessWidget {
  const _StudentNotificationLine({
    required this.userId,
    required this.notification,
    required this.showRule,
    required this.onChanged,
  });

  final String? userId;
  final DbNotification notification;
  final bool showRule;
  final VoidCallback onChanged;

  Future<void> _openAction(BuildContext context) async {
    final id = userId;
    if (id != null && id.isNotEmpty && !notification.isRead) {
      await MobileDataService.markNotificationsRead(id, [notification.id]);
      onChanged();
    }
    final action = notification.actionUri;
    if (action == null || !context.mounted) return;
    await _openHostedPage(
      context,
      path: action.path,
      title: notification.title,
      queryParameters: action.queryParameters,
      onClosed: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = notification.isRead
        ? const Color(0xFFB3AAA4)
        : _studentCosmicBlue;
    return Column(
      children: [
        if (showRule) const Divider(height: 1, indent: 18, endIndent: 18),
        InkWell(
          onTap: () => _openAction(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notificationIcon(notification.type),
                    color: accent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _studentInk,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _studentRaspberry,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _studentPlum),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          color: _studentPlum.withValues(alpha: .67),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.actionUri != null) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _studentPlum,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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

  Future<void> _openAction(BuildContext context) async {
    await _markRead();
    final action = notification.actionUri;
    if (action == null || !context.mounted) return;
    await _openHostedPage(
      context,
      path: action.path,
      title: notification.title,
      queryParameters: action.queryParameters,
      onClosed: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _openAction(context),
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
            ? (notification.actionUri == null
                  ? null
                  : const Icon(Icons.chevron_right_rounded))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: _primary, size: 10),
                  if (notification.actionUri != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ],
              ),
      ),
    );
  }
}

class _StudentActivityRow extends StatelessWidget {
  const _StudentActivityRow({required this.activity, required this.onTap});

  final DbActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = activity.isReviewed
        ? _studentCosmicBlue
        : activity.isSubmitted
        ? _studentPlum
        : activity.isOverdue
        ? _studentRaspberry
        : _studentMarigold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE9E1DC)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    activity.isReviewed
                        ? Icons.star_rounded
                        : Icons.brush_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _studentHeading(18),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Due ${_formatDate(activity.dueDate)}',
                        style: const TextStyle(
                          color: _studentPlum,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    activity.studentStatusLabel,
                    style: TextStyle(
                      color: statusColor == _studentMarigold
                          ? _studentInk
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded, color: _studentPlum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityHero extends StatelessWidget {
  const _ActivityHero({required this.activity});

  final DbActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _studentRaspberry,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StudentBadge(
                  icon: Icons.schedule_rounded,
                  label: 'Due ${_formatDate(activity.dueDate)}',
                ),
                const SizedBox(height: 12),
                Text(
                  activity.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _studentHeading(30, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 98,
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7C2),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.draw_rounded, color: _studentPlum, size: 58),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _studentMarigold,
                    size: 25,
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

class _StarRating extends StatelessWidget {
  const _StarRating({required this.score});

  final num? score;

  @override
  Widget build(BuildContext context) {
    final rating = normalizeMobileStarRating(score);
    final label = mobileStarRatingLabel(score);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            ...List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFFFB526),
                size: 23,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkGrid extends StatelessWidget {
  const _ArtworkGrid({required this.artworks, this.onArtworkTap});

  final List<DbArtwork> artworks;
  final ValueChanged<DbArtwork>? onArtworkTap;

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
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return _ArtworkCard(
          artwork: artwork,
          onTap: onArtworkTap == null ? null : () => onArtworkTap!(artwork),
        );
      },
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.artwork, this.onTap});

  final DbArtwork artwork;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Semantics(
        button: onTap != null,
        label: onTap == null ? null : 'Open submitted work ${artwork.title}',
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (onTap != null)
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _primary,
                        ),
                    ],
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

DbActivity? _activityForArtwork(StudentBundle? bundle, DbArtwork artwork) {
  if (bundle == null) return null;
  for (final activity in bundle.activities) {
    if (artwork.submissionId.isNotEmpty &&
        activity.submission?.id == artwork.submissionId) {
      return activity;
    }
  }
  if (artwork.imageUrl.isNotEmpty) {
    for (final activity in bundle.activities) {
      if (activity.submission?.artworkUrl == artwork.imageUrl) return activity;
    }
  }
  return null;
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

class _PrivateR2Image extends StatefulWidget {
  const _PrivateR2Image({
    super.key,
    required this.kind,
    required this.ownerId,
    required this.fallback,
    this.legacyPath = '',
    this.size = 48,
    this.borderRadius = 999,
  });

  final R2MediaKind kind;
  final String ownerId;
  final String legacyPath;
  final double size;
  final double borderRadius;
  final Widget fallback;

  @override
  State<_PrivateR2Image> createState() => _PrivateR2ImageState();
}

class _PrivateR2ImageState extends State<_PrivateR2Image> {
  late Future<Uint8List?> _future;
  late int _revision;

  @override
  void initState() {
    super.initState();
    _revision = R2MediaService.revision(widget.kind, widget.ownerId);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _PrivateR2Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    final revision = R2MediaService.revision(widget.kind, widget.ownerId);
    if (oldWidget.ownerId != widget.ownerId ||
        oldWidget.kind != widget.kind ||
        oldWidget.legacyPath != widget.legacyPath ||
        revision != _revision) {
      _revision = revision;
      _future = _load();
    }
  }

  Future<Uint8List?> _load() => R2MediaService.load(
    widget.kind,
    widget.ownerId,
    legacyPath: widget.legacyPath,
  ).catchError((_) => null);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) {
              return Center(child: widget.fallback);
            }
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(child: widget.fallback),
            );
          },
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.klass,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
  });

  final DbClass klass;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: _PrivateR2Image(
          kind: R2MediaKind.classes,
          ownerId: klass.id,
          legacyPath: klass.imagePath,
          fallback: CircleAvatar(
            backgroundColor: const Color(0xFFF1F1F4),
            foregroundColor: _ink,
            child: Text(klass.initial),
          ),
        ),
        title: Text(
          klass.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${klass.studentCount} students - ${klass.activityCount} activities${klass.isActive ? '' : '\nDisabled ${_formatDate(klass.disabledAt)}'}',
        ),
        isThreeLine: !klass.isActive,
        trailing: Wrap(
          spacing: 2,
          children: [
            if (klass.isActive)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
              ),
            IconButton(
              onPressed: onToggleActive,
              icon: Icon(
                klass.isActive ? Icons.archive_outlined : Icons.restore_rounded,
              ),
              tooltip: klass.isActive ? 'Disable class' : 'Restore class',
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherActivityTile extends StatelessWidget {
  const _TeacherActivityTile({
    required this.activity,
    required this.onView,
    required this.onEdit,
  });

  final DbActivity activity;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onView,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit activity',
                      ),
                    ],
                  ),
                  Text(
                    activity.className.isEmpty
                        ? 'No class'
                        : activity.className,
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
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View activity →',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
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

Future<void> _showTeacherActivityOverview(
  BuildContext context,
  DbActivity activity,
) async {
  final draft = ActivityArDraft.parse(activity.rawDescription);
  final modelNames = draft.modelIds.map((id) {
    for (final model in sandboxFallbackModels) {
      if (model.id == id) return model.label;
    }
    return id;
  }).toList();
  final objectNames = draft.allowedObjectIds.map((id) {
    for (final object in _activityObjectOptions) {
      if (object.id == id) return object.label;
    }
    return id;
  }).toList();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVITY OVERVIEW',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.title,
                        style: Theme.of(sheetContext).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      activity.className.isEmpty
                          ? 'No class'
                          : activity.className,
                    ),
                    _Chip('Due ${_formatDate(activity.dueDate)}'),
                    _Chip(
                      draft.puzzlePieces == 0
                          ? 'Puzzle off'
                          : '${draft.puzzlePieces}-piece puzzle',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Description',
                  children: [
                    Text(
                      draft.summary.isEmpty
                          ? 'No description provided.'
                          : draft.summary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Instructions',
                  children: [
                    Text(
                      draft.instructions.isEmpty
                          ? 'No instructions provided.'
                          : draft.instructions,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'AR materials',
                  children: [
                    _InfoRow(
                      'Base models',
                      modelNames.isEmpty ? 'None' : modelNames.join(', '),
                    ),
                    _InfoRow(
                      'Object kit',
                      objectNames.isEmpty ? 'None' : objectNames.join(', '),
                    ),
                    _InfoRow(
                      'Colors',
                      draft.allowedColors.isEmpty
                          ? 'Default palette'
                          : draft.allowedColors
                                .map(
                                  (hex) => draft.allowedColorNames[hex] ?? hex,
                                )
                                .join(', '),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
          style: const TextStyle(fontWeight: FontWeight.w700),
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
        leading: _PrivateR2Image(
          kind: R2MediaKind.avatars,
          ownerId: student.id,
          legacyPath: student.avatarPath,
          fallback: CircleAvatar(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            child: Text(_initials(student.name)),
          ),
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
        leading: _PrivateR2Image(
          kind: R2MediaKind.avatars,
          ownerId: child.student.id,
          legacyPath: child.student.avatarPath,
          fallback: CircleAvatar(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            child: Text(_initials(child.student.name)),
          ),
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

Future<void> _confirmToggleClass(
  BuildContext context,
  DbClass classItem,
  VoidCallback onSaved,
) async {
  final restoring = !classItem.isActive;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(restoring ? 'Restore class?' : 'Disable class?'),
      content: Text(
        restoring
            ? 'Restore "${classItem.displayName}" so its students and activities are active again?'
            : 'Disable "${classItem.displayName}"? Its students, activities, submissions, and reports will be kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(restoring ? 'Restore' : 'Disable'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final result = await MobileDataService.setClassActive(
    classItem.id,
    isActive: restoring,
  );
  if (!context.mounted) return;
  if (!result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Unable to update this class.')),
    );
    return;
  }
  onSaved();
}

Future<void> _classDialog({
  required BuildContext context,
  required String teacherId,
  DbClass? classItem,
  required VoidCallback onSaved,
}) async {
  final gradeController = TextEditingController(text: classItem?.grade ?? '');
  final sectionController = TextEditingController(
    text: classItem?.section ?? '',
  );
  final subjectController = TextEditingController(
    text: classItem?.subject ?? '',
  );
  String? error;
  bool loading = false;
  Uint8List? selectedImageBytes;
  String selectedImageType = '';
  bool removeImage = false;
  String selectedColor = classItem?.color ?? '#1800AD';

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
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Class color',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    const [
                      '#1800AD',
                      '#2563EB',
                      '#15803D',
                      '#B85C00',
                      '#7C2AE8',
                      '#C2410C',
                      '#BE185D',
                      '#0F766E',
                    ].map((hex) {
                      final selected = selectedColor == hex;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: 'Class color $hex',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: loading
                              ? null
                              : () => setState(() => selectedColor = hex),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _colorFromHex(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? _ink : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Class image',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: selectedImageBytes != null
                            ? Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : removeImage || classItem == null
                            ? Container(
                                color: const Color(0xFFF0EEFC),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: _primary,
                                ),
                              )
                            : _PrivateR2Image(
                                kind: R2MediaKind.classes,
                                ownerId: classItem.id,
                                legacyPath: classItem.imagePath,
                                size: 72,
                                borderRadius: 16,
                                fallback: Container(
                                  color: const Color(0xFFF0EEFC),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: _primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: loading
                                ? null
                                : () async {
                                    final picked = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: const [
                                            'png',
                                            'jpg',
                                            'jpeg',
                                            'webp',
                                          ],
                                          withData: true,
                                        );
                                    final file = picked?.files.single;
                                    if (file == null) return;
                                    if (file.size > r2MediaMaxUploadBytes) {
                                      setState(
                                        () => error =
                                            'Image is too large. Maximum size is 20 MB.',
                                      );
                                      return;
                                    }
                                    final bytes = file.bytes;
                                    final contentType = _pickedImageMimeType(
                                      file,
                                    );
                                    if (bytes == null || contentType == null) {
                                      setState(
                                        () => error =
                                            'Use a PNG, JPG, or WebP image.',
                                      );
                                      return;
                                    }
                                    setState(() {
                                      selectedImageBytes = bytes;
                                      selectedImageType = contentType;
                                      removeImage = false;
                                      error = null;
                                    });
                                  },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                              selectedImageBytes == null
                                  ? 'Choose image'
                                  : 'Change image',
                            ),
                          ),
                          if (selectedImageBytes != null ||
                              (classItem?.imagePath.isNotEmpty ?? false))
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                      selectedImageBytes = null;
                                      selectedImageType = '';
                                      removeImage = true;
                                    }),
                              child: const Text('Remove image'),
                            ),
                          const Text(
                            'PNG, JPG, or WebP up to 20 MB. Stored privately in Cloudflare R2.',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            name:
                                '${gradeController.text.trim()} - ${sectionController.text.trim()}',
                            grade: gradeController.text,
                            section: sectionController.text,
                            subject: subjectController.text,
                            color: selectedColor,
                          )
                        : await MobileDataService.updateClass(
                            classItem.id,
                            name:
                                '${gradeController.text.trim()} - ${sectionController.text.trim()}',
                            grade: gradeController.text,
                            section: sectionController.text,
                            subject: subjectController.text,
                            color: selectedColor,
                          );
                    if (!context.mounted) return;
                    if (result.success) {
                      final classId = classItem?.id ?? result.value ?? '';
                      try {
                        if (selectedImageBytes != null) {
                          final imagePath = await R2MediaService.upload(
                            R2MediaKind.classes,
                            classId,
                            selectedImageBytes!,
                            selectedImageType,
                          );
                          final imageResult =
                              await MobileDataService.setClassImagePath(
                                classId,
                                imagePath,
                              );
                          if (!imageResult.success) {
                            await R2MediaService.delete(
                              R2MediaKind.classes,
                              classId,
                            ).catchError((_) {});
                            throw R2MediaException(
                              imageResult.error ??
                                  'Unable to save the class image.',
                            );
                          }
                        } else if (removeImage && classItem != null) {
                          final imageResult =
                              await MobileDataService.setClassImagePath(
                                classId,
                                null,
                              );
                          if (!imageResult.success) {
                            throw R2MediaException(
                              imageResult.error ??
                                  'Unable to remove the class image.',
                            );
                          }
                          await R2MediaService.delete(
                            R2MediaKind.classes,
                            classId,
                          ).catchError((_) {});
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        onSaved();
                      } catch (uploadError) {
                        if (!context.mounted) return;
                        if (classItem == null) {
                          Navigator.pop(context);
                          onSaved();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Class created, but its image could not be uploaded: $uploadError',
                              ),
                            ),
                          );
                        } else {
                          setState(() {
                            loading = false;
                            error = uploadError.toString();
                          });
                        }
                      }
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

  gradeController.dispose();
  sectionController.dispose();
  subjectController.dispose();
}

String? _pickedImageMimeType(PlatformFile file) {
  return switch ((file.extension ?? '').toLowerCase()) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => null,
  };
}

String _normalizeClassColor(String value) {
  final color = value.trim().toUpperCase();
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(color) ? color : '#1800AD';
}

Future<void> _reviewSubmissionDialog({
  required BuildContext context,
  required String teacherId,
  required DbSubmission submission,
  required VoidCallback onSaved,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => TeacherSubmissionReviewPage(
        teacherId: teacherId,
        submission: submission,
      ),
    ),
  );
  if (saved == true) onSaved();
}

class TeacherSubmissionReviewPage extends StatefulWidget {
  const TeacherSubmissionReviewPage({
    super.key,
    required this.teacherId,
    required this.submission,
  });

  final String teacherId;
  final DbSubmission submission;

  @override
  State<TeacherSubmissionReviewPage> createState() =>
      _TeacherSubmissionReviewPageState();
}

class _TeacherSubmissionReviewPageState
    extends State<TeacherSubmissionReviewPage> {
  late Future<TeacherReviewContext> _future;
  final _feedbackController = TextEditingController();
  final _nextStepsController = TextEditingController();
  List<TextEditingController> _noteControllers = [];
  List<String> _ratings = [];
  TeacherReviewContext? _review;
  bool _reviewInitialized = false;
  int _score = 0;
  bool _confirmed = false;
  bool _saving = false;
  bool _checkingAi = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _score = normalizeMobileStarRating(widget.submission.score);
    _feedbackController.text = widget.submission.feedback;
    _future = MobileDataService.fetchTeacherReviewContext(widget.submission);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nextStepsController.dispose();
    for (final controller in _noteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _acceptReview(TeacherReviewContext review) {
    if (_reviewInitialized) return;
    _reviewInitialized = true;
    _review = review;
    final criteria = review.rubric?.criteria ?? const [];
    _ratings = List.filled(criteria.length, '');
    _noteControllers = List.generate(
      criteria.length,
      (_) => TextEditingController(),
    );
  }

  Future<void> _runAiCheck() async {
    setState(() {
      _checkingAi = true;
      _error = null;
    });
    try {
      final evaluation = await MobileDataService.requestTeacherAiReview(
        widget.submission.id,
        force: _review?.aiEvaluation != null,
      );
      if (!mounted) return;
      setState(() {
        _review = TeacherReviewContext(
          rubric: _review?.rubric,
          aiEvaluation: evaluation,
        );
        _checkingAi = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingAi = false;
        _error = 'AI checking did not finish. You can still grade manually.';
      });
    }
  }

  void _useAiDraft() {
    final evaluation = _review?.aiEvaluation;
    if (evaluation == null || !evaluation.isCompleted) return;
    setState(() {
      if (evaluation.suggestedScore > 0) _score = evaluation.suggestedScore;
      if (evaluation.feedback.isNotEmpty) {
        _feedbackController.text = evaluation.feedback;
      }
      if (evaluation.criteria.length == _ratings.length) {
        for (var index = 0; index < _ratings.length; index++) {
          final rating = evaluation.criteria[index].rating;
          if (_rubricRatingCodes.contains(rating)) _ratings[index] = rating;
        }
      }
    });
  }

  Future<void> _viewAr() async {
    await openArExperience(
      context,
      trustedHostedWebBaseUri.replace(
        path: '/mobile/activity/${widget.submission.activityId}/start',
        queryParameters: {
          'mobile': '1',
          'studentId': widget.submission.studentId,
          'mode': 'view',
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await MobileDataService.finalizeSubmissionReview(
      teacherId: widget.teacherId,
      submission: widget.submission,
      score: _score,
      feedback: _feedbackController.text,
      nextSteps: _nextStepsController.text,
      rubric: _review?.rubric,
      criterionRatings: _ratings,
      criterionNotes: _noteControllers.map((item) => item.text).toList(),
      teacherConfirmed: _confirmed,
      aiEvaluation: _review?.aiEvaluation,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = result.error ?? 'Could not save this review.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review submission')),
      body: FutureBuilder<TeacherReviewContext>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              error: snapshot.error,
              onRetry: () {
                setState(() {
                  _reviewInitialized = false;
                  _future = MobileDataService.fetchTeacherReviewContext(
                    widget.submission,
                  );
                });
              },
            );
          }
          final review = snapshot.data ?? const TeacherReviewContext();
          _acceptReview(review);
          final rubric = _review?.rubric;
          final evaluation = _review?.aiEvaluation;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              _HeroPanel(
                title: widget.submission.activityTitle,
                subtitle:
                    '${widget.submission.studentName}\nSubmitted ${_formatDateTime(widget.submission.submittedAt)}',
                trailing: _Thumbnail(
                  url: widget.submission.artworkUrl,
                  seed: widget.submission.id,
                  size: 72,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _viewAr,
                icon: const Icon(Icons.view_in_ar_rounded),
                label: const Text('View submitted work in AR'),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Saved evidence'),
              const SizedBox(height: 8),
              _SubmissionEvidenceCard(submission: widget.submission),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'AI rubric check',
                actionLabel: evaluation == null ? 'Run check' : 'Check again',
                onAction: rubric == null || _checkingAi ? null : _runAiCheck,
              ),
              const SizedBox(height: 8),
              _AiReviewCard(
                evaluation: evaluation,
                loading: _checkingAi,
                rubricMissing: rubric == null,
                onUse: _useAiDraft,
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Teacher assessment'),
              const SizedBox(height: 8),
              if (rubric == null)
                const _EmptyCard(
                  icon: Icons.fact_check_outlined,
                  title: 'No rubric attached',
                  body: 'Choose the final stars and feedback below.',
                )
              else ...[
                _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rubric.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (rubric.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rubric.description,
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
                ...List.generate(rubric.criteria.length, (index) {
                  final criterion = rubric.criteria[index];
                  return _RubricCriterionEditor(
                    criterion: criterion,
                    value: _ratings[index],
                    noteController: _noteControllers[index],
                    onChanged: (value) =>
                        setState(() => _ratings[index] = value),
                  );
                }),
              ],
              const SizedBox(height: 16),
              _OverallRatingPicker(
                value: _score,
                onChanged: (value) => setState(() => _score = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  hintText: 'Write clear feedback for the learner',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nextStepsController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Next steps',
                  hintText: 'What should the learner try next?',
                  alignLabelWithHint: true,
                ),
              ),
              if (rubric != null) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _confirmed,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) =>
                      setState(() => _confirmed = value ?? false),
                  title: const Text('I confirm this final teacher review'),
                  subtitle: const Text(
                    'AI suggestions are drafts; the saved result is your assessment.',
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(_saving ? 'Saving review…' : 'Save final review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SubmissionEvidenceCard extends StatelessWidget {
  const _SubmissionEvidenceCard({required this.submission});

  final DbSubmission submission;

  @override
  Widget build(BuildContext context) {
    final analytics = _submissionAnalytics(submission.rawDescription);
    final colorAccuracy = _nestedNum(analytics, 'coloring', 'accuracyPercent');
    final puzzleAccuracy = _nestedNum(analytics, 'puzzle', 'accuracyPercent');
    final puzzleSeconds = _nestedNum(analytics, 'puzzle', 'completionSeconds');
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (submission.artworkUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                submission.artworkUrl,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (submission.artworkUrl.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (colorAccuracy != null)
                _Chip('Color ${colorAccuracy.toStringAsFixed(0)}%'),
              if (puzzleAccuracy != null)
                _Chip('Puzzle ${puzzleAccuracy.toStringAsFixed(0)}%'),
              if (puzzleSeconds != null)
                _Chip('Puzzle ${puzzleSeconds.toStringAsFixed(0)} sec'),
              _Chip(submission.reviewStatusLabel),
            ],
          ),
          if (analytics.isEmpty && submission.rawDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _submissionSummary(submission.rawDescription),
              style: const TextStyle(color: _muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiReviewCard extends StatelessWidget {
  const _AiReviewCard({
    required this.evaluation,
    required this.loading,
    required this.rubricMissing,
    required this.onUse,
  });

  final TeacherAiEvaluation? evaluation;
  final bool loading;
  final bool rubricMissing;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    if (rubricMissing) {
      return const _EmptyCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Attach a rubric to use AI checking',
        body: 'Manual star rating and feedback are still available.',
      );
    }
    if (loading) {
      return const _CardShell(
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 14),
            Expanded(child: Text('Comparing evidence with each rubric level…')),
          ],
        ),
      );
    }
    final item = evaluation;
    if (item == null) {
      return const _EmptyCard(
        icon: Icons.auto_awesome_outlined,
        title: 'No AI draft yet',
        body:
            'Run a check for a rubric-based suggestion, then confirm it yourself.',
      );
    }
    if (!item.isCompleted) {
      return _EmptyCard(
        icon: Icons.info_outline_rounded,
        title: item.status == 'processing'
            ? 'AI check is processing'
            : 'AI check unavailable',
        body: item.error.isEmpty
            ? 'Try the check again or continue with manual grading.'
            : item.error,
      );
    }
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Suggested ${item.suggestedScore}/5 stars',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onUse, child: const Text('Use draft')),
            ],
          ),
          if (item.feedback.isNotEmpty) Text(item.feedback),
          if (item.criteria.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...item.criteria.map(
              (criterion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${criterion.title}: ${_rubricRatingLabel(criterion.rating)}${criterion.evidence.isEmpty ? '' : '\n${criterion.evidence}'}',
                  style: const TextStyle(color: _muted, height: 1.35),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RubricCriterionEditor extends StatelessWidget {
  const _RubricCriterionEditor({
    required this.criterion,
    required this.value,
    required this.noteController,
    required this.onChanged,
  });

  final StudentRubricCriterion criterion;
  final String value;
  final TextEditingController noteController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            criterion.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rubricRatingCodes.map((code) {
              return ChoiceChip(
                label: Text(_rubricRatingLabel(code)),
                selected: value == code,
                onSelected: (_) => onChanged(code),
              );
            }).toList(),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              criterion.levels
                      .where(
                        (level) => _canonicalRubricRating(level.code) == value,
                      )
                      .map((level) => level.description)
                      .firstOrNull ??
                  '',
              style: const TextStyle(color: _muted),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Criterion note (optional)',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallRatingPicker extends StatelessWidget {
  const _OverallRatingPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall rating',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                onPressed: () => onChanged(star),
                iconSize: 36,
                color: const Color(0xFFFFB526),
                icon: Icon(
                  star <= value
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
              );
            }),
          ),
          Text(value == 0 ? 'Choose 1–5 stars' : '$value/5 stars'),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _CardShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Text(
                'Unable to load review: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
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
  final base = trustedHostedWebBaseUri;
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

Future<void> _openHostedPage(
  BuildContext context, {
  required String path,
  required String title,
  Map<String, String> queryParameters = const {},
  VoidCallback? onClosed,
}) async {
  final base = trustedHostedWebBaseUri;
  await openHostedExperience(
    context,
    base.replace(path: path, queryParameters: queryParameters),
    title: title,
  );
  onClosed?.call();
}

class MobileDataService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<StudentBundle> loadStudentBundle(String studentId) async {
    await _refreshActivityReminders();
    final results = await Future.wait<Object?>([
      fetchStudentActivities(studentId),
      fetchStudentClass(studentId),
      fetchNotifications(studentId),
    ]);
    final activities = results[0] as List<DbActivity>;
    final classItem = results[1] as DbClass?;
    final notifications = results[2] as List<DbNotification>;
    final submissions = activities
        .map((item) => item.submission)
        .whereType<DbSubmission>()
        .toList();
    final artworks = await fetchStudentArtworks(studentId, submissions);
    return StudentBundle(
      studentId: studentId,
      classItem: classItem,
      activities: activities,
      artworks: artworks,
      notifications: notifications,
    );
  }

  static Future<TeacherBundle> loadTeacherBundle(String teacherId) async {
    await _refreshActivityReminders();
    final classes = await fetchTeacherClasses(teacherId);
    final activeClasses = classes.where((item) => item.isActive).toList();
    final primary = await Future.wait<Object>([
      fetchTeacherStudents(activeClasses),
      fetchTeacherActivities(teacherId, activeClasses),
      fetchTeacherGestureAlerts(teacherId),
      fetchNotifications(teacherId),
    ]);
    final students = primary[0] as List<DbStudent>;
    final activities = primary[1] as List<DbActivity>;
    final evidenceResults = await Future.wait<Object>([
      fetchTeacherSubmissions(teacherId, activities, roster: students),
      fetchTeacherRubricEvidence(activities),
    ]);
    final submissions = evidenceResults[0] as List<DbSubmission>;
    final rubricEvidence = evidenceResults[1] as List<TeacherRubricEvidence>;
    final alerts = primary[2] as List<DbGestureAlert>;
    final notifications = primary[3] as List<DbNotification>;
    return TeacherBundle(
      teacherId: teacherId,
      classes: classes,
      students: students,
      activities: activities,
      submissions: submissions,
      rubricEvidence: rubricEvidence,
      gestureAlerts: alerts,
      notifications: notifications,
    );
  }

  static Future<TeacherMobileSettings> fetchTeacherSettings(
    String userId,
  ) async {
    Map<String, dynamic> userSettings = const {};
    Map<String, dynamic> preferences = const {};
    try {
      final value = await _client
          .from('user_settings')
          .select('settings')
          .eq('user_id', userId)
          .maybeSingle();
      if (value?['settings'] is Map) {
        userSettings = Map<String, dynamic>.from(value!['settings'] as Map);
      }
    } catch (_) {
      // Defaults keep the settings page usable before optional table setup.
    }
    try {
      final value = await _client
          .from('notification_preferences')
          .select(
            'in_app_enabled, email_enabled, activity_assigned, grade_posted, due_soon, missing_work, account_updates',
          )
          .eq('user_id', userId)
          .maybeSingle();
      if (value != null) preferences = Map<String, dynamic>.from(value);
    } catch (_) {
      // Notification defaults are used when no preference row exists.
    }
    return TeacherMobileSettings.fromRows(userSettings, preferences);
  }

  static Future<DbResult> saveTeacherSettings(
    String userId,
    TeacherMobileSettings settings,
  ) async {
    try {
      await _client.from('user_settings').upsert({
        'user_id': userId,
        'settings': settings.userSettingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      await _client.from('notification_preferences').upsert({
        'user_id': userId,
        ...settings.notificationPreferencesJson,
      }, onConflict: 'user_id');
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<ParentBundle> loadParentBundle(String parentId) async {
    await _refreshActivityReminders();
    final results = await Future.wait<Object?>([
      _fetchParentStudentIds(parentId),
      fetchNotifications(parentId),
    ]);
    final studentIds = results[0] as List<String>;
    final notifications = results[1] as List<DbNotification>;
    if (studentIds.isEmpty) {
      return ParentBundle(
        parentId: parentId,
        children: const [],
        notifications: notifications,
      );
    }

    final users = await _fetchUsersByIds(studentIds);
    final children = <ParentChild>[];
    for (final student in users) {
      final activities = await fetchStudentActivities(student.id);
      children.add(ParentChild(student: student, activities: activities));
    }
    return ParentBundle(
      parentId: parentId,
      children: children,
      notifications: notifications,
    );
  }

  static Future<ClassDetailBundle> loadClassDetail(String classId) async {
    final results = await Future.wait<Object?>([
      fetchClass(classId),
      fetchClassStudents(classId),
      fetchClassActivities(classId),
    ]);
    return ClassDetailBundle(
      classItem: results[0] as DbClass?,
      students: results[1] as List<DbStudent>,
      activities: results[2] as List<DbActivity>,
    );
  }

  static Future<DbClass?> fetchClass(String classId) async {
    final row = await _client
        .from('classes')
        .select(
          'id, teacher_id, name, grade, section, subject, color, image_url, student_count, created_at, is_active, disabled_at, disabled_by',
        )
        .eq('id', classId)
        .maybeSingle();
    return row == null ? null : DbClass.fromRow(row);
  }

  static Future<DbClass?> fetchStudentClass(String studentId) async {
    final rows = _rows(
      await _client
          .from('class_students')
          .select(
            'class_id, enrolled_at, classes:class_id(id, name, grade, section, subject, color, image_url, student_count, is_active, disabled_at)',
          )
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false),
    );
    for (final row in rows) {
      final nested = row['classes'];
      if (nested is! Map) continue;
      final classRow = Map<String, dynamic>.from(nested);
      if (classRow['is_active'] == false) continue;
      return DbClass.fromRow(classRow);
    }
    return null;
  }

  static Future<void> _refreshActivityReminders() async {
    try {
      await _client.rpc('refresh_my_activity_reminders');
    } catch (_) {
      // Existing stored notifications remain useful if reminder generation is
      // temporarily unavailable.
    }
  }

  static Future<List<DbNotification>> fetchNotifications(String userId) async {
    try {
      final rows = _rows(
        await _client
            .from('notifications')
            .select(
              'id, recipient_id, type, title, message, action_url, metadata, read_at, created_at',
            )
            .eq('recipient_id', userId)
            .order('created_at', ascending: false)
            .limit(100),
      );
      return rows.map(DbNotification.fromRow).toList();
    } catch (_) {
      return const [];
    }
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

    final fallbackActivityIds = <String>{};
    try {
      final enrollmentRows = _rows(
        await _client
            .from('class_students')
            .select('class_id')
            .eq('student_id', studentId),
      );
      final enrolledClassIds = enrollmentRows
          .map((row) => _string(row['class_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (enrolledClassIds.isNotEmpty) {
        final activeClassIds =
            _rows(
                  await _client
                      .from('classes')
                      .select('id')
                      .inFilter('id', enrolledClassIds)
                      .eq('is_active', true),
                )
                .map((row) => _string(row['id']))
                .where((id) => id.isNotEmpty)
                .toList();
        if (activeClassIds.isNotEmpty) {
          fallbackActivityIds.addAll(
            _rows(
              await _client
                  .from('activities')
                  .select('id')
                  .inFilter('class_id', activeClassIds)
                  .eq('status', 'active'),
            ).map((row) => _string(row['id'])).where((id) => id.isNotEmpty),
          );
        }
      }
    } catch (_) {
      // Assignment and submission rows still provide a useful activity list if
      // the defensive class-activity fallback is temporarily unavailable.
    }

    final activityIds = <String>{
      ...assignmentRows
          .map((row) => _string(row['activity_id']))
          .where((id) => id.isNotEmpty),
      ...submissionRows
          .map((row) => _string(row['activity_id']))
          .where((id) => id.isNotEmpty),
      ...fallbackActivityIds,
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

    final classIds = activityRows
        .map((row) => _string(row['class_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final activeClassIds = classIds.isEmpty
        ? <String>{}
        : _rows(
            await _client
                .from('classes')
                .select('id')
                .inFilter('id', classIds)
                .eq('is_active', true),
          ).map((row) => _string(row['id'])).toSet();
    final visibleActivityRows = activityRows.where((row) {
      final classId = _string(row['class_id']);
      return classId.isEmpty || activeClassIds.contains(classId);
    }).toList();

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

    final activities = visibleActivityRows.map((row) {
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
            'id, teacher_id, name, grade, section, subject, color, image_url, student_count, created_at, is_active, disabled_at, disabled_by',
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

  static Future<List<DbStudent>> fetchTeacherStudents(
    List<DbClass> classes,
  ) async {
    try {
      final classIds = classes
          .map((item) => item.id)
          .where((id) => id.isNotEmpty)
          .toList();
      if (classIds.isEmpty) return const [];
      final rows = _rows(
        await _client
            .from('class_students')
            .select('student_id, student_name, student_email')
            .inFilter('class_id', classIds),
      );
      final enrollmentById = <String, DbStudent>{};
      for (final row in rows) {
        final student = DbStudent.fromEnrollmentRow(row);
        if (student.id.isNotEmpty) enrollmentById[student.id] = student;
      }
      if (enrollmentById.isEmpty) return const [];
      try {
        final current = await _fetchUsersByIds(enrollmentById.keys.toList());
        for (final student in current) {
          final snapshot = enrollmentById[student.id];
          enrollmentById[student.id] = DbStudent(
            id: student.id,
            name: resolveMobileStudentDisplayName(
              profileName: student.name,
              enrollmentName: snapshot?.name ?? '',
              email: student.email.isNotEmpty
                  ? student.email
                  : snapshot?.email ?? '',
            ),
            email: student.email.isNotEmpty
                ? student.email
                : snapshot?.email ?? '',
            role: student.role,
            avatarPath: student.avatarPath,
          );
        }
      } catch (_) {
        // Enrollment snapshots remain a safe display fallback.
      }
      final students = enrollmentById.values.toList()
        ..sort((left, right) => left.name.compareTo(right.name));
      return students;
    } catch (_) {
      // Reports remain available even when roster access is temporarily down.
      return const [];
    }
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
    final students = rows.map(DbStudent.fromEnrollmentRow).toList();
    final ids = students
        .map((student) => student.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return students;

    try {
      final currentRows = _rows(
        await _client
            .from('users')
            .select('id, name, email, role, avatar_url')
            .inFilter('id', ids)
            .eq('role', 'student'),
      );
      final currentById = {
        for (final row in currentRows)
          _string(row['id']): DbStudent.fromUserRow(row),
      };
      return students
          .map((student) => currentById[student.id] ?? student)
          .toList();
    } catch (_) {
      return students;
    }
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

    final activeClassIds = classes.map((item) => item.id).toSet();
    final activities = rows
        .map(DbActivity.fromRow)
        .where(
          (activity) =>
              activity.classId.isEmpty ||
              activeClassIds.contains(activity.classId),
        )
        .toList();
    if (activities.isEmpty) return [];
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

  static Future<List<DbActivity>> fetchTeacherStudentActivities(
    String studentId,
    List<DbActivity> teacherActivities,
    List<DbSubmission> teacherSubmissions,
  ) async {
    if (teacherActivities.isEmpty) return [];

    final activityIds = teacherActivities.map((item) => item.id).toList();
    final assignmentRows = _rows(
      await _client
          .from('activity_assignments')
          .select('activity_id, student_id, status, assigned_at')
          .eq('student_id', studentId)
          .inFilter('activity_id', activityIds),
    );
    final assignmentsByActivity = {
      for (final row in assignmentRows) _string(row['activity_id']): row,
    };
    final submissionsByActivity = <String, DbSubmission>{};
    for (final submission in teacherSubmissions) {
      if (submission.studentId == studentId &&
          !submissionsByActivity.containsKey(submission.activityId)) {
        submissionsByActivity[submission.activityId] = submission;
      }
    }

    final visible = teacherActivities
        .where((activity) {
          return assignmentsByActivity.containsKey(activity.id) ||
              submissionsByActivity.containsKey(activity.id);
        })
        .map((activity) {
          final assignment = assignmentsByActivity[activity.id];
          final submission = submissionsByActivity[activity.id];
          return DbActivity(
            id: activity.id,
            title: activity.title,
            summary: activity.summary,
            rawDescription: activity.rawDescription,
            dueDate: activity.dueDate,
            status: activity.status,
            imageUrl: submission?.artworkUrl.isNotEmpty == true
                ? submission!.artworkUrl
                : activity.imageUrl,
            classId: activity.classId,
            grade: activity.grade,
            subject: activity.subject,
            assignmentStatus: _normalizeStatus(assignment?['status']),
            assignedAt: _date(assignment?['assigned_at']),
            submission: submission?.copyWith(activityTitle: activity.title),
            assignmentCount: activity.assignmentCount,
            submissionCount: activity.submissionCount,
            className: activity.className,
          );
        })
        .toList();

    visible.sort((a, b) {
      final aDone = a.isSubmitted ? 1 : 0;
      final bDone = b.isSubmitted ? 1 : 0;
      if (aDone != bDone) return aDone.compareTo(bDone);
      return (a.dueDate ?? DateTime(2099)).compareTo(
        b.dueDate ?? DateTime(2099),
      );
    });
    return visible;
  }

  static Future<List<DbSubmission>> fetchTeacherSubmissions(
    String teacherId,
    List<DbActivity> teacherActivities, {
    List<DbStudent> roster = const [],
  }) async {
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
    final rosterById = {for (final student in roster) student.id: student};
    final studentById = <String, DbStudent>{...rosterById};
    for (final student in students) {
      final snapshot = rosterById[student.id];
      studentById[student.id] = DbStudent(
        id: student.id,
        name: resolveMobileStudentDisplayName(
          profileName: student.name,
          enrollmentName: snapshot?.name ?? '',
          email: student.email.isNotEmpty
              ? student.email
              : snapshot?.email ?? '',
        ),
        email: student.email.isNotEmpty ? student.email : snapshot?.email ?? '',
        role: student.role,
        avatarPath: student.avatarPath,
      );
    }

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

  static Future<List<TeacherRubricEvidence>> fetchTeacherRubricEvidence(
    List<DbActivity> activities,
  ) async {
    final activityIds = activities.map((item) => item.id).toList();
    if (activityIds.isEmpty) return const [];
    final observations = _rows(
      await _client
          .from('rubric_observations')
          .select('id, learner_id, activity_id, teacher_confirmed_at')
          .inFilter('activity_id', activityIds)
          .not('teacher_confirmed_at', 'is', null),
    );
    if (observations.isEmpty) return const [];
    final observationById = {
      for (final row in observations) _string(row['id']): row,
    };
    final criteria = _rows(
      await _client
          .from('rubric_criterion_observations')
          .select('observation_id, criterion_title_snapshot, selected_rating')
          .inFilter('observation_id', observationById.keys.toList()),
    );
    final activityById = {for (final item in activities) item.id: item};
    return criteria
        .map((criterion) {
          final observation =
              observationById[_string(criterion['observation_id'])];
          final activityId = _string(observation?['activity_id']);
          return TeacherRubricEvidence(
            studentId: _string(observation?['learner_id']),
            activityId: activityId,
            activityTitle:
                activityById[activityId]?.title ?? 'Untitled activity',
            criterionTitle: _string(criterion['criterion_title_snapshot']),
            rating: _canonicalRubricRating(criterion['selected_rating']),
            confirmedAt: _date(observation?['teacher_confirmed_at']),
          );
        })
        .where((item) => item.studentId.isNotEmpty && item.rating.isNotEmpty)
        .toList();
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
    String color = '#1800AD',
  }) async {
    final safeName = name.trim();
    if (grade.trim().isEmpty ||
        section.trim().isEmpty ||
        subject.trim().isEmpty) {
      return const DbResult.failure(
        'Grade level, section, and subject are required.',
      );
    }
    try {
      final row = await _client
          .from('classes')
          .insert({
            'teacher_id': teacherId,
            'name': safeName,
            'grade': grade.trim(),
            'section': section.trim(),
            'subject': subject.trim(),
            'color': _normalizeClassColor(color),
          })
          .select('id')
          .single();
      return DbResult.success(value: _string(row['id']));
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
    String color = '#1800AD',
  }) async {
    if (grade.trim().isEmpty ||
        section.trim().isEmpty ||
        subject.trim().isEmpty) {
      return const DbResult.failure(
        'Grade level, section, and subject are required.',
      );
    }
    try {
      await _client
          .from('classes')
          .update({
            'name': name.trim(),
            'grade': grade.trim(),
            'section': section.trim(),
            'subject': subject.trim(),
            'color': _normalizeClassColor(color),
          })
          .eq('id', classId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> setClassImagePath(
    String classId,
    String? imagePath,
  ) async {
    try {
      await _client
          .from('classes')
          .update({'image_url': imagePath})
          .eq('id', classId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<String> fetchUserAvatarPath(String userId) async {
    final row = await _client
        .from('users')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return _string(row?['avatar_url']);
  }

  static Future<DbResult> setUserAvatarPath(
    String userId,
    String? avatarPath,
  ) async {
    try {
      await _client
          .from('users')
          .update({'avatar_url': avatarPath})
          .eq('id', userId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> setClassActive(
    String classId, {
    required bool isActive,
  }) async {
    try {
      final actorId = _client.auth.currentUser?.id;
      if (actorId == null || actorId.isEmpty) {
        return const DbResult.failure('Sign in again to update this class.');
      }
      await _client
          .from('classes')
          .update({
            'is_active': isActive,
            'disabled_at': isActive ? null : DateTime.now().toIso8601String(),
            'disabled_by': isActive ? null : actorId,
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
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
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
    String rubricId = '',
  }) async {
    if (title.trim().isEmpty) {
      return const DbResult.failure('Activity title is required.');
    }
    try {
      await _client.rpc(
        'create_activity_with_assignments',
        params: {
          'p_teacher_id': teacherId,
          'p_title': title.trim(),
          'p_description': _isEncodedActivityDescription(description)
              ? description
              : encodeMobileActivityDescription(description.trim()),
          'p_class_id': classItem.id,
          'p_grade': classItem.grade.isEmpty ? null : classItem.grade,
          'p_subject': classItem.subject.isEmpty ? null : classItem.subject,
          'p_due_date': dueDate?.toIso8601String(),
          'p_status': 'active',
          'p_image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'p_rubric_id': rubricId.isEmpty ? null : rubricId,
        },
      );
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
    String existingDescription = '',
    String rubricAction = 'keep',
    String rubricId = '',
  }) async {
    if (title.trim().isEmpty) {
      return const DbResult.failure('Activity title is required.');
    }
    try {
      await _client.rpc(
        'update_activity_with_rubric',
        params: {
          'p_activity_id': activityId,
          'p_title': title.trim(),
          'p_description': encodeMobileActivityDescription(
            description.trim(),
            existingDescription: existingDescription,
          ),
          'p_due_date': dueDate?.toIso8601String(),
          'p_image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'p_rubric_action': rubricAction,
          'p_rubric_id': rubricId.isEmpty ? null : rubricId,
        },
      );
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<List<ActivityRubricOption>> fetchActivityRubricOptions(
    String teacherId,
  ) async {
    final result = await _client.rpc(
      'get_activity_rubric_options',
      params: {'p_teacher_id': teacherId},
    );
    return _rows(result).map(ActivityRubricOption.fromRow).toList();
  }

  static Future<List<TeacherRubricDefinition>> fetchTeacherRubrics(
    String teacherId,
  ) async {
    final rows = _rows(
      await _client
          .from('rubrics')
          .select('id, title, description, criteria, metadata, created_at')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false),
    );
    return rows.map(TeacherRubricDefinition.fromRow).toList();
  }

  static Future<({DbResult result, String rubricId})> createTeacherRubric({
    required String teacherId,
    required String title,
    required String activityType,
    required List<Map<String, dynamic>> criteria,
  }) async {
    try {
      final row = await _client
          .from('rubrics')
          .insert({
            'teacher_id': teacherId,
            'title': title.trim(),
            'description': 'Teacher-created private-school activity rubric.',
            'criteria': criteria,
            'metadata': {
              'version': 2,
              'isTemplate': true,
              'assessmentStyle': 'private-school',
              'ratingScale': 'BG-DV-CO',
              'activityType': activityType,
            },
          })
          .select('id')
          .single();
      return (result: const DbResult.success(), rubricId: _string(row['id']));
    } catch (error) {
      return (result: DbResult.failure(error.toString()), rubricId: '');
    }
  }

  static Future<DbResult> attachTeacherRubric(
    String activityId,
    String rubricId,
  ) async {
    try {
      await _client.rpc(
        'set_activity_rubric',
        params: {
          'p_activity_id': activityId,
          'p_rubric_id': rubricId.isEmpty ? null : rubricId,
        },
      );
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<DbResult> deleteTeacherRubric(String rubricId) async {
    try {
      final usage = await _client
          .from('activity_rubrics')
          .select('activity_id')
          .eq('rubric_id', rubricId)
          .limit(1);
      if (_rows(usage).isNotEmpty) {
        return const DbResult.failure(
          'This rubric is attached to an activity and must be kept for its saved grading history. Use “Use as copy” to make a new version.',
        );
      }
      await _client.from('rubrics').delete().eq('id', rubricId);
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<ActivityRubricManagementState> fetchActivityRubricState(
    String activityId,
  ) async {
    final result = await _client.rpc(
      'get_activity_rubric_management_state',
      params: {'p_activity_id': activityId},
    );
    if (result is Map) {
      return ActivityRubricManagementState.fromJson(
        Map<String, dynamic>.from(result),
      );
    }
    return const ActivityRubricManagementState();
  }

  static Future<StudentActivityAssessment> fetchStudentActivityAssessment(
    String activityId,
  ) async {
    final result = await _client.rpc(
      'get_student_activity_assessment',
      params: {'p_activity_id': activityId},
    );
    if (result is! Map) return const StudentActivityAssessment();
    return StudentActivityAssessment.fromJson(
      Map<String, dynamic>.from(result),
    );
  }

  static Future<TeacherReviewContext> fetchTeacherReviewContext(
    DbSubmission submission,
  ) async {
    StudentRubric? rubric;
    TeacherAiEvaluation? aiEvaluation;

    final rubricRow = await _client
        .from('activity_rubrics')
        .select('rubric_snapshot, rubric_version, rubric:rubrics(*)')
        .eq('activity_id', submission.activityId)
        .maybeSingle();
    if (rubricRow != null) {
      final source = rubricRow['rubric_snapshot'] ?? rubricRow['rubric'];
      if (source is Map) {
        final json = Map<String, dynamic>.from(source);
        json['assignedVersion'] = rubricRow['rubric_version'];
        rubric = StudentRubric.fromJson(json);
      }
    }

    try {
      final aiRow = await _client
          .from('submission_ai_evaluations')
          .select('*')
          .eq('submission_id', submission.id)
          .maybeSingle();
      if (aiRow != null) aiEvaluation = TeacherAiEvaluation.fromJson(aiRow);
    } catch (_) {
      // AI assistance is optional; teacher review remains fully usable.
    }

    return TeacherReviewContext(rubric: rubric, aiEvaluation: aiEvaluation);
  }

  static Future<TeacherAiEvaluation?> requestTeacherAiReview(
    String submissionId, {
    bool force = false,
  }) async {
    final response = await _client.functions.invoke(
      'grade-ar-submission',
      body: {'submissionId': submissionId, 'force': force},
    );
    final data = response.data;
    if (data is! Map) return null;
    final evaluation = data['evaluation'];
    if (evaluation is Map) {
      return TeacherAiEvaluation.fromJson(
        Map<String, dynamic>.from(evaluation),
      );
    }
    return null;
  }

  static Future<DbResult> finalizeSubmissionReview({
    required String teacherId,
    required DbSubmission submission,
    required int score,
    required String feedback,
    required String nextSteps,
    required StudentRubric? rubric,
    required List<String> criterionRatings,
    required List<String> criterionNotes,
    required bool teacherConfirmed,
    TeacherAiEvaluation? aiEvaluation,
  }) async {
    if (score < 1 || score > 5) {
      return const DbResult.failure('Choose an overall rating from 1 to 5.');
    }
    if (rubric != null &&
        (!teacherConfirmed ||
            criterionRatings.length != rubric.criteria.length ||
            criterionRatings.any(
              (rating) => !_rubricRatingCodes.contains(rating),
            ))) {
      return const DbResult.failure(
        'Rate every rubric criterion and confirm the final teacher review.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final observation = rubric == null
        ? null
        : <String, dynamic>{
            'rubric_id': rubric.id,
            'rubric_version': rubric.version,
            'learner_id': submission.studentId,
            'activity_id': submission.activityId,
            'activity_name': submission.activityTitle,
            'observer_id': teacherId,
            'observation_date': DateTime.now()
                .toIso8601String()
                .split('T')
                .first,
            'overall_comment': feedback.trim().isEmpty ? null : feedback.trim(),
            'evidence_url': submission.artworkUrl.isEmpty
                ? null
                : submission.artworkUrl,
            'next_steps': nextSteps.trim().isEmpty ? null : nextSteps.trim(),
            'teacher_confirmed_at': now,
            'ai_evaluation_id':
                aiEvaluation?.isCompleted == true &&
                    aiEvaluation?.submissionId == submission.id
                ? aiEvaluation?.id
                : null,
          };
    final criteria = rubric == null
        ? const <Map<String, dynamic>>[]
        : List.generate(rubric.criteria.length, (index) {
            final criterion = rubric.criteria[index];
            String descriptor(String code) =>
                criterion.levels
                    .where(
                      (level) => _canonicalRubricRating(level.code) == code,
                    )
                    .map((level) => level.description)
                    .firstOrNull ??
                '';
            return <String, dynamic>{
              'criterion_index': index,
              'criterion_title_snapshot': criterion.name,
              'beginning_descriptor_snapshot': descriptor('BG'),
              'developing_descriptor_snapshot': descriptor('DV'),
              'consistent_descriptor_snapshot': descriptor('CO'),
              'selected_rating': criterionRatings[index],
              'teacher_note': criterionNotes[index].trim().isEmpty
                  ? null
                  : criterionNotes[index].trim(),
            };
          });

    try {
      await _client.rpc(
        'finalize_submission_review',
        params: {
          'p_submission_id': submission.id,
          'p_teacher_id': teacherId,
          'p_score': score,
          'p_feedback': feedback.trim(),
          'p_observation': observation,
          'p_criteria': criteria,
        },
      );
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
  }

  static Future<String> uploadActivityThumbnail({
    required String teacherId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final extension = safeName.contains('.') ? safeName.split('.').last : 'jpg';
    final path =
        '$teacherId/${DateTime.now().millisecondsSinceEpoch}-${safeName.isEmpty ? 'thumbnail.$extension' : safeName}';
    await _client.storage
        .from('activity-thumbnails')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '31536000',
            contentType: _imageContentType(extension),
            upsert: false,
          ),
        );
    return _client.storage.from('activity-thumbnails').getPublicUrl(path);
  }

  static Future<DbResult> markNotificationsRead(
    String userId,
    List<String> notificationIds,
  ) async {
    final ids = notificationIds.where((id) => id.isNotEmpty).toSet();
    if (userId.isEmpty || ids.isEmpty) return const DbResult.success();

    try {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('recipient_id', userId)
          .inFilter('id', ids.toList());
      return const DbResult.success();
    } catch (error) {
      return DbResult.failure(error.toString());
    }
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
          .select('id, name, email, role, avatar_url')
          .inFilter('id', ids),
    );
    return rows.map(DbStudent.fromUserRow).toList();
  }
}

class StudentBundle {
  const StudentBundle({
    required this.studentId,
    required this.classItem,
    required this.activities,
    required this.artworks,
    required this.notifications,
  });

  final String studentId;
  final DbClass? classItem;
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
        .map(normalizeMobileStarRating)
        .where((score) => score > 0)
        .toList();
    if (scores.isEmpty) return 'N/A';
    final total = scores.fold<int>(0, (sum, score) => sum + score);
    return (total / scores.length).toStringAsFixed(1);
  }
}

class TeacherMobileSettings {
  const TeacherMobileSettings({
    this.backgroundMusic = true,
    this.soundEffects = true,
    this.voiceInstructions = true,
    this.notifications = true,
    this.dataSaver = false,
    this.quality = 'auto',
    this.inAppEnabled = true,
    this.emailEnabled = true,
    this.activityAssigned = true,
    this.gradePosted = true,
    this.dueSoon = true,
    this.missingWork = true,
    this.accountUpdates = true,
  });

  final bool backgroundMusic;
  final bool soundEffects;
  final bool voiceInstructions;
  final bool notifications;
  final bool dataSaver;
  final String quality;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool activityAssigned;
  final bool gradePosted;
  final bool dueSoon;
  final bool missingWork;
  final bool accountUpdates;

  factory TeacherMobileSettings.fromRows(
    Map<String, dynamic> settings,
    Map<String, dynamic> preferences,
  ) {
    bool flag(Map<String, dynamic> source, String key, bool fallback) =>
        source[key] is bool ? source[key] as bool : fallback;
    final qualityValue = _string(settings['quality']).toLowerCase();
    return TeacherMobileSettings(
      backgroundMusic: flag(settings, 'backgroundMusic', true),
      soundEffects: flag(settings, 'soundEffects', true),
      voiceInstructions: flag(settings, 'voiceInstructions', true),
      notifications: flag(settings, 'notifications', true),
      dataSaver: flag(settings, 'dataSaver', false),
      quality: const {'auto', 'high', 'medium', 'low'}.contains(qualityValue)
          ? qualityValue
          : 'auto',
      inAppEnabled: flag(preferences, 'in_app_enabled', true),
      emailEnabled: flag(preferences, 'email_enabled', true),
      activityAssigned: flag(preferences, 'activity_assigned', true),
      gradePosted: flag(preferences, 'grade_posted', true),
      dueSoon: flag(preferences, 'due_soon', true),
      missingWork: flag(preferences, 'missing_work', true),
      accountUpdates: flag(preferences, 'account_updates', true),
    );
  }

  TeacherMobileSettings copyWith({
    bool? backgroundMusic,
    bool? soundEffects,
    bool? voiceInstructions,
    bool? notifications,
    bool? dataSaver,
    String? quality,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? activityAssigned,
    bool? gradePosted,
    bool? dueSoon,
    bool? missingWork,
    bool? accountUpdates,
  }) => TeacherMobileSettings(
    backgroundMusic: backgroundMusic ?? this.backgroundMusic,
    soundEffects: soundEffects ?? this.soundEffects,
    voiceInstructions: voiceInstructions ?? this.voiceInstructions,
    notifications: notifications ?? this.notifications,
    dataSaver: dataSaver ?? this.dataSaver,
    quality: quality ?? this.quality,
    inAppEnabled: inAppEnabled ?? this.inAppEnabled,
    emailEnabled: emailEnabled ?? this.emailEnabled,
    activityAssigned: activityAssigned ?? this.activityAssigned,
    gradePosted: gradePosted ?? this.gradePosted,
    dueSoon: dueSoon ?? this.dueSoon,
    missingWork: missingWork ?? this.missingWork,
    accountUpdates: accountUpdates ?? this.accountUpdates,
  );

  Map<String, dynamic> get userSettingsJson => {
    'backgroundMusic': backgroundMusic,
    'soundEffects': soundEffects,
    'voiceInstructions': voiceInstructions,
    'notifications': notifications,
    'dataSaver': dataSaver,
    'quality': quality,
  };

  Map<String, dynamic> get notificationPreferencesJson => {
    'in_app_enabled': inAppEnabled,
    'email_enabled': emailEnabled,
    'activity_assigned': activityAssigned,
    'grade_posted': gradePosted,
    'due_soon': dueSoon,
    'missing_work': missingWork,
    'account_updates': accountUpdates,
  };
}

class TeacherRubricEvidence {
  const TeacherRubricEvidence({
    required this.studentId,
    required this.activityId,
    required this.activityTitle,
    required this.criterionTitle,
    required this.rating,
    required this.confirmedAt,
  });

  final String studentId;
  final String activityId;
  final String activityTitle;
  final String criterionTitle;
  final String rating;
  final DateTime? confirmedAt;

  double? get value => switch (rating) {
    'CO' => 1,
    'DV' => .67,
    'BG' => .33,
    _ => null,
  };

  String get category {
    final title = criterionTitle.toLowerCase();
    if (RegExp(r'colou?r|paint|hue|shade').hasMatch(title)) {
      return 'coloring';
    }
    if (RegExp(
      r'puzzle|piece|connect|assembl|arrang|fit|trace',
    ).hasMatch(title)) {
      return 'puzzle';
    }
    return 'overall';
  }
}

class TeacherBundle {
  const TeacherBundle({
    required this.teacherId,
    required this.classes,
    required this.students,
    required this.activities,
    required this.submissions,
    required this.rubricEvidence,
    required this.gestureAlerts,
    required this.notifications,
  });

  final String teacherId;
  final List<DbClass> classes;
  final List<DbStudent> students;
  final List<DbActivity> activities;
  final List<DbSubmission> submissions;
  final List<TeacherRubricEvidence> rubricEvidence;
  final List<DbGestureAlert> gestureAlerts;
  final List<DbNotification> notifications;

  List<DbClass> get activeClasses =>
      classes.where((item) => item.isActive).toList();
  List<DbClass> get inactiveClasses =>
      classes.where((item) => !item.isActive).toList();

  int get totalStudents => students.length;
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
        .map(normalizeMobileStarRating)
        .where((score) => score > 0)
        .toList();
    if (scores.isEmpty) return 'N/A';
    final total = scores.fold<int>(0, (sum, score) => sum + score);
    return (total / scores.length).toStringAsFixed(1);
  }
}

class ClassDetailBundle {
  const ClassDetailBundle({
    required this.classItem,
    required this.students,
    required this.activities,
  });

  final DbClass? classItem;
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
    this.color = '#1800AD',
    this.imagePath = '',
    this.isActive = true,
    this.disabledAt,
    this.studentCount = 0,
    this.activityCount = 0,
  });

  final String id;
  final String name;
  final String grade;
  final String section;
  final String subject;
  final String color;
  final String imagePath;
  final bool isActive;
  final DateTime? disabledAt;
  final int studentCount;
  final int activityCount;

  factory DbClass.fromRow(Map<String, dynamic> row) {
    return DbClass(
      id: _string(row['id']),
      name: _string(row['name'], fallback: 'Class'),
      grade: _string(row['grade']),
      section: _string(row['section']),
      subject: _string(row['subject']),
      color: _normalizeClassColor(_string(row['color'])),
      imagePath: _string(row['image_url']),
      isActive: row['is_active'] != false,
      disabledAt: _date(row['disabled_at']),
      studentCount: _int(row['student_count']),
    );
  }

  DbClass copyWith({
    int? studentCount,
    int? activityCount,
    String? imagePath,
    String? color,
  }) {
    return DbClass(
      id: id,
      name: name,
      grade: grade,
      section: section,
      subject: subject,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive,
      disabledAt: disabledAt,
      studentCount: studentCount ?? this.studentCount,
      activityCount: activityCount ?? this.activityCount,
    );
  }

  String get displayName {
    final parts = [
      grade,
      section,
    ].where((item) => item.trim().isNotEmpty).join(' - ');
    if (name.trim().toLowerCase() == parts.trim().toLowerCase()) return parts;
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
    this.avatarPath = '',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarPath;

  factory DbStudent.fromEnrollmentRow(Map<String, dynamic> row) {
    return DbStudent(
      id: _string(row['student_id'], fallback: _string(row['id'])),
      name: _string(row['student_name'], fallback: 'Student'),
      email: _string(row['student_email']),
      role: 'student',
      avatarPath: _string(row['avatar_url']),
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
      avatarPath: _string(row['avatar_url']),
    );
  }
}

class ActivityRubricOption {
  const ActivityRubricOption({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    required this.criteriaCount,
  });

  final String id;
  final String title;
  final String description;
  final String version;
  final int criteriaCount;

  factory ActivityRubricOption.fromRow(Map<String, dynamic> row) {
    return ActivityRubricOption(
      id: _string(row['id']),
      title: _string(row['title'], fallback: 'Untitled rubric'),
      description: _string(row['description']),
      version: _string(row['rubric_version'], fallback: '1'),
      criteriaCount: _int(row['criteria_count']),
    );
  }
}

class TeacherRubricDefinition {
  const TeacherRubricDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.criteria,
  });

  final String id;
  final String title;
  final String description;
  final String activityType;
  final List<TeacherRubricCriterion> criteria;

  String get criteriaSummary => criteria
      .map((criterion) => criterion.name)
      .where((name) => name.isNotEmpty)
      .join(' · ');

  factory TeacherRubricDefinition.fromRow(Map<String, dynamic> row) {
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : const <String, dynamic>{};
    return TeacherRubricDefinition(
      id: _string(row['id']),
      title: _string(row['title'], fallback: 'Untitled rubric'),
      description: _string(row['description']),
      activityType: _string(metadata['activityType'], fallback: 'general'),
      criteria: _rows(
        row['criteria'],
      ).map(TeacherRubricCriterion.fromJson).toList(),
    );
  }
}

class TeacherRubricCriterion {
  const TeacherRubricCriterion({
    required this.name,
    required this.beginning,
    required this.developing,
    required this.consistent,
  });

  final String name;
  final String beginning;
  final String developing;
  final String consistent;

  factory TeacherRubricCriterion.fromJson(Map<String, dynamic> json) {
    final levels = _rows(json['levels']);
    String descriptionFor(String code, String fallback) {
      final matching = levels.where(
        (level) => _normalizeRubricCode(level['code']) == code,
      );
      return matching.isEmpty
          ? fallback
          : _string(matching.first['description'], fallback: fallback);
    }

    return TeacherRubricCriterion(
      name: _string(json['name']),
      beginning: descriptionFor('BG', _rubricBeginningDescription),
      developing: descriptionFor('DV', _rubricDevelopingDescription),
      consistent: descriptionFor('CO', _rubricConsistentDescription),
    );
  }
}

class ActivityRubricManagementState {
  const ActivityRubricManagementState({
    this.rubricId = '',
    this.rubricTitle = '',
    this.rubricVersion = '',
    this.changeLocked = false,
    this.lockReason,
    this.hasSubmissions = false,
  });

  final String rubricId;
  final String rubricTitle;
  final String rubricVersion;
  final bool changeLocked;
  final String? lockReason;
  final bool hasSubmissions;

  factory ActivityRubricManagementState.fromJson(Map<String, dynamic> json) {
    final reason = _string(json['lock_reason']);
    return ActivityRubricManagementState(
      rubricId: _string(json['rubric_id']),
      rubricTitle: _string(json['rubric_title']),
      rubricVersion: _string(json['rubric_version']),
      changeLocked: json['change_locked'] == true,
      lockReason: reason.isEmpty ? null : reason,
      hasSubmissions: json['has_submissions'] == true,
    );
  }
}

class TeacherReviewContext {
  const TeacherReviewContext({this.rubric, this.aiEvaluation});

  final StudentRubric? rubric;
  final TeacherAiEvaluation? aiEvaluation;
}

class TeacherAiCriterion {
  const TeacherAiCriterion({
    required this.title,
    required this.rating,
    required this.evidence,
  });

  final String title;
  final String rating;
  final String evidence;

  factory TeacherAiCriterion.fromJson(Map<String, dynamic> json) {
    return TeacherAiCriterion(
      title: _string(
        json['criterion'] ?? json['name'] ?? json['title'],
        fallback: 'Criterion',
      ),
      rating: _canonicalRubricRating(json['levelCode'] ?? json['level_code']),
      evidence: _string(json['evidence'] ?? json['reasoning']),
    );
  }
}

class TeacherAiEvaluation {
  const TeacherAiEvaluation({
    required this.id,
    required this.submissionId,
    required this.status,
    required this.suggestedScore,
    required this.feedback,
    required this.criteria,
    required this.error,
  });

  final String id;
  final String submissionId;
  final String status;
  final int suggestedScore;
  final String feedback;
  final List<TeacherAiCriterion> criteria;
  final String error;

  bool get isCompleted => status == 'completed';

  factory TeacherAiEvaluation.fromJson(Map<String, dynamic> json) {
    return TeacherAiEvaluation(
      id: _string(json['id']),
      submissionId: _string(json['submission_id']),
      status: _normalizeStatus(json['status']),
      suggestedScore: normalizeMobileStarRating(_num(json['suggested_score'])),
      feedback: _string(json['feedback']),
      criteria: _rows(
        json['criterion_scores'],
      ).map(TeacherAiCriterion.fromJson).toList(),
      error: _string(json['error']),
    );
  }
}

class StudentActivityAssessment {
  const StudentActivityAssessment({this.rubric, this.finalReview});

  final StudentRubric? rubric;
  final StudentFinalReview? finalReview;

  factory StudentActivityAssessment.fromJson(Map<String, dynamic> json) {
    final rubricJson = json['rubric'];
    final reviewJson = json['final_review'];
    return StudentActivityAssessment(
      rubric: rubricJson is Map
          ? StudentRubric.fromJson(Map<String, dynamic>.from(rubricJson))
          : null,
      finalReview: reviewJson is Map
          ? StudentFinalReview.fromJson(Map<String, dynamic>.from(reviewJson))
          : null,
    );
  }
}

class StudentRubric {
  const StudentRubric({
    required this.id,
    required this.title,
    required this.description,
    required this.criteria,
    required this.version,
  });

  final String id;
  final String title;
  final String description;
  final List<StudentRubricCriterion> criteria;
  final String version;

  factory StudentRubric.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    final rawTitle = _string(json['title'], fallback: 'Activity rubric');
    final rawDescription = _string(json['description']);
    return StudentRubric(
      id: _string(json['id']),
      title: _hasLegacyPublicRubricLabel(rawTitle)
          ? 'Activity rubric'
          : rawTitle,
      description: _hasLegacyPublicRubricLabel(rawDescription)
          ? ''
          : rawDescription,
      criteria: _rows(
        json['criteria'],
      ).map(StudentRubricCriterion.fromJson).toList(),
      version: _string(
        json['assignedVersion'] ??
            (metadata is Map ? metadata['version'] : null),
        fallback: '1',
      ),
    );
  }
}

class StudentRubricCriterion {
  const StudentRubricCriterion({required this.name, required this.levels});

  final String name;
  final List<StudentRubricLevel> levels;

  factory StudentRubricCriterion.fromJson(Map<String, dynamic> json) {
    return StudentRubricCriterion(
      name: _string(json['name'], fallback: 'Criterion'),
      levels: _rows(json['levels']).map(StudentRubricLevel.fromJson).toList(),
    );
  }
}

class StudentRubricLevel {
  const StudentRubricLevel({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;

  factory StudentRubricLevel.fromJson(Map<String, dynamic> json) {
    final code = _canonicalRubricRating(json['code']);
    return StudentRubricLevel(
      code: code,
      label: code.isEmpty
          ? _string(json['label'], fallback: 'Level')
          : _rubricRatingLabel(code),
      description: _string(json['description']),
    );
  }
}

class StudentFinalReview {
  const StudentFinalReview({
    required this.score,
    required this.feedback,
    required this.overallComment,
    required this.nextSteps,
    required this.evidenceUrl,
    required this.teacherConfirmedAt,
    required this.criteria,
    required this.colorSuggestion,
  });

  final int score;
  final String feedback;
  final String overallComment;
  final String nextSteps;
  final String evidenceUrl;
  final DateTime? teacherConfirmedAt;
  final List<StudentCriterionResult> criteria;
  final StudentColorSuggestion? colorSuggestion;

  factory StudentFinalReview.fromJson(Map<String, dynamic> json) {
    final colorJson = json['approved_color_suggestion'];
    return StudentFinalReview(
      score: _int(json['score']),
      feedback: _string(json['feedback']),
      overallComment: _string(json['overall_comment']),
      nextSteps: _string(json['next_steps']),
      evidenceUrl: _string(json['evidence_url']),
      teacherConfirmedAt: _date(json['teacher_confirmed_at']),
      criteria: _rows(
        json['criteria'],
      ).map(StudentCriterionResult.fromJson).toList(),
      colorSuggestion: colorJson is Map
          ? StudentColorSuggestion.fromJson(
              Map<String, dynamic>.from(colorJson),
            )
          : null,
    );
  }
}

class StudentCriterionResult {
  const StudentCriterionResult({
    required this.title,
    required this.selectedRating,
    required this.teacherNote,
  });

  final String title;
  final String selectedRating;
  final String teacherNote;

  factory StudentCriterionResult.fromJson(Map<String, dynamic> json) {
    return StudentCriterionResult(
      title: _string(json['criterion_title_snapshot'], fallback: 'Criterion'),
      selectedRating: _string(json['selected_rating']).toUpperCase(),
      teacherNote: _string(json['teacher_note']),
    );
  }

  String get ratingLabel => switch (selectedRating) {
    'B' => 'Beginning',
    'D' => 'Developing',
    'C' => 'Consistent',
    'NO' => 'Not observed',
    'NA' => 'Not applicable',
    _ => selectedRating,
  };
}

class StudentColorSuggestion {
  const StudentColorSuggestion({
    required this.message,
    required this.rationale,
    required this.colors,
  });

  final String message;
  final String rationale;
  final List<StudentSuggestedColor> colors;

  factory StudentColorSuggestion.fromJson(Map<String, dynamic> json) {
    return StudentColorSuggestion(
      message: _string(json['message'], fallback: 'Color suggestion'),
      rationale: _string(json['rationale']),
      colors: _rows(
        json['colors'],
      ).map(StudentSuggestedColor.fromJson).toList(),
    );
  }
}

class StudentSuggestedColor {
  const StudentSuggestedColor({required this.name, required this.hex});

  final String name;
  final String hex;

  factory StudentSuggestedColor.fromJson(Map<String, dynamic> json) {
    return StudentSuggestedColor(
      name: _string(json['name'], fallback: 'Suggested color'),
      hex: _string(json['hex']),
    );
  }
}

class DbActivity {
  const DbActivity({
    required this.id,
    required this.title,
    required this.summary,
    required this.rawDescription,
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
  final String rawDescription;
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
    final rawDescription = _string(row['description']);
    final parsedDescription = _parseActivityDescription(rawDescription);
    final title = _string(row['title'], fallback: 'Untitled Activity');
    return DbActivity(
      id: _string(row['id']),
      title: title,
      summary: parsedDescription,
      rawDescription: rawDescription,
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
      rawDescription: rawDescription,
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
    required this.rawDescription,
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
  final String rawDescription;
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
      rawDescription: _string(row['description']),
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
      rawDescription: rawDescription,
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
    this.actionUrl = '',
    this.metadata = const <String, dynamic>{},
    this.isRead = false,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime? createdAt;
  final String actionUrl;
  final Map<String, dynamic> metadata;
  final bool isRead;

  Uri? get actionUri {
    final parsed = Uri.tryParse(actionUrl);
    if (parsed == null ||
        parsed.hasScheme ||
        parsed.hasAuthority ||
        parsed.fragment.isNotEmpty ||
        !parsed.path.startsWith('/')) {
      return null;
    }
    return parsed;
  }

  factory DbNotification.fromRow(Map<String, dynamic> row) {
    return DbNotification(
      id: _string(row['id']),
      type: _string(row['type'], fallback: 'notification'),
      title: _string(row['title'], fallback: 'Notification'),
      message: _string(row['message']),
      createdAt: _date(row['created_at']),
      actionUrl: _string(row['action_url']),
      metadata: row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : const <String, dynamic>{},
      isRead: _date(row['read_at']) != null,
    );
  }

  DbNotification copyWith({bool? isRead}) {
    return DbNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      actionUrl: actionUrl,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
    );
  }
}

class DbResult {
  const DbResult._({required this.success, this.error, this.value});
  const DbResult.success({String? value}) : this._(success: true, value: value);
  const DbResult.failure(String error) : this._(success: false, error: error);

  final bool success;
  final String? error;
  final String? value;
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

bool _isGenericStudentName(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'student' ||
      normalized == 'student user' ||
      normalized == 'learner';
}

String resolveMobileStudentDisplayName({
  required String profileName,
  required String enrollmentName,
  required String email,
}) {
  if (!_isGenericStudentName(profileName)) return profileName.trim();
  if (!_isGenericStudentName(enrollmentName)) return enrollmentName.trim();
  final localPart = email.trim().split('@').first.trim();
  return localPart.isEmpty ? 'Student' : localPart;
}

String _normalizeStatus(Object? value) =>
    _string(value).toLowerCase().replaceAll(' ', '_');

const _rubricRatingCodes = <String>{'BG', 'DV', 'CO', 'NO', 'NA'};

String _canonicalRubricRating(Object? value) {
  final code = _string(value).toUpperCase();
  return switch (code) {
    'B' => 'BG',
    'D' => 'DV',
    'C' => 'CO',
    _ when _rubricRatingCodes.contains(code) => code,
    _ => '',
  };
}

String _rubricRatingLabel(String code) => switch (code) {
  'BG' => 'Beginning',
  'DV' => 'Developing',
  'CO' => 'Consistent',
  'NO' => 'Not observed',
  'NA' => 'Not applicable',
  _ => 'Choose rating',
};

bool _hasLegacyPublicRubricLabel(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('sf9') ||
      normalized.contains('sp9') ||
      normalized.contains('deped') ||
      normalized.contains('public-school') ||
      normalized.contains('public school') ||
      normalized.contains('curriculum standard');
}

String _imageContentType(String extension) => switch (extension.toLowerCase()) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  'gif' => 'image/gif',
  _ => 'image/jpeg',
};

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

Color _colorFromHex(String value) {
  final normalized = value.replaceAll('#', '').trim();
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFBDBDBD);
}

IconData _notificationIcon(String type) {
  switch (type) {
    case 'assignment':
    case 'activity_assigned':
      return Icons.assignment_turned_in_outlined;
    case 'review':
    case 'grade_posted':
      return Icons.grade_outlined;
    case 'submission':
    case 'submission_received':
      return Icons.inbox_outlined;
    case 'alert':
      return Icons.warning_amber_outlined;
    case 'student_linked':
      return Icons.family_restroom_outlined;
    case 'account_registered':
      return Icons.person_add_alt_rounded;
    case 'reminder':
    case 'due_soon':
    case 'missing_work':
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

bool _isEncodedActivityDescription(String description) {
  try {
    final value = jsonDecode(description);
    return value is Map && value['tag'] == 'activity_ar_v1';
  } catch (_) {
    return false;
  }
}

class ActivityArDraft {
  const ActivityArDraft({
    this.summary = '',
    this.instructions = '',
    this.allowedObjectIds = const ['cube', 'sphere', 'cone'],
    this.modelIds = const ['cactus'],
    this.puzzlePieces = 0,
    this.allowedColors = const [],
    this.allowedColorNames = const {},
    this.colorRequirements = const [],
  });

  final String summary;
  final String instructions;
  final List<String> allowedObjectIds;
  final List<String> modelIds;
  final int puzzlePieces;
  final List<String> allowedColors;
  final Map<String, String> allowedColorNames;
  final List<ActivityColorRequirement> colorRequirements;

  factory ActivityArDraft.parse(String description) {
    final text = description.trim();
    if (!text.startsWith('{')) return ActivityArDraft(summary: description);
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map || decoded['tag'] != 'activity_ar_v1') {
        return ActivityArDraft(summary: description);
      }
      final modelIds =
          (decoded['modelIds'] is List
                  ? decoded['modelIds'] as List
                  : [decoded['modelId']])
              .map(_string)
              .where((id) => id.isNotEmpty)
              .toList();
      final colors =
          (decoded['allowedColors'] is List
                  ? decoded['allowedColors'] as List
                  : const [])
              .map(
                (value) =>
                    value is Map ? _string(value['hex']) : _string(value),
              )
              .where((hex) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex))
              .map((hex) => hex.toUpperCase())
              .toList();
      final colorNames = <String, String>{};
      for (final value
          in decoded['allowedColors'] is List
              ? decoded['allowedColors'] as List
              : const []) {
        if (value is! Map) continue;
        final hex = _string(value['hex']).toUpperCase();
        final name = _string(value['name']);
        if (colors.contains(hex) && name.isNotEmpty) colorNames[hex] = name;
      }
      final objects =
          (decoded['allowedObjectIds'] is List
                  ? decoded['allowedObjectIds'] as List
                  : const ['cube', 'sphere', 'cone'])
              .map(_string)
              .where(
                (id) => _activityObjectOptions.any((item) => item.id == id),
              )
              .toList();
      final requirements = _rows(decoded['colorRequirements'])
          .map(ActivityColorRequirement.fromJson)
          .whereType<ActivityColorRequirement>()
          .toList();
      return ActivityArDraft(
        summary: _string(decoded['summary']),
        instructions: _string(decoded['instructions']),
        allowedObjectIds: objects.isEmpty ? const ['cube'] : objects,
        modelIds: modelIds.isEmpty ? const ['cactus'] : modelIds,
        puzzlePieces: const {0, 3, 4}.contains(_int(decoded['puzzlePieces']))
            ? _int(decoded['puzzlePieces'])
            : 0,
        allowedColors: colors,
        allowedColorNames: colorNames,
        colorRequirements: requirements,
      );
    } catch (_) {
      return ActivityArDraft(summary: description);
    }
  }
}

class ActivityColorRequirement {
  const ActivityColorRequirement({
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.colorHex,
    required this.colorName,
  });

  final String targetType;
  final String targetId;
  final String targetLabel;
  final String colorHex;
  final String colorName;

  static ActivityColorRequirement? fromJson(Map<String, dynamic> json) {
    final targetType = json['targetType'] == 'object' ? 'object' : 'model';
    final targetId = _string(json['targetId']);
    final colorHex = _string(json['colorHex']).toUpperCase();
    if (targetId.isEmpty || !RegExp(r'^#[0-9A-F]{6}$').hasMatch(colorHex)) {
      return null;
    }
    return ActivityColorRequirement(
      targetType: targetType,
      targetId: targetId,
      targetLabel: _string(json['targetLabel'], fallback: targetId),
      colorHex: colorHex,
      colorName: _string(json['colorName'], fallback: colorHex),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetType': targetType,
    'targetId': targetId,
    'targetLabel': targetLabel,
    'colorHex': colorHex,
    'colorName': colorName.toLowerCase(),
  };
}

String encodeMobileActivityDescription(
  String summary, {
  String existingDescription = '',
  String instructions = '',
  List<String> allowedObjectIds = const ['cube', 'sphere', 'cone'],
  List<SandboxModelOption> models = const [],
  int puzzlePieces = 0,
  List<String> allowedColors = const [],
  Map<String, String> allowedColorNames = const {},
  List<ActivityColorRequirement> colorRequirements = const [],
}) {
  Map<String, dynamic> payload = <String, dynamic>{};
  final existing = existingDescription.trim();
  if (existing.startsWith('{')) {
    try {
      final decoded = jsonDecode(existing);
      if (decoded is Map && decoded['tag'] == 'activity_ar_v1') {
        payload = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // A malformed legacy description is replaced by the canonical payload.
    }
  }
  payload['tag'] = 'activity_ar_v1';
  payload['summary'] = summary;
  payload['instructions'] = instructions.trim();
  payload['allowedObjectIds'] = allowedObjectIds;
  final safeModels = models.isEmpty
      ? sandboxFallbackModels.where((model) => model.id == 'cactus').toList()
      : models;
  payload['modelId'] = safeModels.first.id;
  payload['modelIds'] = safeModels.map((model) => model.id).toList();
  payload['models'] = safeModels.map((model) {
    final base = _sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '');
    return {
      'id': model.id,
      'label': model.label,
      'modelUrl': '$base/models/files/${Uri.encodeComponent(model.id)}',
      'modelFileType': model.fileType,
    };
  }).toList();
  payload['modelUrl'] =
      '${_sandboxModelApiBase.replaceAll(RegExp(r'/+$'), '')}/models/files/${Uri.encodeComponent(safeModels.first.id)}';
  payload['modelFileType'] = safeModels.first.fileType;
  payload['puzzlePieces'] = const {0, 3, 4}.contains(puzzlePieces)
      ? puzzlePieces
      : 0;
  payload['allowedColors'] = allowedColors
      .where((hex) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex))
      .take(10)
      .map((hex) {
        final normalized = hex.toUpperCase();
        final name = _string(allowedColorNames[normalized]).isNotEmpty
            ? _string(allowedColorNames[normalized]).toLowerCase()
            : _activityColorOptions
                      .where((color) => color.hex == normalized)
                      .map((color) => color.name.toLowerCase())
                      .firstOrNull ??
                  normalized.toLowerCase();
        return {'hex': normalized, 'name': name};
      })
      .toList();
  final selectedColorSet = allowedColors
      .map((item) => item.toUpperCase())
      .toSet();
  final validRequirementTargets = <String>{
    ...allowedObjectIds.map((id) => 'object:$id'),
    ...safeModels.map((model) => 'model:${model.id}'),
  };
  payload['colorRequirements'] = colorRequirements
      .where(
        (item) =>
            selectedColorSet.contains(item.colorHex) &&
            validRequirementTargets.contains(
              '${item.targetType}:${item.targetId}',
            ),
      )
      .take(24)
      .map((item) => item.toJson())
      .toList();
  return jsonEncode(payload);
}
