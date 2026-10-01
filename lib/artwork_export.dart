import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

const artworkMaxInputBytes = 20 * 1024 * 1024;
const artworkMaxPixels = 16 * 1024 * 1024;
const artworkMaxDimension = 8192;
const _artworkTypes = {'image/png', 'image/jpeg', 'image/webp'};

class ArtworkExportException implements Exception {
  const ArtworkExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Only raster artwork is supported. Scene JSON and activity cover images must
/// never be substituted by callers when a submission has no saved picture.
bool isSupportedArtworkImage(String source) {
  if (source.startsWith('data:')) {
    return RegExp(
      r'^data:image/(png|jpeg|webp);base64,',
      caseSensitive: false,
    ).hasMatch(source);
  }
  final uri = Uri.tryParse(source);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

String artworkPngFileName(String studentName, String activityTitle) {
  final stem = '$studentName-$activityTitle'
      .replaceAll(RegExp(r'[\x00-\x1f<>:"/\\|?*]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[.\s-]+|[.\s-]+$'), '');
  final safe = stem.isEmpty ? 'E-Likha-artwork' : stem;
  return '${safe.substring(0, safe.length.clamp(0, 110))}.png';
}

Future<Uint8List> loadArtworkImageBytes(
  String source, {
  http.Client? client,
}) async {
  if (!isSupportedArtworkImage(source)) {
    throw const ArtworkExportException(
      'This submission has no supported artwork picture.',
    );
  }
  if (source.startsWith('data:')) {
    final encoded = source.substring(source.indexOf(',') + 1);
    if (encoded.length > ((artworkMaxInputBytes + 2) ~/ 3) * 4) {
      throw const ArtworkExportException(
        'Artwork exceeds the 20 MB image limit.',
      );
    }
    try {
      final bytes = base64Decode(encoded);
      _checkByteLength(bytes);
      return bytes;
    } on FormatException {
      throw const ArtworkExportException(
        'The saved artwork picture is invalid.',
      );
    }
  }

  final transport = client ?? http.Client();
  try {
    // No authentication headers are sent to arbitrary image hosts. Redirects
    // are refused, including HTTPS-to-HTTP redirects.
    final request = http.Request('GET', Uri.parse(source))
      ..followRedirects = false;
    final response = await transport
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const ArtworkExportException(
        'Unable to download the artwork picture. Try again.',
      );
    }
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (!_artworkTypes.contains(contentType)) {
      throw const ArtworkExportException(
        'The saved file is not a PNG, JPEG, or WebP picture.',
      );
    }
    if ((response.contentLength ?? 0) > artworkMaxInputBytes) {
      throw const ArtworkExportException(
        'Artwork exceeds the 20 MB image limit.',
      );
    }
    final bytes = BytesBuilder(copy: false);
    await (() async {
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > artworkMaxInputBytes) {
          throw const ArtworkExportException(
            'Artwork exceeds the 20 MB image limit.',
          );
        }
        bytes.add(chunk);
      }
    })().timeout(const Duration(seconds: 30));
    final result = bytes.takeBytes();
    _checkByteLength(result);
    return result;
  } on TimeoutException {
    throw const ArtworkExportException(
      'Artwork download timed out. Check your connection and try again.',
    );
  } on ArtworkExportException {
    rethrow;
  } catch (_) {
    throw const ArtworkExportException(
      'Unable to download the artwork picture. Check your connection.',
    );
  } finally {
    if (client == null) transport.close();
  }
}

void _checkByteLength(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const ArtworkExportException('The saved artwork picture is empty.');
  }
  if (bytes.length > artworkMaxInputBytes) {
    throw const ArtworkExportException(
      'Artwork exceeds the 20 MB image limit.',
    );
  }
}

/// Inspect encoded dimensions before allocating a full pixel surface, then
/// decode and encode an actual PNG instead of just renaming the source file.
Future<Uint8List> artworkBytesToPng(Uint8List bytes, {int? targetWidth}) async {
  _checkByteLength(bytes);
  final isPng =
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a;
  final isJpeg =
      bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  final isWebp =
      bytes.length >= 12 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP';
  if (!isPng && !isJpeg && !isWebp) {
    throw const ArtworkExportException(
      'The saved file is not a PNG, JPEG, or WebP picture.',
    );
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width > artworkMaxDimension ||
        descriptor.height > artworkMaxDimension ||
        descriptor.width * descriptor.height > artworkMaxPixels) {
      throw const ArtworkExportException(
        'Artwork is too large to safely open on this device.',
      );
    }
    codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth?.clamp(1, descriptor.width),
    );
    image = (await codec.getNextFrame()).image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) {
      throw const ArtworkExportException('Unable to create the PNG picture.');
    }
    return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  } on ArtworkExportException {
    rethrow;
  } catch (_) {
    throw const ArtworkExportException(
      'The saved artwork picture could not be opened.',
    );
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

Future<Uint8List> loadArtworkPng(
  String source, {
  http.Client? client,
  int? targetWidth,
}) async => artworkBytesToPng(
  await loadArtworkImageBytes(source, client: client),
  targetWidth: targetWidth,
);
