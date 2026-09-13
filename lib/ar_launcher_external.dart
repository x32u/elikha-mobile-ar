import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'hosted_web_security.dart';

Future<bool> openHostedExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) {
  return _openExternal(context, url, title: title);
}

Future<bool> openHostedWebExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) {
  return openHostedExperience(context, url, title: title);
}

Future<bool> openArExperience(BuildContext context, Uri url) {
  return _openExternal(context, url, title: 'AR');
}

Future<bool> _openExternal(
  BuildContext context,
  Uri url, {
  required String title,
}) async {
  if (!isTrustedHostedWebUri(url)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocked an untrusted e-Likha link.')),
      );
    }
    return false;
  }

  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open $title right now.')));
  }
  return false;
}
