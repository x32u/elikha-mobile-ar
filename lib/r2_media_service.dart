import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const r2MediaApiBase = String.fromEnvironment(
  'ELIKHA_MODEL_API_URL',
  defaultValue: 'https://elikha-r2-models.elikha-r2-models-worker.workers.dev',
);

const r2MediaMaxUploadBytes = 20 * 1024 * 1024;
const r2MediaAcceptedTypes = <String>{'image/png', 'image/jpeg', 'image/webp'};

enum R2MediaKind {
  avatars('avatars'),
  classes('classes');

  const R2MediaKind(this.path);
  final String path;
}

class R2MediaException implements Exception {
  const R2MediaException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class R2MediaService {
  R2MediaService._();

  static final Map<String, Uint8List?> _cache = {};
  static final Map<String, int> _revisions = {};
  static const int _maxCacheBytes = 32 * 1024 * 1024;
  static int _cacheBytes = 0;

  static Future<String> _accessToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken.trim() ?? '';
    if (token.isEmpty) {
      throw const R2MediaException('Your session has expired. Sign in again.');
    }
    return token;
  }

  static Uri _endpoint(R2MediaKind kind, String ownerId) {
    final id = ownerId.trim();
    if (id.isEmpty) {
      throw const R2MediaException('An image owner is required.');
    }
    final base = r2MediaApiBase.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const R2MediaException(
        'Cloudflare R2 image storage is not configured for this build.',
      );
    }
    final endpoint = Uri.parse(
      '$base/media/${kind.path}/${Uri.encodeComponent(id)}',
    );
    final isLocal =
        endpoint.host == 'localhost' ||
        endpoint.host == '127.0.0.1' ||
        endpoint.host == '::1';
    if (endpoint.scheme != 'https' && !(isLocal && endpoint.scheme == 'http')) {
      throw const R2MediaException(
        'Cloudflare R2 image storage must use a secure HTTPS endpoint.',
      );
    }
    return endpoint;
  }

  static String _cacheKey(R2MediaKind kind, String ownerId) =>
      '${kind.path}/${ownerId.trim()}';

  static Future<Uint8List?> load(
    R2MediaKind kind,
    String ownerId, {
    String legacyPath = '',
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(kind, ownerId);
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && cached.isNotEmpty) return cached;
      // Older hot-reloaded builds could retain a cached null after a temporary
      // 404. Never let that stale fallback suppress a later successful read.
      _removeCached(key);
    }

    final headers = <String, String>{
      'Authorization': 'Bearer ${await _accessToken()}',
      if (legacyPath.trim().isNotEmpty) 'X-Legacy-Path': legacyPath.trim(),
    };
    final response = await http
        .get(_endpoint(kind, ownerId), headers: headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw R2MediaException(
        _errorMessage(response, 'Unable to load this image.'),
        statusCode: response.statusCode,
      );
    }
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (!contentType.startsWith('image/')) {
      throw const R2MediaException('The stored file is not a supported image.');
    }
    final bytes = response.bodyBytes;
    _putCache(key, bytes);
    return bytes;
  }

  static Future<String> upload(
    R2MediaKind kind,
    String ownerId,
    Uint8List bytes,
    String contentType,
  ) async {
    final normalizedType = contentType.split(';').first.trim().toLowerCase();
    if (!r2MediaAcceptedTypes.contains(normalizedType)) {
      throw const R2MediaException('Use a PNG, JPG, or WebP image.');
    }
    if (bytes.isEmpty) {
      throw const R2MediaException('Choose an image to upload.');
    }
    if (bytes.length > r2MediaMaxUploadBytes) {
      throw const R2MediaException(
        'Image is too large. Maximum size is 20 MB.',
      );
    }

    final request = http.Request('PUT', _endpoint(kind, ownerId))
      ..headers.addAll({
        'Authorization': 'Bearer ${await _accessToken()}',
        'Content-Type': normalizedType,
      })
      ..bodyBytes = bytes;
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw R2MediaException(
        _errorMessage(response, 'Unable to upload this image.'),
        statusCode: response.statusCode,
      );
    }
    final key = _cacheKey(kind, ownerId);
    _putCache(key, bytes);
    _revisions[key] = (_revisions[key] ?? 0) + 1;
    return 'r2-media/${kind.path}/${ownerId.trim()}';
  }

  static Future<void> delete(R2MediaKind kind, String ownerId) async {
    final response = await http
        .delete(
          _endpoint(kind, ownerId),
          headers: {'Authorization': 'Bearer ${await _accessToken()}'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw R2MediaException(
        _errorMessage(response, 'Unable to remove this image.'),
        statusCode: response.statusCode,
      );
    }
    final key = _cacheKey(kind, ownerId);
    _removeCached(key);
    _revisions[key] = (_revisions[key] ?? 0) + 1;
  }

  static void invalidate(R2MediaKind kind, String ownerId) {
    final key = _cacheKey(kind, ownerId);
    _removeCached(key);
    _revisions[key] = (_revisions[key] ?? 0) + 1;
  }

  static int revision(R2MediaKind kind, String ownerId) =>
      _revisions[_cacheKey(kind, ownerId)] ?? 0;

  static void _putCache(String key, Uint8List bytes) {
    _removeCached(key);
    while (_cache.isNotEmpty && _cacheBytes + bytes.length > _maxCacheBytes) {
      _removeCached(_cache.keys.first);
    }
    if (bytes.length <= _maxCacheBytes) {
      _cache[key] = bytes;
      _cacheBytes += bytes.length;
    }
  }

  static void _removeCached(String key) {
    final previous = _cache.remove(key);
    if (previous != null) _cacheBytes -= previous.length;
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        final message = (decoded['error'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {
      // The status-aware fallback is clearer than leaking a non-JSON body.
    }
    return '$fallback (Cloudflare returned ${response.statusCode}.)';
  }
}
