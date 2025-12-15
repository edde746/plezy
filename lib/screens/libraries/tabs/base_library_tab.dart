import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/plex_library.dart';
import '../../../utils/app_logger.dart';
import '../../../mixins/library_tab_state.dart';
import '../../../mixins/refreshable.dart';
import '../content_state_builder.dart';

/// Base class for library tab screens that provides common state management
/// and lifecycle handling for tabs that display library content.
///
/// Type parameter T: The type of items this tab displays
///
/// Subclasses must implement:
/// - [loadData]: Load data from the Plex API
/// - [buildContent]: Build the UI for displaying loaded items
///
/// Optional overrides:
/// - [emptyIcon]: Icon to show when there are no items
/// - [emptyMessage]: Message to show when there are no items
/// - [errorContext]: Context for error messages (defaults to "content")
/// - [getRefreshStream]: Stream to listen for refresh events
abstract class BaseLibraryTab<T> extends StatefulWidget {
  final PlexLibrary library;
  final String? viewMode;
  final String? density;

  /// Callback invoked when data has finished loading successfully.
  /// Used by parent to trigger focus on the first item.
  final VoidCallback? onDataLoaded;

  /// Whether this tab is currently the active/visible tab.
  /// Used for internal focus management.
  final bool isActive;

  /// Whether to suppress auto-focus when tab becomes active.
  /// Used when navigating via tab bar to keep focus on the tab chips.
  final bool suppressAutoFocus;

  /// Called when the user presses BACK in the tab content.
  /// Used to navigate focus back to the tab bar.
  final VoidCallback? onBack;

  const BaseLibraryTab({
    super.key,
    required this.library,
    this.viewMode,
    this.density,
    this.onDataLoaded,
    this.isActive = false,
    this.suppressAutoFocus = false,
    this.onBack,
  });
}

/// State mixin that provides the common implementation for library tabs
/// This preserves AutomaticKeepAliveClientMixin functionality
abstract class BaseLibraryTabState<T, W extends BaseLibraryTab<T>> extends State<W>
    with AutomaticKeepAliveClientMixin, Refreshable, LibraryTabStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  PlexLibrary get library => widget.library;

  @override
  void refresh() {
    loadItems();
  }

  // State management
  List<T> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<void>? _refreshSubscription;

  // Focus management
  bool _hasLoadedData = false;
  bool _hasFocused = false;

  // Getters for subclasses
  List<T> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedData => _hasLoadedData;

  // Setters for subclasses that override loadItems with custom logic
  @protected
  set items(List<T> value) => _items = value;
  @protected
  set isLoading(bool value) => _isLoading = value;
  @protected
  set errorMessage(String? value) => _errorMessage = value;
  @protected
  set hasLoadedData(bool value) => _hasLoadedData = value;

  @override
  void initState() {
    super.initState();
    loadItems();

    // Subscribe to refresh stream if provided
    final refreshStream = getRefreshStream();
    if (refreshStream != null) {
      _refreshSubscription = refreshStream.listen((_) {
        if (mounted) {
          loadItems();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.globalKey != widget.library.globalKey) {
      // Reset focus state for new library
      _hasFocused = false;
      _hasLoadedData = false;
      // Immediately clear stale data before async load
      setState(() {
        _items = [];
        _isLoading = true;
        _errorMessage = null;
      });
      loadItems();
    }

    // Check if we should focus (became active after data loaded)
    if (widget.isActive && !oldWidget.isActive) {
      tryFocus();
    }
  }

  /// Load items from the API
  /// This is the main data loading function that subclasses must implement
  Future<List<T>> loadData();

  /// Build the content widget given the loaded items
  /// This is called by ContentStateBuilder when items are available
  Widget buildContent(List<T> items);

  /// Icon to display when there are no items (empty state)
  IconData get emptyIcon;

  /// Message to display when there are no items (empty state)
  String get emptyMessage;

  /// Context string for error messages (e.g., "playlists", "collections")
  String get errorContext;

  /// Optional refresh stream to listen for external refresh events
  /// Return null if no refresh stream is needed
  Stream<void>? getRefreshStream() => null;

  /// Try to focus the first item if conditions are met (active + loaded + not yet focused)
  @protected
  void tryFocus() {
    // Don't auto-focus if suppressed (e.g., when navigating via tab bar)
    if (widget.suppressAutoFocus) return;

    if (widget.isActive && _hasLoadedData && !_hasFocused && _items.isNotEmpty) {
      _hasFocused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          focusFirstItem();
        }
      });
    }
  }

  /// Focus the first item in the tab. Subclasses should override this.
  void focusFirstItem() {
    // Default implementation - subclasses should override
  }

  /// Load items with error handling and state management
  Future<void> loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _items = []; // Clear items to prevent showing stale data during load
    });

    try {
      final loadedItems = await loadData();

      if (!mounted) return;

      setState(() {
        _items = loadedItems;
        _isLoading = false;
      });

      // Mark data as loaded and try to focus
      _hasLoadedData = true;
      tryFocus();

      // Notify parent that data has loaded
      if (widget.onDataLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDataLoaded!();
        });
      }
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Error loading $errorContext', error: e);
      setState(() {
        _errorMessage = 'Failed to load $errorContext: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return ContentStateBuilder<T>(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      items: _items,
      emptyIcon: emptyIcon,
      emptyMessage: emptyMessage,
      onRetry: loadItems,
      builder: (items) => RefreshIndicator(onRefresh: loadItems, child: buildContent(items)),
    );
  }
}
