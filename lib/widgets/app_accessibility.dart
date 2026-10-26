import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/mono_theme.dart';
import '../theme/mono_tokens.dart';
import 'settings_builder.dart';

/// Adds the user's preferences to platform accessibility settings. Never turns
/// off an operating-system accommodation or flattens nonlinear text scaling.
class AppAccessibility extends StatelessWidget {
  const AppAccessibility({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SettingsBuilder(
    prefs: const [
      SettingsService.accessibilityTextScale,
      SettingsService.reduceMotion,
      SettingsService.highContrast,
      SettingsService.boldInterfaceText,
      SettingsService.largeTouchTargets,
    ],
    builder: (context) {
      final settings = SettingsService.instance, media = MediaQuery.of(context);
      final motion = media.disableAnimations || settings.read(SettingsService.reduceMotion);
      final contrast = media.highContrast || settings.read(SettingsService.highContrast);
      final bold = media.boldText || settings.read(SettingsService.boldInterfaceText);
      final targets = media.accessibleNavigation || settings.read(SettingsService.largeTouchTargets);
      var theme = Theme.of(context);
      if (contrast) {
        final dark = theme.brightness == Brightness.dark;
        final background = dark ? Colors.black : Colors.white, foreground = dark ? Colors.white : Colors.black;
        theme = monoTheme(
          MonoPalette(
            bg: background,
            surface: background,
            outline: foreground,
            text: foreground,
            textMuted: foreground,
            accent: foreground,
          ),
        );
      }
      final token = theme.extension<MonoTokens>();
      theme = theme.copyWith(
        visualDensity: targets ? VisualDensity.standard : theme.visualDensity,
        materialTapTargetSize: targets ? MaterialTapTargetSize.padded : theme.materialTapTargetSize,
        iconButtonTheme: targets
            ? IconButtonThemeData(
                style:
                    theme.iconButtonTheme.style?.copyWith(minimumSize: const WidgetStatePropertyAll(Size(48, 48))) ??
                    const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
              )
            : theme.iconButtonTheme,
        textTheme: bold ? _boldTheme(theme.textTheme) : theme.textTheme,
        pageTransitionsTheme: motion
            ? PageTransitionsTheme(
                builders: {for (final platform in TargetPlatform.values) platform: const _StillPageTransition()},
              )
            : theme.pageTransitionsTheme,
        extensions: [
          for (final ext in theme.extensions.values)
            if (ext is! MonoTokens) ext,
          if (token != null)
            motion
                ? token.copyWith(
                    fast: Duration.zero,
                    normal: Duration.zero,
                    slow: Duration.zero,
                    expressive: Duration.zero,
                  )
                : token,
        ],
      );
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: motion,
          highContrast: contrast,
          boldText: bold,
          textScaler: MultipliedTextScaler(media.textScaler, settings.read(SettingsService.accessibilityTextScale)),
        ),
        child: Theme(data: theme, child: child),
      );
    },
  );
}

class MultipliedTextScaler extends TextScaler {
  const MultipliedTextScaler(this.base, this.factor);
  final TextScaler base;
  final double factor;
  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
  @override
  bool operator ==(Object other) => other is MultipliedTextScaler && other.base == base && other.factor == factor;
  @override
  int get hashCode => Object.hash(base, factor);
}

class _StillPageTransition extends PageTransitionsBuilder {
  const _StillPageTransition();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

TextTheme _boldTheme(TextTheme theme) => theme.copyWith(
  displayLarge: theme.displayLarge
      ?.copyWith(fontWeight: theme.displayLarge?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  displayMedium: theme.displayMedium
      ?.copyWith(fontWeight: theme.displayMedium?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  displaySmall: theme.displaySmall
      ?.copyWith(fontWeight: theme.displaySmall?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  headlineLarge: theme.headlineLarge
      ?.copyWith(fontWeight: theme.headlineLarge?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  headlineMedium: theme.headlineMedium
      ?.copyWith(fontWeight: theme.headlineMedium?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  headlineSmall: theme.headlineSmall
      ?.copyWith(fontWeight: theme.headlineSmall?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  titleLarge: theme.titleLarge
      ?.copyWith(fontWeight: theme.titleLarge?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  titleMedium: theme.titleMedium
      ?.copyWith(fontWeight: theme.titleMedium?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  titleSmall: theme.titleSmall
      ?.copyWith(fontWeight: theme.titleSmall?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  bodyLarge: theme.bodyLarge
      ?.copyWith(fontWeight: theme.bodyLarge?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  bodyMedium: theme.bodyMedium
      ?.copyWith(fontWeight: theme.bodyMedium?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  bodySmall: theme.bodySmall
      ?.copyWith(fontWeight: theme.bodySmall?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  labelLarge: theme.labelLarge
      ?.copyWith(fontWeight: theme.labelLarge?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  labelMedium: theme.labelMedium
      ?.copyWith(fontWeight: theme.labelMedium?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
  labelSmall: theme.labelSmall
      ?.copyWith(fontWeight: theme.labelSmall?.fontWeight ?? FontWeight.normal)
      .apply(fontWeightDelta: 2),
);
