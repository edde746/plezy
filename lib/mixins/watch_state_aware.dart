import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/watch_state_notifier.dart';
import 'event_aware.dart';

/// Mixin for screens that need to react to watch state changes.
///
/// Provides automatic subscription management and filtering based on
/// which items the screen cares about.
///
/// Example usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with WatchStateAware {
///   List<PlexMetadata> _items = [];
///
///   @override
///   Set<String>? get watchedRatingKeys =>
///       _items.map((e) => e.ratingKey).toSet();
///
///   @override
///   void onWatchStateChanged(WatchStateEvent event) {
///     // Refresh affected item
///     _refreshItem(event.ratingKey);
///   }
/// }
/// ```
mixin WatchStateAware<T extends StatefulWidget> on State<T> {
  StreamSubscription<WatchStateEvent>? _watchStateSubscription;

  /// Override to scope events to a specific server.
  ///
  /// Return null to receive events from all servers.
  String? get watchStateServerId => null;

  /// Override to specify which global keys this screen cares about.
  ///
  /// Use format `serverId:ratingKey`.
  /// Return null to fall back to [watchedRatingKeys] matching.
  Set<String>? get watchedGlobalKeys => null;

  /// Override to specify which ratingKeys this screen cares about.
  ///
  /// Return null to receive ALL events (not recommended for performance).
  /// Return an empty set to receive no events.
  ///
  /// The set should include:
  /// - Direct items displayed (e.g., episode ratingKeys in a season view)
  /// - Parent items that affect display (e.g., show ratingKey for on-deck)
  Set<String>? get watchedRatingKeys;

  /// Called when a relevant watch state change occurs.
  ///
  /// Only called if [watchedRatingKeys] is null or contains an affected key.
  void onWatchStateChanged(WatchStateEvent event);

  @override
  void initState() {
    super.initState();
    _watchStateSubscription = subscribeToHierarchicalEvents<WatchStateEvent>(
      notifier: WatchStateNotifier(),
      mounted: () => mounted,
      serverId: () => watchStateServerId,
      globalKeys: () => watchedGlobalKeys,
      ratingKeys: () => watchedRatingKeys,
      onEvent: onWatchStateChanged,
    );
  }

  @override
  void dispose() {
    _watchStateSubscription?.cancel();
    _watchStateSubscription = null;
    super.dispose();
  }
}
