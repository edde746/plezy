import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_memory_tracker.dart';
import '../media/media_library.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/platform_detector.dart';
import '../utils/library_grouping.dart';
import '../providers/multi_server_provider.dart';
import '../services/fullscreen_state_manager.dart';
import '../theme/mono_tokens.dart';
import '../widgets/backend_badge.dart';
import '../i18n/strings.g.dart';

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
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              color: () {
                if (isSelected && isFocused) return t.text.withValues(alpha: 0.15);
                if (isSelected) return t.text.withValues(alpha: 0.1);
                if (isFocused) return t.text.withValues(alpha: 0.12);
                return null;
              }(),
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
                        child: () {
                          if (useSimpleLayout) return label;
                          final opacity = isCollapsed ? 0.0 : 1.0;
                          return AnimatedOpacity(opacity: opacity, duration: t.fast, child: label);
                        }(),
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
  final NavigationTabId selectedTab;
  final String? selectedLibraryKey;
  final bool isOfflineMode;
  final bool isSidebarFocused;
  final bool alwaysExpanded;
  final bool isReconnecting;
  final ValueChanged<NavigationTabId> onDestinationSelected;
  final ValueChanged<String> onLibrarySelected;

  /// Called when RIGHT arrow is pressed to navigate to content without selecting.
  final VoidCallback? onNavigateToContent;

  /// Called when the user taps the reconnect button in offline mode.
  final VoidCallback? onReconnect;

  const SideNavigationRail({
    super.key,
    required this.selectedTab,
    this.selectedLibraryKey,
    this.isOfflineMode = false,
    this.isSidebarFocused = false,
    this.alwaysExpanded = false,
    this.isReconnecting = false,
    required this.onDestinationSelected,
    required this.onLibrarySelected,
    this.onNavigateToContent,
    this.onReconnect,
  });

  @override
  State<SideNavigationRail> createState() => SideNavigationRailState();
}

class SideNavigationRailState extends State<SideNavigationRail> {
  bool _librariesExpanded = true;

  // Collapsed/expanded state
  bool _isHovered = false;
  bool _isTouchExpanded = false;
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
  static const _kReconnect = 'reconnect';
  static const _kFullscreen = 'fullscreen';
  static const _kHiddenLibraries = 'hiddenLibraries';
  static const _kServerHeaderPrefix = 'serverHeader_';

  bool _hiddenLibrariesExpanded = false;
  final Set<String> _collapsedServerIds = {};

  // Unified focus state tracker for all nav items (main + libraries)
  late final FocusMemoryTracker _focusTracker;

  /// Whether the sidebar should be expanded (always, hover, or focus)
  bool get _shouldExpand => widget.alwaysExpanded || _isHovered || _isTouchExpanded || widget.isSidebarFocused;

  /// macOS has the system green button; mobile/TV have no OS fullscreen toggle.
  bool get _showFullscreenToggle => Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _focusTracker = FocusMemoryTracker(
      onFocusChanged: () {
        // ignore: no-empty-block - setState triggers rebuild to update focus styling
        if (mounted) setState(() {});
      },
      debugLabelPrefix: 'nav',
    );
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _focusTracker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SideNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse after navigation (selection changed)
    if (oldWidget.selectedTab != widget.selectedTab || oldWidget.selectedLibraryKey != widget.selectedLibraryKey) {
      _isTouchExpanded = false;
    }
  }

  void _onHoverEnter() {
    _collapseTimer?.cancel();
    _isTouchExpanded = false; // Mouse takes over
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

  /// Build the set of valid focus keys (main nav + current libraries + server headers)
  Set<String> _buildValidFocusKeys(List<MediaLibrary> libraries, Set<String> serverIds) {
    return {
      _kHome,
      _kLibraries,
      _kSearch,
      _kDownloads,
      _kSettings,
      _kReconnect,
      _kHiddenLibraries,
      if (_showFullscreenToggle) _kFullscreen,
      'liveTv',
      ...libraries.map((lib) => lib.globalKey),
      ...serverIds.map((id) => _kServerHeaderPrefix + id),
    };
  }

  /// Build the visual order of library items inside the libraries body. Must
  /// mirror what `_buildLibraryGroupedColumn` actually renders so D-pad
  /// navigation lands on the visually next item.
  List<String> _buildLibraryBodyOrder(List<MediaLibrary> libs, {required bool showServerHeaders}) {
    if (!showServerHeaders) {
      return libs.map((lib) => lib.globalKey).toList();
    }
    final grouped = groupLibrariesByFirstAppearance(libs);
    final result = <String>[];
    for (final serverKey in grouped.serverOrder) {
      if (serverKey.isNotEmpty) {
        result.add(_kServerHeaderPrefix + serverKey);
      }
      if (serverKey.isEmpty || !_collapsedServerIds.contains(serverKey)) {
        for (final lib in grouped.byServer[serverKey]!) {
          result.add(lib.globalKey);
        }
      }
    }
    return result;
  }

  /// Ordered list of focusable keys matching visual top-to-bottom order.
  List<String> _buildFocusOrder(
    List<MediaLibrary> visibleLibraries,
    List<MediaLibrary> hiddenLibraries, {
    required bool hasLiveTv,
    required bool showServerHeaders,
  }) {
    return [
      if (widget.isOfflineMode && widget.onReconnect != null) _kReconnect,
      if (!widget.isOfflineMode) ...[
        _kHome,
        _kLibraries,
        if (_librariesExpanded) ...[
          ..._buildLibraryBodyOrder(visibleLibraries, showServerHeaders: showServerHeaders),
          if (hiddenLibraries.isNotEmpty) ...[
            _kHiddenLibraries,
            if (_hiddenLibrariesExpanded)
              ..._buildLibraryBodyOrder(hiddenLibraries, showServerHeaders: showServerHeaders),
          ],
        ],
        if (hasLiveTv) 'liveTv',
        _kSearch,
      ],
      _kDownloads,
      _kSettings,
      if (_showFullscreenToggle) _kFullscreen,
    ];
  }

  /// Handle D-pad UP/DOWN by explicitly moving focus to the next/previous item.
  KeyEventResult _handleVerticalNavigation(FocusNode _, KeyEvent event, List<String> focusOrder) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final isUp = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!isDown && !isUp) return KeyEventResult.ignored;

    final currentKey = _focusTracker.lastFocusedKey;
    if (currentKey == null) return KeyEventResult.ignored;

    final currentIndex = focusOrder.indexOf(currentKey);
    if (currentIndex == -1) return KeyEventResult.ignored;

    final nextIndex = isDown ? currentIndex + 1 : currentIndex - 1;
    if (nextIndex < 0 || nextIndex >= focusOrder.length) return KeyEventResult.handled;

    final nextNode = _focusTracker.nodeFor(focusOrder[nextIndex]);
    if (nextNode == null) return KeyEventResult.ignored;

    nextNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = nextNode.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 200));
      }
    });
    return KeyEventResult.handled;
  }

  /// Collapse the sidebar (resets touch-expand state).
  void collapse() {
    if (_isTouchExpanded) {
      setState(() => _isTouchExpanded = false);
    }
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
      case 'mixed':
        return Symbols.share_rounded;
      default:
        return Symbols.folder_rounded;
    }
  }

  /// Calculate top padding for macOS traffic lights
  double _getTopPadding(BuildContext context) {
    double basePadding = MediaQuery.paddingOf(context).top + 16;

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

    final allLibraries = librariesProvider.libraries;
    final visibleLibraries = <MediaLibrary>[];
    final hiddenLibraries = <MediaLibrary>[];
    final serverIds = <String>{};
    for (final lib in allLibraries) {
      if (lib.serverId != null) serverIds.add(lib.serverId!);
      if (hiddenKeys.contains(lib.globalKey)) {
        hiddenLibraries.add(lib);
      } else {
        visibleLibraries.add(lib);
      }
    }

    _focusTracker.pruneExcept(_buildValidFocusKeys(allLibraries, serverIds));
    _collapsedServerIds.retainAll(serverIds);

    final isCollapsed = !_shouldExpand;
    final hasLiveTv = context.watch<MultiServerProvider>().hasLiveTv;

    // Server grouping: only when multi-server AND the user-facing toggle is on.
    final groupByServerSetting = context.select<SettingsProvider, bool>((p) => p.groupLibrariesByServer);
    final showServerHeaders = serverIds.length > 1 && groupByServerSetting;

    final focusOrder = _buildFocusOrder(
      visibleLibraries,
      hiddenLibraries,
      hasLiveTv: hasLiveTv,
      showServerHeaders: showServerHeaders,
    );

    // Listen to fullscreen changes for macOS
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        return TapRegion(
          onTapOutside: (_) {
            if (_isTouchExpanded) {
              setState(() => _isTouchExpanded = false);
            }
          },
          child: MouseRegion(
            onEnter: (_) => _onHoverEnter(),
            onExit: (_) => _onHoverExit(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isCollapsed ? () => setState(() => _isTouchExpanded = true) : null,
              child: AnimatedContainer(
                duration: t.normal,
                curve: Curves.easeOutCubic,
                width: isCollapsed ? collapsedWidth : expandedWidth,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(color: t.surface),
                child: IgnorePointer(
                  ignoring: isCollapsed,
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: (node, event) => _handleVerticalNavigation(node, event, focusOrder),
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
                              // Reconnect button when offline
                              if (widget.isOfflineMode && widget.onReconnect != null) ...[
                                _buildReconnectItem(isCollapsed: isCollapsed),
                                const SizedBox(height: 8),
                              ],

                              // In online mode, show full navigation
                              if (!widget.isOfflineMode) ...[
                                // Home
                                _buildNavItem(
                                  icon: Symbols.home_rounded,
                                  selectedIcon: Symbols.home_rounded,
                                  label: Translations.of(context).common.home,
                                  isSelected: widget.selectedTab == NavigationTabId.discover,
                                  isFocused: _focusTracker.isFocused(_kHome),
                                  onTap: () => widget.onDestinationSelected(NavigationTabId.discover),
                                  focusNode: _focusTracker.get(_kHome),
                                  isCollapsed: isCollapsed,
                                ),

                                const SizedBox(height: 8),

                                // Libraries section
                                _buildLibrariesSection(
                                  visibleLibraries,
                                  hiddenLibraries,
                                  t,
                                  isCollapsed: isCollapsed,
                                  showServerHeaders: showServerHeaders,
                                ),

                                const SizedBox(height: 8),

                                // Live TV (only if DVR available)
                                if (context.watch<MultiServerProvider>().hasLiveTv) ...[
                                  _buildNavItem(
                                    icon: Symbols.live_tv_rounded,
                                    selectedIcon: Symbols.live_tv_rounded,
                                    label: Translations.of(context).navigation.liveTv,
                                    isSelected: widget.selectedTab == NavigationTabId.liveTv,
                                    isFocused: _focusTracker.isFocused('liveTv'),
                                    onTap: () => widget.onDestinationSelected(NavigationTabId.liveTv),
                                    focusNode: _focusTracker.get('liveTv'),
                                    isCollapsed: isCollapsed,
                                  ),

                                  const SizedBox(height: 8),
                                ],

                                // Search
                                _buildNavItem(
                                  icon: Symbols.search_rounded,
                                  selectedIcon: Symbols.search_rounded,
                                  label: Translations.of(context).common.search,
                                  isSelected: widget.selectedTab == NavigationTabId.search,
                                  isFocused: _focusTracker.isFocused(_kSearch),
                                  onTap: () => widget.onDestinationSelected(NavigationTabId.search),
                                  focusNode: _focusTracker.get(_kSearch),
                                  isCollapsed: isCollapsed,
                                ),

                                const SizedBox(height: 8),
                              ],

                              // Downloads (hidden on Apple TV — no user
                              // file storage)
                              if (!PlatformDetector.isAppleTV()) ...[
                                _buildNavItem(
                                  icon: Symbols.download_rounded,
                                  selectedIcon: Symbols.download_rounded,
                                  label: Translations.of(context).navigation.downloads,
                                  isSelected: widget.selectedTab == NavigationTabId.downloads,
                                  isFocused: _focusTracker.isFocused(_kDownloads),
                                  onTap: () => widget.onDestinationSelected(NavigationTabId.downloads),
                                  focusNode: _focusTracker.get(_kDownloads),
                                  isCollapsed: isCollapsed,
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Settings
                              _buildNavItem(
                                icon: Symbols.settings_rounded,
                                selectedIcon: Symbols.settings_rounded,
                                label: Translations.of(context).common.settings,
                                isSelected: widget.selectedTab == NavigationTabId.settings,
                                isFocused: _focusTracker.isFocused(_kSettings),
                                onTap: () => widget.onDestinationSelected(NavigationTabId.settings),
                                focusNode: _focusTracker.get(_kSettings),
                                isCollapsed: isCollapsed,
                              ),
                            ],
                          ),
                        ),

                        if (_showFullscreenToggle)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: _buildFullscreenItem(isCollapsed: isCollapsed),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _buildReconnectItem({required bool isCollapsed}) {
    final t = tokens(context);
    final isFocused = _focusTracker.isFocused(_kReconnect);

    return NavigationRailItem(
      icon: widget.isReconnecting ? Symbols.sync_rounded : Symbols.wifi_rounded,
      label: widget.isReconnecting
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.text))
          : Text(
              Translations.of(context).common.reconnect,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: t.textMuted),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
      isSelected: false,
      isFocused: isFocused,
      isCollapsed: isCollapsed,
      // ignore: no-empty-block - no-op tap handler while reconnecting
      onTap: widget.isReconnecting ? () {} : () => widget.onReconnect?.call(),
      focusNode: _focusTracker.get(_kReconnect),
      onNavigateRight: widget.onNavigateToContent,
    );
  }

  Widget _buildFullscreenItem({required bool isCollapsed}) {
    final t = tokens(context);
    final isFullscreen = FullscreenStateManager().isFullscreen;
    final isFocused = _focusTracker.isFocused(_kFullscreen);

    return NavigationRailItem(
      icon: isFullscreen ? Symbols.fullscreen_exit_rounded : Symbols.fullscreen_rounded,
      label: Text(
        isFullscreen ? Translations.of(context).common.exitFullscreen : Translations.of(context).common.fullscreen,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: t.textMuted),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      isSelected: false,
      isFocused: isFocused,
      isCollapsed: isCollapsed,
      onTap: () => unawaited(FullscreenStateManager().toggleFullscreen()),
      focusNode: _focusTracker.get(_kFullscreen),
      onNavigateRight: widget.onNavigateToContent,
    );
  }

  Widget _buildLibrariesSection(
    List<MediaLibrary> visibleLibraries,
    List<MediaLibrary> hiddenLibraries,
    dynamic t, {
    bool isCollapsed = false,
    bool showServerHeaders = false,
  }) {
    final librariesProvider = context.watch<LibrariesProvider>();
    final isLoading = librariesProvider.isLoading;
    final isLibrariesSelected = widget.selectedTab == NavigationTabId.libraries && widget.selectedLibraryKey == null;
    final isLibrariesFocused = _focusTracker.isFocused(_kLibraries);
    final allEmpty = visibleLibraries.isEmpty && hiddenLibraries.isEmpty;

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
              canRequestFocus: false,
              onTap: () {
                setState(() {
                  _librariesExpanded = !_librariesExpanded;
                });
              },
              borderRadius: BorderRadius.circular(tokens(context).radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: () {
                    if (isLibrariesSelected) return t.text.withValues(alpha: 0.1);
                    if (isLibrariesFocused) return t.text.withValues(alpha: 0.08);
                    return null;
                  }(),
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
                            color: widget.selectedTab == NavigationTabId.libraries ? t.text : t.textMuted,
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
                                  fontWeight: widget.selectedTab == NavigationTabId.libraries
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: widget.selectedTab == NavigationTabId.libraries ? t.text : t.textMuted,
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
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.textMuted),
                      ),
                    ),
                  )
                else if (allEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      Translations.of(context).libraries.noLibrariesFound,
                      style: TextStyle(fontSize: 12, color: t.textMuted),
                    ),
                  )
                else ...[
                  if (visibleLibraries.isNotEmpty)
                    _buildLibraryGroupedColumn(visibleLibraries, t, showServerHeaders: showServerHeaders),
                  if (hiddenLibraries.isNotEmpty) ...[
                    _buildHiddenLibrariesHeader(hiddenLibraries.length, t),
                    if (_hiddenLibrariesExpanded)
                      _buildLibraryGroupedColumn(hiddenLibraries, t, showServerHeaders: showServerHeaders),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Get set of library names that appear more than once (not globally unique)
  Set<String> _getNonUniqueLibraryNames(List<MediaLibrary> libraries) {
    final nameCounts = <String, int>{};
    for (final lib in libraries) {
      nameCounts[lib.title] = (nameCounts[lib.title] ?? 0) + 1;
    }
    return nameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  Widget _buildLibraryGroupedColumn(List<MediaLibrary> libraries, dynamic t, {required bool showServerHeaders}) {
    if (!showServerHeaders) {
      final nonUniqueNames = _getNonUniqueLibraryNames(libraries);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: libraries.map((library) {
          final showServerName = nonUniqueNames.contains(library.title) && library.serverName != null;
          return _buildLibraryItem(library, t, showServerName: showServerName);
        }).toList(),
      );
    }

    final grouped = groupLibrariesByFirstAppearance(libraries);
    final children = <Widget>[];
    for (final serverKey in grouped.serverOrder) {
      final bucket = grouped.byServer[serverKey]!;
      // serverKey is '' when serverId is null — skip the header in that case.
      if (serverKey.isNotEmpty) {
        final serverName = bucket.first.serverName ?? serverKey;
        children.add(_buildServerHeader(serverKey, serverName, t));
      }
      if (serverKey.isEmpty || !_collapsedServerIds.contains(serverKey)) {
        for (final library in bucket) {
          children.add(_buildLibraryItem(library, t, showServerName: false));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildServerHeader(String serverId, String serverName, dynamic t) {
    // Resolve backend per server so the badge matches the brand. Falls back
    // to the generic `dns` icon if the client isn't registered yet (rare —
    // can happen during a profile switch before the manager rehydrates).
    final backend = context.read<MultiServerProvider>().serverManager.getClient(serverId)?.backend;
    return _buildCollapsibleHeader(
      focusKey: _kServerHeaderPrefix + serverId,
      icon: Symbols.dns_rounded,
      iconSize: 14,
      leading: backend == null ? null : BackendBadge(backend: backend, size: 14, color: t.textMuted),
      label: serverName,
      labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: t.textMuted),
      verticalPadding: 6,
      isExpanded: !_collapsedServerIds.contains(serverId),
      onToggle: () => _toggleServerCollapse(serverId),
      t: t,
    );
  }

  void _toggleServerCollapse(String serverId) {
    setState(() {
      if (!_collapsedServerIds.add(serverId)) {
        _collapsedServerIds.remove(serverId);
      }
    });
  }

  Widget _buildHiddenLibrariesHeader(int count, dynamic t) {
    return _buildCollapsibleHeader(
      focusKey: _kHiddenLibraries,
      icon: Symbols.visibility_off_rounded,
      iconSize: 16,
      label: Translations.of(context).libraries.hiddenLibrariesCount(count: count),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textMuted),
      verticalPadding: 8,
      isExpanded: _hiddenLibrariesExpanded,
      onToggle: () => setState(() => _hiddenLibrariesExpanded = !_hiddenLibrariesExpanded),
      t: t,
    );
  }

  Widget _buildCollapsibleHeader({
    required String focusKey,
    required IconData icon,
    required double iconSize,
    Widget? leading,
    required String label,
    required TextStyle labelStyle,
    required double verticalPadding,
    required bool isExpanded,
    required VoidCallback onToggle,
    required dynamic t,
  }) {
    final isFocused = _focusTracker.isFocused(focusKey);
    final radius = BorderRadius.circular(tokens(context).radiusSm);
    // Match library-item indent: outer Padding(left: 12) + inner horizontal 17.
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Focus(
        focusNode: _focusTracker.get(focusKey),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey.isSelectKey) {
            onToggle();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight && widget.onNavigateToContent != null) {
            widget.onNavigateToContent!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            canRequestFocus: false,
            onTap: onToggle,
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(color: isFocused ? t.text.withValues(alpha: 0.08) : null, borderRadius: radius),
              clipBehavior: Clip.hardEdge,
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                constrainedAxis: Axis.vertical,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: expandedWidth - 24,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 17),
                    child: Row(
                      children: [
                        leading ?? AppIcon(icon, fill: 1, size: iconSize, color: t.textMuted),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
                        ),
                        AppIcon(
                          isExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                          fill: 1,
                          size: 16,
                          color: t.textMuted,
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
    );
  }

  Widget _buildLibraryItem(MediaLibrary library, dynamic t, {bool showServerName = false}) {
    final isSelected =
        widget.selectedTab == NavigationTabId.libraries && widget.selectedLibraryKey == library.globalKey;
    final isFocused = _focusTracker.isFocused(library.globalKey);
    final focusNode = _focusTracker.get(library.globalKey);

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: NavigationRailItem(
        icon: _getLibraryIcon(library.kind.id),
        selectedIcon: _getLibraryIcon(library.kind.id),
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
}
