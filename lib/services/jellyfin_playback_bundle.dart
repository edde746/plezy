import '../media/media_version.dart';

/// Bundle returned by [JellyfinClient.fetchPlaybackBundle].
///
/// Threads the data [PlaybackInitializationService] needs out of a single
/// Jellyfin item fetch — the chosen `MediaSource` JSON, the parsed
/// [MediaVersion] list (so the version picker can disambiguate alternate
/// cuts), the item-level `Chapters` array, and a couple of convenience
/// fields lifted off the selected source. Replaces the previous pattern
/// of reaching into [MediaItem.raw] from outside the client.
class JellyfinPlaybackBundle {
  /// One [MediaVersion] per `MediaSource`. The selected version's id
  /// matches [selectedSourceId].
  final List<MediaVersion> availableVersions;

  /// Raw `MediaSource` JSON the caller should feed to
  /// `jellyfinMediaSourceToMediaSourceInfo` for track parsing.
  final Map<String, dynamic> selectedSource;

  /// Item-level `Chapters` array (raw JSON list). Empty when the item
  /// has no chapters.
  final List<dynamic> chapters;

  /// `Container` field on the selected source — passed to
  /// `buildDirectStreamUrl` so the player gets the right extension hint.
  final String? container;

  /// `Id` of the selected source. Multi-source items must forward this as
  /// `MediaSourceId=` even when it equals the item id; otherwise Jellyfin
  /// falls back to its first sorted source instead of the selected version.
  final String? selectedSourceId;

  /// Effective source index after source-id matching and range clamping.
  final int selectedSourceIndex;

  /// Item-level `Trickplay` manifest (raw JSON object). `null` when the
  /// server hasn't run trickplay extraction for this item.
  final Object? trickplay;

  const JellyfinPlaybackBundle({
    required this.availableVersions,
    required this.selectedSource,
    required this.chapters,
    this.container,
    this.selectedSourceId,
    this.selectedSourceIndex = 0,
    this.trickplay,
  });

  /// Source id to pin in playback/download URLs. Preserve the old single-source
  /// behavior when Jellyfin's source id differs from the item id, and also pin
  /// multi-source primary items where the selected source id equals [itemId].
  String? pinnedSourceIdForItem(String itemId) {
    final id = selectedSourceId?.trim();
    if (id == null || id.isEmpty) return null;
    return availableVersions.length > 1 || id != itemId ? id : null;
  }
}
