import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'app_menu.dart';
import 'overlay_sheet.dart';

/// A menu action item for context menus
class ContextMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final bool requiresConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.requiresConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
    this.isDestructive = false,
  });
}

/// Shows the manage/reorder-libraries sheet (dialog on TV, overlay sheet
/// otherwise). Reorder and hide/unhide are provider-backed, so any screen can
/// open it.
///
/// [onOrderChanged] runs after the new order is written to
/// [LibrariesProvider] (the libraries screen uses it to poke MainScreen's
/// side nav). [onToggleVisibility] overrides the default plain hide/unhide
/// (the libraries screen adds "re-select first visible library" logic).
Future<void> showLibraryManagementSheet(
  BuildContext context, {
  VoidCallback? onOrderChanged,
  Future<void> Function(MediaLibrary library)? onToggleVisibility,
}) {
  final librariesProvider = context.read<LibrariesProvider>();
  final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
  final allLibraries = librariesProvider.libraries;

  Future<void> defaultToggleVisibility(MediaLibrary library) async {
    final isHidden = hiddenLibrariesProvider.hiddenLibraryKeys.contains(library.globalKey);
    if (isHidden) {
      await hiddenLibrariesProvider.unhideLibrary(library.globalKey);
    } else {
      await hiddenLibrariesProvider.hideLibrary(library.globalKey);
    }
  }

  Widget buildSheet({required bool isDialog}) => _LibraryManagementSheet(
    isDialog: isDialog,
    allLibraries: List.from(allLibraries),
    hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
    onReorder: (reorderedLibraries) {
      librariesProvider.updateLibraryOrder(reorderedLibraries);
      onOrderChanged?.call();
    },
    onToggleVisibility: onToggleVisibility ?? defaultToggleVisibility,
    getLibraryMenuItems: _getLibraryMenuItems,
    onLibraryMenuAction: (action, library) => _handleLibraryMenuAction(context, action, library),
  );

  if (PlatformDetector.isTV()) {
    return showScopedDialog<void>(context: context, builder: (context) => buildSheet(isDialog: true));
  }
  // showAdaptive rather than of(context).show: on mobile, settings is a pushed
  // route outside the OverlaySheetHost subtree, so only the fallback path is
  // available there. isScrollControlled keeps the fallback modal from capping
  // the sheet at ~9/16 of the screen.
  return OverlaySheetController.showAdaptive<void>(
    context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => buildSheet(isDialog: false),
  );
}

List<ContextMenuItem> _getLibraryMenuItems(MediaLibrary library) {
  // Refresh metadata is the only admin action both backends support — Plex
  // hits `/library/sections/{id}/refresh?force=1`, Jellyfin posts to
  // `/Items/{id}/Refresh` (the library view is itself an item).
  final refresh = ContextMenuItem(
    value: 'refresh',
    icon: Symbols.sync_rounded,
    label: t.libraries.refreshMetadata,
    requiresConfirmation: true,
    confirmationTitle: t.libraries.refreshMetadata,
    confirmationMessage: t.libraries.refreshMetadataConfirm(title: library.title),
    isDestructive: true,
  );
  // Scan / analyze / empty trash hit Plex-only endpoints. Gating them keeps
  // [getPlexClientForLibrary] from falling back through `_resolveClient` to
  // the first online Plex server and firing the action against the wrong
  // backend.
  if (library.backend != MediaBackend.plex) return [refresh];
  return [
    ContextMenuItem(
      value: 'scan',
      icon: Symbols.refresh_rounded,
      label: t.libraries.scanLibraryFiles,
      requiresConfirmation: true,
      confirmationTitle: t.libraries.scanLibrary,
      confirmationMessage: t.libraries.scanLibraryConfirm(title: library.title),
    ),
    ContextMenuItem(
      value: 'analyze',
      icon: Symbols.analytics_rounded,
      label: t.libraries.analyze,
      requiresConfirmation: true,
      confirmationTitle: t.libraries.analyzeLibrary,
      confirmationMessage: t.libraries.analyzeLibraryConfirm(title: library.title),
    ),
    refresh,
    ContextMenuItem(
      value: 'empty_trash',
      icon: Symbols.delete_outline_rounded,
      label: t.libraries.emptyTrash,
      requiresConfirmation: true,
      confirmationTitle: t.libraries.emptyTrash,
      confirmationMessage: t.libraries.emptyTrashConfirm(title: library.title),
      isDestructive: true,
    ),
  ];
}

Future<void> _handleLibraryMenuAction(BuildContext context, String action, MediaLibrary library) async {
  // Find the menu item for confirmation details
  final menuItems = _getLibraryMenuItems(library);
  final item = menuItems.where((i) => i.value == action).firstOrNull;
  if (item == null) return;

  if (item.requiresConfirmation) {
    final confirmed = await showConfirmDialog(
      context,
      title: item.confirmationTitle ?? t.dialog.confirmAction,
      message: item.confirmationMessage ?? t.libraries.confirmActionMessage,
      confirmText: t.common.confirm,
      isDestructive: item.isDestructive,
    );
    if (!confirmed || !context.mounted) return;
  }

  switch (action) {
    case 'scan':
      unawaited(_scanLibrary(context, library));
      break;
    case 'analyze':
      unawaited(_analyzeLibrary(context, library));
      break;
    case 'refresh':
      unawaited(_refreshLibraryMetadata(context, library));
      break;
    case 'empty_trash':
      unawaited(_emptyLibraryTrash(context, library));
      break;
  }
}

Future<void> _performLibraryAction(
  BuildContext context, {
  required MediaLibrary library,
  required Future<void> Function(PlexClient client) action,
  required String progressMessage,
  required String successMessage,
  required String Function(Object error) failureMessage,
}) async {
  try {
    final client = context.getPlexClientForLibrary(library);

    if (context.mounted) {
      showAppSnackBar(context, progressMessage, duration: const Duration(seconds: 2));
    }

    await action(client);

    if (context.mounted) {
      showSuccessSnackBar(context, successMessage);
    }
  } catch (e) {
    appLogger.e('Library action failed', error: e);
    if (context.mounted) {
      showErrorSnackBar(context, failureMessage(e));
    }
  }
}

/// Backend-neutral counterpart to [_performLibraryAction] for ops that exist
/// on the [MediaServerClient] interface (currently just refresh metadata).
/// Resolves the client through `getMediaClientForLibrary` so a Jellyfin
/// library is routed to its own server, not a fallback Plex one.
Future<void> _performMediaLibraryAction(
  BuildContext context, {
  required MediaLibrary library,
  required Future<void> Function(MediaServerClient client) action,
  required String progressMessage,
  required String successMessage,
  required String Function(Object error) failureMessage,
}) async {
  try {
    final client = context.getMediaClientForLibrary(library);

    if (context.mounted) {
      showAppSnackBar(context, progressMessage, duration: const Duration(seconds: 2));
    }

    await action(client);

    if (context.mounted) {
      showSuccessSnackBar(context, successMessage);
    }
  } catch (e) {
    appLogger.e('Library action failed', error: e);
    if (context.mounted) {
      showErrorSnackBar(context, failureMessage(e));
    }
  }
}

Future<void> _scanLibrary(BuildContext context, MediaLibrary library) {
  return _performLibraryAction(
    context,
    library: library,
    action: (client) => client.scanLibrary(library.id),
    progressMessage: t.messages.libraryScanning(title: library.title),
    successMessage: t.messages.libraryScanStarted(title: library.title),
    failureMessage: (error) => t.messages.libraryScanFailed(error: error.toString()),
  );
}

Future<void> _refreshLibraryMetadata(BuildContext context, MediaLibrary library) {
  return _performMediaLibraryAction(
    context,
    library: library,
    action: (client) => client.refreshLibraryMetadata(library.id),
    progressMessage: t.messages.metadataRefreshing(title: library.title),
    successMessage: t.messages.metadataRefreshStarted(title: library.title),
    failureMessage: (error) => t.messages.metadataRefreshFailed(error: error.toString()),
  );
}

Future<void> _emptyLibraryTrash(BuildContext context, MediaLibrary library) {
  return _performLibraryAction(
    context,
    library: library,
    action: (client) => client.emptyLibraryTrash(library.id),
    progressMessage: t.libraries.emptyingTrash(title: library.title),
    successMessage: t.libraries.trashEmptied(title: library.title),
    failureMessage: (error) => t.libraries.failedToEmptyTrash(error: error),
  );
}

Future<void> _analyzeLibrary(BuildContext context, MediaLibrary library) {
  return _performLibraryAction(
    context,
    library: library,
    action: (client) => client.analyzeLibrary(library.id),
    progressMessage: t.libraries.analyzing(title: library.title),
    successMessage: t.libraries.analysisStarted(title: library.title),
    failureMessage: (error) => t.libraries.failedToAnalyze(error: error),
  );
}

class _LibraryManagementSheet extends StatefulWidget {
  final bool isDialog;
  final List<MediaLibrary> allLibraries;
  final Set<String> hiddenLibraryKeys;
  final Function(List<MediaLibrary>) onReorder;
  final Function(MediaLibrary) onToggleVisibility;
  final List<ContextMenuItem> Function(MediaLibrary) getLibraryMenuItems;
  final void Function(String action, MediaLibrary library) onLibraryMenuAction;

  const _LibraryManagementSheet({
    this.isDialog = false,
    required this.allLibraries,
    required this.hiddenLibraryKeys,
    required this.onReorder,
    required this.onToggleVisibility,
    required this.getLibraryMenuItems,
    required this.onLibraryMenuAction,
  });

  @override
  State<_LibraryManagementSheet> createState() => _LibraryManagementSheetState();
}

class _LibraryManagementSheetState extends State<_LibraryManagementSheet> {
  late List<MediaLibrary> _tempLibraries;

  // Keyboard navigation state
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0 = row, 1 = visibility button, 2 = options button
  int? _movingIndex; // Non-null when in move mode
  int? _originalIndex; // Original position before move (for cancel)
  List<MediaLibrary>? _originalOrder; // Original order before move (for cancel)
  final FocusNode _listFocusNode = FocusNode();
  final ScrollController _dialogScrollController = ScrollController();
  bool _backKeyDownSeen = false;

  @override
  void initState() {
    super.initState();
    _tempLibraries = List.from(widget.allLibraries);
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    _dialogScrollController.dispose();
    super.dispose();
  }

  void _ensureFocusedVisible() {
    if (!widget.isDialog) return;
    if (!_dialogScrollController.hasClients) return;

    const double itemHeight = 72.0; // Material ListTile with subtitle
    const double listTopPadding = 8.0;
    final double targetTop = listTopPadding + (_focusedIndex * itemHeight);
    final double targetBottom = targetTop + itemHeight;

    final double viewportTop = _dialogScrollController.offset;
    final double viewportHeight = _dialogScrollController.position.viewportDimension;
    final double viewportBottom = viewportTop + viewportHeight;

    // Already fully visible — skip
    if (targetTop >= viewportTop && targetBottom <= viewportBottom) return;

    // Place item at ~25% from top of viewport
    final double destination = (targetTop - viewportHeight * 0.25).clamp(
      0.0,
      _dialogScrollController.position.maxScrollExtent,
    );

    _dialogScrollController.animateTo(destination, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    // Track back key down/up pairing. If focus was elsewhere during KeyDown
    // (e.g., on a bottom sheet) and returns here before KeyUp, we get a stray
    // KeyUp that would incorrectly pop the dialog. Consume it instead.
    if (key.isBackKey) {
      if (event is KeyDownEvent) {
        _backKeyDownSeen = true;
      } else if (event is KeyUpEvent && !_backKeyDownSeen) {
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent) {
        _backKeyDownSeen = false;
      }
    }

    final backResult = handleBackKeyAction(event, () {
      if (_movingIndex != null) {
        // Cancel move - restore original position
        setState(() {
          if (_originalOrder != null) {
            _tempLibraries = List.from(_originalOrder!);
          }
          _focusedIndex = _originalIndex ?? 0;
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
      } else {
        OverlaySheetController.popAdaptive(context);
      }
    });
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    if (_movingIndex != null) {
      // Move mode - arrows reorder the item
      if (key.isUpKey && _movingIndex! > 0) {
        setState(() {
          final item = _tempLibraries.removeAt(_movingIndex!);
          _tempLibraries.insert(_movingIndex! - 1, item);
          _movingIndex = _movingIndex! - 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _movingIndex! < _tempLibraries.length - 1) {
        setState(() {
          final item = _tempLibraries.removeAt(_movingIndex!);
          _tempLibraries.insert(_movingIndex! + 1, item);
          _movingIndex = _movingIndex! + 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        // Confirm move - apply the reorder
        widget.onReorder(_tempLibraries);
        setState(() {
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
        return KeyEventResult.handled;
      }
    } else {
      // Navigation mode
      if (key.isUpKey && _focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
          _focusedColumn = 0; // Reset to row when changing rows
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _focusedIndex < _tempLibraries.length - 1) {
        setState(() {
          _focusedIndex++;
          _focusedColumn = 0; // Reset to row when changing rows
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isLeftKey && _focusedColumn > 0) {
        setState(() => _focusedColumn--);
        return KeyEventResult.handled;
      }
      if (key.isRightKey && _focusedColumn < 2) {
        setState(() => _focusedColumn++);
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        if (_focusedColumn == 0) {
          // Enter move mode
          setState(() {
            _movingIndex = _focusedIndex;
            _originalIndex = _focusedIndex;
            _originalOrder = List.from(_tempLibraries);
          });
        } else if (_focusedColumn == 1) {
          // Toggle visibility
          final library = _tempLibraries[_focusedIndex];
          widget.onToggleVisibility(library);
        } else if (_focusedColumn == 2) {
          // Show options menu
          final library = _tempLibraries[_focusedIndex];
          _showLibraryMenuBottomSheet(context, library);
        }
        return KeyEventResult.handled;
      }
    }

    // Block d-pad keys at boundaries so focus doesn't escape the dialog
    if (key.isDpadDirection) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _reorderLibraries(int oldIndex, int newIndex) {
    setState(() {
      final library = _tempLibraries.removeAt(oldIndex);
      _tempLibraries.insert(newIndex, library);
    });
    // Apply immediately
    widget.onReorder(_tempLibraries);
  }

  void _showLibraryMenuBottomSheet(BuildContext outerContext, MediaLibrary library) {
    final menuItems = widget.getLibraryMenuItems(library);
    OverlaySheetController.pushAdaptive<String>(
      outerContext,
      builder: (context) => AppMenuSheet<String>(
        title: library.title,
        entries: [
          for (final item in menuItems)
            AppMenuItem<String>(value: item.value, icon: item.icon, label: item.label, destructive: item.isDestructive),
        ],
        onSelected: (value) => widget.onLibraryMenuAction(value, library),
      ),
    );
  }

  /// Whether the libraries span more than one connected server.
  bool _hasMultipleServers() {
    final serverIds = _tempLibraries.where((lib) => lib.serverId != null).map((lib) => lib.serverId).toSet();
    return serverIds.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild when hidden libraries change
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenLibraryKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    if (widget.isDialog) {
      return Dialog(
        child: PopScope(
          canPop: false, // Prevent system back from double-popping; handled by _handleKeyEvent
          // ignore: no-empty-block - required callback, blocks system back on Android TV
          onPopInvokedWithResult: (didPop, result) {},
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const AppIcon(Symbols.edit_rounded, fill: 1),
                  const SizedBox(width: 12),
                  Text(t.libraries.manageLibraries),
                ],
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const AppIcon(Symbols.close_rounded, fill: 1),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: Focus(
              focusNode: _listFocusNode,
              autofocus: InputModeTracker.isKeyboardMode(context),
              onKeyEvent: _handleKeyEvent,
              child: _buildFlatLibraryListDialog(hiddenLibraryKeys),
            ),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  const AppIcon(Symbols.edit_rounded, fill: 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t.libraries.manageLibraries, style: const TextStyle(fontSize: 20, fontWeight: .bold)),
                  ),
                  IconButton(
                    icon: const AppIcon(Symbols.close_rounded, fill: 1),
                    onPressed: () => OverlaySheetController.popAdaptive(context),
                  ),
                ],
              ),
            ),

            // Library list (grouped by server if multiple servers)
            Expanded(
              child: Focus(
                focusNode: _listFocusNode,
                autofocus: InputModeTracker.isKeyboardMode(context),
                onKeyEvent: _handleKeyEvent,
                child: _buildFlatLibraryList(scrollController, hiddenLibraryKeys),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build library list for dialog (TV) using ListView with scroll-into-view support
  Widget _buildFlatLibraryListDialog(Set<String> hiddenLibraryKeys) {
    final showServerNames = _hasMultipleServers();
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return ReorderableListView.builder(
      scrollController: _dialogScrollController,
      onReorderItem: _reorderLibraries,
      itemCount: _tempLibraries.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final library = _tempLibraries[index];
        final showServerName = showServerNames && library.serverName != null;
        final isFocused = isKeyboardMode && index == _focusedIndex;
        final isMoving = index == _movingIndex;

        return _buildLibraryTile(
          library,
          index,
          hiddenLibraryKeys,
          showServerName: showServerName,
          isFocused: isFocused,
          isMoving: isMoving,
          focusedColumn: isFocused ? _focusedColumn : null,
        );
      },
    );
  }

  /// Build flat library list with a server subtitle when multiple servers are connected
  Widget _buildFlatLibraryList(ScrollController scrollController, Set<String> hiddenLibraryKeys) {
    final showServerNames = _hasMultipleServers();
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return ReorderableListView.builder(
      scrollController: scrollController,
      onReorderItem: _reorderLibraries,
      itemCount: _tempLibraries.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final library = _tempLibraries[index];
        final showServerName = showServerNames && library.serverName != null;
        final isFocused = isKeyboardMode && index == _focusedIndex;
        final isMoving = index == _movingIndex;
        return _buildLibraryTile(
          library,
          index,
          hiddenLibraryKeys,
          showServerName: showServerName,
          isFocused: isFocused,
          isMoving: isMoving,
          focusedColumn: isFocused ? _focusedColumn : null,
        );
      },
    );
  }

  /// Build a single library tile
  Widget _buildLibraryTile(
    MediaLibrary library,
    int index,
    Set<String> hiddenLibraryKeys, {
    bool showServerName = false,
    bool isFocused = false,
    bool isMoving = false,
    int? focusedColumn,
  }) {
    final isHidden = hiddenLibraryKeys.contains(library.globalKey);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine background color based on state
    Color? tileColor;
    if (isMoving) {
      tileColor = colorScheme.primaryContainer;
    } else if (isFocused && focusedColumn == 0) {
      // Only highlight row when row itself is focused (column 0)
      tileColor = colorScheme.surfaceContainerHighest;
    }

    // Button focus states
    final isVisibilityButtonFocused = isFocused && focusedColumn == 1;
    final isOptionsButtonFocused = isFocused && focusedColumn == 2;

    return Opacity(
      key: ValueKey(library.globalKey),
      opacity: isHidden ? 0.5 : 1.0,
      child: ListTile(
        tileColor: tileColor,
        leading: Row(
          mainAxisSize: .min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: AppIcon(
                isMoving ? Symbols.swap_vert_rounded : Symbols.drag_indicator_rounded,
                fill: 1,
                color: isMoving ? colorScheme.primary : IconTheme.of(context).color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            AppIcon(ContentTypeHelper.getLibraryIcon(library.kind.id), fill: 1),
          ],
        ),
        title: Text(library.title),
        subtitle: showServerName
            ? Text(
                library.serverName!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: .min,
          children: [
            Container(
              decoration: FocusTheme.focusBackgroundDecoration(isFocused: isVisibilityButtonFocused, borderRadius: 20),
              child: IconButton(
                icon: AppIcon(isHidden ? Symbols.visibility_off_rounded : Symbols.visibility_rounded, fill: 1),
                tooltip: isHidden ? t.libraries.showLibrary : t.libraries.hideLibrary,
                onPressed: () => widget.onToggleVisibility(library),
              ),
            ),
            Container(
              decoration: FocusTheme.focusBackgroundDecoration(isFocused: isOptionsButtonFocused, borderRadius: 20),
              child: IconButton(
                icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                tooltip: t.libraries.libraryOptions,
                onPressed: () => _showLibraryMenuBottomSheet(context, library),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
