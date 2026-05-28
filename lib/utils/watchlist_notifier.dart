import 'app_logger.dart';
import 'base_notifier.dart';

/// Event representing a change to the account watchlist.
class WatchlistEvent {
  /// Cloud ratingKey of the item that changed.
  final String ratingKey;

  /// True if the item was added, false if removed.
  final bool added;

  WatchlistEvent({required this.ratingKey, required this.added});

  @override
  String toString() => 'WatchlistEvent(${added ? 'added' : 'removed'}, $ratingKey)';
}

/// Notifier for Plex watchlist add/remove changes across the app.
///
/// Singleton mirroring [WatchStateNotifier]. Screens subscribe to refresh when
/// an item is added to or removed from the watchlist from anywhere (detail
/// page, browse context menu, or the Watchlist screen itself).
class WatchlistNotifier extends BaseNotifier<WatchlistEvent> {
  static final WatchlistNotifier _instance = WatchlistNotifier._internal();

  factory WatchlistNotifier() => _instance;

  WatchlistNotifier._internal();

  @override
  void notify(WatchlistEvent event) {
    appLogger.d('WatchlistNotifier: $event');
    super.notify(event);
  }

  void notifyChanged({required String ratingKey, required bool added}) {
    notify(WatchlistEvent(ratingKey: ratingKey, added: added));
  }
}
