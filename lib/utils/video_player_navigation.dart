import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../models/plex_metadata.dart';
import '../screens/video_player_screen.dart';

/// Navigates to the VideoPlayerScreen with instant transitions to prevent white flash.
///
/// This utility function provides a consistent way to navigate to the video player
/// across the app, using PageRouteBuilder with zero-duration transitions to eliminate
/// the white flash that occurs with MaterialPageRoute.
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The Plex metadata for the content to play
/// - [preferredAudioTrack]: Optional audio track to select on playback start
/// - [preferredSubtitleTrack]: Optional subtitle track to select on playback start
/// - [preferredPlaybackRate]: Optional playback speed to set on playback start
/// - [usePushReplacement]: If true, replaces current route instead of pushing;
///   useful for episode-to-episode navigation. Defaults to false.
///
/// Returns a Future that completes with a boolean indicating whether the content
/// was watched, or null if navigation was cancelled.
Future<bool?> navigateToVideoPlayer(
  BuildContext context, {
  required PlexMetadata metadata,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  double? preferredPlaybackRate,
  bool usePushReplacement = false,
}) async {
  final route = PageRouteBuilder<bool>(
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: metadata,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      preferredPlaybackRate: preferredPlaybackRate,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  if (usePushReplacement) {
    return Navigator.of(context).pushReplacement<bool, bool>(route);
  } else {
    return Navigator.push<bool>(context, route);
  }
}
