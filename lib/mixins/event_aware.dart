import 'dart:async';
import '../utils/base_notifier.dart';
import '../utils/hierarchical_event_mixin.dart';

/// Creates a filtered stream subscription for hierarchical events.
///
/// Used internally by [DeletionAware] and [WatchStateAware] to avoid
/// duplicating the subscription and filtering logic.
StreamSubscription<E> subscribeToHierarchicalEvents<E extends HierarchicalEventMixin>({
  required BaseNotifier<E> notifier,
  required bool Function() mounted,
  required String? Function() serverId,
  required Set<String>? Function() globalKeys,
  required Set<String>? Function() ratingKeys,
  required void Function(E event) onEvent,
}) {
  return notifier.stream.listen((event) {
    if (!mounted()) return;

    final sid = serverId();
    if (sid != null && event.serverId != sid) return;

    final gk = globalKeys();
    if (gk != null) {
      if (event.affectsAnyGlobalKey(gk)) {
        onEvent(event);
      }
      return;
    }

    final rk = ratingKeys();
    if (rk == null || event.affectsAnyOf(rk)) {
      onEvent(event);
    }
  });
}
