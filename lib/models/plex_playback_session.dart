enum PlexPlaybackRoute { directPlay, directStream, transcode }

class PlexPlaybackSession {
  final PlexPlaybackRoute route;
  final String sessionIdentifier;
  final String streamUrl;
  final String sourcePath;
  final int mediaIndex;
  final int partIndex;

  const PlexPlaybackSession({
    required this.route,
    required this.sessionIdentifier,
    required this.streamUrl,
    required this.sourcePath,
    this.mediaIndex = 0,
    this.partIndex = 0,
  });

  bool get isPlexManagedSession => streamUrl.contains('/video/:/transcode/universal/');

  bool get usesTranscodeEndpoint => route != PlexPlaybackRoute.directPlay;
}
