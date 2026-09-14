import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../media/media_item.dart';
import '../../providers/playback_state_provider.dart';
import '../../services/episode_navigation_service.dart';
import '../../services/playback_initialization_types.dart';
import 'completion_latch.dart';

/// All mutable state of the player screen's episode vertical: adjacency,
/// loading flags, the Play Next prompt/countdown, the transient-retry budget
/// (#1867), and the end-of-video completion latch.
///
/// The episode analog of [LiveTvSessionState]: one owned home for the
/// vertical's fields, operated on by the episode part extensions. The reload
/// engine touches exactly three groups: it clears the prompt when a new item
/// starts opening, resets adjacency plus the retry budget when a replacement
/// item commits, and records the classified failure reason on a failed
/// reload.
class EpisodeSessionState {
  MediaItem? next;
  MediaItem? previous;

  /// Retryable sentinel until the fire-and-forget initial adjacency load
  /// commits found, boundary, or unavailable.
  QueueNavigationStatus nextStatus = QueueNavigationStatus.failed;

  /// globalKey of the adjacent episode whose playback metadata row was last
  /// prefetched into the API cache.
  String? primedNextGlobalKey;

  bool isResolvingCompletionAdjacency = false;
  bool isLoadingNext = false;
  bool isLoadingPrevious = false;

  bool showPlayNextDialog = false;

  Timer? autoPlayTimer;
  final ValueNotifier<int> autoPlayCountdown = ValueNotifier<int>(5);

  /// Transient episode-transition failure retry (#1867). A failed in-place
  /// reload records the classified reason here so the play-next flow can
  /// distinguish a retryable server blip from a permanent failure. The
  /// retry count resets when a reload succeeds.
  PlaybackFailureReason? lastReloadFailureReason;
  int playNextTransientRetryCount = 0;

  /// End-of-video Play Next latch. Completion comes from the player EOF
  /// signal; position ticks only re-arm once playback is more than 2s from
  /// the end.
  final CompletionLatch completionLatch = CompletionLatch(rearmWindowMs: 2000);

  /// Per-screen adjacency loader with its client-side series cache.
  final EpisodeNavigationService navigation = EpisodeNavigationService();

  void dispose() {
    autoPlayTimer?.cancel();
    autoPlayCountdown.dispose();
  }
}
