import '../media/media_version.dart';
import '../media/media_source_info.dart';
import '../utils/jellyfin_time.dart';
import '../utils/json_utils.dart';
import 'jellyfin_mappers.dart';

/// Translate a Jellyfin `MediaSource` JSON object into [MediaSourceInfo] so the
/// existing Plex-shaped track picker can render readable labels and the
/// auto-track-selection has a `selected` flag to honour. Exposed as a
/// top-level function for unit testing the field mapping without spinning
/// up a [PlaybackInitializationService] or a [JellyfinClient].
///
/// [chapters] is Jellyfin's item-level `Chapters` array (the JSON list).
/// Each entry has `{Name, StartPositionTicks, ImageDateModified}`. Pass it
/// in here — Jellyfin doesn't nest chapters inside MediaSource so the
/// caller has to thread the field through.
///
/// [trickplay] is `BaseItemDto.Trickplay` — the item-level trickplay manifest.
/// Parsed defensively because two shapes appear in the wild: a flat
/// `Map<resolutionKey, info>` (per Jellyfin OpenAPI) and a nested
/// `Map<sourceId, Map<resolutionKey, info>>` (Streamyfin reports this).
MediaSourceInfo jellyfinMediaSourceToMediaSourceInfo(
  Map<String, dynamic> source, {
  Object? chapters,
  Object? trickplay,
}) {
  final streams = source['MediaStreams'];
  final audioTracks = <MediaAudioTrack>[];
  final subtitleTracks = <MediaSubtitleTrack>[];
  // partId stays null for Jellyfin because Plex's `/library/parts/{id}`
  // select-stream endpoint has no Jellyfin equivalent. Jellyfin track
  // persistence is driven by `/Sessions/Playing/Progress` stream indexes.
  const int? partId = null;
  final defaultAudioStreamIndex = flexibleInt(source['DefaultAudioStreamIndex']);
  final defaultSubtitleStreamIndex = flexibleInt(source['DefaultSubtitleStreamIndex']);
  double? frameRate;

  if (streams is List) {
    for (final s in streams) {
      if (s is! Map<String, dynamic>) continue;
      final f = parseJellyfinStreamFields(s);
      switch (f.type) {
        case 'video':
          frameRate ??= f.frameRate;
          break;
        case 'audio':
          audioTracks.add(
            MediaAudioTrack(
              id: f.index,
              index: f.index,
              codec: f.codec,
              language: f.language,
              languageCode: f.languageCode,
              title: f.title,
              displayTitle: f.displayTitle,
              channels: f.channels,
              selected: defaultAudioStreamIndex != null ? f.index == defaultAudioStreamIndex : f.isDefault,
            ),
          );
          break;
        case 'subtitle':
          subtitleTracks.add(
            MediaSubtitleTrack(
              id: f.index,
              index: f.index,
              codec: f.codec,
              language: f.language,
              languageCode: f.languageCode,
              title: f.title,
              displayTitle: f.displayTitle,
              selected: defaultSubtitleStreamIndex != null
                  ? f.index == defaultSubtitleStreamIndex
                  : f.isDefault || f.isForced,
              forced: f.isForced,
              key: f.isExternal ? f.deliveryUrl : null,
              external: f.isExternal,
            ),
          );
          break;
      }
    }
  }

  final mappedChapters = <MediaChapter>[];
  if (chapters is List) {
    for (var i = 0; i < chapters.length; i++) {
      final entry = chapters[i];
      if (entry is! Map<String, dynamic>) continue;
      final startMs = jellyfinTicksToMs(entry['StartPositionTicks']) ?? 0;
      mappedChapters.add(MediaChapter(id: i, index: i, startTimeOffset: startMs, title: entry['Name'] as String?));
    }
    MediaChapter.backfillEndOffsets(mappedChapters);
  }

  final mediaSourceId = source['Id'] as String?;
  final trickplayByWidth = _parseTrickplayManifest(trickplay, mediaSourceId);

  return MediaSourceInfo(
    videoUrl: '',
    audioTracks: audioTracks,
    subtitleTracks: subtitleTracks,
    chapters: mappedChapters,
    partId: partId,
    frameRate: frameRate,
    mediaSourceId: mediaSourceId,
    defaultAudioStreamIndex: defaultAudioStreamIndex,
    defaultSubtitleStreamIndex: defaultSubtitleStreamIndex,
    trickplayByWidth: trickplayByWidth,
  );
}

/// Parse Jellyfin chapters from the raw `BaseItemDto` payload into neutral
/// playback extras. Markers are not exposed by Jellyfin, so the list is empty.
PlaybackExtras jellyfinPlaybackExtrasFromRaw(dynamic raw, String itemId) {
  String segment(String value) => Uri.encodeComponent(value);
  String query(String value) => Uri.encodeComponent(value);

  final chapters = raw is Map<String, dynamic> ? raw['Chapters'] : null;
  final mapped = <MediaChapter>[];
  if (chapters is List) {
    for (var i = 0; i < chapters.length; i++) {
      final entry = chapters[i];
      if (entry is! Map<String, dynamic>) continue;
      final startMs = jellyfinTicksToMs(entry['StartPositionTicks']) ?? 0;
      // Jellyfin chapter image path: `/Items/{itemId}/Images/Chapter/{i}?tag=...`.
      final imageTag = entry['ImageTag'];
      final thumb = imageTag is String && imageTag.isNotEmpty
          ? '/Items/${segment(itemId)}/Images/Chapter/$i?tag=${query(imageTag)}'
          : null;
      mapped.add(
        MediaChapter(id: i, index: i, startTimeOffset: startMs, title: entry['Name']?.toString(), thumb: thumb),
      );
    }
    MediaChapter.backfillEndOffsets(mapped);
  }
  return PlaybackExtras(chapters: mapped, markers: const []);
}

/// Coerce a Jellyfin trickplay manifest to `Map<int width, TrickplayInfo>`,
/// tolerating both the flat OpenAPI shape (`{ "320": {...} }`) and the nested
/// Streamyfin shape (`{ "<sourceId>": { "320": {...} } }`).
///
/// Returns `null` when [raw] is missing, malformed, or contains no usable
/// entries — callers treat that as "no scrub thumbnails".
Map<int, TrickplayInfo>? _parseTrickplayManifest(Object? raw, String? sourceId) {
  if (raw is! Map) return null;
  if (raw.isEmpty) return null;

  // Discriminate FLAT vs NESTED by inspecting the values:
  //   FLAT  → at least one value is itself a TrickplayInfoDto-like map
  //           (has both `Width` and `Height` keys).
  //   NESTED → values are themselves resolution-keyed maps; the inner
  //           values are the TrickplayInfoDto-like ones.
  final Map resolutionMap;
  if (raw.values.any(_looksLikeTrickplayInfo)) {
    resolutionMap = raw;
  } else {
    final byId = sourceId != null ? raw[sourceId] : null;
    if (byId is Map) {
      resolutionMap = byId;
    } else {
      // Source id not in the manifest — fall back to the first nested
      // entry so the user still gets *something*. The caller already
      // chose the right source; this is best-effort recovery.
      final first = raw.values.cast<Object?>().firstWhere((v) => v is Map, orElse: () => null);
      if (first is! Map) return null;
      resolutionMap = first;
    }
  }

  final result = <int, TrickplayInfo>{};
  resolutionMap.forEach((key, value) {
    if (value is! Map) return;
    final width = flexibleInt(key) ?? flexibleInt(value['Width']);
    final height = flexibleInt(value['Height']);
    final tileWidth = flexibleInt(value['TileWidth']);
    final tileHeight = flexibleInt(value['TileHeight']);
    final thumbnailCount = flexibleInt(value['ThumbnailCount']);
    final interval = flexibleInt(value['Interval']);
    if (width == null ||
        height == null ||
        tileWidth == null ||
        tileHeight == null ||
        thumbnailCount == null ||
        interval == null) {
      return;
    }
    if (width <= 0 || height <= 0 || tileWidth <= 0 || tileHeight <= 0 || thumbnailCount <= 0 || interval <= 0) {
      return;
    }
    final bandwidth = flexibleInt(value['Bandwidth']) ?? 0;
    result[width] = TrickplayInfo(
      width: width,
      height: height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      thumbnailCount: thumbnailCount,
      interval: interval,
      bandwidth: bandwidth,
    );
  });

  return result.isEmpty ? null : result;
}

bool _looksLikeTrickplayInfo(Object? v) => v is Map && v.containsKey('Width') && v.containsKey('Height');

/// Build a [MediaVersion] list from a Jellyfin item's `MediaSources` array so
/// the existing version picker UI renders labels for alternate versions.
/// Resolution comes from the video stream inside `MediaStreams` — Jellyfin
/// doesn't surface Width/Height on the source itself.
///
/// Names are only attached when they actually disambiguate (i.e. the
/// sources have different `Name` values). For the common single-source
/// case the Name equals the item title and adds noise to the technical
/// label, so we skip it.
///
/// Exposed as a top-level function for unit testing the field mapping
/// without spinning up a [PlaybackInitializationService] or a [JellyfinClient].
List<MediaVersion> jellyfinSourcesToVersions(List<dynamic> sources) {
  final names = <String?>[];
  for (final src in sources) {
    names.add(src is Map<String, dynamic> ? src['Name'] as String? : null);
  }
  final useName = names.where((n) => n != null && n.isNotEmpty).toSet().length > 1;

  final versions = <MediaVersion>[];
  for (var i = 0; i < sources.length; i++) {
    final src = sources[i];
    if (src is! Map<String, dynamic>) continue;
    final sourceId = (src['Id'] as String?) ?? '';
    versions.add(
      jellyfinMediaSourceToVersion(
        src,
        versionId: i.toString(),
        partId: i.toString(),
        streamPath: sourceId,
        name: useName ? src['Name'] as String? : null,
      ),
    );
  }
  return versions;
}
