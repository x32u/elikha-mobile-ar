import 'package:elikha_mobile/hosted_web_security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trusted hosted web URLs', () {
    test('accepts routes on the configured e-Likha origin', () {
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(
            path: '/mobile/activity/abc/start',
            queryParameters: const <String, String>{'mobile': '1'},
          ),
        ),
        isTrue,
      );
    });

    test('rejects lookalike origins and non-TLS URLs', () {
      expect(
        isTrustedHostedWebUri(
          Uri.parse(
            '${trustedHostedWebBaseUri.scheme}://${trustedHostedWebBaseUri.host}.attacker.example/student',
          ),
        ),
        isFalse,
      );
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(scheme: 'http', path: '/student'),
        ),
        isFalse,
      );
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(port: 444, path: '/student'),
        ),
        isFalse,
      );
    });

    test('rejects credentials in query parameters', () {
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(
            path: '/student',
            queryParameters: const <String, String>{'access_token': 'secret'},
          ),
        ),
        isFalse,
      );
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(
            path: '/student',
            queryParameters: const <String, String>{'refresh_token': 'secret'},
          ),
        ),
        isFalse,
      );
      expect(
        isTrustedHostedWebUri(
          trustedHostedWebBaseUri.replace(
            path: '/student',
            fragment: 'access_token=secret',
          ),
        ),
        isFalse,
      );
    });
  });

  test('derives the supabase-js auth storage key', () {
    expect(
      supabaseWebAuthStorageKey('https://qoixmfuxinmbtwfrhles.supabase.co'),
      'sb-qoixmfuxinmbtwfrhles-auth-token',
    );
  });

  test('session seed uses local storage instead of URL state', () {
    final script = buildSupabaseSessionSeedScript(
      storageKey: 'sb-project-auth-token',
      session: const <String, dynamic>{
        'access_token': 'access-value',
        'refresh_token': 'refresh-value',
      },
    );

    expect(script, contains('window.localStorage.setItem'));
    expect(script, isNot(contains('location.')));
    expect(script, isNot(contains('URLSearchParams')));
  });

  test('close snapshot stops media before returning hosted auth state', () {
    final script = buildHostedWebSessionSnapshotScript('sb-project-auth-token');

    expect(script, contains('window.localStorage.getItem'));
    expect(script, contains('getTracks'));
    expect(script, contains('track.stop()'));
    expect(script, isNot(contains('removeItem')));
  });

  test('download bridge chunks Blob reports without exposing auth', () {
    final script = buildHostedWebDownloadBridgeScript();

    expect(script, contains('ElikhaDownload'));
    expect(script, contains("target.closest('a[download]')"));
    expect(script, contains("type: 'chunk'"));
    expect(script, contains('MAX_BYTES'));
    expect(script, isNot(contains('auth-token')));
  });

  test('decodes raw and WebView-quoted Supabase session values', () {
    const raw =
        '{"access_token":"access","refresh_token":"refresh","expires_at":1}';

    expect(decodeSupabaseSessionStorageValue(raw)?['refresh_token'], 'refresh');
    expect(
      decodeSupabaseSessionStorageValue(
        '"${raw.replaceAll('"', '\\"')}"',
      )?['access_token'],
      'access',
    );
    expect(decodeSupabaseSessionStorageValue('not json'), isNull);
  });
}
