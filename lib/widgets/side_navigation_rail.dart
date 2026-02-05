import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_memory_tracker.dart';
import '../models/plex_library.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../services/fullscreen_state_manager.dart';
import '../theme/mono_tokens.dart';
import '../i18n/strings.g.dart';
import '../watch_together/screens/watch_together_screen.dart';
import '../watch_together/widgets/invitations_indicator.dart';

/// Reusable navigation rail item widget that handles focus, selection, and interaction
class NavigationRailItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final Widget label;
  final bool isSelected;
  final bool isFocused;
  final bool isCollapsed;
  final bool useSimpleLayout;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final bool autofocus;
  final BorderRadius borderRadius;
  final double iconSize;

  /// Called when RIGHT arrow is pressed to navigate to content area.
  final VoidCallback? onNavigateRight;

  const NavigationRailItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isFocused,
    this.isCollapsed = false,
    this.useSimpleLayout = false,
    required this.onTap,
    required this.focusNode,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.iconSize = 22,
    this.onNavigateRight,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey.isSelectKey) {
          onTap();
          return KeyEventResult.handled;
        }
        // RIGHT arrow navigates to content area
        if (event.logicalKey == LogicalKeyboardKey.arrowRight && onNavigateRight != null) {
          onNavigateRight!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected && isFocused
                  ? t.text.withValues(alpha: 0.15) // Selected + focused
                  : isSelected
                  ? t.text.withValues(alpha: 0.1) // Just selected
                  : isFocused
                  ? t.text.withValues(alpha: 0.12) // Just focused (more visible)
                  : null,
              borderRadius: borderRadius,
            ),
            clipBehavior: Clip.hardEdge,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: SideNavigationRailState.expandedWidth - 24,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 17),
                  child: Row(
                    children: [
                      AppIcon(
                        isSelected && selectedIcon != null ? selectedIcon! : icon,
                        fill: 1,
                        size: iconSize,
                        color: isSelected ? t.text : t.textMuted,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: useSimpleLayout
                            ? label
                            : AnimatedOpacity(opacity: isCollapsed ? 0.0 : 1.0, duration: t.fast, child: label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Side navigation rail for Desktop and Android TV platforms
class SideNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final String? selectedLibraryKey;
  final bool isOfflineMode;
  final bool isSidebarFocused;
  final bool alwaysExpanded;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onLibrarySelected;

  /// Called when RIGHT arrow is pressed to navigate to content without selecting.
  final VoidCallback? onNavigateToContent;

  const SideNavigationRail({
    super.key,
    required this.selectedIndex,
    this.selectedLibraryKey,
    this.isOfflineMode = false,
    this.isSidebarFocused = false,
    this.alwaysExpanded = false,
    required this.onDestinationSelected,
    required this.onLibrarySelected,
    this.onNavigateToContent,
  });

  @override
  State<SideNavigationRail> createState() => SideNavigationRailState();
}

class SideNavigationRailState extends State<SideNavigationRail> {
  bool _librariesExpanded = true;

  // Collapsed/expanded state
  bool _isHovered = false;
  Timer? _collapseTimer;
  static const double collapsedWidth = 80.0;
  static const double expandedWidth = 220.0;
  static const Duration _collapseDelay = Duration(milliseconds: 150);

  // Focus keys for main nav items
  static const _kHome = 'home';
  static const _kLibraries = 'libraries';
  static const _kSearch = 'search';
  static const _kDownloads = 'downloads';
  static const _kSettings = 'settings';
  static const _kWatchTogether = 'watchTogether';

  // Unified focus state tracker for all nav items (main + libraries)
  late final FocusMemoryTracker _focusTracker;

  /// Whether the sidebar should be expanded (always, hover, or focus)
  bool get _shouldExpand => widget.alwaysExpanded || _isHovered || widget.isSidebarFocused;

  @override
  void initState() {
    super.initState();
    _focusTracker = FocusMemoryTracker(
      onFocusChanged: () {
        if (mounted) setState(() {});
      },
      debugLabelPrefix: 'nav',
    );
  }

  @override
  void didUpdateWidget(SideNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger rebuild when focus state changes
    if (oldWidget.isSidebarFocused != widget.isSidebarFocused) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _focusTracker.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    _collapseTimer?.cancel();
    if (!_isHovered) {
      setState(() => _isHovered = true);
    }
  }

  void _onHoverExit() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_collapseDelay, () {
      if (mounted && _isHovered) {
        setState(() => _isHovered = false);
      }
    });
  }

  /// The key of the last focused sidebar item (for pre-capture before focus shifts).
  String? get lastFocusedKey => _focusTracker.lastFocusedKey;

  /// Focus the last focused nav item, or Home as fallback.
  /// If [targetKey] is provided, try it first (used when the caller captured
  /// the intended target before a focus-scope switch overwrote it).
  void focusActiveItem({String? targetKey}) {
    if (targetKey != null) {
      final node = _focusTracker.nodeFor(targetKey);
      if (node != null) {
        node.requestFocus();
        return;
      }
    }
    _focusTracker.restoreFocus(fallbackKey: _kHome);
  }

  /// Build the set of valid focus keys (main nav + current libraries)
  Set<String> _buildValidFocusKeys(List<PlexLibrary> libraries) {
    return {_kHome, _kLibraries, _kSearch, _kDownloads, _kSettings, _kWatchTogether, ...libraries.map((lib) => lib.globalKey)};
  }

  /// Reload libraries (called when servers change or profile switches)
  void reloadLibraries() {
    final librariesProvider = context.read<LibrariesProvider>();
    librariesProvider.refresh();
  }

  IconData _getLibraryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Symbols.movie_rounded;
      case 'show':
        return Symbols.tv_rounded;
      case 'artist':
        return Symbols.music_note_rounded;
      case 'photo':
        return Symbols.photo_rounded;
      default:
        return Symbols.folder_rounded;
    }
  }

  /// Calculate top padding for macOS traffic lights
  double _getTopPadding(BuildContext context) {
    double basePadding = MediaQuery.of(context).padding.top + 16;

    // On macOS, add extra padding for traffic lights (when not fullscreen)
    if (Platform.isMacOS) {
      final isFullscreen = FullscreenStateManager().isFullscreen;
      if (!isFullscreen) {
        // Traffic lights area is approximately 52 pixels high
        basePadding = basePadding < 52 ? 52 : basePadding;
      }
    }

    return basePadding;
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final librariesProvider = context.watch<LibrariesProvider>();
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    // Get libraries from provider and filter visible ones
    final allLibraries = librariesProvider.libraries;
    final visibleLibraries = allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

    // Prune stale focus nodes when libraries change
    _focusTracker.pruneExcept(_buildValidFocusKeys(allLibraries));

    final isCollapsed = !_shouldExpand;

    // Listen to fullscreen changes for macOS
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        return MouseRegion(
          onEnter: (_) => _onHoverEnter(),
          onExit: (_) => _onHoverExit(),
          child: AnimatedContainer(
            duration: t.normal,
            curve: Curves.easeOutCubic,
            width: isCollapsed ? collapsedWidth : expandedWidth,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(color: t.surface),
            child: Column(
              children: [
                // Safe area for status bar and macOS traffic lights
                SizedBox(height: _getTopPadding(context)),

                // Navigation content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // In offline mode, only show Downloads and Settings
                      if (!widget.isOfflineMode) ...[
                        // Home
                        _buildNavItem(
                          icon: Symbols.home_rounded,
                          selectedIcon: Symbols.home_rounded,
                          label: Translations.of(context).navigation.home,
                          isSelected: widget.selectedIndex == 0,
                          isFocused: _focusTracker.isFocused(_kHome),
                          onTap: () => widget.onDestinationSelected(0),
                          focusNode: _focusTracker.get(_kHome),
                          isCollapsed: isCollapsed,
                        ),

                        const SizedBox(height: 8),

                        // Libraries section
                        _buildLibrariesSection(visibleLibraries, t, isCollapsed: isCollapsed),

                        const SizedBox(height: 8),

                        // Search
                        _buildNavItem(
                          icon: Symbols.search_rounded,
                          selectedIcon: Symbols.search_rounded,
                          label: Translations.of(context).navigation.search,
                          isSelected: widget.selectedIndex == 2,
                          isFocused: _focusTracker.isFocused(_kSearch),
                          onTap: () => widget.onDestinationSelected(2),
                          focusNode: _focusTracker.get(_kSearch),
                          isCollapsed: isCollapsed,
                        ),

                        const SizedBox(height: 8),
                      ],

                      // Downloads
                      _buildNavItem(
                        icon: Symbols.download_rounded,
                        selectedIcon: Symbols.download_rounded,
                        label: Translations.of(context).navigation.downloads,
                        isSelected: NavigationTab.isTabAtIndex(
                          NavigationTabId.downloads,
                          widget.selectedIndex,
                          isOffline: widget.isOfflineMode,
                        ),
                        isFocused: _focusTracker.isFocused(_kDownloads),
                        onTap: () => widget.onDestinationSelected(
                          NavigationTab.indexFor(NavigationTabId.downloads, isOffline: widget.isOfflineMode),
                        ),
                        focusNode: _focusTracker.get(_kDownloads),
                        isCollapsed: isCollapsed,
                      ),

                      const SizedBox(height: 8),

                      // Settings
                      _buildNavItem(
                        icon: Symbols.settings_rounded,
                        selectedIcon: Symbols.settings_rounded,
                        label: Translations.of(context).navigation.settings,
                        isSelected: NavigationTab.isTabAtIndex(
                          NavigationTabId.settings,
                          widget.selectedIndex,
                          isOffline: widget.isOfflineMode,
                        ),
                        isFocused: _focusTracker.isFocused(_kSettings),
                        onTap: () => widget.onDestinationSelected(
                          NavigationTab.indexFor(NavigationTabId.settings, isOffline: widget.isOfflineMode),
                        ),
                        focusNode: _focusTracker.get(_kSettings),
                        isCollapsed: isCollapsed,
                      ),

                      // Watch Together (only in online mode)
                      if (!widget.isOfflineMode) ...[
                        const SizedBox(height: 8),
                        _buildWatchTogetherItem(t, isCollapsed: isCollapsed),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required bool isFocused,
    required VoidCallback onTap,
    required FocusNode focusNode,
    required bool isCollapsed,
    bool autofocus = false,
  }) {
    final t = tokens(context);

    return NavigationRailItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? t.text : t.textMuted,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      isSelected: isSelected,
      isFocused: isFocused,
      isCollapsed: isCollapsed,
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus,
      onNavigateRight: widget.onNavigateToContent,
    );
  }

  Widget _buildLibrariesSection(List<PlexLibrary> visibleLibraries, dynamic t, {bool isCollapsed = false}) {
    final librariesProvider = context.watch<LibrariesProvider>();
    final isLoading = librariesProvider.isLoading;
    final isLibrariesSelected = widget.selectedIndex == 1 && widget.selectedLibraryKey == null;
    final isLibrariesFocused = _focusTracker.isFocused(_kLibraries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Libraries header with expand/collapse
        Focus(
          focusNode: _focusTracker.get(_kLibraries),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey.isSelectKey) {
              setState(() {
                _librariesExpanded = !_librariesExpanded;
              });
              return KeyEventResult.handled;
            }
            // RIGHT arrow navigates to content area
            if (event.logicalKey == LogicalKeyboardKey.arrowRight && widget.onNavigateToContent != null) {
              widget.onNavigateToContent!();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _librariesExpanded = !_librariesExpanded;
                });
              },
              borderRadius: BorderRadius.circular(tokens(context).radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: isLibrariesSelected
                      ? t.text.withValues(alpha: 0.1)
                      : isLibrariesFocused
                      ? t.text.withValues(alpha: 0.08)
                      : null,
                  borderRadius: BorderRadius.circular(tokens(context).radiusMd),
                ),
                clipBehavior: Clip.hardEdge,
                child: UnconstrainedBox(
                  alignment: Alignment.centerLeft,
                  constrainedAxis: Axis.vertical,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: expandedWidth - 24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 17),
                      child: Row(
                        children: [
                          AppIcon(
                            Symbols.video_library_rounded,
                            fill: 1,
                            size: 22,
                            color: widget.selectedIndex == 1 ? t.text : t.textMuted,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: isCollapsed ? 0.0 : 1.0,
                              duration: tokens(context).fast,
                              child: Text(
                                Translations.of(context).navigation.libraries,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: widget.selectedIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                                  color: widget.selectedIndex == 1 ? t.text : t.textMuted,
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: isCollapsed ? 0.0 : 1.0,
                            duration: tokens(context).fast,
                            child: AppIcon(
                              _librariesExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                              fill: 1,
                              size: 20,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Library items with animated height
        TweenAnimationBuilder<double>(
          tween: Tween(end: (_librariesExpanded && !isCollapsed) ? 1.0 : 0.0),
          duration: tokens(context).normal,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRect(
              child: Align(alignment: Alignment.topCenter, heightFactor: value, child: child),
            );
          },
          child: ExcludeFocus(
            excluding: !_librariesExpanded || isCollapsed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: t.textMuted),
                          ),
                        ),
                      )
                    : visibleLibraries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          Translations.of(context).libraries.noLibrariesFound,
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                      )
                    : _buildLibraryItems(visibleLibraries, t),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Get set of library names that appear more than once (not globally unique)
  Set<String> _getNonUniqueLibraryNames(List<PlexLibrary> libraries) {
    final nameCounts = <String, int>{};
    for (final lib in libraries) {
      nameCounts[lib.title] = (nameCounts[lib.title] ?? 0) + 1;
    }
    return nameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  Widget _buildLibraryItems(List<PlexLibrary> visibleLibraries, dynamic t) {
    // Find which library names are not unique
    final nonUniqueNames = _getNonUniqueLibraryNames(visibleLibraries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleLibraries.map((library) {
        final showServerName = nonUniqueNames.contains(library.title) && library.serverName != null;
        return _buildLibraryItem(library, t, showServerName: showServerName);
      }).toList(),
    );
  }

  Widget _buildLibraryItem(PlexLibrary library, dynamic t, {bool showServerName = false}) {
    final isSelected = widget.selectedIndex == 1 && widget.selectedLibraryKey == library.globalKey;
    final isFocused = _focusTracker.isFocused(library.globalKey);
    final focusNode = _focusTracker.get(library.globalKey);

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: NavigationRailItem(
        icon: _getLibraryIcon(library.type),
        selectedIcon: _getLibraryIcon(library.type),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              library.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? t.text : t.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (showServerName)
              Text(
                library.serverName!,
                style: TextStyle(fontSize: 9, color: t.textMuted.withValues(alpha: 0.4)),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isSelected: isSelected,
        isFocused: isFocused,
        useSimpleLayout: true,
        onTap: () => widget.onLibrarySelected(library.globalKey),
        focusNode: focusNode,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        iconSize: 18,
        onNavigateRight: widget.onNavigateToContent,
      ),
    );
  }

  Widget _buildWatchTogetherItem(dynamic t, {bool isCollapsed = false}) {
    final isFocused = _focusTracker.isFocused(_kWatchTogether);
    final focusNode = _focusTracker.get(_kWatchTogether);

    return InvitationsIndicator(
      child: NavigationRailItem(
        icon: Symbols.group_rounded,
        selectedIcon: Symbols.group_rounded,
        label: Text(
          Translations.of(context).watchTogether.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: t.textMuted,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        isSelected: false,
        isFocused: isFocused,
        isCollapsed: isCollapsed,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WatchTogetherScreen()),
          );
        },
        focusNode: focusNode,
        onNavigateRight: widget.onNavigateToContent,
      ),
    );
  }
}
