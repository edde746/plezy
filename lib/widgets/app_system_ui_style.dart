import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app-wide system status bar style, declared once at the root.
///
/// Flutter restyles the status bar only when a frame paints a
/// [SystemUiOverlayStyle] region under it, and an [AppBar] is the only widget
/// in the app that paints one. Without this, a screen with no app bar under the
/// status bar (Discover, sign-in, Search) kept whatever the last app bar sent —
/// or, on a fresh Android 14-or-older activity, the embedding's 25% black bar
/// (#2934).
///
/// App bars still win where they reach the status bar: Flutter applies the
/// innermost region under it. The style equals the one a Material 3 [AppBar]
/// on the scaffold background derives, so moving between screens with and
/// without one sends nothing. Like an [AppBar]'s, it leaves the navigation bar
/// alone.
class AppSystemUiStyle extends StatelessWidget {
  const AppSystemUiStyle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final background = ThemeData.estimateBrightnessForColor(Theme.of(context).scaffoldBackgroundColor);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        // iOS reads the brightness behind the bar, Android the icon brightness.
        statusBarBrightness: background,
        statusBarIconBrightness: background == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
