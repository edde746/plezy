import '../../media/media_server_client.dart';
import '../../models/livetv_channel.dart';

/// Launch parameters for a live TV session. A [VideoPlayerScreen] plays live
/// TV iff it was constructed with one of these — the type encodes the
/// "these fields travel together" invariant the nine separate nullable
/// constructor parameters used to leave implicit.
class LiveTvSessionArgs {
  final String? channelName;

  /// Pre-resolved stream URL (Jellyfin always provides one; Plex tunes
  /// in-player when null).
  final String? streamUrl;

  final List<LiveTvChannel>? channels;
  final int? currentChannelIndex;
  final String? dvrKey;

  /// Backend-neutral client typing. The four in-player live ops branch on
  /// `client is PlexClient` / `client is JellyfinClient` at their use sites:
  /// Plex tunes a transcode session and gets capture-buffer updates;
  /// Jellyfin uses its `/Sessions/Playing*` endpoints for progress reporting
  /// and re-opens [streamUrl] for retry. Tune (Plex-only by protocol)
  /// and seek (Plex-only — Jellyfin live channels aren't seekable) gate
  /// explicitly on `client is PlexClient`.
  final MediaServerClient? client;

  final String? sessionIdentifier;
  final String? sessionPath;

  const LiveTvSessionArgs({
    this.channelName,
    this.streamUrl,
    this.channels,
    this.currentChannelIndex,
    this.dvrKey,
    this.client,
    this.sessionIdentifier,
    this.sessionPath,
  });
}
