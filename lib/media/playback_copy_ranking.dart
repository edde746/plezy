import '../models/transcode_quality_preset.dart';
import 'media_item.dart';
import 'media_item_merge.dart';
import 'media_version.dart';

enum PlaybackCopyReason { offline, reachable, unavailable, missingParts, decodeFallback, qualityLimit, unknown }

/// An explanation of an ordering decision, not permission to switch editions
/// or carry a timeline position between copies. Opening remains explicit.
class PlaybackCopyRank {
  const PlaybackCopyRank(this.item, this.version, this.reason, this._priority);
  final MediaItem item;
  final MediaVersion? version;
  final PlaybackCopyReason reason;
  final List<int> _priority;
}

/// Choose a practical copy before considering resolution. Missing metadata is
/// uncertainty, never evidence that a file cannot play. A verified local copy
/// remains useful even when its server is unreachable or reports missing media.
List<PlaybackCopyRank> rankPlaybackCopies(
  Iterable<MediaItem> copies, {
  required Set<String> onlineServerIds,
  Set<String> verifiedOfflineKeys = const {},
  Set<String> refusedVideoCodecs = const {},
  TranscodeQualityPreset quality = TranscodeQualityPreset.original,
}) {
  List<int> versionPriority(MediaVersion version) {
    final codec = switch (version.videoCodec?.toLowerCase()) {
      'h265' || 'hev1' => 'hevc',
      'avc' || 'avc1' => 'h264',
      final value => value,
    };
    final rejected = refusedVideoCodecs.contains(codec);
    final cap = quality.videoBitrateKbps;
    final height = quality.resolutionHeight;
    final exceeds =
        (cap != null && (version.bitrate ?? 0) > cap) || (height != null && (version.resolutionHeight ?? 0) > height);
    return [version.isPlayable ? 0 : 1, rejected ? 1 : 0, exceeds ? 1 : 0, -(version.resolutionHeight ?? 0)];
  }

  final ranked = <PlaybackCopyRank>[];
  for (final item in copies) {
    final versions = [...?item.mediaVersions]
      ..sort((a, b) {
        final result = _comparePriority(versionPriority(a), versionPriority(b));
        return result == 0 ? a.id.compareTo(b.id) : result;
      });
    final version = versions.firstOrNull;
    final priority = version == null ? [0, 0, 0, 0] : versionPriority(version);
    final offline = verifiedOfflineKeys.contains(item.globalKey);
    final online = onlineServerIds.contains(item.serverId);
    final reason = offline
        ? PlaybackCopyReason.offline
        : !online
        ? PlaybackCopyReason.unavailable
        : priority[0] != 0
        ? PlaybackCopyReason.missingParts
        : priority[1] != 0
        ? PlaybackCopyReason.decodeFallback
        : priority[2] != 0
        ? PlaybackCopyReason.qualityLimit
        : version == null
        ? PlaybackCopyReason.unknown
        : PlaybackCopyReason.reachable;
    ranked.add(
      PlaybackCopyRank(item, version, reason, [
        offline
            ? 0
            : online && priority[0] == 0
            ? 1
            : 2,
        // A local copy was checked independently of stale server-side versions.
        if (!offline) ...priority,
      ]),
    );
  }
  ranked.sort((a, b) {
    final result = _comparePriority(a._priority, b._priority);
    return result == 0 ? compareLibraryCopies(a.item, b.item) : result;
  });
  return ranked;
}

int _comparePriority(List<int> a, List<int> b) {
  for (var index = 0; index < a.length && index < b.length; index++) {
    final result = a[index].compareTo(b[index]);
    if (result != 0) return result;
  }
  return a.length.compareTo(b.length);
}
