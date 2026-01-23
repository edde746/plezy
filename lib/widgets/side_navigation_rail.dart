import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../models/plex_library.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/storage_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/content_utils.dart';
import '../i18n/strings.g.dart';

/// Tracks focus state for a set of named items, avoiding repeated boilerplate
class _FocusStateTracker {
  final Map<String, FocusNode> _nodes = {};
  final Set<String> _focused = {};
  final VoidCallback _onChanged;

  _FocusStateTracker(this._onChanged);

  /// Get or create a focus node for the given key
  FocusNode get(String key, {String? debugLabel}) {
    return _nodes.putIfAbsent(key, () {
      final node = FocusNode(debugLabel: debugLabel ?? 'nav_$key');
      node.addListener(() {
        final wasFocused = _focused.contains(key);
        if (node.hasFocus && !wasFocused) {
          _focused.add(key);
          _onChanged();
        } else if (!node.hasFocus && wasFocused) {
          _focused.remove(key);
          _onChanged();
        }
      });
      return node;
    });
  }

  /// Check if a key is currently focused
  bool isFocused(String key) => _focused.contains(key);

  /// Check if a node exists for the given key
  FocusNode? nodeFor(String key) => _nodes[key];

  /// Dispose all nodes
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
    _focused.clear();
  }

  /// Remove nodes not in the given set of valid keys (prunes stale nodes)
  void pruneExcept(Set<String> validKeys) {
    final toRemove = _nodes.keys.where((k) => !validKeys.contains(k)).toList();
    for (final key in toRemove) {
      _nodes[key]?.dispose();
      _nodes.remove(key);
      _focused.remove(key);
    }
  }
}

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
                width: SideNavigationRailState._expandedWidth - 24,
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
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onLibrarySelected;

  const SideNavigationRail({
    super.key,
    required this.selectedIndex,
    this.selectedLibraryKey,
    this.isOfflineMode = false,
    this.isSidebarFocused = false,
    required this.onDestinationSelected,
    required this.onLibrarySelected,
  });

  @override
  State<SideNavigationRail> createState() => SideNavigationRailState();
}

class SideNavigationRailState extends State<SideNavigationRail> {
  bool _librariesExpanded = true;
  List<PlexLibrary> _libraries = [];
  bool _isLoadingLibraries = true;

  // Collapsed/expanded state
  bool _isHovered = false;
  Timer? _collapseTimer;
  static const double collapsedWidth = 80.0;
  static const double _expandedWidth = 220.0;
  static const Duration _collapseDelay = Duration(milliseconds: 150);

  // Focus keys for main nav items
  static const _kHome = 'home';
  static const _kLibraries = 'libraries';
  static const _kSearch = 'search';
  static const _kDownloads = 'downloads';
  static const _kSettings = 'settings';

  // Unified focus state tracker for all nav items (main + libraries)
  late final _FocusStateTracker _focusTracker;

  /// Whether the sidebar should be expanded (hover or focus)
  bool get _shouldExpand => _isHovered || widget.isSidebarFocused;

  @override
  void initState() {
    super.initState();
    _focusTracker = _FocusStateTracker(() {
      if (mounted) setState(() {});
    });
    _loadLibraries();
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

  /// Focus the currently selected nav item
  void focusActiveItem() {
    if (widget.selectedLibraryKey != null) {
      // A library is selected - focus that library item
      _focusTracker.nodeFor(widget.selectedLibraryKey!)?.requestFocus();
    } else {
      // Focus main nav item based on selectedIndex
      final key = switch (widget.selectedIndex) {
        0 => _kHome,
        1 => _kLibraries,
        2 => _kSearch,
        3 => _kDownloads,
        4 => _kSettings,
        _ => null,
      };
      if (key != null) _focusTracker.nodeFor(key)?.requestFocus();
    }
  }

  /// Fetch, filter, and order libraries (pure logic, no state changes)
  Future<List<PlexLibrary>> _resolveLibraries(MultiServerProvider provider, StorageService storage) async {
    if (!provider.hasConnectedServers) return [];

    final libraries = await provider.aggregationService.getLibrariesFromAllServers();

    // Filter out unsupported library types (music)
    var filtered = libraries.where((lib) => !ContentTypeHelper.isMusicLibrary(lib)).toList();

    // Apply saved order
    final savedOrder = storage.getLibraryOrder();
    if (savedOrder == null || savedOrder.isEmpty) return filtered;

    final libraryMap = {for (var lib in filtered) lib.globalKey: lib};
    final ordered = <PlexLibrary>[];
    for (final key in savedOrder) {
      final lib = libraryMap.remove(key);
      if (lib != null) ordered.add(lib);
    }
    ordered.addAll(libraryMap.values); // New libraries not in saved order
    return ordered;
  }

  /// Build the set of valid focus keys (main nav + current libraries)
  Set<String> _buildValidFocusKeys(List<PlexLibrary> libraries) {
    return {_kHome, _kLibraries, _kSearch, _kDownloads, _kSettings, ...libraries.map((lib) => lib.globalKey)};
  }

  Future<void> _loadLibraries() async {
    final provider = context.read<MultiServerProvider>();
    final storage = await StorageService.getInstance();

    try {
      final libraries = await _resolveLibraries(provider, storage);

      if (mounted) {
        setState(() {
          _libraries = libraries;
          _isLoadingLibraries = false;
        });
        // Prune stale library focus nodes
        _focusTracker.pruneExcept(_buildValidFocusKeys(libraries));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLibraries = false;
        });
      }
    }
  }

  /// Reload libraries (called when servers change)
  void reloadLibraries() {
    setState(() {
      _isLoadingLibraries = true;
    });
    _loadLibraries();
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
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    // Filter visible libraries
    final visibleLibraries = _libraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

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
            width: isCollapsed ? collapsedWidth : _expandedWidth,
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
    );
  }

  Widget _buildLibrariesSection(List<PlexLibrary> visibleLibraries, dynamic t, {bool isCollapsed = false}) {
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
                    width: _expandedWidth - 24,
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

        // Library items (hidden when collapsed to avoid clipped partial items)
        if (_librariesExpanded && !isCollapsed) ...[
          const SizedBox(height: 4),
          _isLoadingLibraries
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
      ),
    );
  }
}
