import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../media/media_item.dart';
import '../media/play_queue.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';

/// Builds the fully resident queue used by video-playlist repeat.
///
/// Plex normally uses a server-side, windowed play queue. That is efficient
/// for ordinary playback, but it makes repeat-all fragile for long playlists:
/// queue item IDs are opaque and the first item may no longer be present in the
/// final 50-item window. A [LocalPlayQueue] gives repeat playback a stable,
/// deterministic index zero on both Plex and Jellyfin.
LocalPlayQueue buildRepeatingVideoPlaylistQueue({
  required String playlistContextKey,
  required List<MediaItem> items,
  required bool shuffle,
  int? startIndex,
  Random? random,
}) {
  if (items.isEmpty) {
    throw StateError('Cannot launch an empty video playlist');
  }

  final queueItems = List<MediaItem>.of(items);
  var selectedIndex = startIndex ?? 0;

  if (shuffle) {
    queueItems.shuffle(random);
    selectedIndex = 0;
  } else if (selectedIndex < 0 || selectedIndex >= queueItems.length) {
    throw RangeError.index(selectedIndex, queueItems, 'startIndex');
  }

  // A playlist is server-scoped. Reject an accidental mixed-backend or
  // mixed-server list rather than publishing a queue that cannot be navigated
  // consistently.
  final backendId = queueItems.first.backend.id;
  final serverId = queueItems.first.serverId;
  if (queueItems.any((item) => item.backend.id != backendId)) {
    throw StateError('A repeating playlist cannot mix media backends');
  }
  if (queueItems.any((item) => item.serverId != serverId)) {
    throw StateError('A repeating playlist cannot mix media servers');
  }

  return LocalPlayQueue(
    id: '$backendId:playlist:$playlistContextKey:${Uuid().v4()}',
    items: queueItems,
    currentIndex: selectedIndex,
    backendId: backendId,
    shuffled: shuffle,
  );
}

/// Launches a repeat-enabled video playlist through a fully resident queue.
Future<void> launchRepeatingVideoPlaylist({
  required BuildContext context,
  required String playlistContextKey,
  required List<MediaItem> items,
  required bool shuffle,
  int? startIndex,
  Random? random,
}) async {
  final queue = buildRepeatingVideoPlaylistQueue(
    playlistContextKey: playlistContextKey,
    items: items,
    shuffle: shuffle,
    startIndex: startIndex,
    random: random,
  );

  final playbackState = context.read<PlaybackStateProvider>();
  playbackState.setPlaybackFromLocalQueue(queue, contextKey: playlistContextKey);

  final selectedIndex = queue.currentIndex ?? 0;
  final itemToPlay = queue.items[selectedIndex];
  appLogger.d(
    'Repeating local playlist queue created '
    '(${queue.items.length} items, start: $selectedIndex, '
    'shuffle: ${queue.shuffled})',
  );

  if (!context.mounted) {
    playbackState.clearShuffle();
    return;
  }

  // Preserve the exact queue object. Resolving a watch-state clone here would
  // break identity-based membership and cause VideoPlayerScreen to discard the
  // queue on entry.
  await navigateToVideoPlayer(context, metadata: itemToPlay, resolveWatchState: false);
}
