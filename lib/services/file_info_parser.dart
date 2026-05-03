import '../media/media_source_info.dart';
import '../utils/json_utils.dart';
import 'plex_constants.dart';

/// Backend-agnostic stream-array walker. Plex and Jellyfin both express the
/// per-source stream list (video/audio/subtitle entries) as `List<dynamic>`
/// under different field names; the per-backend [FileInfoStreamReader]
/// implementations encapsulate the naming differences so the call sites in
/// each client can hand a streams array straight to [walkStreams] and read
/// the four-tuple result.
enum FileInfoStreamType { video, audio, subtitle }

/// Normalised projection of a single entry in Jellyfin's `MediaStreams` array.
/// Callers build their own typed output from this shared extraction so the
/// field-name parsing only lives in one place.
typedef JellyfinStreamFields = ({
  String? type,
  int index,
  String? codec,
  String? language,
  String? languageCode,
  String? title,
  String? displayTitle,
  bool isDefault,
  bool isForced,
  bool isExternal,
  String? deliveryUrl,
  int? channels,
  double? frameRate,
});

JellyfinStreamFields parseJellyfinStreamFields(Map<String, dynamic> s, {int fallbackIndex = 0}) {
  final deliveryMethod = (s['DeliveryMethod'] as String?)?.toLowerCase();
  final isExternal = deliveryMethod != null ? deliveryMethod == 'external' : s['IsExternal'] == true;
  return (
    type: (s['Type'] as String?)?.toLowerCase(),
    index: flexibleInt(s['Index']) ?? fallbackIndex,
    codec: s['Codec'] as String?,
    language: s['DisplayLanguage'] as String? ?? s['Language'] as String?,
    languageCode: s['Language'] as String?,
    title: s['Title'] as String?,
    displayTitle: s['DisplayTitle'] as String?,
    isDefault: s['IsDefault'] as bool? ?? false,
    isForced: s['IsForced'] as bool? ?? false,
    isExternal: isExternal,
    deliveryUrl: s['DeliveryUrl'] as String?,
    channels: flexibleInt(s['Channels']),
    frameRate: flexibleDouble(s['RealFrameRate']) ?? flexibleDouble(s['AverageFrameRate']),
  );
}

/// Single-pass result of walking a streams array. Keeps both the raw
/// `videoStream` / `audioStream` map pointers (for callers that need to dig
/// out keys the parsed track classes don't carry — e.g. `colorSpace`,
/// `BitDepth`, `BitRate`) and the parsed neutral track lists.
class FileInfoStreams {
  final Map<String, dynamic>? videoStream;
  final Map<String, dynamic>? audioStream;
  final List<MediaAudioTrack> audioTracks;
  final List<MediaSubtitleTrack> subtitleTracks;
  final double? frameRate;

  const FileInfoStreams({
    required this.videoStream,
    required this.audioStream,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.frameRate,
  });

  static const empty = FileInfoStreams(
    videoStream: null,
    audioStream: null,
    audioTracks: [],
    subtitleTracks: [],
    frameRate: null,
  );
}

abstract class FileInfoStreamReader {
  /// Classify a raw stream entry — return null to skip (unknown / irrelevant).
  FileInfoStreamType? typeOf(Map<String, dynamic> stream);

  /// Build a neutral [MediaAudioTrack] from a backend-specific audio entry.
  /// [autoIndex] is the 1-based ordinal of this track among audio entries
  /// in the streams array; backends that lack a stable per-stream `id` can
  /// fall back to it.
  MediaAudioTrack toAudioTrack(Map<String, dynamic> stream, int autoIndex);

  /// Build a neutral [MediaSubtitleTrack] from a backend-specific subtitle
  /// entry. See [autoIndex] note on [toAudioTrack].
  MediaSubtitleTrack toSubtitleTrack(Map<String, dynamic> stream, int autoIndex);

  /// Pull the playback frame rate out of the video stream entry. Used by
  /// callers that build a [MediaSourceInfo] for the player so the renderer
  /// can pick the right refresh-rate match on capable displays.
  double? frameRateOf(Map<String, dynamic> videoStream);
}

typedef MalformedStreamHandler = void Function(Object error, StackTrace stackTrace, Map<String, dynamic> stream);

/// Walk [streams] in a single pass. Captures the first video / audio entries
/// (later ones are ignored — both backends serve a single primary track per
/// type), accumulates *all* audio / subtitle tracks for selection UIs, and
/// extracts the frame rate from the video entry.
FileInfoStreams walkStreams(
  List<dynamic>? streams,
  FileInfoStreamReader reader, {
  MalformedStreamHandler? onMalformed,
}) {
  if (streams == null || streams.isEmpty) return FileInfoStreams.empty;
  final audioTracks = <MediaAudioTrack>[];
  final subtitleTracks = <MediaSubtitleTrack>[];
  Map<String, dynamic>? videoStream;
  Map<String, dynamic>? audioStream;
  double? frameRate;
  var audioIndex = 0;
  var subtitleIndex = 0;
  for (final raw in streams) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      final type = reader.typeOf(raw);
      if (type == null) continue;
      switch (type) {
        case FileInfoStreamType.video:
          videoStream ??= raw;
          frameRate ??= reader.frameRateOf(raw);
        case FileInfoStreamType.audio:
          audioStream ??= raw;
          audioIndex++;
          audioTracks.add(reader.toAudioTrack(raw, audioIndex));
        case FileInfoStreamType.subtitle:
          subtitleIndex++;
          subtitleTracks.add(reader.toSubtitleTrack(raw, subtitleIndex));
      }
    } catch (error, stackTrace) {
      if (onMalformed == null) rethrow;
      onMalformed(error, stackTrace, raw);
    }
  }
  return FileInfoStreams(
    videoStream: videoStream,
    audioStream: audioStream,
    audioTracks: audioTracks,
    subtitleTracks: subtitleTracks,
    frameRate: frameRate,
  );
}

/// Reader for Plex's `Part.Stream[]` entries. Field naming follows Plex's
/// camelCase: `streamType` (1=video, 2=audio, 3=subtitle), numeric `id`,
/// `language`/`languageCode`, `selected`/`forced` arrive as bool-ish strings
/// or 0/1 ints (handled by [flexibleBool]).
class PlexFileInfoStreamReader implements FileInfoStreamReader {
  const PlexFileInfoStreamReader();

  @override
  FileInfoStreamType? typeOf(Map<String, dynamic> stream) {
    final t = stream['streamType'];
    if (t is! int) return null;
    return switch (t) {
      PlexStreamType.video => FileInfoStreamType.video,
      PlexStreamType.audio => FileInfoStreamType.audio,
      PlexStreamType.subtitle => FileInfoStreamType.subtitle,
      _ => null,
    };
  }

  @override
  MediaAudioTrack toAudioTrack(Map<String, dynamic> stream, int _) {
    return MediaAudioTrack(
      id: stream['id'] as int,
      index: stream['index'] as int?,
      codec: stream['codec'] as String?,
      language: stream['language'] as String?,
      languageCode: stream['languageCode'] as String?,
      title: stream['title'] as String?,
      displayTitle: stream['displayTitle'] as String?,
      channels: stream['channels'] as int?,
      selected: flexibleBool(stream['selected']),
    );
  }

  @override
  MediaSubtitleTrack toSubtitleTrack(Map<String, dynamic> stream, int _) {
    return MediaSubtitleTrack(
      id: stream['id'] as int,
      index: stream['index'] as int?,
      codec: stream['codec'] as String?,
      language: stream['language'] as String?,
      languageCode: stream['languageCode'] as String?,
      title: stream['title'] as String?,
      displayTitle: stream['displayTitle'] as String?,
      selected: flexibleBool(stream['selected']),
      forced: flexibleBool(stream['forced']),
      key: stream['key'] as String?,
    );
  }

  @override
  double? frameRateOf(Map<String, dynamic> videoStream) {
    return (videoStream['frameRate'] as num?)?.toDouble();
  }
}

/// Reader for Jellyfin's `MediaSources[].MediaStreams[]` entries. Field
/// naming is PascalCase: `Type` ('Video'/'Audio'/'Subtitle'), `Index` per
/// stream-type ordinal, `IsDefault`/`IsForced` as proper booleans. The
/// per-stream `Index` can theoretically be null on misconfigured items, so
/// the reader falls back to the walker's `autoIndex` for stable IDs.
class JellyfinFileInfoStreamReader implements FileInfoStreamReader {
  const JellyfinFileInfoStreamReader();

  @override
  FileInfoStreamType? typeOf(Map<String, dynamic> stream) {
    final type = (stream['Type'] as String?)?.toLowerCase();
    return switch (type) {
      'video' => FileInfoStreamType.video,
      'audio' => FileInfoStreamType.audio,
      'subtitle' => FileInfoStreamType.subtitle,
      _ => null,
    };
  }

  @override
  MediaAudioTrack toAudioTrack(Map<String, dynamic> s, int autoIndex) {
    final f = parseJellyfinStreamFields(s, fallbackIndex: autoIndex);
    return MediaAudioTrack(
      id: f.index,
      index: f.index,
      codec: f.codec,
      language: f.language,
      languageCode: f.languageCode,
      title: f.title,
      displayTitle: f.displayTitle,
      channels: f.channels,
      selected: f.isDefault,
    );
  }

  @override
  MediaSubtitleTrack toSubtitleTrack(Map<String, dynamic> s, int autoIndex) {
    final f = parseJellyfinStreamFields(s, fallbackIndex: autoIndex);
    return MediaSubtitleTrack(
      id: f.index,
      index: f.index,
      codec: f.codec,
      language: f.language,
      languageCode: f.languageCode,
      title: f.title,
      displayTitle: f.displayTitle,
      selected: f.isDefault,
      forced: f.isForced,
      key: f.isExternal ? f.deliveryUrl : null,
      external: f.isExternal,
    );
  }

  @override
  double? frameRateOf(Map<String, dynamic> videoStream) {
    return (videoStream['RealFrameRate'] as num?)?.toDouble() ?? (videoStream['AverageFrameRate'] as num?)?.toDouble();
  }
}
