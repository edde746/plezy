import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../screens/audiobook_player_screen.dart';

/// Navigates to the AudiobookPlayerScreen with instant transitions.
///
/// This utility function provides a consistent way to navigate to the audiobook player
/// across the app, using PageRouteBuilder with zero-duration transitions.
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The Plex metadata for the chapter/track to play
/// - [playlist]: Optional list of all chapters in the book for sequential playback
/// - [initialIndex]: Index of the track to start playing (defaults to 0)
/// - [usePushReplacement]: If true, replaces current route instead of pushing
///
/// Returns a Future that completes with a boolean indicating whether the content
/// was played, or null if navigation was cancelled.
Future<bool?> navigateToAudiobookPlayer(
  BuildContext context, {
  required PlexMetadata metadata,
  List<PlexMetadata>? playlist,
  int initialIndex = 0,
  bool usePushReplacement = false,
}) async {
  // Extract navigator before any async operations
  final navigator = Navigator.of(context);

  final route = PageRouteBuilder<bool>(
    pageBuilder: (context, animation, secondaryAnimation) => AudiobookPlayerScreen(
      metadata: metadata,
      playlist: playlist,
      initialIndex: initialIndex,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  if (usePushReplacement) {
    return navigator.pushReplacement<bool, bool>(route);
  } else {
    return navigator.push<bool>(route);
  }
}
