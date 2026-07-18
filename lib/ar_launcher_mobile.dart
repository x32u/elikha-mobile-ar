import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<bool> openArExperience(BuildContext context, Uri url) async {
  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (!isMobile) {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open AR: $url')));
    }
    return false;
  }

  final hasCameraPermission = await _ensureCameraPermission(context);
  if (!hasCameraPermission) return false;
  if (!context.mounted) return false;

  final submitted = await Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (_) => _ArWebViewPage(url: url)));
  return submitted ?? false;
}

Future<bool> _ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.request();
  if (status.isGranted) return true;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission is required for AR.')),
    );
  }
  return false;
}

class _ArWebViewPage extends StatefulWidget {
  const _ArWebViewPage({required this.url});

  final Uri url;

  @override
  State<_ArWebViewPage> createState() => _ArWebViewPageState();
}

class _ArWebViewPageState extends State<_ArWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool get _isVrMode => widget.url.queryParameters['vr'] == '1';

  @override
  void initState() {
    super.initState();
    if (_isVrMode) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _controller =
        WebViewController(onPermissionRequest: (request) => request.grant())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) => setState(() => _progress = progress),
            ),
          )
          ..addJavaScriptChannel(
            'ElikhaMobile',
            onMessageReceived: _handleMessage,
          )
          ..loadRequest(widget.url);
  }

  @override
  void dispose() {
    if (_isVrMode) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _handleMessage(JavaScriptMessage message) {
    try {
      final payload = jsonDecode(message.message);
      if (payload is Map && payload['type'] == 'submitted') {
        if (mounted) Navigator.of(context).pop(true);
      } else if (payload is Map && payload['type'] == 'exit') {
        if (mounted) Navigator.of(context).pop(false);
      }
    } catch (_) {
      // Ignore non-JSON messages from the web app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isVrMode ? null : AppBar(title: const Text('AR Project')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
        ],
      ),
    );
  }
}
