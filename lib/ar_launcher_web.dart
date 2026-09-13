// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'hosted_web_security.dart';

Future<bool> openHostedExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) async {
  if (!_validate(context, url)) return false;
  html.window.location.assign(url.toString());
  return false;
}

Future<bool> openHostedWebExperience(
  BuildContext context,
  Uri url, {
  String title = 'e-Likha',
}) {
  return openHostedExperience(context, url, title: title);
}

Future<bool> openArExperience(BuildContext context, Uri url) async {
  if (!_validate(context, url)) return false;

  // A top-level page is required for dependable web camera access. Keep only
  // the current page's origin and path as the return target; auth fragments or
  // other sensitive browser state are never copied into the AR URL.
  final current = Uri.tryParse(html.window.location.href);
  final safeReturnUrl = current == null
      ? trustedHostedWebBaseUri.toString()
      : current.replace(query: '', fragment: '').toString();
  final targetUrl = url.replace(
    queryParameters: <String, String>{
      ...url.queryParameters,
      'returnUrl': safeReturnUrl,
    },
  );
  html.window.location.assign(targetUrl.toString());
  return false;
}

bool _validate(BuildContext context, Uri url) {
  if (isTrustedHostedWebUri(url)) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked an untrusted e-Likha link.')),
    );
  }
  return false;
}
