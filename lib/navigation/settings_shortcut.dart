import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/settings/settings_screen.dart';
import '../utils/platform_detector.dart';
import '../utils/video_player_navigation.dart';

/// Route name of a pushed [SettingsScreen] — lets the settings keyboard
/// shortcut recognize settings already in the stack instead of stacking a
/// duplicate.
const String kSettingsRouteName = '/settings';

/// The route every settings push site uses, so a pushed settings screen is
/// identifiable by [kSettingsRouteName].
MaterialPageRoute<void> buildSettingsRoute() {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: kSettingsRouteName),
    builder: (_) => const SettingsScreen(),
  );
}

/// True when [event] is the desktop "open settings" chord — Cmd+, on macOS
/// (per the HIG, #1909) or Ctrl+, on Windows/Linux. Never matches on
/// non-desktop form factors: TVs and phones have no settings-shortcut
/// convention. Uses [defaultTargetPlatform] rather than `Platform.isMacOS`
/// so tests can exercise both chords from one host.
bool isSettingsShortcut(KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  if (event.logicalKey != LogicalKeyboardKey.comma) return false;
  if (!PlatformDetector.isDesktopOS() || PlatformDetector.isTV()) return false;

  final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
  final isControlPressed = HardwareKeyboard.instance.isControlPressed;
  return defaultTargetPlatform == TargetPlatform.macOS
      ? isMetaPressed && !isControlPressed
      : isControlPressed && !isMetaPressed;
}

/// Tracks whether a settings-named route is anywhere in a navigator's stack.
/// Registered as a navigator observer and consulted by [SettingsShortcut] so
/// the chord can never stack settings over settings, including while an
/// unnamed settings sub-page is on top of the settings route.
class SettingsRouteTracker extends NavigatorObserver {
  int _liveSettingsRoutes = 0;

  bool get hasSettingsRoute => _liveSettingsRoutes > 0;

  static bool _isSettings(Route<dynamic>? route) => route?.settings.name == kSettingsRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isSettings(route)) _liveSettingsRoutes++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isSettings(route)) _liveSettingsRoutes--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isSettings(route)) _liveSettingsRoutes--;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isSettings(oldRoute)) _liveSettingsRoutes--;
    if (_isSettings(newRoute)) _liveSettingsRoutes++;
  }
}

/// Session-wide handler for the settings keyboard shortcut.
///
/// Wraps the profile-session navigator so the chord works from any pushed
/// content route (detail pages, downloads, now playing). MainScreen carries
/// its own nearer handler that reuses its tab-aware open behavior; this
/// fallback only sees the chord while focus is in a route above MainScreen.
/// No-ops while a settings route is anywhere in the stack (a settings
/// sub-page may be on top of it) or the video player is current — the player
/// owns the keyboard.
class SettingsShortcut extends StatelessWidget {
  const SettingsShortcut({
    super.key,
    required this.navigatorKey,
    required this.settingsRoutes,
    this.routeBuilder = buildSettingsRoute,
    required this.child,
  });

  /// The profile-session navigator settings routes are pushed onto.
  final GlobalKey<NavigatorState> navigatorKey;

  /// The tracker registered in that navigator's observers.
  final SettingsRouteTracker settingsRoutes;

  /// Defaults to [buildSettingsRoute]; injectable so tests can push a
  /// stand-in page without the full settings provider graph.
  final Route<void> Function() routeBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (node, event) {
        if (!isSettingsShortcut(event)) return KeyEventResult.ignored;
        _openSettings();
        return KeyEventResult.handled;
      },
      child: child,
    );
  }

  void _openSettings() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (settingsRoutes.hasSettingsRoute) return;
    if (_isVideoPlayerOnTop(navigator)) return;

    navigator.push(routeBuilder());
  }

  static bool _isVideoPlayerOnTop(NavigatorState navigator) {
    var onTop = false;
    navigator.popUntil((route) {
      if (route.isCurrent) onTop = route.settings.name == kVideoPlayerRouteName;
      return true; // inspect only — never pops
    });
    return onTop;
  }
}
