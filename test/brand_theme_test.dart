import 'dart:math' as math;

import 'package:elikha_mobile/brand_theme.dart';
import 'package:elikha_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // These are color/theme tests, not font-rendering tests. Provide a local
    // font fixture for every Inter weight so theme construction stays offline.
    final fontFixture = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    final logoFixture = await rootBundle.load(
      'assets/images/elikhalogolarge.png',
    );
    final originalManifest =
        const StandardMessageCodec().decodeMessage(
              await rootBundle.load('AssetManifest.bin'),
            )
            as Map;
    final fontPaths = [
      for (final weight in const [
        'Thin',
        'ExtraLight',
        'Light',
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
        'Black',
      ])
        'test-fonts/Inter-$weight.ttf',
    ];
    final manifest = <String, Object>{
      for (final entry in originalManifest.entries)
        entry.key as String: entry.value as Object,
      for (final path in fontPaths)
        path: [
          {'asset': path},
        ],
    };
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final path = const StringCodec().decodeMessage(message);
      if (path == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(manifest);
      }
      if (fontPaths.contains(path)) return fontFixture;
      if (path == 'assets/images/elikhalogolarge.png') return logoFixture;
      return null;
    });
  });

  tearDownAll(() async {
    await GoogleFonts.pendingFonts();
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
  });

  test('logo palette and neutral support tokens are exact', () {
    expect(ElikhaBrand.primary, const Color(0xFF1800AD));
    expect(ElikhaBrand.secondary, const Color(0xFF38B6FF));
    expect(ElikhaBrand.ink, Colors.black);
    expect(ElikhaBrand.surface, Colors.white);
    expect(ElikhaBrand.background, Colors.white);
    expect(ElikhaBrand.muted, const Color(0x99000000));
    expect(ElikhaBrand.border, const Color(0x1F000000));
    expect(ElikhaBrand.disabled, const Color(0x61000000));
    expect(ElikhaBrand.softBlue, const Color(0xFFF0F9FF));
    expect(ElikhaBrand.primaryTint, const Color(0xFFF0EDFF));
  });

  test('Material roles use logo colors and readable foregrounds', () async {
    final theme = ElikhaBrand.materialTheme();
    await GoogleFonts.pendingFonts();
    expect(theme.colorScheme.primary, ElikhaBrand.primary);
    expect(theme.colorScheme.onPrimary, Colors.white);
    expect(theme.colorScheme.secondary, ElikhaBrand.secondary);
    expect(theme.colorScheme.onSecondary, Colors.black);
    expect(theme.colorScheme.surface, Colors.white);
    expect(theme.colorScheme.onSurface, Colors.black);
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.textTheme.bodyMedium?.color, Colors.black);
    expect(theme.textTheme.headlineLarge?.color, Colors.black);
    expect(theme.dividerTheme.color, ElikhaBrand.border);
    expect(theme.appBarTheme.foregroundColor, Colors.black);
    expect(theme.snackBarTheme.backgroundColor, Colors.black);
    expect(theme.snackBarTheme.contentTextStyle?.color, Colors.white);
  });

  test('active navigation is white on deep blue', () async {
    final theme = ElikhaBrand.materialTheme();
    await GoogleFonts.pendingFonts();
    const selected = {WidgetState.selected};
    const unselected = <WidgetState>{};
    final bar = theme.navigationBarTheme;
    expect(bar.indicatorColor, ElikhaBrand.primary);
    expect(bar.iconTheme?.resolve(selected)?.color, Colors.white);
    expect(bar.iconTheme?.resolve(unselected)?.color, ElikhaBrand.muted);
    expect(bar.labelTextStyle?.resolve(selected)?.color, ElikhaBrand.primary);
    expect(bar.labelTextStyle?.resolve(unselected)?.color, ElikhaBrand.muted);
    final drawer = theme.navigationDrawerTheme;
    expect(drawer.indicatorColor, ElikhaBrand.primary);
    expect(drawer.iconTheme?.resolve(selected)?.color, Colors.white);
    expect(drawer.labelTextStyle?.resolve(selected)?.color, Colors.white);
    expect(drawer.labelTextStyle?.resolve(unselected)?.color, Colors.black);
  });

  test('Shad components share the same logo palette', () async {
    final theme = ElikhaBrand.shadTheme();
    await GoogleFonts.pendingFonts();
    final colors = theme.colorScheme;
    expect(colors.primary, ElikhaBrand.primary);
    expect(colors.primaryForeground, Colors.white);
    expect(colors.secondary, ElikhaBrand.secondary);
    expect(colors.secondaryForeground, Colors.black);
    expect(colors.background, Colors.white);
    expect(colors.foreground, Colors.black);
    expect(colors.card, Colors.white);
    expect(colors.cardForeground, Colors.black);
    expect(colors.popover, Colors.white);
    expect(colors.popoverForeground, Colors.black);
    expect(colors.ring, ElikhaBrand.primary);
    expect(colors.border, ElikhaBrand.border);
  });

  test('primary and secondary text meet WCAG normal-text contrast', () {
    expect(
      _contrast(ElikhaBrand.primary, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(ElikhaBrand.secondary, Colors.black),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('Material primary button and navigation render brand states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ElikhaBrand.materialTheme(),
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                label: 'Activities',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final buttonMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(buttonMaterial.color, ElikhaBrand.primary);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Continue'))).style.color,
      Colors.white,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.home_rounded))).color,
      Colors.white,
    );
    expect(
      IconTheme.of(
        tester.element(find.byIcon(Icons.assignment_outlined)),
      ).color,
      ElikhaBrand.muted,
    );
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    Size(320, 568),
    Size(768, 1024),
    Size(844, 390),
  ]) {
    testWidgets('login remains usable at $viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: ElikhaBrand.materialTheme(),
          home: LoginScreen(onSignedIn: () {}, onForgotPassword: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style?.backgroundColor?.resolve(const {}),
        ElikhaBrand.primary,
      );
      expect(button.style?.foregroundColor?.resolve(const {}), Colors.white);
      await tester.ensureVisible(find.text('Forgot password?'));
      expect(tester.takeException(), isNull);
    });
  }
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  return (math.max(firstLuminance, secondLuminance) + .05) /
      (math.min(firstLuminance, secondLuminance) + .05);
}
