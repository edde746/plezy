import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/deletion_notifier.dart';
import 'event_aware.dart';

/// Mixin for screens that need to react to deletion events.
///
/// Provides automatic subscription management and filtering based on
/// which items the screen cares about.
///
/// Example usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with DeletionAware {
///   List<PlexMetadata> _items = [];
///
///   @override
///   Set<String>? get deletionRatingKeys =>
///       _items.map((e) => e.ratingKey).toSet();
///
///   @override
///   void onDeletionEvent(DeletionEvent event) {
///     setState(() {
///       _items.removeWhere((e) => e.ratingKey == event.ratingKey);
///     });
///   }
/// }
/// ```
mixin DeletionAware<T extends StatefulWidget> on State<T> {
  StreamSubscription<DeletionEvent>? _deletionSubscription;

  /// Override to scope events to a specific server.
  ///
  /// Return null to receive events from all servers.
  String? get deletionServerId => null;

  /// Override to specify which global keys this screen cares about.
  ///
  /// Use format `serverId:ratingKey`.
  /// Return null to fall back to [deletionRatingKeys] matching.
  Set<String>? get deletionGlobalKeys => null;

  /// Override to specify which ratingKeys this screen cares about.
  ///
  /// Return null to receive ALL events (not recommended for performance).
  /// Return an empty set to receive no events.
  ///
  /// The set should include:
  /// - Direct items displayed (e.g., episode ratingKeys in a season view)
  /// - Parent items that affect display (e.g., show ratingKey for seasons)
  Set<String>? get deletionRatingKeys;

  /// Called when a relevant deletion event occurs.
  ///
  /// Only called if [deletionRatingKeys] is null or contains an affected key.
  void onDeletionEvent(DeletionEvent event);

  @override
  void initState() {
    super.initState();
    _deletionSubscription = subscribeToHierarchicalEvents<DeletionEvent>(
      notifier: DeletionNotifier(),
      mounted: () => mounted,
      serverId: () => deletionServerId,
      globalKeys: () => deletionGlobalKeys,
      ratingKeys: () => deletionRatingKeys,
      onEvent: onDeletionEvent,
    );
  }

  @override
  void dispose() {
    _deletionSubscription?.cancel();
    _deletionSubscription = null;
    super.dispose();
  }
}
