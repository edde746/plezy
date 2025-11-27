import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../i18n/strings.g.dart';

/// Service responsible for fetching video playback data from the Plex server
class PlaybackInitializationService {
  final PlexClient client;

  PlaybackInitializationService({
    required this.client,
  });

  /// Fetch playback data for the given metadata
  ///
  /// Returns a PlaybackInitializationResult with video URL and available versions
  Future<PlaybackInitializationResult> getPlaybackData({
    required PlexMetadata metadata,
    required int selectedMediaIndex,
  }) async {
    try {
      // Get consolidated playback data (URL, media info, and versions) in a single API call
      final playbackData = await client.getVideoPlaybackData(
        metadata.ratingKey,
        mediaIndex: selectedMediaIndex,
      );

      if (!playbackData.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      // Return result with available versions and video URL
      return PlaybackInitializationResult(
        availableVersions: playbackData.availableVersions,
        videoUrl: playbackData.videoUrl!,
      );
    } catch (e) {
      if (e is PlaybackException) {
        rethrow;
      }
      throw PlaybackException(t.messages.errorLoading(error: e.toString()));
    }
  }
}

/// Result of playback initialization
class PlaybackInitializationResult {
  final List<dynamic> availableVersions;
  final String? videoUrl;

  PlaybackInitializationResult({
    required this.availableVersions,
    this.videoUrl,
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
