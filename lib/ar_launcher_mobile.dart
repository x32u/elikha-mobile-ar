import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'hosted_web_security.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// Opens a trusted, authenticated e-Likha web route inside the native shell.
Future<bool> openHostedExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) {
  return _openTrustedExperience(context, url, title: title);
}

/// Descriptive alias kept for callers that explicitly refer to hosted web.
Future<bool> openHostedWebExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) {
  return openHostedExperience(context, url, title: title);
}

/// Opens the existing hosted AR route while preserving the original API.
Future<bool> openArExperience(BuildContext context, Uri url) async {
  if (!_validateTrustedUrl(context, url)) return false;

  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!isMobile) {
    return _launchExternal(context, url, label: 'AR');
  }

  final isVrMode = url.queryParameters['vr'] == '1';
  try {
    // Apply the camera-experience display mode before showing any preparation
    // or permission UI. Short phones therefore never receive a portrait modal
    // squeezed into a landscape viewport halfway through the launch flow.
    await _applyCameraExperienceDisplayMode();
    if (!context.mounted) return false;

    final wantsToContinue = await _showArPreparationGuide(
      context,
      isVrMode: isVrMode,
    );
    if (!wantsToContinue || !context.mounted) return false;

    final hasCameraPermission = await _ensureCameraPermission(context);
    if (!hasCameraPermission || !context.mounted) return false;

    return await _openTrustedExperience(
      context,
      url,
      title: isVrMode ? 'VR Project' : 'AR Project',
      allowCamera: true,
      // Every camera experience needs the full landscape viewport. This also
      // removes the native app bar so it cannot cover the hosted AR controls.
      immersive: true,
    );
  } finally {
    // This covers guide cancellation, denied permission, failed session seed,
    // WebView load errors, submission, explicit exit, and the system Back key.
    await _restoreDefaultDisplayMode();
  }
}

Future<void> _applyCameraExperienceDisplayMode() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> _restoreDefaultDisplayMode() async {
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

Future<bool> _openTrustedExperience(
  BuildContext context,
  Uri url, {
  required String title,
  bool allowCamera = false,
  bool immersive = false,
}) async {
  if (!_validateTrustedUrl(context, url)) return false;

  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!isMobile) {
    return _launchExternal(context, url, label: title);
  }

  final sessionSeed = await _prepareSessionSeed(context);
  if (sessionSeed == null || !context.mounted) return false;

  // The hosted client receives a copy of the refresh token and may rotate it.
  // Pause the native timer while the WebView is open so two clients do not try
  // to refresh the same token concurrently; the latest hosted session is
  // synchronized back before this route closes.
  final auth = Supabase.instance.client.auth;
  auth.stopAutoRefresh();
  try {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _HostedWebViewPage(
          url: url,
          title: title,
          sessionSeed: sessionSeed,
          allowCamera: allowCamera,
          immersive: immersive,
        ),
      ),
    );
    return result ?? false;
  } finally {
    auth.startAutoRefresh();
  }
}

bool _validateTrustedUrl(BuildContext context, Uri url) {
  if (isTrustedHostedWebUri(url)) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked an untrusted e-Likha link.')),
    );
  }
  return false;
}

Future<bool> _launchExternal(
  BuildContext context,
  Uri url, {
  required String label,
}) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open $label right now.')));
  }
  return false;
}

Future<_SessionSeed?> _prepareSessionSeed(BuildContext context) async {
  try {
    final client = Supabase.instance.client;
    var session = client.auth.currentSession;
    if (session == null) {
      _showSignInAgainMessage(context);
      return null;
    }

    final expiresAt = session.expiresAt;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt != null && expiresAt - nowSeconds < 300) {
      session = (await client.auth.refreshSession()).session;
      if (!context.mounted) return null;
    }
    if (session == null) {
      _showSignInAgainMessage(context);
      return null;
    }

    final storageKey = supabaseWebAuthStorageKey(_supabaseUrl);
    final sessionJson = <String, dynamic>{
      'access_token': session.accessToken,
      'expires_in': session.expiresIn,
      'expires_at': session.expiresAt,
      'refresh_token': session.refreshToken,
      'token_type': session.tokenType,
      'user': session.user.toJson(),
    };
    return _SessionSeed(storageKey: storageKey, session: sessionJson);
  } catch (_) {
    if (context.mounted) _showSignInAgainMessage(context);
    return null;
  }
}

void _showSignInAgainMessage(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Your secure session expired. Please sign in again.'),
    ),
  );
}

Future<bool> _showArPreparationGuide(
  BuildContext context, {
  required bool isVrMode,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      icon: const Icon(Icons.view_in_ar_rounded, size: 40),
      title: Text(isVrMode ? 'Before you start VR' : 'Before you start AR'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GuideStep(
            number: '1',
            text: 'Keep your device in landscape, then tap Continue.',
          ),
          _GuideStep(
            number: '2',
            text: isVrMode
                ? 'The back camera will show the space in front of you.'
                : 'The front camera will show you and your hand gestures.',
          ),
          const _GuideStep(
            number: '3',
            text:
                'Use a clear, well-lit space and keep the camera unobstructed.',
          ),
          const _GuideStep(
            number: '4',
            text: 'Follow the on-screen cue before moving your artwork.',
          ),
          const SizedBox(height: 8),
          const Text(
            'e-Likha uses the camera only while this experience is open. '
            'Microphone access is not requested. Voice Guide can be turned on '
            'or off inside the activity.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Continue'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> _ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.request();
  if (status.isGranted) return true;

  if (!context.mounted) return false;
  if (status.isPermanentlyDenied || status.isRestricted) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Camera access is off'),
        content: const Text(
          'Enable camera permission in device settings, then return to '
          'e-Likha to use AR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(openAppSettings().then((_) {}));
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission is required for AR.')),
    );
  }
  return false;
}

class _SessionSeed {
  const _SessionSeed({required this.storageKey, required this.session});

  final String storageKey;
  final Map<String, dynamic> session;
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text(number)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _FilePickerFilter {
  const _FilePickerFilter({required this.type, this.extensions});

  final FileType type;
  final List<String>? extensions;
}

_FilePickerFilter _filePickerFilter(List<String> acceptTypes) {
  final accepted = acceptTypes
      .expand((value) => value.split(','))
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (accepted.isEmpty || accepted.contains('*/*')) {
    return const _FilePickerFilter(type: FileType.any);
  }
  if (accepted.every((value) => value == 'image/*')) {
    return const _FilePickerFilter(type: FileType.image);
  }

  const mimeExtensions = <String, List<String>>{
    'image/*': ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
    'image/jpeg': ['jpg', 'jpeg'],
    'image/png': ['png'],
    'image/gif': ['gif'],
    'image/webp': ['webp'],
    'model/gltf-binary': ['glb'],
    'model/obj': ['obj'],
    'application/x-blender': ['blend'],
    'application/x-3ds': ['3ds'],
  };
  final extensions = <String>{};
  for (final acceptedType in accepted) {
    if (acceptedType.startsWith('.') && acceptedType.length > 1) {
      extensions.add(acceptedType.substring(1));
      continue;
    }
    extensions.addAll(mimeExtensions[acceptedType] ?? const []);
  }
  if (extensions.isEmpty) {
    return const _FilePickerFilter(type: FileType.any);
  }
  return _FilePickerFilter(
    type: FileType.custom,
    extensions: extensions.toList(growable: false),
  );
}

bool _isValidTransferId(String id) {
  return id.length <= 80 && RegExp(r'^[A-Za-z0-9-]+$').hasMatch(id);
}

String? _sanitizeReportFileName(String? rawName) {
  const allowedExtensions = {'csv', 'xlsx', 'xls', 'pdf', 'json', 'txt'};
  var name = (rawName ?? '').trim().split(RegExp(r'[/\\]')).last;
  name = name
      .replaceAll(RegExp(r'[\u0000-\u001F<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (name.length > 180) name = name.substring(name.length - 180);
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return null;
  final extension = name.substring(dot + 1).toLowerCase();
  if (!allowedExtensions.contains(extension)) return null;
  return name;
}

class _PendingDownload {
  _PendingDownload({required this.name, required this.expectedSize});

  final String name;
  final int expectedSize;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  int receivedBytes = 0;

  void add(Uint8List chunk) {
    _bytes.add(chunk);
    receivedBytes += chunk.length;
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

class _HostedSessionSnapshot {
  const _HostedSessionSnapshot({required this.captured, required this.session});

  final bool captured;
  final Map<String, dynamic>? session;
}

class _HostedWebViewPage extends StatefulWidget {
  const _HostedWebViewPage({
    required this.url,
    required this.title,
    required this.sessionSeed,
    required this.allowCamera,
    required this.immersive,
  });

  final Uri url;
  final String title;
  final _SessionSeed sessionSeed;
  final bool allowCamera;
  final bool immersive;

  @override
  State<_HostedWebViewPage> createState() => _HostedWebViewPageState();
}

class _HostedWebViewPageState extends State<_HostedWebViewPage>
    with WidgetsBindingObserver {
  static const int _maxDownloadBytes = 25 * 1024 * 1024;

  late final WebViewController _controller;
  final Map<String, _PendingDownload> _pendingDownloads = {};
  int _progress = 0;
  bool _isSeeding = false;
  bool _sessionSeeded = false;
  bool _destinationReady = false;
  bool _closing = false;
  bool _cleanedUp = false;
  bool _saveDialogOpen = false;
  bool _hostedAuthLost = false;
  String? _loadError;

  Uri get _bootstrapUrl => trustedHostedWebBaseUri.replace(
    path: '/',
    queryParameters: const <String, String>{'mobileBootstrap': '1'},
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller =
        WebViewController(onPermissionRequest: _handlePermissionRequest)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(widget.allowCamera ? Colors.black : Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: _handleNavigationRequest,
              onProgress: (progress) {
                if (mounted) setState(() => _progress = progress);
              },
              onUrlChange: _handleUrlChange,
              onPageFinished: _handlePageFinished,
              onWebResourceError: (error) {
                if (error.isForMainFrame == true && mounted && !_closing) {
                  setState(() {
                    _loadError = 'The e-Likha page could not be loaded.';
                    _destinationReady = false;
                  });
                }
              },
            ),
          )
          ..addJavaScriptChannel(
            'ElikhaMobile',
            onMessageReceived: _handleMessage,
          )
          ..addJavaScriptChannel(
            'ElikhaDownload',
            onMessageReceived: _handleDownloadMessage,
          )
          ..loadRequest(_bootstrapUrl);
    _configurePlatformController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Supabase Flutter normally restarts its native refresh timer on resume.
    // Keep it paused while the hosted client owns refresh-token rotation.
    if (state == AppLifecycleState.resumed && !_closing) {
      Supabase.instance.client.auth.stopAutoRefresh();
      if (widget.immersive) {
        unawaited(_applyCameraExperienceDisplayMode());
      }
    }
  }

  void _configurePlatformController() {
    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      unawaited(
        platformController.setOnShowFileSelector(_selectFilesForWebView),
      );
    }
  }

  Future<List<String>> _selectFilesForWebView(FileSelectorParams params) async {
    if (_closing) return const [];
    final currentUrl = await _controller.currentUrl();
    final currentUri = currentUrl == null ? null : Uri.tryParse(currentUrl);
    if (currentUri == null || !isTrustedHostedWebUri(currentUri)) {
      return const [];
    }

    final filter = _filePickerFilter(params.acceptTypes);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: filter.type,
        allowedExtensions: filter.extensions,
      );
      if (result == null) return const [];

      return result.files
          .map((file) {
            final identifier = file.identifier?.trim();
            if (identifier != null && identifier.isNotEmpty) {
              return identifier;
            }
            final path = file.path?.trim();
            return path == null || path.isEmpty
                ? null
                : Uri.file(path).toString();
          })
          .whereType<String>()
          .toList(growable: false);
    } catch (_) {
      if (mounted && !_closing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The file picker could not be opened.')),
        );
      }
      return const [];
    }
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    final isCleanupNavigation =
        _closing && uri?.scheme == 'about' && uri?.path == 'blank';
    if ((uri != null && isTrustedHostedWebUri(uri)) || isCleanupNavigation) {
      return NavigationDecision.navigate;
    }

    if (mounted && !_closing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _closing) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A link outside e-Likha was blocked.')),
        );
      });
    }
    return NavigationDecision.prevent;
  }

  void _handleUrlChange(UrlChange change) {
    if (!_sessionSeeded || _closing) return;
    final uri = change.url == null ? null : Uri.tryParse(change.url!);
    if (uri != null && isTrustedHostedWebUri(uri) && uri.path == '/login') {
      _hostedAuthLost = true;
      unawaited(_close(false));
    }
  }

  Future<void> _handlePageFinished(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !isTrustedHostedWebUri(uri) || _closing) return;

    // Hosted logout clears its auth storage and redirects here. Close the
    // embedded portal immediately; the session snapshot in `_close` then
    // clears the native session as well instead of presenting a second login
    // screen inside an already authenticated mobile shell.
    if (_sessionSeeded && uri.path == '/login') {
      _hostedAuthLost = true;
      unawaited(_close(false));
      return;
    }

    if (!_sessionSeeded && !_isSeeding) {
      _isSeeding = true;
      try {
        final script = buildSupabaseSessionSeedScript(
          storageKey: widget.sessionSeed.storageKey,
          session: widget.sessionSeed.session,
        );
        await _controller.runJavaScript(script);
        _sessionSeeded = true;
        await _controller.loadRequest(widget.url);
      } catch (_) {
        if (mounted) {
          setState(() {
            _loadError = 'Your secure e-Likha session could not be opened.';
          });
        }
      } finally {
        _isSeeding = false;
      }
      return;
    }

    if (_sessionSeeded && mounted) {
      try {
        await _controller.runJavaScript(buildHostedWebDownloadBridgeScript());
      } catch (_) {
        // The page remains usable when its optional native download bridge is
        // unavailable. Report exports will show their existing web fallback.
      }
      if (!mounted || _closing) return;
      setState(() {
        _destinationReady = true;
        _loadError = null;
      });
    }
  }

  Future<void> _handlePermissionRequest(
    WebViewPermissionRequest request,
  ) async {
    final requestsOnlyCamera =
        request.types.isNotEmpty &&
        request.types.every(
          (type) => type.name == WebViewPermissionResourceType.camera.name,
        );
    final currentUrl = await _controller.currentUrl();
    final currentUri = currentUrl == null ? null : Uri.tryParse(currentUrl);
    final isTrustedPage =
        currentUri != null && isTrustedHostedWebUri(currentUri);

    if (widget.allowCamera && requestsOnlyCamera && isTrustedPage) {
      await request.grant();
    } else {
      await request.deny();
    }
  }

  void _handleMessage(JavaScriptMessage message) {
    try {
      final payload = jsonDecode(message.message);
      if (payload is Map && payload['type'] == 'submitted') {
        unawaited(_close(true));
      } else if (payload is Map && payload['type'] == 'exit') {
        unawaited(_close(false));
      }
    } catch (_) {
      // Ignore non-JSON messages from the trusted web application.
    }
  }

  void _handleDownloadMessage(JavaScriptMessage message) {
    if (_closing || !_destinationReady) return;

    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type']?.toString() ?? '';
      final id = decoded['id']?.toString() ?? '';
      if (!_isValidTransferId(id)) return;

      switch (type) {
        case 'start':
          final size = (decoded['size'] as num?)?.toInt() ?? -1;
          final name = _sanitizeReportFileName(decoded['name']?.toString());
          if (size < 0 || size > _maxDownloadBytes || name == null) {
            _pendingDownloads.remove(id);
            _showDownloadMessage(
              name == null
                  ? 'Only report files can be saved from this workspace.'
                  : 'This report is too large to save inside the app.',
            );
            return;
          }
          if (_pendingDownloads.length >= 2 &&
              !_pendingDownloads.containsKey(id)) {
            _showDownloadMessage(
              'Wait for the current report to finish first.',
            );
            return;
          }
          _pendingDownloads[id] = _PendingDownload(
            name: name,
            expectedSize: size,
          );
          break;
        case 'chunk':
          final pending = _pendingDownloads[id];
          final encoded = decoded['data'];
          if (pending == null || encoded is! String || encoded.length > 70000) {
            return;
          }
          final chunk = base64Decode(encoded);
          if (pending.receivedBytes + chunk.length > pending.expectedSize ||
              pending.receivedBytes + chunk.length > _maxDownloadBytes) {
            _pendingDownloads.remove(id);
            _showDownloadMessage(
              'The report download was incomplete. Try again.',
            );
            return;
          }
          pending.add(chunk);
          break;
        case 'end':
          final pending = _pendingDownloads.remove(id);
          if (pending == null) return;
          if (pending.receivedBytes != pending.expectedSize) {
            _showDownloadMessage(
              'The report download was incomplete. Try again.',
            );
            return;
          }
          unawaited(_saveReport(pending));
          break;
        case 'error':
          _pendingDownloads.remove(id);
          final detail = decoded['message']?.toString().trim() ?? '';
          _showDownloadMessage(
            detail.isEmpty || detail.length > 240
                ? 'The report could not be saved.'
                : detail,
          );
          break;
      }
    } catch (_) {
      // Ignore malformed messages from the hosted page.
    }
  }

  Future<void> _saveReport(_PendingDownload report) async {
    if (_saveDialogOpen || _closing) {
      _showDownloadMessage('Wait for the current report to finish first.');
      return;
    }
    _saveDialogOpen = true;
    try {
      final extension = report.name.split('.').last.toLowerCase();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save e-Likha report',
        fileName: report.name,
        bytes: report.takeBytes(),
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (savedPath != null && mounted && !_closing) {
        _showDownloadMessage('Report saved successfully.');
      }
    } catch (_) {
      _showDownloadMessage('The report could not be saved. Try again.');
    } finally {
      _saveDialogOpen = false;
    }
  }

  void _showDownloadMessage(String message) {
    if (!mounted || _closing) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _retry() async {
    if (_closing) return;
    setState(() {
      _loadError = null;
      _destinationReady = false;
      _isSeeding = false;
      _sessionSeeded = false;
      _progress = 0;
    });
    await _controller.loadRequest(_bootstrapUrl);
  }

  Future<void> _close(bool result) async {
    if (_closing) return;
    setState(() => _closing = true);
    final snapshot = await _captureHostedSessionAndStopMedia();
    try {
      await Future.wait<void>([
        _cleanup(),
        _synchronizeNativeSession(snapshot),
      ]).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Teardown is deliberately bounded. Best-effort work may finish after
      // the route has closed, but it must never trap the user in the WebView.
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<_HostedSessionSnapshot> _captureHostedSessionAndStopMedia() async {
    try {
      final value = await _controller
          .runJavaScriptReturningResult(
            buildHostedWebSessionSnapshotScript(widget.sessionSeed.storageKey),
          )
          .timeout(const Duration(seconds: 1));
      return _HostedSessionSnapshot(
        captured: true,
        session: decodeSupabaseSessionStorageValue(value),
      );
    } catch (_) {
      return const _HostedSessionSnapshot(captured: false, session: null);
    }
  }

  Future<void> _synchronizeNativeSession(
    _HostedSessionSnapshot snapshot,
  ) async {
    if (!_sessionSeeded) return;

    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;
    if (_hostedAuthLost) {
      await client.auth.signOut(scope: SignOutScope.local);
      return;
    }
    if (!snapshot.captured) return;

    final session = snapshot.session;
    if (session == null) {
      await client.auth.signOut(scope: SignOutScope.local);
      return;
    }

    final hostedUser = session['user'];
    final hostedUserId = hostedUser is Map
        ? hostedUser['id']?.toString() ?? ''
        : '';
    final accessToken = session['access_token']?.toString() ?? '';
    final refreshToken = session['refresh_token']?.toString() ?? '';
    if (hostedUserId != currentUserId ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      await client.auth.signOut(scope: SignOutScope.local);
      return;
    }

    try {
      final response = await client.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );
      if (response.session?.user.id != currentUserId) {
        await client.auth.signOut(scope: SignOutScope.local);
      }
    } catch (_) {
      // An offline validation failure leaves the existing native session in
      // place. Its normal refresh path will re-validate when connectivity
      // returns.
    }
  }

  Future<void> _cleanup() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    _pendingDownloads.clear();
    try {
      await _controller
          .runJavaScript(
            buildHostedWebCleanupScript(widget.sessionSeed.storageKey),
          )
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // The page may already have been disposed or failed before bootstrapping.
    }
    try {
      await _controller
          .loadRequest(Uri.parse('about:blank'))
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // Loading a blank page is best-effort during teardown.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cleanup());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close(false));
      },
      child: Scaffold(
        backgroundColor: widget.allowCamera ? Colors.black : Colors.white,
        appBar: widget.immersive ? null : AppBar(title: Text(widget.title)),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (!_destinationReady && _loadError == null)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_loadError != null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_destinationReady && _progress < 100)
              LinearProgressIndicator(value: _progress / 100),
          ],
        ),
      ),
    );
  }
}
