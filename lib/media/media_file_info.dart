import '../utils/formatters.dart';

/// Backend-neutral file-info payload rendered by `FileInfoBottomSheet`.
///
/// The shape mirrors what both media servers actually return: an item owns one
/// or more *versions* (Plex `Media`, Jellyfin `MediaSources`), a version owns
/// one or more *parts* (Plex `Part`; Jellyfin folds the file into the source,
/// so it always yields exactly one), and a part owns the demuxed *streams*.
/// Nothing is collapsed to "the first entry" — split/stacked files and
/// multi-version libraries surface every entry.
///
/// Every field either backend exposes about the file itself is modelled here.
/// Deliberately excluded are Jellyfin's ffmpeg-input plumbing flags
/// (`IgnoreDts`, `IgnoreIndex`, `GenPtsInput`, `ReadAtNativeFramerate`,
/// `RequiresOpening`/`Closing`/`Looping`, `SupportsProbing`,
/// `UseMostCompatibleTranscodingProfile`, `TranscodingSubProtocol`,
/// `HasSegments`) and its `Localized*` label helpers: they describe the
/// transcoder contract or duplicate a flag already modelled, not the file.
class MediaFileInfo {
  /// Every version the server reports, in server order.
  final List<MediaFileVersion> versions;

  const MediaFileInfo({this.versions = const []});
}

/// One playable version of an item: Plex `Media`, Jellyfin `MediaSources[]`.
///
/// The video/audio summary fields are the server's own roll-up of the primary
/// streams. They are kept because Plex derives them independently of the
/// stream table (an item can carry a `Media.videoResolution` label with no
/// probed streams at all), and they are what the version picker shows.
class MediaFileVersion {
  final String? id;

  /// Server-assigned version label (Plex `Media.title`, Jellyfin
  /// `MediaSource.Name`).
  final String? title;

  final String? container;

  /// Overall bitrate in kbps. Jellyfin reports bps and is normalised here.
  final int? bitrateKbps;

  final int? durationMs;
  final int? width;
  final int? height;
  final double? aspectRatio;

  /// Server resolution label (`1080`, `4k`, `sd`).
  final String? videoResolutionLabel;

  final String? videoCodec;
  final String? videoProfile;

  /// Server frame-rate label (Plex `24p`, `NTSC`).
  final String? videoFrameRateLabel;

  final String? audioCodec;
  final String? audioProfile;
  final int? audioChannels;

  final bool? optimizedForStreaming;
  final bool? has64bitOffsets;

  /// Jellyfin `Protocol` (`File`, `Http`, …).
  final String? protocol;

  /// Jellyfin `VideoType` (`VideoFile`, `Dvd`, `BluRay`, `Iso`).
  final String? videoType;

  final bool? isRemote;
  final bool? isInfiniteStream;
  final bool? supportsDirectPlay;
  final bool? supportsDirectStream;
  final bool? supportsTranscoding;

  /// Jellyfin content ETag — the identity the server invalidates caches on.
  final String? eTag;

  /// Jellyfin default stream selection for this source. `-1` on the subtitle
  /// index is an explicit "start with subtitles off".
  final int? defaultAudioStreamIndex;
  final int? defaultSubtitleStreamIndex;

  /// Jellyfin `MediaSource.Type` (`Default`, `Grouping`, `Placeholder`).
  final String? sourceType;

  /// Plex `proxyType == 42` — this version is a server-generated optimized
  /// copy rather than the original file.
  final bool? isOptimizedVersion;

  /// Plex `target` — the optimization profile that produced this version.
  final String? optimizationTarget;

  /// Plex `deletedAt` (epoch seconds). Plex keeps listing an optimized
  /// version it has already deleted, and that is exactly what a user
  /// staring at a missing file needs to see.
  final DateTime? deletedAt;

  /// Jellyfin `Timestamp` — transport-stream timestamp mode (`None`, `Zero`,
  /// `Valid`) for TS containers.
  final String? transportStreamTimestamp;

  /// Plex `displayOffset` — where this version starts inside a multi-part
  /// presentation, as a percentage.
  final int? displayOffsetPercent;

  final List<MediaFilePart> parts;

  /// Embedded non-media files (Jellyfin `MediaAttachments`) — typically the
  /// fonts an ASS subtitle track needs.
  final List<MediaFileAttachment> attachments;

  const MediaFileVersion({
    this.id,
    this.title,
    this.container,
    this.bitrateKbps,
    this.durationMs,
    this.width,
    this.height,
    this.aspectRatio,
    this.videoResolutionLabel,
    this.videoCodec,
    this.videoProfile,
    this.videoFrameRateLabel,
    this.audioCodec,
    this.audioProfile,
    this.audioChannels,
    this.optimizedForStreaming,
    this.has64bitOffsets,
    this.protocol,
    this.videoType,
    this.isRemote,
    this.isInfiniteStream,
    this.supportsDirectPlay,
    this.supportsDirectStream,
    this.supportsTranscoding,
    this.eTag,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
    this.sourceType,
    this.isOptimizedVersion,
    this.optimizationTarget,
    this.deletedAt,
    this.transportStreamTimestamp,
    this.displayOffsetPercent,
    this.parts = const [],
    this.attachments = const [],
  });

  String? get bitrateFormatted => bitrateKbps == null ? null : ByteFormatter.formatBitrate(bitrateKbps!);

  String? get durationFormatted => formatMediaDuration(durationMs);

  /// `1920x1080` when the server probed dimensions, otherwise its own label.
  String? get resolutionFormatted {
    if (width != null && height != null) return '${width}x$height';
    return videoResolutionLabel;
  }

  String? get aspectRatioFormatted => aspectRatio?.toStringAsFixed(2);

  int get totalFileSize => parts.fold(0, (sum, part) => sum + (part.fileSize ?? 0));

  String? get totalFileSizeFormatted {
    final total = totalFileSize;
    return total == 0 ? null : ByteFormatter.formatBytes(total, decimals: 2);
  }
}

/// One file backing a version: Plex `Part`, or the Jellyfin source's own file.
class MediaFilePart {
  final String? id;
  final String? filePath;
  final int? fileSize;
  final String? container;
  final int? durationMs;
  final bool? optimizedForStreaming;
  final bool? has64bitOffsets;

  /// Plex: the server generated BIF/preview thumbnails for this part.
  final bool? hasThumbnail;

  /// Plex `indexes` — which preview-thumbnail index exists (`sd`).
  final String? indexes;

  /// Plex `packetLength` for transport-stream containers.
  final int? packetLength;

  /// Plex `failureBIFResultCode` / `failureBIFRetryCount` — why the server
  /// has no preview thumbnails for this file, and how often it has retried.
  final int? previewFailureCode;
  final int? previewRetryCount;

  /// Plex `exists` / `accessible` — whether the file is still on disk and
  /// whether the server can read it. Only populated when the metadata was
  /// fetched with `checkFiles=1`, which is what the app's Plex client does.
  final bool? exists;
  final bool? accessible;

  /// Plex `Part.key` — the server-relative streaming path for this file.
  final String? streamKey;

  final List<MediaStreamDetails> streams;

  const MediaFilePart({
    this.id,
    this.filePath,
    this.fileSize,
    this.container,
    this.durationMs,
    this.optimizedForStreaming,
    this.has64bitOffsets,
    this.hasThumbnail,
    this.indexes,
    this.packetLength,

    this.previewFailureCode,
    this.previewRetryCount,
    this.exists,
    this.accessible,
    this.streamKey,
    this.streams = const [],
  });

  String? get fileSizeFormatted => fileSize == null ? null : ByteFormatter.formatBytes(fileSize!, decimals: 2);

  String? get durationFormatted => formatMediaDuration(durationMs);

  /// Trailing path segment — the filename the user recognises.
  String? get fileName {
    final path = filePath;
    if (path == null || path.isEmpty) return null;
    final separator = path.contains('\\') ? '\\' : '/';
    final segments = path.split(separator).where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  Iterable<MediaStreamDetails> streamsOfKind(MediaStreamKind kind) => streams.where((s) => s.kind == kind);
}

/// Embedded attachment (Jellyfin `MediaAttachments`).
class MediaFileAttachment {
  final int? index;
  final String? fileName;
  final String? mimeType;
  final String? codec;

  const MediaFileAttachment({this.index, this.fileName, this.mimeType, this.codec});
}

enum MediaStreamKind { video, audio, subtitle, image, data, lyric, unknown }

/// Colour/HDR classification of a video stream, normalised across backends.
///
/// Jellyfin reports it directly (`VideoRangeType`); Plex is derived from the
/// transfer characteristics plus the Dolby Vision block.
enum MediaVideoRange {
  sdr,
  hdr,
  hdr10,
  hdr10Plus,
  hlg,
  dolbyVision,
  dolbyVisionHdr10,
  dolbyVisionHlg,
  unknown;

  /// Technical label. Left untranslated on purpose — these are the trade
  /// names people match against their display's spec sheet, exactly like the
  /// codec strings next to them.
  String? get label => switch (this) {
    MediaVideoRange.sdr => 'SDR',
    MediaVideoRange.hdr => 'HDR',
    MediaVideoRange.hdr10 => 'HDR10',
    MediaVideoRange.hdr10Plus => 'HDR10+',
    MediaVideoRange.hlg => 'HLG',
    MediaVideoRange.dolbyVision => 'Dolby Vision',
    MediaVideoRange.dolbyVisionHdr10 => 'Dolby Vision (HDR10)',
    MediaVideoRange.dolbyVisionHlg => 'Dolby Vision (HLG)',
    MediaVideoRange.unknown => null,
  };
}

/// Dolby Vision descriptor. Plex exposes it as `DOVI*` keys on the video
/// stream, Jellyfin as `Dv*`/`*PresentFlag`.
class MediaDolbyVisionInfo {
  final int? profile;
  final int? level;
  final String? version;
  final int? blCompatibilityId;
  final bool? blPresent;
  final bool? elPresent;
  final bool? rpuPresent;

  /// Jellyfin's own summary string (`Dolby Vision Profile 8.1 (HDR10)`).
  final String? title;

  const MediaDolbyVisionInfo({
    this.profile,
    this.level,
    this.version,
    this.blCompatibilityId,
    this.blPresent,
    this.elPresent,
    this.rpuPresent,
    this.title,
  });

  bool get isEmpty =>
      profile == null &&
      level == null &&
      version == null &&
      blCompatibilityId == null &&
      blPresent == null &&
      elPresent == null &&
      rpuPresent == null &&
      title == null;

  /// `Profile 8.1` — the shorthand people actually quote.
  String? get profileFormatted {
    if (profile == null) return title;
    final compatibility = blCompatibilityId;
    return compatibility == null || compatibility == 0 ? 'Profile $profile' : 'Profile $profile.$compatibility';
  }
}

/// One demuxed stream of a part. A single class covers video/audio/subtitle so
/// the sheet can render any stream the server reports — including the image
/// and data streams both backends occasionally expose — without a per-kind
/// parallel hierarchy. Fields that don't apply to a kind stay null.
class MediaStreamDetails {
  final MediaStreamKind kind;

  /// Backend stream id (Plex `Stream.id`, Jellyfin has none).
  final String? id;

  /// Container stream ordinal.
  final int? index;

  /// 1-based ordinal among streams of the same kind, for display.
  final int ordinal;

  final String? title;

  /// Server-rendered summary (Plex `extendedDisplayTitle`, Jellyfin
  /// `DisplayTitle`).
  final String? displayTitle;

  final String? codec;

  /// FourCC / container codec tag (Plex `codecID`, Jellyfin `CodecTag`).
  final String? codecTag;

  final String? profile;
  final int? level;

  /// Human-readable language (Plex `language`, Jellyfin `DisplayLanguage`).
  final String? language;

  /// ISO 639 code as the server reports it.
  final String? languageCode;

  /// Stream bitrate in kbps. Jellyfin reports bps and is normalised here.
  final int? bitrateKbps;

  final bool? isDefault;
  final bool? isForced;
  final bool? isSelected;
  final bool? isExternal;
  final bool? isHearingImpaired;

  /// Plex dubbed/original audio flags.
  final bool? isDub;
  final bool? isOriginal;

  // ---- video ----
  final int? width;
  final int? height;
  final int? codedWidth;
  final int? codedHeight;
  final double? frameRate;
  final String? scanType;
  final bool? isInterlaced;
  final int? bitDepth;
  final int? refFrames;
  final String? pixelFormat;
  final String? colorSpace;
  final String? colorRange;
  final String? colorPrimaries;
  final String? colorTransfer;
  final String? chromaSubsampling;
  final String? chromaLocation;

  /// Display aspect ratio as the server words it (`16:9`, `2.35:1`).
  final String? aspectRatio;

  final String? pixelAspectRatio;
  final bool? isAnamorphic;
  final MediaVideoRange videoRange;
  final bool? hasHdr10Plus;
  final MediaDolbyVisionInfo? dolbyVision;

  /// Jellyfin `IsAVC` — whether an H.264 stream uses the AVC (not Annex B)
  /// bitstream layout, with its NAL length prefix size.
  final bool? isAvc;
  final int? nalLengthSize;

  /// Plex `hasScalingMatrix` — H.264 custom scaling matrices, which some
  /// hardware decoders reject.
  final bool? hasScalingMatrix;

  /// Transport-stream PID / program identifier.
  final String? streamIdentifier;

  /// Free-form ffmpeg stream comment tag (Plex `comment`, Jellyfin
  /// `Comment` on embedded cover art).
  final String? comment;

  /// Clockwise display rotation in degrees (Jellyfin `Rotation`).
  final int? rotation;

  /// Plex `descriptions` — the track carries audio descriptions for the
  /// visually impaired.
  final bool? hasDescriptions;

  /// Plex `headerCompression` — the Matroska track uses header stripping,
  /// which some demuxers reject.
  final bool? headerCompression;

  /// On-disk path of a sidecar stream (Jellyfin `Path` on external subtitle
  /// and lyric streams).
  final String? filePath;

  /// Jellyfin `TimeBase` — the stream's ffmpeg time base (`1/24000`).
  final String? timeBase;

  // ---- audio ----
  final int? channels;
  final String? channelLayout;
  final int? sampleRate;

  /// Jellyfin `AudioSpatialFormat` (`DolbyAtmos`, `DTSX`).
  final String? spatialFormat;

  // ---- subtitle ----
  final bool? isTextSubtitle;

  /// The server can hand this subtitle over as a sidecar file rather than
  /// muxed in the stream.
  final bool? supportsExternalStream;

  /// Sidecar subtitle file format (Plex `format`).
  final String? subtitleFormat;

  /// Where a downloaded subtitle came from (Plex `providerTitle`).
  final String? providerTitle;

  /// Match score of a downloaded/auto-selected subtitle.
  final int? score;

  /// Plex `key` on a sidecar subtitle — the server-relative path the
  /// subtitle file is served from, and what marks the track external.
  final String? externalKey;

  /// Plex `transient` — a subtitle attached to this playback only, not
  /// stored on the item.
  final bool? isTransient;

  /// Plex `sourceKey` — the library stream a downloaded subtitle was
  /// copied from.
  final String? sourceKey;

  const MediaStreamDetails({
    required this.kind,
    required this.ordinal,
    this.timeBase,
    this.externalKey,
    this.isTransient,
    this.sourceKey,
    this.comment,
    this.rotation,
    this.hasDescriptions,
    this.headerCompression,
    this.filePath,
    this.id,
    this.index,
    this.title,
    this.displayTitle,
    this.codec,
    this.codecTag,
    this.profile,
    this.level,
    this.language,
    this.languageCode,
    this.bitrateKbps,
    this.isDefault,
    this.isForced,
    this.isSelected,
    this.isExternal,
    this.isHearingImpaired,
    this.isDub,
    this.isOriginal,
    this.width,
    this.height,
    this.codedWidth,
    this.codedHeight,
    this.frameRate,
    this.scanType,
    this.isInterlaced,
    this.bitDepth,
    this.refFrames,
    this.pixelFormat,
    this.colorSpace,
    this.colorRange,
    this.colorPrimaries,
    this.colorTransfer,
    this.chromaSubsampling,
    this.chromaLocation,
    this.aspectRatio,
    this.pixelAspectRatio,
    this.isAnamorphic,
    this.videoRange = MediaVideoRange.unknown,
    this.hasHdr10Plus,
    this.dolbyVision,
    this.isAvc,
    this.nalLengthSize,
    this.hasScalingMatrix,
    this.streamIdentifier,
    this.channels,
    this.channelLayout,
    this.sampleRate,
    this.spatialFormat,
    this.isTextSubtitle,
    this.supportsExternalStream,
    this.subtitleFormat,
    this.providerTitle,
    this.score,
  });

  String? get bitrateFormatted => bitrateKbps == null ? null : ByteFormatter.formatBitrate(bitrateKbps!);

  String? get resolutionFormatted => (width != null && height != null) ? '${width}x$height' : null;

  String? get codedResolutionFormatted =>
      (codedWidth != null && codedHeight != null) ? '${codedWidth}x$codedHeight' : null;

  String? get frameRateFormatted {
    final rate = frameRate;
    if (rate == null) return null;
    final rounded = rate.roundToDouble();
    final text = (rate - rounded).abs() < 0.0005 ? rounded.toStringAsFixed(0) : rate.toStringAsFixed(3);
    return '$text fps';
  }

  String? get sampleRateFormatted {
    final rate = sampleRate;
    if (rate == null) return null;
    return rate % 1000 == 0 ? '${rate ~/ 1000} kHz' : '${(rate / 1000).toStringAsFixed(1)} kHz';
  }

  String? get bitDepthFormatted => bitDepth == null ? null : '$bitDepth bit';

  /// `5.1 (6 ch)` — layout first, because that is what people scan for.
  String? get channelsFormatted {
    final layout = channelLayout;
    final count = channels;
    if (layout != null && layout.isNotEmpty && count != null) return '$layout ($count ch)';
    if (layout != null && layout.isNotEmpty) return layout;
    if (count != null) return '$count ch';
    return null;
  }

  bool get isSpatialAudio {
    final format = spatialFormat;
    return format != null && format.isNotEmpty && format.toLowerCase() != 'none';
  }

  /// `DolbyAtmos` → `Dolby Atmos`. Jellyfin ships the enum name verbatim.
  String? get spatialFormatLabel {
    if (!isSpatialAudio) return null;
    return spatialFormat!.replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ');
  }

  /// Short label for the stream row: the server's own summary when it has one,
  /// otherwise title/language/codec in that order.
  String get headline {
    for (final candidate in [displayTitle, title, language, codec]) {
      if (candidate != null && candidate.trim().isNotEmpty) return candidate.trim();
    }
    return '#$ordinal';
  }
}

/// `1h 23m 45s` / `23m 45s` / `45s`. Shared by version and part rows.
String? formatMediaDuration(int? milliseconds) {
  if (milliseconds == null) return null;
  final totalSeconds = milliseconds ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}
