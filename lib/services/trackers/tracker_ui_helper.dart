import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../plex_client.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../providers/offline_mode_provider.dart';
import '../../screens/media_detail_screen.dart';
import '../../utils/provider_extensions.dart';
import 'watch_state_overlay.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Navigation helpers — tracker stub → Plex MediaDetailScreen
// ──────────────────────────────────────────────────────────────────────────────

/// Navigates to the show detail screen for a tracker stub episode.
/// Resolves via the active [TrackerStubResolver]; no-op when no resolver is active.
Future<void> navigateToTrackerStubShow(BuildContext context, MediaItem stub,
    {bool isOffline = false}) async {
  final resolver = WatchStateOverlay.instance.stubResolver;
  if (resolver == null) return;
  final client = context.getPlexClientWithFallback(stub.serverId);
  final showItem = await resolver.resolveStubShowForNavigation(stub, client);
  if (!context.mounted) return;
  if (showItem == null) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Could not find this show in your Plex library')));
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MediaDetailScreen(metadata: showItem, isOffline: isOffline)),
  );
}

/// Navigates to the movie detail screen for a tracker stub movie.
/// Resolves via the active [TrackerStubResolver]; no-op when no resolver is active.
Future<void> navigateToTrackerMovieDetail(BuildContext context, MediaItem stub,
    {bool isOffline = false}) async {
  final resolver = WatchStateOverlay.instance.stubResolver;
  if (resolver == null) return;
  final client = context.getPlexClientWithFallback(stub.serverId);
  final movieItem = await resolver.resolveStubMovieForNavigation(stub, client);
  if (!context.mounted) return;
  if (movieItem == null) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Could not find this movie in your Plex library')));
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MediaDetailScreen(metadata: movieItem, isOffline: isOffline)),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Resolution helpers — stub → real Plex MediaItem (for playback)
// ──────────────────────────────────────────────────────────────────────────────

/// Resolves [item] to its effective Plex [MediaItem] for a user-initiated action
/// (mark watched, remove from continue watching, etc.). Use this for mutations.
/// For navigation/playback use [resolveTrackerEpisodeStub] / [resolveTrackerMovieStub] directly.
///
/// Returns [item] unchanged when no active resolver owns it.
/// Returns the resolved item on success.
/// Returns null and shows an error snackbar when resolution fails; callers must
/// check [context].mounted before using a null result.
Future<MediaItem?> resolveTrackerItemForAction(BuildContext context, MediaItem item) async {
  final resolver = WatchStateOverlay.instance.stubResolver;
  if (resolver == null || !resolver.ownsStub(item.id)) return item;
  // Stub resolution requires a live Plex connection — refuse when offline.
  if (context.read<OfflineModeProvider>().isOffline) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Cannot resolve this item while offline')));
    return null;
  }
  final client = context.getPlexClientWithFallback(item.serverId);
  final MediaItem? resolved = item.kind == MediaKind.movie
      ? await resolver.resolveMovieStub(item, client)
      : await resolver.resolveEpisodeStub(item, client);
  if (!context.mounted) return null;
  if (resolved == null) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Could not find this item in your Plex library')));
  }
  return resolved;
}

/// Resolves a tracker stub episode to the real Plex episode [MediaItem].
/// Returns [stub] unchanged when no resolver is active, resolution fails, or offline.
Future<MediaItem> resolveTrackerEpisodeStub(BuildContext context, MediaItem stub) async {
  if (context.read<OfflineModeProvider>().isOffline) return stub;
  final resolver = WatchStateOverlay.instance.stubResolver;
  if (resolver == null || !resolver.ownsStub(stub.id)) return stub;
  final client = context.getPlexClientWithFallback(stub.serverId);
  return resolver.resolveEpisodeStub(stub, client);
}

/// Resolves a tracker stub movie to the real Plex movie [MediaItem].
/// Returns [stub] when no resolver is active or offline; null when the movie was not found.
Future<MediaItem?> resolveTrackerMovieStub(BuildContext context, MediaItem stub) async {
  if (context.read<OfflineModeProvider>().isOffline) return stub;
  final resolver = WatchStateOverlay.instance.stubResolver;
  if (resolver == null || !resolver.ownsStub(stub.id)) return stub;
  final client = context.getPlexClientWithFallback(stub.serverId);
  return resolver.resolveMovieStub(stub, client);
}

// ──────────────────────────────────────────────────────────────────────────────
// Enrichment helpers — populate stub→Plex bridge map in the background
// ──────────────────────────────────────────────────────────────────────────────

/// Searches Plex for tracker stubs not yet in the bridge map and populates it.
/// Safe to call fire-and-forget; concurrent callers wait for the in-progress run.
Future<void> enrichTrackerStubs(
    String? preferredServerId, Map<String, PlexClient> clientMap) async {
  await WatchStateOverlay.instance.stubResolver?.enrichStubs(preferredServerId, clientMap);
}

/// Eagerly resolves episode display positions for Continue Watching cards so
/// the correct S/E label is shown before the user taps anything.
Future<void> resolveTrackerEpisodeDisplayPositions(
    Map<String, PlexClient> clients, String? fallbackServerId) async {
  await WatchStateOverlay.instance.stubResolver
      ?.resolveEpisodeDisplayPositions(clients, fallbackServerId);
}
