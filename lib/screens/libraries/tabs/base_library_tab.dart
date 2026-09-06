import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/library_change_event.dart';
import '../../../media/media_library.dart';
import '../../../utils/error_message_utils.dart';
import '../../../mixins/library_tab_state.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/library_content_notifier.dart';
import '../../../utils/refresh_pacer.dart';
import '../../../providers/libraries_provider.dart';
import '../../../mixins/refreshable.dart';
import '../../video_player_screen.dart';
import '../content_state_builder.dart';

/// Base class for library tab screens that provides common state management
/// and lifecycle handling for tabs that display library content.
///
/// Type parameter T: The type of items this tab displays
///
/// State subclasses must implement:
/// - [BaseLibraryTabState.loadItems]: Load the tab's items, typically by
///   passing a fetch to [BaseLibraryTabState.runLoadTransaction]
/// - [BaseLibraryTabState.buildContent]: Build the UI for displaying loaded items
///
/// Optional overrides:
/// - [emptyIcon]: Icon to show when there are no items
/// - [emptyMessage]: Message to show when there are no items
/// - [errorContext]: Context for error messages (defaults to "content")
/// - [getRefreshStream]: Stream to listen for refresh events
abstract class BaseLibraryTab<T> extends StatefulWidget {
  final MediaLibrary library;
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

/// State base class that provides the common implementation for library tabs.
/// This preserves AutomaticKeepAliveClientMixin functionality.
///
/// [loadItems] is the single load hook. Simple tabs implement it by handing
/// their fetch to [runLoadTransaction], which owns the shared load transaction
/// (generation tracking, localized error mapping, and post-frame
/// [BaseLibraryTab.onDataLoaded] notification). Paginated tabs implement
/// [loadItems] with their own pipeline and report via [markItemsLoaded].
abstract class BaseLibraryTabState<T, W extends BaseLibraryTab<T>> extends State<W>
    with AutomaticKeepAliveClientMixin, Refreshable, LibraryTabStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  MediaLibrary get library => widget.library;

  @override
  void refresh() {
    loadItems();
  }

  // State management
  List<T> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<void>? _refreshSubscription;
  int _loadGeneration = 0;
  StreamSubscription<LibraryChangeEvent>? _liveLibrarySubscription;
  late final RefreshPacer _livePacer;
  bool _inPlaceReload = false;

  /// The effective [TickerMode] notifier this tab listens to for
  /// hidden→visible transitions (a pushed opaque route popping). Rebound
  /// when the ancestor changes; `null` until first bound.
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  /// The library content epoch (see [LibrariesProvider.libraryContentEpoch])
  /// this tab's data was loaded under.
  int _loadedLibraryContentEpoch = 0;

  /// The provider epoch captured when the current load started, so a push
  /// landing mid-fetch is not marked consumed by data that predates it.
  int _libraryContentEpochAtLoadStart = 0;

  // Focus management
  bool _hasLoadedData = false;
  @protected
  bool hasFocused = false;
  bool _hasFocusedChromeFallback = false;

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

  @protected
  int get libraryLoadGeneration => _loadGeneration;

  @protected
  int beginLibraryLoad() {
    snapshotLibraryContentEpoch();
    return ++_loadGeneration;
  }

  @protected
  void invalidateLibraryLoad() {
    _loadGeneration++;
  }

  @protected
  bool isCurrentLibraryLoad(int generation, String libraryGlobalKey) {
    return mounted && generation == _loadGeneration && widget.library.globalKey == libraryGlobalKey;
  }

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

    // Live push refresh (#1646): a server library change targeting this
    // library swaps the visible tab's data in place. Hidden tabs skip it —
    // their activation staleness check owns the reload.
    _livePacer = RefreshPacer(
      debounce: liveRefreshDebounce,
      cooldown: liveRefreshCooldown,
      blockedRetry: liveRefreshBlockedRetry,
      isBlocked: () => isLiveRefreshBlocked || VideoPlayerScreenState.activeGlobalKey != null,
      runPass: _runLiveRefresh,
    );
    _liveLibrarySubscription = LibraryContentNotifier().stream.listen(_onLiveLibraryChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTickerModeNotifier();
  }

  @override
  void activate() {
    super.activate();
    // Reparented: the TickerMode ancestor may have changed.
    _updateTickerModeNotifier();
  }

  @override
  void dispose() {
    invalidateLibraryLoad();
    _refreshSubscription?.cancel();
    _liveLibrarySubscription?.cancel();
    _tickerModeNotifier?.removeListener(_onSurfaceVisibilityChanged);
    _tickerModeNotifier = null;
    _livePacer.dispose();
    super.dispose();
  }

  /// Mirrors [TickerProviderStateMixin]: [TickerMode.getValuesNotifier] reads
  /// the ancestor without registering a dependency, so rebind on the
  /// lifecycle hooks where the ancestor can change.
  void _updateTickerModeNotifier() {
    final notifier = TickerMode.getValuesNotifier(context);
    if (identical(notifier, _tickerModeNotifier)) return;
    _tickerModeNotifier?.removeListener(_onSurfaceVisibilityChanged);
    _tickerModeNotifier = notifier..addListener(_onSurfaceVisibilityChanged);
  }

  /// A push that landed while this tab sat under an opaque route (or behind
  /// another main tab) was dropped by [_onLiveLibraryChange], but the
  /// provider still marked the epoch. Nothing else observes the route pop —
  /// `isActive` never flips — so replay it here through the same paced
  /// in-place path a live event takes. Main-tab activation is already
  /// consumed: [LibrariesScreen.onTabShown] reloads synchronously before the
  /// frame that flips [TickerMode], so the epoch is current by the time this
  /// fires and no second pass is scheduled.
  void _onSurfaceVisibilityChanged() {
    if (!mounted || !_isLiveSurfaceVisible) return;
    if (!_isLibraryContentStale) return;
    _livePacer.schedule();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.globalKey != widget.library.globalKey) {
      invalidateLibraryLoad();
      // Reset focus state for new library
      hasFocused = false;
      _hasFocusedChromeFallback = false;
      _hasLoadedData = false;
      // Immediately clear stale data before async load
      _items = [];
      _isLoading = true;
      _errorMessage = null;
      loadItems();
    } else if (widget.isActive && !oldWidget.isActive) {
      // Became the visible tab again: consume push-marked staleness (#1646).
      // The library-changed branch above already reloads unconditionally.
      refreshIfLibraryContentStale();
    }

    // Check if we should focus (became active after data loaded)
    if (widget.isActive && !oldWidget.isActive) {
      tryFocus();
    }
  }

  /// Tests and isolated subtrees may pump a tab without a [LibrariesProvider].
  LibrariesProvider? _librariesProviderOrNull() {
    try {
      return context.read<LibrariesProvider>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Capture the provider's current epoch at load start. [beginLibraryLoad]
  /// does this for transaction-based tabs; paginated pipelines that bypass it
  /// call this at the top of their load instead.
  @protected
  void snapshotLibraryContentEpoch() {
    final provider = _librariesProviderOrNull();
    if (provider != null) {
      _libraryContentEpochAtLoadStart = provider.libraryContentEpoch(widget.library.globalKey);
    }
  }

  /// Mark the load-start epoch snapshot consumed alongside a successful
  /// commit, so [refreshIfLibraryContentStale] can tell whether a server push
  /// has marked the library since. Deliberately the snapshot, not the current
  /// epoch: a push that landed while the fetch was in flight stays stale.
  /// Subclasses with their own load pipeline call this after committing
  /// fresh data.
  @protected
  void recordLibraryContentEpoch() {
    _loadedLibraryContentEpoch = _libraryContentEpochAtLoadStart;
    // A committed load is as good as a live pass: defer a push event landing
    // moments later to the cooldown's trailing edge.
    _livePacer.notePass();
  }

  /// The provider's current epoch for this library, or `null` without a
  /// [LibrariesProvider] (nothing marks staleness then).
  int? _providerLibraryContentEpoch() {
    return _librariesProviderOrNull()?.libraryContentEpoch(widget.library.globalKey);
  }

  /// Whether a server push marked this library's content since the last
  /// committed load.
  bool get _isLibraryContentStale {
    final epoch = _providerLibraryContentEpoch();
    return epoch != null && epoch != _loadedLibraryContentEpoch;
  }

  /// Reload once when a server push marked this library's content stale since
  /// the last load (#1646). Called when the tab is next shown — never live —
  /// so scroll position and focus are undisturbed while the user is on it.
  void refreshIfLibraryContentStale() {
    if (!mounted) return;
    final epoch = _providerLibraryContentEpoch();
    if (epoch == null || epoch == _loadedLibraryContentEpoch) return;
    _loadedLibraryContentEpoch = epoch;
    _libraryContentEpochAtLoadStart = epoch;
    loadItems();
  }

  /// Pacing for push-driven live refreshes, mirroring [DiscoverProvider]:
  /// merge event bursts, bound the pass frequency during bulk imports, and
  /// retry while [isLiveRefreshBlocked]. Overridable so tests use short
  /// real waits.
  @protected
  Duration get liveRefreshDebounce => const Duration(seconds: 3);
  @protected
  Duration get liveRefreshCooldown => const Duration(minutes: 2);
  @protected
  Duration get liveRefreshBlockedRetry => const Duration(seconds: 15);

  /// True while a live in-place refresh would disturb the user (subclasses
  /// add scrolling/jump state). Playback is checked separately.
  @protected
  bool get isLiveRefreshBlocked => false;

  /// One matcher with the provider's epoch marking so live passes and
  /// activation staleness always agree; the local fallback only serves
  /// harnesses pumped without a [LibrariesProvider].
  bool _eventTargetsLibrary(LibraryChangeEvent event) {
    final provider = _librariesProviderOrNull();
    if (provider != null) return provider.eventTargetsLibrary(event, widget.library);
    final serverId = widget.library.serverId;
    if (serverId == null || event.serverId != serverId) return false;
    return event.libraryIds.isEmpty || event.libraryIds.contains(widget.library.id);
  }

  void _onLiveLibraryChange(LibraryChangeEvent event) {
    if (!mounted || !event.hasChanges || !_eventTargetsLibrary(event)) return;
    // Only the visible tab live-updates. Inactive siblings reload on
    // activation via [refreshIfLibraryContentStale]; an active tab under a
    // route or another main tab replays the drop when [TickerMode] re-enables
    // it ([_onSurfaceVisibilityChanged]) — never fetch invisibly.
    if (!_isLiveSurfaceVisible) return;
    _livePacer.schedule();
  }

  /// Active within the Libraries screen *and* the screen itself is the
  /// visible main tab: [TickerMode] is how MainScreen mutes hidden tab
  /// subtrees, so a grid behind Discover neither fetches nor jumps its
  /// scroll offset invisibly. No ancestor (tests, other hosts) means
  /// visible.
  bool get _isLiveSurfaceVisible => widget.isActive && TickerMode.getValuesNotifier(context).value.enabled;

  bool _runLiveRefresh() {
    if (!mounted || !_isLiveSurfaceVisible) return false;
    unawaited(performLiveLibraryRefresh());
    return true;
  }

  /// Swap this tab's data in place after a server push. The default reloads
  /// through [runLoadTransaction] without clearing, so the old content stays
  /// on screen until the fresh list lands (no spinner, no scroll reset, no
  /// focus churn); a failure keeps the old content silently. Only valid for
  /// tabs whose [loadItems] delegates to [runLoadTransaction] — paginated
  /// pipelines (browse, card grids) override with a sparse repopulate,
  /// because their clearing load would blank the visible grid.
  @protected
  Future<void> performLiveLibraryRefresh() {
    _inPlaceReload = true;
    return loadItems();
  }

  /// Load the tab's items. Typically delegates to [runLoadTransaction].
  Future<void> loadItems();

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
    // On mobile (touch mode), skip auto-focus to prevent ensureVisible()
    // from interfering with TabBarView page animations
    if (!InputModeTracker.isKeyboardMode(context)) return;

    if (!widget.isActive || !_hasLoadedData) return;

    final loadGeneration = _loadGeneration;
    final libraryGlobalKey = widget.library.globalKey;
    if (hasFocusableContent) {
      _hasFocusedChromeFallback = false;
      if (hasFocused) return;
      hasFocused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) {
          focusFirstItem();
        }
      });
      return;
    }

    if (!_hasFocusedChromeFallback) {
      _hasFocusedChromeFallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) {
          focusEmptyState();
        }
      });
    }
  }

  /// Post-load bookkeeping for tabs that replace [loadItems] with their own
  /// (paginated) fetch: mark the tab loaded, take focus if it's due, and let
  /// the parent know once the frame carrying the items is in.
  @protected
  void markItemsLoaded() {
    _hasLoadedData = true;
    recordLibraryContentEpoch();
    tryFocus();
    if (widget.onDataLoaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDataLoaded!();
      });
    }
  }

  /// Whether [focusFirstItem] has a real content target to focus.
  @protected
  bool get hasFocusableContent => _items.isNotEmpty;

  /// Focus content when available, otherwise return to the library chrome.
  void focusContentOrChrome() {
    if (hasFocusableContent) {
      focusFirstItem();
    } else {
      focusEmptyState();
    }
  }

  /// Fallback for empty/error states, where content has no focusable child.
  @protected
  void focusEmptyState() {
    widget.onBack?.call();
  }

  /// Focus the first item in the tab. Subclasses should override this.
  // ignore: no-empty-block - default no-op, subclasses override to focus their first item
  void focusFirstItem() {}

  /// Shared load transaction: generation tracking, localized error mapping,
  /// and post-frame [BaseLibraryTab.onDataLoaded] notification.
  ///
  /// When entered through [performLiveLibraryRefresh] the pass is in-place:
  /// the old items stay rendered while the fetch runs (no spinner), and a
  /// failure keeps them silently instead of swapping in an error state.
  @protected
  Future<void> runLoadTransaction(Future<List<T>> Function() fetch) async {
    if (!mounted) return;
    final inPlace = _inPlaceReload && hasFocusableContent;
    _inPlaceReload = false;
    final loadGeneration = beginLibraryLoad();
    final libraryGlobalKey = widget.library.globalKey;

    if (!inPlace) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _items = []; // Clear items to prevent showing stale data during load
      });
    }

    try {
      final loadedItems = await fetch();
      if (!isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) return;
      final focusedBeforeCommit = FocusManager.instance.primaryFocus;
      final contentOwnedFocus =
          focusedBeforeCommit?.context?.findAncestorStateOfType<BaseLibraryTabState<T, W>>() == this;

      setState(() {
        _items = loadedItems;
        _isLoading = false;
        _hasLoadedData = true;
      });
      recordLibraryContentEpoch();
      // A populated live pass is not a tab-entry focus handoff. In particular,
      // its completion must not reclaim focus from chrome or a covering route.
      if (!inPlace) tryFocus();
      if (inPlace && !hasFocusableContent && contentOwnedFocus && _isLiveSurfaceVisible) {
        // Only an emptied, actively focused surface hands back to its chrome.
        // A menu, route, or sidebar that already owns focus remains untouched.
        focusEmptyState();
      }

      final onDataLoaded = widget.onDataLoaded;
      if (!inPlace && onDataLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) {
            onDataLoaded();
          }
        });
      }
    } catch (e, stackTrace) {
      if (!isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) return;
      if (inPlace) {
        // Best-effort background refresh: keep the visible content.
        appLogger.d('Live library refresh failed for ${widget.library.globalKey}', error: e);
        return;
      }
      final message = localizedLoadErrorMessage(e, stackTrace, context: errorContext);
      if (!isCurrentLibraryLoad(loadGeneration, libraryGlobalKey)) return;

      setState(() {
        _errorMessage = message;
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
