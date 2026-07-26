import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../navigation/profile_navigation_scope.dart';
import '../screens/music/album_detail_screen.dart';
import '../screens/music/artist_detail_screen.dart';
import '../screens/music/now_playing_screen.dart';
import '../services/device_performance.dart';
import '../services/music/music_playback_service.dart';
import '../theme/mono_motion.dart';
import '../theme/mono_tokens.dart';
import 'app_logger.dart';
import 'platform_detector.dart';
import 'provider_extensions.dart';

/// Route name of the now-playing screen — the mini-player's route observer
/// suppresses itself while this (or the video player) is in the stack.
const String kNowPlayingRouteName = '/now_playing';

/// Content routes belong on the profile-session navigator. For contexts
/// inside it this is exactly `Navigator.of(context)`; the mini-player overlay
/// sits *above* that navigator (its nearest navigator is the root one), so it
/// resolves the profile navigator through [ProfileNavigationScope] instead.
NavigatorState _contentNavigatorOf(BuildContext context) {
  return ProfileNavigationScope.maybeOf(context)?.navigatorKey.currentState ?? Navigator.of(context);
}

/// Push the artist detail screen for [artist] on the profile navigator.
Future<void> navigateToArtist(BuildContext context, MediaItem artist) async {
  await _contentNavigatorOf(context).push(MaterialPageRoute(builder: (context) => ArtistDetailScreen(artist: artist)));
}

/// Push the album detail screen for [album] on the profile navigator.
Future<void> navigateToAlbum(BuildContext context, MediaItem album) async {
  await _contentNavigatorOf(context).push(MaterialPageRoute(builder: (context) => AlbumDetailScreen(album: album)));
}

/// Push the now-playing screen (slide-up + fade) on the profile navigator.
/// No-op when it is already on top (e.g. TV auto-push while open). Popping
/// it never touches playback — audio continues under the mini-player.
Future<void> openNowPlaying(BuildContext context) async {
  final navigator = _contentNavigatorOf(context);
  if (_isRouteOnTop(navigator, kNowPlayingRouteName)) return;
  final duration = DevicePerformance.reducedDuration(tokens(context).expressive);
  await navigator.push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: kNowPlayingRouteName),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MonoMotion.emphasized,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

bool _isRouteOnTop(NavigatorState navigator, String name) {
  var onTop = false;
  navigator.popUntil((route) {
    if (route.isCurrent) onTop = route.settings.name == name;
    return true; // inspect only — never pops
  });
  return onTop;
}

/// TV has no persistent mini-player, so starting playback lands the user on
/// the now-playing screen directly.
void _autoOpenNowPlayingOnTv(BuildContext context) {
  if (!PlatformDetector.isTV() || !context.mounted) return;
  // A failed start (error surfaced on the service's errors stream) leaves no
  // current track — nothing to show.
  if (context.read<MusicPlaybackService>().currentTrack == null) return;
  openNowPlaying(context).catchError((Object e) {
    appLogger.w('Failed to auto-open now playing', error: e);
  });
}

/// Start playback of [tracks] via the session [MusicPlaybackService].
Future<void> playTracks(
  BuildContext context, {
  required List<MediaItem> tracks,
  MediaItem? startTrack,
  required MusicPlayContext playContext,
  bool shuffle = false,
}) async {
  await context.read<MusicPlaybackService>().playFromList(
    tracks: tracks,
    startTrack: startTrack,
    playContext: playContext,
    shuffle: shuffle,
  );
  if (context.mounted) _autoOpenNowPlayingOnTv(context);
}

/// Fetch a track list with [fetch], then play it — the shape every music
/// entry point that needs a server round-trip before playback repeats:
/// [MusicPlaybackService.beginPlayIntent] → fetch → mounted/intent re-check →
/// [playTracks]. Guarding the round-trip with the intent keeps a slow fetch
/// from replacing a queue the user started later.
///
/// [onError] reports a failed fetch and runs only while the intent is still
/// current and [context] mounted; passing null instead lets the failure
/// propagate to the caller's own error boundary. [onEmpty] handles a
/// successful but empty fetch; passing null hands the empty list to
/// [playTracks] unchanged.
Future<void> playFetchedTracks(
  BuildContext context, {
  required Future<List<MediaItem>> Function() fetch,
  required MusicPlayContext playContext,
  void Function(Object error, StackTrace stackTrace)? onError,
  VoidCallback? onEmpty,
  MediaItem? startTrack,
  bool shuffle = false,
}) async {
  final service = context.read<MusicPlaybackService>();
  final intent = service.beginPlayIntent();
  final List<MediaItem> tracks;
  try {
    tracks = await fetch();
  } catch (error, stackTrace) {
    if (!service.isPlayIntentCurrent(intent)) return;
    if (onError == null) rethrow;
    if (!context.mounted) return;
    onError(error, stackTrace);
    return;
  }
  if (!context.mounted || !service.isPlayIntentCurrent(intent)) return;
  if (tracks.isEmpty && onEmpty != null) {
    onEmpty();
    return;
  }
  await playTracks(context, tracks: tracks, startTrack: startTrack, playContext: playContext, shuffle: shuffle);
}

/// Play [track] within its album queue: fetch the album's tracks and start
/// at [track]. Falls back to single-track playback when the track has no
/// album, isn't found in it, or the album fetch fails.
///
/// Hand-written rather than routed through [playFetchedTracks]: the fallback
/// must play under the *same* intent as the album fetch, so a stale fallback
/// can never supersede a newer request.
Future<void> playTrackWithAlbumContext(BuildContext context, MediaItem track) async {
  final service = context.read<MusicPlaybackService>();
  final intent = service.beginPlayIntent();

  final albumId = track.parentId;
  final client = context.getMediaClientForItemOrNull(track);
  if (albumId != null && client != null) {
    try {
      final tracks = await client.fetchAlbumTracks(albumId);
      final startIndex = tracks.indexWhere((item) => item.id == track.id);
      if (!context.mounted || !service.isPlayIntentCurrent(intent)) return;
      if (startIndex != -1) {
        await playTracks(
          context,
          tracks: tracks,
          startTrack: tracks[startIndex],
          playContext: MusicPlayContext(id: albumId, title: track.albumTitle ?? '', kind: MusicPlayContextKind.album),
        );
        return;
      }
    } catch (e) {
      if (!service.isPlayIntentCurrent(intent)) return;
      appLogger.w('Failed to fetch album context for track ${track.id}; playing single track', error: e);
      if (!context.mounted) return;
    }
  }

  if (!context.mounted || !service.isPlayIntentCurrent(intent)) return;
  await playTracks(
    context,
    tracks: [track],
    playContext: MusicPlayContext(title: track.title ?? '', kind: MusicPlayContextKind.tracks),
  );
}

/// Fetch and play an instant mix seeded from [seed] (track/album/artist).
/// Only call when the seed's server advertises
/// `ServerCapabilities.instantMix`.
Future<void> playInstantMix(BuildContext context, MediaItem seed) async {
  await context.read<MusicPlaybackService>().playInstantMix(seed);
  if (context.mounted) _autoOpenNowPlayingOnTv(context);
}
