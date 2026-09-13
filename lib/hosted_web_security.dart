import 'dart:convert';

/// The only web origin that the native shell is allowed to embed.
///
/// Release builds use the production site by default. A reviewed preview can
/// be selected with `--dart-define=ELIKHA_WEB_URL=https://preview.example`.
const String trustedHostedWebOrigin = String.fromEnvironment(
  'ELIKHA_WEB_URL',
  defaultValue: 'https://elikhaweb.vercel.app',
);

/// Parses and validates the configured e-Likha web origin.
///
/// Only an HTTPS origin is accepted. Paths, credentials, query parameters,
/// and fragments belong to individual routes and are deliberately forbidden
/// in the build-time origin setting.
Uri get trustedHostedWebBaseUri {
  final uri = Uri.tryParse(trustedHostedWebOrigin.trim());
  final hasOnlyOriginPath =
      uri != null &&
      (uri.path.isEmpty || uri.path == '/') &&
      uri.query.isEmpty &&
      uri.fragment.isEmpty;
  if (uri == null ||
      !uri.isAbsolute ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      !hasOnlyOriginPath) {
    throw const FormatException(
      'ELIKHA_WEB_URL must be a complete HTTPS origin without a path.',
    );
  }

  return uri.replace(path: '', query: null, fragment: null);
}

const Set<String> _sensitiveQueryParameterNames = <String>{
  'accesstoken',
  'authorization',
  'apikey',
  'codeverifier',
  'refreshtoken',
  'session',
  'token',
};

/// Returns whether [uri] belongs to the configured e-Likha web application.
///
/// Authentication credentials are deliberately rejected in the query string.
/// Native-to-web authentication is transferred through same-origin storage.
bool isTrustedHostedWebUri(Uri uri) {
  late final Uri trusted;
  try {
    trusted = trustedHostedWebBaseUri;
  } on FormatException {
    return false;
  }
  if (uri.scheme.toLowerCase() != trusted.scheme.toLowerCase() ||
      uri.host.toLowerCase() != trusted.host.toLowerCase() ||
      uri.port != trusted.port ||
      uri.userInfo.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    return false;
  }

  return !uri.queryParameters.keys.any(
    (key) => _sensitiveQueryParameterNames.contains(
      key.toLowerCase().replaceAll(RegExp(r'[-_]'), ''),
    ),
  );
}

/// Derives the storage key used by supabase-js for an official project URL.
String supabaseWebAuthStorageKey(String supabaseUrl) {
  final uri = Uri.tryParse(supabaseUrl);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      !uri.host.toLowerCase().endsWith('.supabase.co')) {
    throw const FormatException('Unsupported Supabase project URL.');
  }

  final projectRef = uri.host.split('.').first.toLowerCase();
  if (!RegExp(r'^[a-z0-9]+$').hasMatch(projectRef)) {
    throw const FormatException('Invalid Supabase project reference.');
  }
  return 'sb-$projectRef-auth-token';
}

/// Creates the small bootstrap script that seeds supabase-js local storage.
///
/// The value is JSON encoded twice: once as the Supabase session JSON and once
/// as a safe JavaScript string literal. Tokens never become part of a URL.
String buildSupabaseSessionSeedScript({
  required String storageKey,
  required Map<String, dynamic> session,
}) {
  final encodedKey = jsonEncode(storageKey);
  final encodedValue = jsonEncode(jsonEncode(session));
  return '''
(() => {
  'use strict';
  window.localStorage.setItem($encodedKey, $encodedValue);
  return true;
})();
''';
}

/// Removes the temporary web auth copy and releases browser-owned resources.
String buildHostedWebCleanupScript(String storageKey) {
  final encodedKey = jsonEncode(storageKey);
  return '''
(() => {
  'use strict';
  try {
    document.querySelectorAll('video, audio').forEach((element) => {
      const stream = element.srcObject;
      if (stream && typeof stream.getTracks === 'function') {
        stream.getTracks().forEach((track) => track.stop());
      }
      element.srcObject = null;
    });
  } catch (_) {}
  try {
    if ('speechSynthesis' in window) window.speechSynthesis.cancel();
  } catch (_) {}
  try {
    window.localStorage.removeItem($encodedKey);
  } catch (_) {}
  return true;
})();
''';
}

/// Reads the hosted Supabase session while immediately releasing camera/audio.
///
/// This is used before any native network synchronization so pressing Back
/// never leaves the camera running while the app waits for a request.
String buildHostedWebSessionSnapshotScript(String storageKey) {
  final encodedKey = jsonEncode(storageKey);
  return '''
(() => {
  'use strict';
  let session = '';
  try {
    session = window.localStorage.getItem($encodedKey) || '';
  } catch (_) {}
  try {
    document.querySelectorAll('video, audio').forEach((element) => {
      const stream = element.srcObject;
      if (stream && typeof stream.getTracks === 'function') {
        stream.getTracks().forEach((track) => track.stop());
      }
      element.srcObject = null;
    });
  } catch (_) {}
  try {
    if ('speechSynthesis' in window) window.speechSynthesis.cancel();
  } catch (_) {}
  return session;
})();
''';
}

/// Installs a same-origin download bridge for reports generated as Blob URLs.
///
/// Android WebView does not save `blob:` downloads itself. The bridge streams
/// modest report files to native code in bounded chunks, where the system save
/// picker handles the final destination. It is idempotent across SPA routes.
String buildHostedWebDownloadBridgeScript() {
  return r'''
(() => {
  'use strict';
  const channel = window.ElikhaDownload;
  if (!channel || typeof channel.postMessage !== 'function') return false;
  if (window.__elikhaNativeDownloadBridgeInstalled) return true;
  window.__elikhaNativeDownloadBridgeInstalled = true;

  const MAX_BYTES = 25 * 1024 * 1024;
  const CHUNK_BYTES = 48 * 1024;
  const post = (payload) => channel.postMessage(JSON.stringify(payload));
  const toBase64 = (bytes) => {
    let binary = '';
    for (let offset = 0; offset < bytes.length; offset += 0x8000) {
      binary += String.fromCharCode.apply(
        null,
        bytes.subarray(offset, Math.min(offset + 0x8000, bytes.length))
      );
    }
    return window.btoa(binary);
  };

  const transfer = async (anchor) => {
    const id = `${Date.now()}-${Math.random().toString(36).slice(2, 12)}`;
    try {
      const response = await window.fetch(anchor.href);
      if (!response.ok && !anchor.href.startsWith('blob:')) {
        throw new Error('The report could not be downloaded.');
      }
      const blob = await response.blob();
      if (blob.size > MAX_BYTES) {
        throw new Error('This report is too large to save inside the mobile app.');
      }
      const name = String(anchor.download || 'elikha-report').slice(0, 180);
      post({ type: 'start', id, name, mime: blob.type || '', size: blob.size });
      const bytes = new Uint8Array(await blob.arrayBuffer());
      for (let offset = 0; offset < bytes.length; offset += CHUNK_BYTES) {
        post({
          type: 'chunk',
          id,
          data: toBase64(bytes.subarray(offset, offset + CHUNK_BYTES)),
        });
      }
      post({ type: 'end', id });
    } catch (error) {
      post({
        type: 'error',
        id,
        message: error && error.message
          ? String(error.message).slice(0, 240)
          : 'The report could not be saved.',
      });
    }
  };

  const originalClick = window.HTMLAnchorElement.prototype.click;
  window.HTMLAnchorElement.prototype.click = function nativeDownloadClick() {
    if (this.download && this.href) {
      void transfer(this);
      return;
    }
    return originalClick.call(this);
  };

  document.addEventListener('click', (event) => {
    const target = event.target;
    const anchor = target && typeof target.closest === 'function'
      ? target.closest('a[download]')
      : null;
    if (!anchor || !anchor.href) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    void transfer(anchor);
  }, true);

  return true;
})();
''';
}

/// Decodes a Supabase session read through `runJavaScriptReturningResult`.
///
/// Android and iOS WebViews may return either the stored JSON text directly or
/// a JSON-quoted version of that text. Decode at most twice and accept only a
/// JSON object so arbitrary JavaScript values cannot become native sessions.
Map<String, dynamic>? decodeSupabaseSessionStorageValue(Object? value) {
  Object? candidate = value;
  for (var attempt = 0; attempt < 2; attempt += 1) {
    if (candidate is Map) {
      return Map<String, dynamic>.from(candidate);
    }
    if (candidate is! String || candidate.trim().isEmpty) return null;
    try {
      candidate = jsonDecode(candidate);
    } catch (_) {
      return null;
    }
  }
  return candidate is Map ? Map<String, dynamic>.from(candidate) : null;
}
