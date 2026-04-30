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

  /// `Id` of the selected source. Forwarded as `MediaSourceId=` only when
  /// there's more than one source on the item; single-source items have
  /// `Id == itemId` so the param adds noise without changing behaviour.
  final String? selectedSourceId;

  /// Item-level `Trickplay` manifest (raw JSON object). `null` when the
  /// server hasn't run trickplay extraction for this item.
  final Object? trickplay;

  const JellyfinPlaybackBundle({
    required this.availableVersions,
    required this.selectedSource,
    required this.chapters,
    this.container,
    this.selectedSourceId,
    this.trickplay,
  });
}
