import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../models/plex_library.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/storage_service.dart';
import '../theme/theme_helper.dart';
import '../i18n/strings.g.dart';

/// Side navigation rail for Desktop and Android TV platforms
class SideNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final String? selectedLibraryKey;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onLibrarySelected;

  const SideNavigationRail({
    super.key,
    required this.selectedIndex,
    this.selectedLibraryKey,
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

  // Focus nodes for main nav items
  late FocusNode _homeFocusNode;
  late FocusNode _librariesFocusNode;
  late FocusNode _searchFocusNode;
  late FocusNode _settingsFocusNode;

  // Focus state tracking
  bool _isHomeFocused = false;
  bool _isLibrariesFocused = false;
  bool _isSearchFocused = false;
  bool _isSettingsFocused = false;

  // Map to store library item focus nodes and states
  final Map<String, FocusNode> _libraryFocusNodes = {};
  final Set<String> _focusedLibraryKeys = {};

  @override
  void initState() {
    super.initState();
    _homeFocusNode = FocusNode(debugLabel: 'nav_home');
    _librariesFocusNode = FocusNode(debugLabel: 'nav_libraries');
    _searchFocusNode = FocusNode(debugLabel: 'nav_search');
    _settingsFocusNode = FocusNode(debugLabel: 'nav_settings');

    _homeFocusNode.addListener(() => _onFocusChange(_homeFocusNode, () {
      setState(() => _isHomeFocused = _homeFocusNode.hasFocus);
    }));
    _librariesFocusNode.addListener(() => _onFocusChange(_librariesFocusNode, () {
      setState(() => _isLibrariesFocused = _librariesFocusNode.hasFocus);
    }));
    _searchFocusNode.addListener(() => _onFocusChange(_searchFocusNode, () {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    }));
    _settingsFocusNode.addListener(() => _onFocusChange(_settingsFocusNode, () {
      setState(() => _isSettingsFocused = _settingsFocusNode.hasFocus);
    }));

    _loadLibraries();
  }

  void _onFocusChange(FocusNode node, VoidCallback updateState) {
    if (mounted) updateState();
  }

  @override
  void dispose() {
    _homeFocusNode.dispose();
    _librariesFocusNode.dispose();
    _searchFocusNode.dispose();
    _settingsFocusNode.dispose();
    for (final node in _libraryFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Get or create a focus node for a library item
  FocusNode _getLibraryFocusNode(String globalKey) {
    return _libraryFocusNodes.putIfAbsent(
      globalKey,
      () {
        final node = FocusNode(debugLabel: 'nav_library_$globalKey');
        node.addListener(() {
          if (mounted) {
            setState(() {
              if (node.hasFocus) {
                _focusedLibraryKeys.add(globalKey);
              } else {
                _focusedLibraryKeys.remove(globalKey);
              }
            });
          }
        });
        return node;
      },
    );
  }

  /// Focus the currently selected nav item
  void focusActiveItem() {
    if (widget.selectedLibraryKey != null) {
      // A library is selected - focus that library item
      final node = _libraryFocusNodes[widget.selectedLibraryKey];
      node?.requestFocus();
    } else {
      // Focus main nav item based on selectedIndex
      switch (widget.selectedIndex) {
        case 0:
          _homeFocusNode.requestFocus();
          break;
        case 1:
          _librariesFocusNode.requestFocus();
          break;
        case 2:
          _searchFocusNode.requestFocus();
          break;
        case 3:
          _settingsFocusNode.requestFocus();
          break;
      }
    }
  }

  Future<void> _loadLibraries() async {
    final multiServerProvider = context.read<MultiServerProvider>();

    if (!multiServerProvider.hasConnectedServers) {
      setState(() {
        _isLoadingLibraries = false;
      });
      return;
    }

    try {
      final libraries = await multiServerProvider.aggregationService
          .getLibrariesFromAllServers();

      // Filter out music libraries (not supported)
      var filteredLibraries = libraries
          .where((lib) => lib.type != 'artist')
          .toList();

      // Apply saved library order
      final storage = await StorageService.getInstance();
      final savedOrder = storage.getLibraryOrder();
      if (savedOrder != null && savedOrder.isNotEmpty) {
        final libraryMap = {
          for (var lib in filteredLibraries) lib.globalKey: lib,
        };
        final orderedLibraries = <PlexLibrary>[];
        for (final key in savedOrder) {
          if (libraryMap.containsKey(key)) {
            orderedLibraries.add(libraryMap[key]!);
            libraryMap.remove(key);
          }
        }
        // Add any new libraries not in saved order
        orderedLibraries.addAll(libraryMap.values);
        filteredLibraries = orderedLibraries;
      }

      if (mounted) {
        setState(() {
          _libraries = filteredLibraries;
          _isLoadingLibraries = false;
        });
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
        return Icons.movie_outlined;
      case 'show':
        return Icons.tv_outlined;
      case 'artist':
        return Icons.music_note_outlined;
      case 'photo':
        return Icons.photo_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  IconData _getLibraryIconFilled(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'artist':
        return Icons.music_note;
      case 'photo':
        return Icons.photo;
      default:
        return Icons.folder;
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
    final visibleLibraries = _libraries
        .where((lib) => !hiddenKeys.contains(lib.globalKey))
        .toList();

    // Listen to fullscreen changes for macOS
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        return Container(
          width: 220,
          color: t.surface,
          child: Column(
            children: [
              // Safe area for status bar and macOS traffic lights
              SizedBox(height: _getTopPadding(context)),

              // Navigation content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // Home
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: Translations.of(context).navigation.home,
                      isSelected: widget.selectedIndex == 0,
                      isFocused: _isHomeFocused,
                      onTap: () => widget.onDestinationSelected(0),
                      focusNode: _homeFocusNode,
                    ),

                    const SizedBox(height: 8),

                    // Libraries section
                    _buildLibrariesSection(visibleLibraries, t),

                    const SizedBox(height: 8),

                    // Search
                    _buildNavItem(
                      icon: Icons.search,
                      selectedIcon: Icons.search,
                      label: Translations.of(context).navigation.search,
                      isSelected: widget.selectedIndex == 2,
                      isFocused: _isSearchFocused,
                      onTap: () => widget.onDestinationSelected(2),
                      focusNode: _searchFocusNode,
                    ),

                    const SizedBox(height: 8),

                    // Settings
                    _buildNavItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: Translations.of(context).navigation.settings,
                      isSelected: widget.selectedIndex == 3,
                      isFocused: _isSettingsFocused,
                      onTap: () => widget.onDestinationSelected(3),
                      focusNode: _settingsFocusNode,
                    ),
                  ],
                ),
              ),
            ],
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
    bool autofocus = false,
  }) {
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? t.text.withValues(alpha: 0.1)
                  : isFocused
                      ? t.text.withValues(alpha: 0.08)
                      : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected ? t.text : t.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? t.text : t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrariesSection(List<PlexLibrary> visibleLibraries, dynamic t) {
    final isLibrariesSelected = widget.selectedIndex == 1 && widget.selectedLibraryKey == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Libraries header with expand/collapse
        Focus(
          focusNode: _librariesFocusNode,
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isLibrariesSelected
                      ? t.text.withValues(alpha: 0.1)
                      : _isLibrariesFocused
                          ? t.text.withValues(alpha: 0.08)
                          : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.selectedIndex == 1
                          ? Icons.video_library
                          : Icons.video_library_outlined,
                      size: 22,
                      color: widget.selectedIndex == 1 ? t.text : t.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Translations.of(context).navigation.libraries,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.selectedIndex == 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: widget.selectedIndex == 1 ? t.text : t.textMuted,
                        ),
                      ),
                    ),
                    Icon(
                      _librariesExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: t.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Library items
        if (_librariesExpanded)
          _isLoadingLibraries
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.textMuted,
                      ),
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
    );
  }

  /// Get set of library names that appear more than once (not globally unique)
  Set<String> _getNonUniqueLibraryNames(List<PlexLibrary> libraries) {
    final nameCounts = <String, int>{};
    for (final lib in libraries) {
      nameCounts[lib.title] = (nameCounts[lib.title] ?? 0) + 1;
    }
    return nameCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();
  }

  Widget _buildLibraryItems(List<PlexLibrary> visibleLibraries, dynamic t) {
    // Find which library names are not unique
    final nonUniqueNames = _getNonUniqueLibraryNames(visibleLibraries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleLibraries.map((library) {
        final showServerName =
            nonUniqueNames.contains(library.title) &&
            library.serverName != null;
        return _buildLibraryItem(library, t, showServerName: showServerName);
      }).toList(),
    );
  }

  Widget _buildLibraryItem(
    PlexLibrary library,
    dynamic t, {
    bool showServerName = false,
  }) {
    final isSelected =
        widget.selectedIndex == 1 &&
        widget.selectedLibraryKey == library.globalKey;
    final isFocused = _focusedLibraryKeys.contains(library.globalKey);
    final focusNode = _getLibraryFocusNode(library.globalKey);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey.isSelectKey) {
          widget.onLibrarySelected(library.globalKey);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onLibrarySelected(library.globalKey),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.only(
              left: 28,
              right: 12,
              top: 10,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? t.text.withValues(alpha: 0.1)
                  : isFocused
                      ? t.text.withValues(alpha: 0.08)
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? _getLibraryIconFilled(library.type)
                      : _getLibraryIcon(library.type),
                  size: 18,
                  color: isSelected ? t.text : t.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 32, // Fixed height for consistent item sizing
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          library.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? t.text : t.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showServerName)
                          Text(
                            library.serverName!,
                            style: TextStyle(
                              fontSize: 9,
                              color: t.textMuted.withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
