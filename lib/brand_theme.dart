import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared logo-led colors for the native E-Likha interface.
/// Learner paint colors and semantic errors are separate from these UI tokens.
abstract final class ElikhaBrand {
  static const primary = Color(0xFF1800AD);
  static const secondary = Color(0xFF38B6FF);
  static const ink = Colors.black;
  static const surface = Colors.white;
  static const background = Colors.white;
  static const muted = Color(0x99000000);
  static const border = Color(0x1F000000);
  static const softBlue = Color(0xFFF0F9FF);
  static const primaryTint = Color(0xFFF0EDFF);
  static const disabled = Color(0x61000000);

  static ThemeData materialTheme() {
    final base = FlexColorScheme.light(
      colors: FlexSchemeColor.from(primary: primary, secondary: secondary),
      surface: surface,
      scaffoldBackground: background,
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 10,
        inputDecoratorRadius: 10,
        navigationBarIndicatorSchemeColor: SchemeColor.primary,
      ),
    ).toTheme;
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: ink, displayColor: ink);
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      disabledColor: disabled,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        onPrimary: surface,
        primaryContainer: primaryTint,
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: ink,
        secondaryContainer: softBlue,
        onSecondaryContainer: ink,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        surfaceTint: surface,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: surface,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: primary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? surface : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected) ? primary : muted,
          );
        }),
      ),
      navigationDrawerTheme: base.navigationDrawerTheme.copyWith(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: primary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? surface : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelLarge!.copyWith(
            color: states.contains(WidgetState.selected) ? surface : ink,
          );
        }),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: surface),
        actionTextColor: secondary,
      ),
    );
  }

  static ShadThemeData shadTheme() => ShadThemeData(
    brightness: Brightness.light,
    colorScheme: const ShadZincColorScheme.light(
      background: background,
      foreground: ink,
      card: surface,
      cardForeground: ink,
      popover: surface,
      popoverForeground: ink,
      primary: primary,
      primaryForeground: surface,
      secondary: secondary,
      secondaryForeground: ink,
      muted: softBlue,
      mutedForeground: muted,
      accent: primary,
      accentForeground: surface,
      border: border,
      input: border,
      ring: primary,
      selection: secondary,
    ),
    radius: const BorderRadius.all(Radius.circular(10)),
    textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
  );
}
