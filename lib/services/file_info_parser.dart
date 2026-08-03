import '../media/media_file_info.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart' show bitrateKbpsFromBps;
import '../utils/json_utils.dart';
import 'plex_constants.dart';

/// Backend-agnostic stream-array walker. Plex and Jellyfin both express the
/// per-source stream list (video/audio/subtitle entries) as `List<dynamic>`
/// under different field names; the per-backend [FileInfoStreamReader]
/// implementations encapsulate the naming differences so the call sites in
/// each client can hand a streams array straight to [walkStreams].
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
  bool isExternalFile,
  bool usesExternalDelivery,
  bool isExternal,
  String? deliveryUrl,
  int? channels,
  double? frameRate,
});

JellyfinStreamFields parseJellyfinStreamFields(Map<String, dynamic> s, {int fallbackIndex = 0}) {
  final deliveryMethod = (s['DeliveryMethod'] as String?)?.toLowerCase();
  final isExternalFile = s['IsExternal'] == true;
  final usesExternalDelivery = deliveryMethod == 'external';
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
    isExternalFile: isExternalFile,
    usesExternalDelivery: usesExternalDelivery,
    isExternal: isExternalFile || usesExternalDelivery,
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

  const FileInfoStreams({
    required this.videoStream,
    required this.audioStream,
    required this.audioTracks,
    required this.subtitleTracks,
  });

  static const empty = FileInfoStreams(videoStream: null, audioStream: null, audioTracks: [], subtitleTracks: []);
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
}

typedef MalformedStreamHandler = void Function(Object error, StackTrace stackTrace, Map<String, dynamic> stream);

/// Walk [streams] in a single pass. Captures the first video / audio entries
/// (later ones are ignored — both backends serve a single primary track per
/// type), accumulates *all* audio / subtitle tracks for selection UIs, and
/// keeps the raw video stream for display-metadata parsing.
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
    final t = flexibleInt(stream['streamType']);
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
      id: flexibleInt(stream['id']) ?? (throw const FormatException('Plex audio stream is missing a numeric id')),
      index: flexibleInt(stream['index']),
      codec: stream['codec'] as String?,
      language: stream['language'] as String?,
      languageCode: stream['languageCode'] as String?,
      title: stream['title'] as String?,
      displayTitle: stream['displayTitle'] as String?,
      channels: flexibleInt(stream['channels']),
      selected: flexibleBool(stream['selected']),
    );
  }

  @override
  MediaSubtitleTrack toSubtitleTrack(Map<String, dynamic> stream, int _) {
    return MediaSubtitleTrack(
      id: flexibleInt(stream['id']) ?? (throw const FormatException('Plex subtitle stream is missing a numeric id')),
      index: flexibleInt(stream['index']),
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
      external: f.isExternal,
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
      external: f.isExternalFile,
      usesExternalDelivery: f.usesExternalDelivery,
    );
  }
}

// ---------------------------------------------------------------------------
// Full per-stream detail extraction for the file-info sheet.
//
// [walkStreams] above deliberately keeps only what playback needs. The sheet
// needs every probed property, so these builders read the raw stream maps a
// second time and project them onto the neutral [MediaStreamDetails]. Both
// backends' field-name maps live side by side here for the same reason the
// readers above do: one place to compare when a server adds a key.
// ---------------------------------------------------------------------------

/// Classify a Plex `Part.Stream[]` entry. Plex numbers stream types 1–4
/// ([PlexStreamType]); anything else maps to [MediaStreamKind.unknown].
///
/// Type 4 is lyrics, not an embedded image — music tracks are the only items
/// that carry it, so the mismatch only became visible once File Info was
/// offered for tracks.
MediaStreamKind plexStreamKind(Map<String, dynamic> s) => switch (flexibleInt(s['streamType'])) {
  PlexStreamType.video => MediaStreamKind.video,
  PlexStreamType.audio => MediaStreamKind.audio,
  PlexStreamType.subtitle => MediaStreamKind.subtitle,
  PlexStreamType.lyrics => MediaStreamKind.lyric,
  _ => MediaStreamKind.unknown,
};

/// Classify a Jellyfin `MediaStreams[]` entry.
MediaStreamKind jellyfinStreamKind(Map<String, dynamic> s) => switch ((s['Type'] as String?)?.toLowerCase()) {
  'video' => MediaStreamKind.video,
  'audio' => MediaStreamKind.audio,
  'subtitle' => MediaStreamKind.subtitle,
  'embeddedimage' => MediaStreamKind.image,
  'lyric' => MediaStreamKind.lyric,
  'data' => MediaStreamKind.data,
  _ => MediaStreamKind.unknown,
};

/// Project a Plex `Part.Stream[]` entry. [ordinal] is the 1-based position
/// among streams of the same kind.
MediaStreamDetails plexStreamDetails(Map<String, dynamic> s, int ordinal) {
  final kind = plexStreamKind(s);
  final dolbyVision = _plexDolbyVision(s);
  return MediaStreamDetails(
    kind: kind,
    ordinal: ordinal,
    id: s['id']?.toString(),
    index: flexibleInt(s['index']),
    title: _text(s['title']),
    displayTitle: _text(s['extendedDisplayTitle']) ?? _text(s['displayTitle']),
    codec: _text(s['codec']),
    codecTag: _text(s['codecID']),
    profile: _text(s['profile']),
    level: flexibleInt(s['level']),
    language: _text(s['language']),
    languageCode: _text(s['languageCode']) ?? _text(s['languageTag']),
    // Plex already reports stream bitrates in kbps.
    bitrateKbps: flexibleInt(s['bitrate']),
    isDefault: flexibleBoolNullable(s['default']),
    isForced: flexibleBoolNullable(s['forced']),
    isSelected: flexibleBoolNullable(s['selected']),
    isExternal: _plexIsExternal(s),
    isHearingImpaired: flexibleBoolNullable(s['hearingImpaired']),
    isDub: flexibleBoolNullable(s['dub']),
    isOriginal: flexibleBoolNullable(s['original']),
    width: flexibleInt(s['width']),
    height: flexibleInt(s['height']),
    codedWidth: flexibleInt(s['codedWidth']),
    codedHeight: flexibleInt(s['codedHeight']),
    frameRate: flexibleDouble(s['frameRate']),
    scanType: _text(s['scanType']),
    isInterlaced: _plexInterlaced(s),
    bitDepth: flexibleInt(s['bitDepth']),
    refFrames: flexibleInt(s['refFrames']),
    colorSpace: _text(s['colorSpace']),
    colorRange: _text(s['colorRange']),
    colorPrimaries: _text(s['colorPrimaries']),
    colorTransfer: _text(s['colorTrc']),
    chromaSubsampling: _text(s['chromaSubsampling']),
    chromaLocation: _text(s['chromaLocation']),
    pixelAspectRatio: _text(s['pixelAspectRatio']),
    isAnamorphic: flexibleBoolNullable(s['anamorphic']),
    videoRange: kind == MediaStreamKind.video ? _plexVideoRange(s, dolbyVision) : MediaVideoRange.unknown,
    dolbyVision: dolbyVision,
    hasScalingMatrix: flexibleBoolNullable(s['hasScalingMatrix']),
    streamIdentifier: _text(s['streamIdentifier']),
    channels: flexibleInt(s['channels']),
    channelLayout: _text(s['audioChannelLayout']),
    sampleRate: flexibleInt(s['samplingRate']),
    subtitleFormat: _text(s['format']),
    providerTitle: _text(s['providerTitle']),
    score: flexibleInt(s['score']),
    externalKey: _text(s['key']),
    isTransient: flexibleBoolNullable(s['transient']),
    sourceKey: _text(s['sourceKey']),
    comment: _text(s['comment']),
    hasDescriptions: flexibleBoolNullable(s['descriptions']),
    headerCompression: flexibleBoolNullable(s['headerCompression']),
  );
}

/// Project a Jellyfin `MediaSources[].MediaStreams[]` entry.
MediaStreamDetails jellyfinStreamDetails(Map<String, dynamic> s, int ordinal) {
  final kind = jellyfinStreamKind(s);
  final interlaced = flexibleBoolNullable(s['IsInterlaced']);
  return MediaStreamDetails(
    kind: kind,
    ordinal: ordinal,
    index: flexibleInt(s['Index']),
    title: _text(s['Title']),
    displayTitle: _text(s['DisplayTitle']),
    codec: _text(s['Codec']),
    codecTag: _text(s['CodecTag']),
    profile: _text(s['Profile']),
    level: flexibleInt(s['Level']),
    language: _text(s['DisplayLanguage']) ?? _text(s['Language']),
    languageCode: _text(s['Language']),
    bitrateKbps: bitrateKbpsFromBps(flexibleInt(s['BitRate'])),
    isDefault: flexibleBoolNullable(s['IsDefault']),
    isForced: flexibleBoolNullable(s['IsForced']),
    isExternal: flexibleBoolNullable(s['IsExternal']),
    isHearingImpaired: flexibleBoolNullable(s['IsHearingImpaired']),
    width: flexibleInt(s['Width']),
    height: flexibleInt(s['Height']),
    frameRate: flexibleDouble(s['RealFrameRate']) ?? flexibleDouble(s['AverageFrameRate']),
    scanType: interlaced == null ? null : (interlaced ? 'interlaced' : 'progressive'),
    isInterlaced: interlaced,
    bitDepth: flexibleInt(s['BitDepth']),
    refFrames: flexibleInt(s['RefFrames']),
    pixelFormat: _text(s['PixelFormat']),
    colorSpace: _text(s['ColorSpace']),
    colorRange: _text(s['ColorRange']),
    colorPrimaries: _text(s['ColorPrimaries']),
    colorTransfer: _text(s['ColorTransfer']),
    aspectRatio: _text(s['AspectRatio']),
    isAnamorphic: flexibleBoolNullable(s['IsAnamorphic']),
    videoRange: kind == MediaStreamKind.video ? _jellyfinVideoRange(s) : MediaVideoRange.unknown,
    hasHdr10Plus: flexibleBoolNullable(s['Hdr10PlusPresentFlag']),
    dolbyVision: _jellyfinDolbyVision(s),
    isAvc: flexibleBoolNullable(s['IsAVC']),
    nalLengthSize: flexibleInt(s['NalLengthSize']),
    channels: flexibleInt(s['Channels']),
    channelLayout: _text(s['ChannelLayout']),
    sampleRate: flexibleInt(s['SampleRate']),
    spatialFormat: _text(s['AudioSpatialFormat']),
    isTextSubtitle: flexibleBoolNullable(s['IsTextSubtitleStream']),
    supportsExternalStream: flexibleBoolNullable(s['SupportsExternalStream']),
    score: flexibleInt(s['Score']),
    timeBase: _text(s['TimeBase']),
    externalKey: _text(s['DeliveryUrl']),
    comment: _text(s['Comment']),
    rotation: flexibleInt(s['Rotation']),
    filePath: _text(s['Path']),
  );
}

/// Project a Jellyfin `MediaSources[].MediaAttachments[]` entry. Plex does not
/// expose attachments on `/library/metadata`, so this has no Plex sibling.
MediaFileAttachment jellyfinAttachment(Map<String, dynamic> a) {
  return MediaFileAttachment(
    index: flexibleInt(a['Index']),
    fileName: _text(a['FileName']),
    mimeType: _text(a['MimeType']),
    // Live servers populate `CodecTag`; `Codec` is in the DTO but usually null.
    codec: _text(a['Codec']) ?? _text(a['CodecTag']),
  );
}

/// Trim and drop empties — both servers emit `""` for "not probed", and an
/// empty row is worse than an absent one.
String? _text(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Plex marks sidecar subtitles with a `/library/streams/...` key rather than
/// an explicit flag.
bool? _plexIsExternal(Map<String, dynamic> s) {
  if (flexibleInt(s['streamType']) != PlexStreamType.subtitle) return null;
  final key = s['key'];
  return key is String && key.isNotEmpty;
}

bool? _plexInterlaced(Map<String, dynamic> s) {
  final scanType = _text(s['scanType'])?.toLowerCase();
  return scanType == null ? null : scanType != 'progressive';
}

MediaDolbyVisionInfo? _plexDolbyVision(Map<String, dynamic> s) {
  if (!flexibleBool(s['DOVIPresent'])) return null;
  return MediaDolbyVisionInfo(
    profile: flexibleInt(s['DOVIProfile']),
    level: flexibleInt(s['DOVILevel']),
    version: _text(s['DOVIVersion']),
    blCompatibilityId: flexibleInt(s['DOVIBLCompatID']),
    blPresent: flexibleBoolNullable(s['DOVIBLPresent']),
    elPresent: flexibleBoolNullable(s['DOVIELPresent']),
    rpuPresent: flexibleBoolNullable(s['DOVIRPUPresent']),
  );
}

MediaDolbyVisionInfo? _jellyfinDolbyVision(Map<String, dynamic> s) {
  final major = flexibleInt(s['DvVersionMajor']);
  final minor = flexibleInt(s['DvVersionMinor']);
  final info = MediaDolbyVisionInfo(
    profile: flexibleInt(s['DvProfile']),
    level: flexibleInt(s['DvLevel']),
    version: major == null ? null : '$major.${minor ?? 0}',
    blCompatibilityId: flexibleInt(s['DvBlSignalCompatibilityId']),
    blPresent: flexibleBoolNullable(s['BlPresentFlag']),
    elPresent: flexibleBoolNullable(s['ElPresentFlag']),
    rpuPresent: flexibleBoolNullable(s['RpuPresentFlag']),
    title: _text(s['VideoDoViTitle']),
  );
  return info.isEmpty ? null : info;
}

/// Plex reports no dynamic-range field, so classify from the Dolby Vision
/// block first and fall back to the transfer characteristics.
MediaVideoRange _plexVideoRange(Map<String, dynamic> s, MediaDolbyVisionInfo? dolbyVision) {
  if (dolbyVision != null) {
    // `dv_bl_signal_compatibility_id`: 1 = HDR10, 2 = SDR/BT.709, 4 = HLG,
    // 6 = Blu-ray HDR10. Profile 7 always carries an HDR10 base layer, and
    // profile 5 carries none (0), so it stays plain Dolby Vision.
    final compatibility = dolbyVision.blCompatibilityId;
    if (compatibility == 4) return MediaVideoRange.dolbyVisionHlg;
    if (dolbyVision.profile == 7 || compatibility == 1 || compatibility == 6) {
      return MediaVideoRange.dolbyVisionHdr10;
    }
    return MediaVideoRange.dolbyVision;
  }
  return switch (_text(s['colorTrc'])?.toLowerCase()) {
    'smpte2084' => MediaVideoRange.hdr10,
    'arib-std-b67' => MediaVideoRange.hlg,
    null => MediaVideoRange.unknown,
    _ => MediaVideoRange.sdr,
  };
}

MediaVideoRange _jellyfinVideoRange(Map<String, dynamic> s) {
  final type = _text(s['VideoRangeType'])?.toLowerCase();
  if (type != null && type != 'unknown') {
    if (type.startsWith('dovi')) {
      if (type.contains('hlg')) return MediaVideoRange.dolbyVisionHlg;
      if (type.contains('hdr10')) return MediaVideoRange.dolbyVisionHdr10;
      return MediaVideoRange.dolbyVision;
    }
    return switch (type) {
      'sdr' => MediaVideoRange.sdr,
      'hdr10' => MediaVideoRange.hdr10,
      'hdr10plus' => MediaVideoRange.hdr10Plus,
      'hlg' => MediaVideoRange.hlg,
      _ => MediaVideoRange.hdr,
    };
  }
  return switch (_text(s['VideoRange'])?.toLowerCase()) {
    'sdr' => MediaVideoRange.sdr,
    'hdr' => MediaVideoRange.hdr,
    _ => MediaVideoRange.unknown,
  };
}
