import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/watch_state_notifier.dart';
import 'trackers/tracker_coordinator.dart';

enum WatchMarkOutcome {
  /// Queued for later sync (offline). The offline provider emitted the event.
  queuedOffline,

  /// Marked on the server; event emitted, trackers fired.
  marked,

  /// Nothing to do (no server id / no bound client).
  skipped,
}

/// Orchestrates watched/unwatched marks: routes offline marks to the offline
/// queue, online marks to the backend client, emits the single
/// [WatchStateNotifier] event, and fires trackers. UI surfaces call this
/// instead of hand-rolling the offline/online + tracker dance; snackbars and
/// refresh callbacks stay with the caller. Client `markWatched`/`markUnwatched`
/// are transport-only — they must never be called directly from UI code.
class WatchActions {
  WatchActions._();

  /// Marks [item] watched/unwatched. [offline] overrides the
  /// [OfflineModeProvider] read for callers that already know (e.g. screens
  /// rendering downloaded content).
  static Future<WatchMarkOutcome> setWatched(
    BuildContext context,
    MediaItem item, {
    required bool watched,
    bool? offline,
  }) async {
    final isOffline = offline ?? context.read<OfflineModeProvider>().isOffline;
    final serverId = item.serverId;

    if (isOffline && serverId != null) {
      final offlineWatch = context.read<OfflineWatchProvider>();
      if (watched) {
        await offlineWatch.markAsWatched(serverId: ServerId(serverId), itemId: item.id);
      } else {
        await offlineWatch.markAsUnwatched(serverId: ServerId(serverId), itemId: item.id);
      }
      return WatchMarkOutcome.queuedOffline;
    }

    if (serverId == null) return WatchMarkOutcome.skipped;
    final client = context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) return WatchMarkOutcome.skipped;

    if (watched) {
      await client.markWatched(item);
    } else {
      await client.markUnwatched(item);
    }
    WatchStateNotifier().notifyWatched(item: item, isNowWatched: watched, cacheServerId: client.cacheServerId);
    unawaited(
      watched
          ? TrackerCoordinator.instance.markWatched(item, client)
          : TrackerCoordinator.instance.markUnwatched(item, client),
    );
    return WatchMarkOutcome.marked;
  }

  /// Removes [item] from Continue Watching without touching watch state.
  /// Throws when no client is bound for the item's server (mirrors the
  /// pre-existing menu behaviour so callers surface an error snackbar).
  static Future<void> removeFromContinueWatching(BuildContext context, MediaItem item) async {
    final client = context.getMediaClientForServer(ServerId(item.serverId!));
    await client.removeFromContinueWatching(item);
    WatchStateNotifier().notifyRemovedFromContinueWatching(item: item);
  }
}
