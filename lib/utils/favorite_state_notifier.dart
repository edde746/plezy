import '../media/ids.dart';
import '../media/media_item.dart';
import 'app_logger.dart';
import 'base_notifier.dart';
import 'global_key_utils.dart';

class FavoriteStateEvent {
  final String itemId;
  final String globalKey;
  final ServerId serverId;
  final String cacheServerId;
  final bool isFavorite;

  FavoriteStateEvent({
    required this.itemId,
    required this.serverId,
    required this.cacheServerId,
    required this.isFavorite,
  }) : globalKey = buildGlobalKey(serverId, itemId);

  String get stateKey => cacheServerId.isNotEmpty && cacheServerId != serverId.value
      ? buildGlobalKey(ServerId(cacheServerId), itemId)
      : globalKey;

  @override
  String toString() => 'FavoriteStateEvent($globalKey, isFavorite: $isFavorite)';
}

/// Session-wide favorite updates for server-backed media.
///
/// The server remains authoritative, while this notifier bridges the interval
/// before lists are fetched again. It also survives the detail route being
/// dismissed while a favorite request is still in flight.
class FavoriteStateNotifier extends BaseNotifier<FavoriteStateEvent> {
  static final FavoriteStateNotifier _instance = FavoriteStateNotifier._internal();

  factory FavoriteStateNotifier() => _instance;

  FavoriteStateNotifier._internal();

  void notifyFavorite({required MediaItem item, required String cacheServerId, required bool isFavorite}) {
    final serverId = serverIdOrNull(item.serverId);
    if (serverId == null) {
      appLogger.w('FavoriteStateNotifier: missing serverId for ${item.id}, skipping favorite event');
      return;
    }
    final event = FavoriteStateEvent(
      itemId: item.id,
      serverId: serverId,
      cacheServerId: cacheServerId,
      isFavorite: isFavorite,
    );
    appLogger.d('FavoriteStateNotifier: $event');
    notify(event);
  }
}
