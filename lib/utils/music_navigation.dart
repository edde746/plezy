import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
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
import 'snackbar_helper.dart';

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

/// True when a real music playback engine is bound. On the stub this shows
/// the standard "not supported yet" notice and returns false — check it
/// BEFORE fetching tracks so the stub never costs a server round-trip.
bool ensureMusicPlaybackAvailable(BuildContext context) {
  if (context.read<MusicPlaybackService>().isAvailable) return true;
  showAppSnackBar(context, t.messages.musicNotSupported);
  return false;
}

/// Start playback of [tracks] via the session [MusicPlaybackService],
/// surfacing the "not supported yet" notice while the stub is bound.
Future<void> playTracks(
  BuildContext context, {
  required List<MediaItem> tracks,
  MediaItem? startTrack,
  required MusicPlayContext playContext,
  bool shuffle = false,
}) async {
  if (!ensureMusicPlaybackAvailable(context)) return;
  await context.read<MusicPlaybackService>().playFromList(
    tracks: tracks,
    startTrack: startTrack,
    playContext: playContext,
    shuffle: shuffle,
  );
  if (context.mounted) _autoOpenNowPlayingOnTv(context);
}

/// Play [track] within its album queue: fetch the album's tracks and start
/// at [track]. Falls back to single-track playback when the track has no
/// album, isn't found in it, or the album fetch fails.
Future<void> playTrackWithAlbumContext(BuildContext context, MediaItem track) async {
  if (!ensureMusicPlaybackAvailable(context)) return;

  final albumId = track.parentId;
  final client = context.getMediaClientForItemOrNull(track);
  if (albumId != null && client != null) {
    try {
      final tracks = await client.fetchAlbumTracks(albumId);
      final startIndex = tracks.indexWhere((item) => item.id == track.id);
      if (!context.mounted) return;
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
      appLogger.w('Failed to fetch album context for track ${track.id}; playing single track', error: e);
      if (!context.mounted) return;
    }
  }

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
  if (!ensureMusicPlaybackAvailable(context)) return;
  await context.read<MusicPlaybackService>().playInstantMix(seed);
  if (context.mounted) _autoOpenNowPlayingOnTv(context);
}
