// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<bool> openArExperience(BuildContext context, Uri url) async {
  // Flutter Web cannot reliably run camera APIs inside a cross-origin iframe.
  // Navigate the current tab so the hosted AR page becomes the top-level origin.
  final returnUrl = html.window.location.href;
  final targetUrl = url.replace(
    queryParameters: {
      ...url.queryParameters,
      'returnUrl': returnUrl,
    },
  );
  html.window.location.assign(targetUrl.toString());
  return false;
}
