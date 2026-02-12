import 'plex_metadata.dart';
import 'livetv_program.dart';

/// A hub from the live TV discover endpoint, with both display and EPG data.
class LiveTvHubResult {
  final String title;
  final String hubKey;
  final List<LiveTvHubEntry> entries;

  LiveTvHubResult({
    required this.title,
    required this.hubKey,
    required this.entries,
  });
}

/// A single item in a live TV hub, holding both display metadata and EPG timing.
class LiveTvHubEntry {
  final PlexMetadata metadata;
  final LiveTvProgram program;

  LiveTvHubEntry({required this.metadata, required this.program});
}
