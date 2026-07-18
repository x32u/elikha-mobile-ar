import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openArExperience(BuildContext context, Uri url) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open AR: $url')));
  }
  return false;
}
