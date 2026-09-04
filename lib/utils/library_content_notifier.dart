import '../media/library_change_event.dart';
import 'base_notifier.dart';

/// App-global fan-out for server push notifications about library content
/// (#1646). [LibraryEventService] publishes one coalesced event per server
/// change burst; profile-scoped consumers ([DiscoverProvider] today) subscribe
/// through [stream] and refetch their own views.
///
/// Same singleton shape as [LibraryRefreshNotifier] / [WatchStateNotifier].
class LibraryContentNotifier extends BaseNotifier<LibraryChangeEvent> {
  static final LibraryContentNotifier _instance = LibraryContentNotifier._internal();

  factory LibraryContentNotifier() => _instance;

  LibraryContentNotifier._internal();

  void notifyChanged(LibraryChangeEvent event) => notify(event);
}
