import 'package:flutter/material.dart';

/// Dependency aspects for [MainScreenFocusScope].
///
/// The scope is an [InheritedModel] so the per-sidebar-flip values (`offset`)
/// only rebuild the few widgets that position against them — depending on the
/// whole scope from a screen's top-level build makes the entire screen rebuild
/// on every sidebar focus flip (measured 150-330ms frames on low-end TVs).
enum MainScreenScopeAspect {
  /// `foregroundLeft` / `sideNavigationWidth` — change when the sidebar
  /// expands or collapses. Depend on these only from small positioning
  /// widgets (e.g. [SideNavigationBleedBuilder] call sites).
  offset,

  /// `isSidebarFocused`.
  focus,

  /// `foregroundWidth` / `viewportWidth` / `reservedSideNavigationWidth` —
  /// stable across sidebar flips (only change with window geometry).
  layout,
}

class MainScreenFocusScope extends InheritedModel<MainScreenScopeAspect> {
  final VoidCallback focusSidebar;
  final VoidCallback focusContent;
  final bool isSidebarFocused;
  final double sideNavigationWidth;
  final double? reservedSideNavigationWidth;
  final double? foregroundLeft;
  final double? foregroundWidth;
  final double? viewportWidth;
  final void Function(String libraryGlobalKey)? selectLibrary;
  final VoidCallback? openSettings;

  const MainScreenFocusScope({
    super.key,
    required this.focusSidebar,
    required this.focusContent,
    required this.isSidebarFocused,
    required this.sideNavigationWidth,
    this.reservedSideNavigationWidth,
    this.foregroundLeft,
    this.foregroundWidth,
    this.viewportWidth,
    this.selectLibrary,
    this.openSettings,
    required super.child,
  });

  /// Whole-scope access. With `listen: true` this registers an aspect-less
  /// dependency (notified on ANY scope change) — use the aspect-scoped static
  /// getters instead wherever possible. Callback access (focusSidebar etc.)
  /// should always pass `listen: false`.
  static MainScreenFocusScope? of(BuildContext context, {bool listen = true}) {
    if (listen) return context.dependOnInheritedWidgetOfExactType<MainScreenFocusScope>();
    return context.getElementForInheritedWidgetOfExactType<MainScreenFocusScope>()?.widget as MainScreenFocusScope?;
  }

  /// Focuses the sidebar without registering an inherited dependency.
  static void focusSidebarOf(BuildContext context) {
    of(context, listen: false)?.focusSidebar();
  }

  static MainScreenFocusScope? _dependOn(BuildContext context, MainScreenScopeAspect aspect) {
    return InheritedModel.inheritFrom<MainScreenFocusScope>(context, aspect: aspect);
  }

  /// Sidebar bleed target (== content offset). Changes per sidebar flip —
  /// depend on it only from small positioning builders.
  static double sideNavigationBleedOf(BuildContext context) {
    return _dependOn(context, MainScreenScopeAspect.offset)?.sideNavigationWidth ?? 0.0;
  }

  /// Content box left edge. Changes per sidebar flip — depend on it only from
  /// small positioning builders.
  static double foregroundLeftOf(BuildContext context) {
    final left = _dependOn(context, MainScreenScopeAspect.offset)?.foregroundLeft;
    if (left != null) return left;
    return 0.0;
  }

  static double foregroundWidthOf(BuildContext context) {
    final width = _dependOn(context, MainScreenScopeAspect.layout)?.foregroundWidth;
    if (width != null && width > 0) return width;
    return MediaQuery.sizeOf(context).width;
  }

  static Size foregroundSizeOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Size(foregroundWidthOf(context), size.height);
  }

  static double fullBleedWidthOf(BuildContext context) {
    final width = _dependOn(context, MainScreenScopeAspect.layout)?.viewportWidth;
    if (width != null && width > 0) return width;
    return MediaQuery.sizeOf(context).width;
  }

  @override
  bool updateShouldNotify(MainScreenFocusScope oldWidget) {
    return isSidebarFocused != oldWidget.isSidebarFocused ||
        sideNavigationWidth != oldWidget.sideNavigationWidth ||
        reservedSideNavigationWidth != oldWidget.reservedSideNavigationWidth ||
        foregroundLeft != oldWidget.foregroundLeft ||
        foregroundWidth != oldWidget.foregroundWidth ||
        viewportWidth != oldWidget.viewportWidth;
  }

  @override
  bool updateShouldNotifyDependent(MainScreenFocusScope oldWidget, Set<MainScreenScopeAspect> dependencies) {
    if (dependencies.contains(MainScreenScopeAspect.offset) &&
        (foregroundLeft != oldWidget.foregroundLeft || sideNavigationWidth != oldWidget.sideNavigationWidth)) {
      return true;
    }
    if (dependencies.contains(MainScreenScopeAspect.focus) && isSidebarFocused != oldWidget.isSidebarFocused) {
      return true;
    }
    if (dependencies.contains(MainScreenScopeAspect.layout) &&
        (foregroundWidth != oldWidget.foregroundWidth ||
            viewportWidth != oldWidget.viewportWidth ||
            reservedSideNavigationWidth != oldWidget.reservedSideNavigationWidth)) {
      return true;
    }
    return false;
  }
}

/// Animates toward the sidebar bleed target for overlays that must stay
/// viewport-pinned (full-bleed backgrounds, the overlaid app bar) while the
/// content box slides during sidebar expansion.
///
/// The duration/curve MUST mirror the content-slide tween in MainScreen's
/// `_buildContent`: pinning works because the two tweens retarget on the same
/// frame and track each other exactly, so the animated `-bleed` cancels the
/// content translate tick for tick.
class SideNavigationBleedBuilder extends StatelessWidget {
  final double targetBleed;
  final Widget? child;
  final Widget Function(BuildContext context, double bleed, Widget? child) builder;

  const SideNavigationBleedBuilder({super.key, required this.targetBleed, this.child, required this.builder});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetBleed),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: builder,
      child: child,
    );
  }
}
