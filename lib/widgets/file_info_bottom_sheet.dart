import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../media/media_file_info.dart';
import '../theme/mono_tokens.dart';
import '../utils/formatters.dart';
import '../utils/scroll_utils.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'bottom_sheet_header.dart';
import 'stat_chip.dart';

/// Full technical breakdown of an item's files.
///
/// Every version the server reports gets its own block, every file inside a
/// version its own card, and every demuxed stream a card of its own — nothing
/// is folded down to "the first one". Fields the active backend does not
/// report are skipped rather than rendered empty.
class FileInfoBottomSheet extends StatefulWidget {
  final MediaFileInfo fileInfo;
  final String title;

  const FileInfoBottomSheet({super.key, required this.fileInfo, required this.title});

  @override
  State<FileInfoBottomSheet> createState() => _FileInfoBottomSheetState();
}

class _FileInfoBottomSheetState extends State<FileInfoBottomSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'FileInfoBottomSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versions = widget.fileInfo.versions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(
          title: t.fileInfo.title,
          icon: Symbols.info_rounded,
          closeFocusNode: _initialFocusNode,
          // Flat sheet: the tonal cards do the separating, so the header
          // keeps no rule under it.
          showBorder: false,
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (widget.title.isNotEmpty) _ItemHeadline(title: widget.title, versions: versions),
              for (var index = 0; index < versions.length; index++)
                _VersionBlock(
                  version: versions[index],
                  index: index,
                  versionCount: versions.length,
                  isLast: index == versions.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Item title plus the at-a-glance chips people actually came for.
class _ItemHeadline extends StatelessWidget {
  final String title;
  final List<MediaFileVersion> versions;

  const _ItemHeadline({required this.title, required this.versions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = versions.isEmpty ? null : versions.first;
    final chips = version == null ? const <String>[] : _summaryChips(version);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  StatChip(label: chip, backgroundColor: tokens(context).text.withValues(alpha: 0.08)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Container, resolution, dynamic range, codecs and size — the summary a
  /// person scans before reading any table.
  List<String> _summaryChips(MediaFileVersion version) {
    final video = _firstOfKind(version, MediaStreamKind.video);
    final audio = _firstOfKind(version, MediaStreamKind.audio);
    final chips = <String>[
      if (version.container != null) version.container!.toUpperCase(),
      if (version.resolutionFormatted != null) version.resolutionFormatted!,
      if (video?.videoRange.label != null && video!.videoRange != MediaVideoRange.sdr) video.videoRange.label!,
      if (version.videoCodec != null) version.videoCodec!.toUpperCase(),
      if (audio?.codec != null) audio!.codec!.toUpperCase(),
      if (audio?.spatialFormatLabel != null) audio!.spatialFormatLabel!,
      if (version.totalFileSizeFormatted != null) version.totalFileSizeFormatted!,
      if (version.durationFormatted != null) version.durationFormatted!,
    ];
    return chips;
  }

  MediaStreamDetails? _firstOfKind(MediaFileVersion version, MediaStreamKind kind) {
    for (final part in version.parts) {
      for (final stream in part.streams) {
        if (stream.kind == kind) return stream;
      }
    }
    return null;
  }
}

/// One server-reported version: overview, its files, its streams.
class _VersionBlock extends StatelessWidget {
  final MediaFileVersion version;
  final int index;
  final int versionCount;
  final bool isLast;

  const _VersionBlock({required this.version, required this.index, required this.versionCount, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (versionCount > 1) ...[
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 10),
            child: Row(
              children: [
                AppIcon(Symbols.layers_rounded, size: 18, fill: 1, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  t.fileInfo.versionCounter(index: index + 1, count: versionCount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (version.title != null && version.title!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      version.title!,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        _InfoSection(title: t.fileInfo.overview, icon: Symbols.movie_info_rounded, fields: _overviewFields(version)),
        for (var partIndex = 0; partIndex < version.parts.length; partIndex++)
          _PartBlock(part: version.parts[partIndex], index: partIndex, partCount: version.parts.length),
        if (version.attachments.isNotEmpty)
          _InfoSection(
            title: t.fileInfo.attachments,
            icon: Symbols.attach_file_rounded,
            subtitle: '${version.attachments.length}',
            fields: [
              for (final attachment in version.attachments)
                _InfoField(
                  label: attachment.fileName ?? '#${attachment.index ?? 0}',
                  value: [
                    if (attachment.mimeType != null) attachment.mimeType!,
                    if (attachment.codec != null) attachment.codec!,
                  ].join(' · '),
                ),
            ],
          ),
        _InfoSection(
          title: t.fileInfo.delivery,
          icon: Symbols.cell_tower_rounded,
          fields: _deliveryFields(context, version),
        ),
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }

  List<_InfoField?> _overviewFields(MediaFileVersion version) {
    return [
      _InfoField.text(t.fileInfo.container, version.container?.toUpperCase()),
      _InfoField.text(t.fileInfo.duration, version.durationFormatted),
      _InfoField.text(t.fileInfo.totalSize, version.totalFileSizeFormatted),
      _InfoField.text(t.fileInfo.overallBitrate, version.bitrateFormatted),
      _InfoField.text(t.fileInfo.resolution, version.resolutionFormatted),
      _InfoField.text(t.fileInfo.aspectRatio, version.aspectRatioFormatted),
      _InfoField.text(t.fileInfo.video, _codecSummary(version.videoCodec, version.videoProfile)),
      _InfoField.text(t.fileInfo.frameRate, version.videoFrameRateLabel),
      _InfoField.text(t.fileInfo.audio, _codecSummary(version.audioCodec, version.audioProfile)),
      _InfoField.text(t.fileInfo.channels, version.audioChannels == null ? null : '${version.audioChannels} ch'),
    ];
  }

  String? _codecSummary(String? codec, String? profile) {
    if (codec == null) return null;
    return profile == null ? codec.toUpperCase() : '${codec.toUpperCase()} · $profile';
  }

  /// Everything about how the server can hand this version over, plus the
  /// bookkeeping fields that only matter when something misbehaves.
  List<_InfoField?> _deliveryFields(BuildContext context, MediaFileVersion version) {
    return [
      _InfoField.text(t.fileInfo.protocol, version.protocol),
      _InfoField.text(t.fileInfo.mediaType, version.videoType),
      _InfoField.text(t.fileInfo.sourceKind, version.sourceType),
      _InfoField.boolean(t.fileInfo.directPlay, version.supportsDirectPlay),
      _InfoField.boolean(t.fileInfo.directStream, version.supportsDirectStream),
      _InfoField.boolean(t.fileInfo.transcoding, version.supportsTranscoding),
      _InfoField.boolean(t.fileInfo.optimizedForStreaming, version.optimizedForStreaming),
      _InfoField.boolean(t.fileInfo.has64bitOffsets, version.has64bitOffsets),
      _InfoField.boolean(t.fileInfo.optimizedVersion, version.isOptimizedVersion),
      _InfoField.text(t.fileInfo.optimizationTarget, version.optimizationTarget),
      _InfoField.text(t.fileInfo.deletedAt, _dateLabel(context, version.deletedAt)),
      _InfoField.text(t.fileInfo.transportTimestamp, version.transportStreamTimestamp),
      _InfoField.text(
        t.fileInfo.displayOffset,
        version.displayOffsetPercent == null ? null : '${version.displayOffsetPercent}%',
      ),
      _InfoField.boolean(t.fileInfo.remoteSource, version.isRemote),
      _InfoField.boolean(t.fileInfo.infiniteStream, version.isInfiniteStream),
      _InfoField.text(t.fileInfo.defaultAudioTrack, _streamIndexLabel(version.defaultAudioStreamIndex)),
      _InfoField.text(t.fileInfo.defaultSubtitleTrack, _streamIndexLabel(version.defaultSubtitleStreamIndex)),
      _InfoField.text(t.fileInfo.versionId, version.id, monospace: true),
      _InfoField.text(t.fileInfo.etag, version.eTag, monospace: true),
    ];
  }

  /// Jellyfin encodes "start with subtitles off" as index -1.
  String? _streamIndexLabel(int? index) {
    if (index == null) return null;
    return index < 0 ? t.fileInfo.subtitlesOff : '#$index';
  }

  /// Locale-aware date plus a clock time that honours the system 24-hour
  /// preference — an ISO string with the offset stripped would be ambiguous.
  String? _dateLabel(BuildContext context, DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final date = formatFullDate(
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}',
    );
    final time = formatClockTime(local, is24Hour: MediaQuery.of(context).alwaysUse24HourFormat);
    return '$date $time';
  }
}

/// One file on disk plus the streams it carries.
class _PartBlock extends StatelessWidget {
  final MediaFilePart part;
  final int index;
  final int partCount;

  const _PartBlock({required this.part, required this.index, required this.partCount});

  /// Video first, then audio, subtitles, images, data — reading order.
  static const _kindOrder = [
    MediaStreamKind.video,
    MediaStreamKind.audio,
    MediaStreamKind.subtitle,
    MediaStreamKind.lyric,
    MediaStreamKind.image,
    MediaStreamKind.data,
    MediaStreamKind.unknown,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoSection(
          title: partCount > 1 ? t.fileInfo.fileCounter(index: index + 1, count: partCount) : t.fileInfo.file,
          icon: Symbols.description_rounded,
          fields: _fileFields(),
          leading: part.filePath == null ? null : _PathRow(path: part.filePath!),
        ),
        for (final kind in _kindOrder)
          if (part.streamsOfKind(kind).isNotEmpty)
            _StreamGroup(kind: kind, streams: part.streamsOfKind(kind).toList(growable: false)),
        if (part.streams.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t.fileInfo.noStreams,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  List<_InfoField?> _fileFields() {
    return [
      // Presence first: when a file has gone missing, that is the answer the
      // sheet was opened for.
      _InfoField.boolean(t.fileInfo.filePresent, part.exists),
      _InfoField.boolean(t.fileInfo.fileReadable, part.accessible),
      _InfoField.text(t.fileInfo.fileName, part.fileName),
      _InfoField.text(t.fileInfo.size, part.fileSizeFormatted),
      _InfoField.text(t.fileInfo.container, part.container?.toUpperCase()),
      _InfoField.text(t.fileInfo.duration, part.durationFormatted),
      _InfoField.boolean(t.fileInfo.optimizedForStreaming, part.optimizedForStreaming),
      _InfoField.boolean(t.fileInfo.has64bitOffsets, part.has64bitOffsets),
      _InfoField.boolean(t.fileInfo.previewThumbnails, part.hasThumbnail),
      _InfoField.text(t.fileInfo.previewIndex, part.indexes),
      _InfoField.text(t.fileInfo.packetLength, part.packetLength?.toString()),
      _InfoField.text(t.fileInfo.previewFailureCode, part.previewFailureCode?.toString()),
      _InfoField.text(t.fileInfo.previewRetries, part.previewRetryCount?.toString()),
      _InfoField.text(t.fileInfo.streamPath, part.streamKey, monospace: true),
      _InfoField.text(t.fileInfo.fileId, part.id, monospace: true),
    ];
  }
}

/// Full-width, monospace, copyable — a path is the one value people extract.
class _PathRow extends StatelessWidget {
  final String path;

  const _PathRow({required this.path});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    showSuccessSnackBar(context, t.fileInfo.pathCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableWrapper(
      semanticLabel: t.fileInfo.copyPath,
      useBackgroundFocus: true,
      disableScale: true,
      onSelect: () => _copy(context),
      // GestureDetector, not InkWell: the sheet renders inside an
      // OverlaySheetHost with no guarantee of an ink-capable Material, and
      // FocusableWrapper already draws the focus affordance.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _copy(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.fileInfo.path,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(path, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: t.fileInfo.copyPath,
                child: AppIcon(Symbols.content_copy_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All streams of one kind, each as its own card.
class _StreamGroup extends StatelessWidget {
  final MediaStreamKind kind;
  final List<MediaStreamDetails> streams;

  const _StreamGroup({required this.kind, required this.streams});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stream in streams)
          _InfoSection(
            title: streams.length > 1 ? '${_groupTitle(kind)} ${stream.ordinal}' : _groupTitle(kind),
            icon: _groupIcon(kind),
            subtitle: stream.headline,
            chips: _flagChips(stream),
            fields: _streamFields(stream),
          ),
      ],
    );
  }

  String _groupTitle(MediaStreamKind kind) => switch (kind) {
    MediaStreamKind.video => t.fileInfo.video,
    MediaStreamKind.audio => t.fileInfo.audio,
    MediaStreamKind.subtitle => t.fileInfo.subtitles,
    MediaStreamKind.image => t.fileInfo.images,
    MediaStreamKind.lyric => t.fileInfo.lyrics,
    MediaStreamKind.data || MediaStreamKind.unknown => t.fileInfo.dataStreams,
  };

  IconData _groupIcon(MediaStreamKind kind) => switch (kind) {
    MediaStreamKind.video => Symbols.movie_rounded,
    MediaStreamKind.audio => Symbols.graphic_eq_rounded,
    MediaStreamKind.subtitle => Symbols.subtitles_rounded,
    MediaStreamKind.image => Symbols.image_rounded,
    MediaStreamKind.lyric => Symbols.lyrics_rounded,
    MediaStreamKind.data || MediaStreamKind.unknown => Symbols.data_object_rounded,
  };

  List<String> _flagChips(MediaStreamDetails stream) {
    return [
      if (stream.isDefault ?? false) t.fileInfo.flagDefault,
      if (stream.isSelected ?? false) t.fileInfo.flagSelected,
      if (stream.isForced ?? false) t.fileInfo.flagForced,
      if (stream.isExternal ?? false) t.fileInfo.flagExternal,
      if (stream.isHearingImpaired ?? false) t.fileInfo.flagHearingImpaired,
      if (stream.isDub ?? false) t.fileInfo.flagDub,
      if (stream.isOriginal ?? false) t.fileInfo.flagOriginal,
    ];
  }

  /// Common identity fields first, then the kind-specific block, then the
  /// low-level container details.
  List<_InfoField?> _streamFields(MediaStreamDetails stream) {
    return [
      _InfoField.text(t.fileInfo.codec, stream.codec?.toUpperCase()),
      _InfoField.text(t.fileInfo.profile, stream.profile),
      // Level 0 is both servers' "not applicable" for audio/subtitle streams.
      _InfoField.text(t.fileInfo.level, (stream.level ?? 0) > 0 ? stream.level!.toString() : null),
      _InfoField.text(t.fileInfo.language, stream.language),
      // Servers that cannot resolve a display name echo the ISO code into
      // both fields; one row is enough then.
      _InfoField.text(t.fileInfo.languageCode, _distinctLanguageCode(stream)),
      _InfoField.text(t.fileInfo.streamTitle, stream.title),
      _InfoField.text(t.fileInfo.bitrate, stream.bitrateFormatted),
      if (kind == MediaStreamKind.video || kind == MediaStreamKind.image) ..._videoFields(stream),
      if (kind == MediaStreamKind.audio) ..._audioFields(stream),
      if (kind == MediaStreamKind.subtitle) ..._subtitleFields(stream),
      _InfoField.text(t.fileInfo.codecTag, stream.codecTag),
      _InfoField.text(t.fileInfo.timeBase, stream.timeBase),
      _InfoField.text(t.fileInfo.streamIdentifier, stream.streamIdentifier),
      _InfoField.text(t.fileInfo.streamIndex, stream.index?.toString()),
      _InfoField.text(t.fileInfo.comment, stream.comment),
      _InfoField.text(t.fileInfo.sidecarFile, stream.filePath, monospace: true),
      _InfoField.text(t.fileInfo.streamId, stream.id, monospace: true),
    ];
  }

  String? _distinctLanguageCode(MediaStreamDetails stream) {
    final code = stream.languageCode;
    if (code == null) return null;
    return code.toLowerCase() == stream.language?.toLowerCase() ? null : code;
  }

  List<_InfoField?> _videoFields(MediaStreamDetails stream) {
    final dolbyVision = stream.dolbyVision;
    return [
      _InfoField.text(t.fileInfo.resolution, stream.resolutionFormatted),
      _InfoField.text(t.fileInfo.codedResolution, stream.codedResolutionFormatted),
      _InfoField.text(t.fileInfo.aspectRatio, stream.aspectRatio),
      _InfoField.text(t.fileInfo.pixelAspectRatio, stream.pixelAspectRatio),
      _InfoField.text(t.fileInfo.frameRate, stream.frameRateFormatted),
      _InfoField.text(t.fileInfo.rotation, stream.rotation == null ? null : '${stream.rotation}°'),
      _InfoField.text(t.fileInfo.dynamicRange, _dynamicRange(stream)),
      _InfoField.text(t.fileInfo.bitDepth, stream.bitDepthFormatted),
      _InfoField.text(t.fileInfo.pixelFormat, stream.pixelFormat),
      _InfoField.text(t.fileInfo.colorSpace, stream.colorSpace),
      _InfoField.text(t.fileInfo.colorRange, stream.colorRange),
      _InfoField.text(t.fileInfo.colorPrimaries, stream.colorPrimaries),
      _InfoField.text(t.fileInfo.colorTransfer, stream.colorTransfer),
      _InfoField.text(t.fileInfo.chromaSubsampling, stream.chromaSubsampling),
      _InfoField.text(t.fileInfo.chromaLocation, stream.chromaLocation),
      _InfoField.text(t.fileInfo.scanType, stream.scanType),
      _InfoField.boolean(t.fileInfo.interlaced, stream.isInterlaced),
      _InfoField.boolean(t.fileInfo.anamorphic, stream.isAnamorphic),
      _InfoField.text(t.fileInfo.referenceFrames, stream.refFrames?.toString()),
      if (dolbyVision != null) ...[
        _InfoField.text(t.fileInfo.dolbyVision, dolbyVision.profileFormatted),
        _InfoField.text(t.fileInfo.dolbyVisionLevel, dolbyVision.level?.toString()),
        _InfoField.text(t.fileInfo.dolbyVisionVersion, dolbyVision.version),
        _InfoField.text(t.fileInfo.dolbyVisionLayers, _dolbyVisionLayers(dolbyVision)),
        _InfoField.text(t.fileInfo.baseLayerCompatibility, dolbyVision.blCompatibilityId?.toString()),
      ],
      _InfoField.boolean(t.fileInfo.avcBitstream, stream.isAvc),
      _InfoField.text(t.fileInfo.nalLengthSize, stream.nalLengthSize?.toString()),
      _InfoField.boolean(t.fileInfo.scalingMatrix, stream.hasScalingMatrix),
    ];
  }

  List<_InfoField?> _audioFields(MediaStreamDetails stream) {
    return [
      _InfoField.text(t.fileInfo.channels, stream.channelsFormatted),
      _InfoField.text(t.fileInfo.sampleRate, stream.sampleRateFormatted),
      _InfoField.text(t.fileInfo.bitDepth, stream.bitDepthFormatted),
      _InfoField.text(t.fileInfo.spatialAudio, stream.spatialFormatLabel),
    ];
  }

  List<_InfoField?> _subtitleFields(MediaStreamDetails stream) {
    return [
      _InfoField.boolean(t.fileInfo.textBased, stream.isTextSubtitle),
      _InfoField.boolean(t.fileInfo.externalDelivery, stream.supportsExternalStream),
      _InfoField.text(t.fileInfo.subtitleFormat, stream.subtitleFormat),
      _InfoField.text(t.fileInfo.provider, stream.providerTitle),
      _InfoField.text(t.fileInfo.matchScore, stream.score?.toString()),
      _InfoField.boolean(t.fileInfo.audioDescription, stream.hasDescriptions),
      _InfoField.boolean(t.fileInfo.headerCompression, stream.headerCompression),
      _InfoField.boolean(t.fileInfo.temporary, stream.isTransient),
      _InfoField.text(t.fileInfo.sourceStream, stream.sourceKey, monospace: true),
      _InfoField.text(t.fileInfo.sidecarPath, stream.externalKey, monospace: true),
    ];
  }

  /// `HDR10+` is an independent flag, so it is appended rather than replacing
  /// the base classification.
  String? _dynamicRange(MediaStreamDetails stream) {
    final label = stream.videoRange.label;
    final hasHdr10Plus = stream.hasHdr10Plus ?? false;
    if (label == null) return hasHdr10Plus ? 'HDR10+' : null;
    if (!hasHdr10Plus || stream.videoRange == MediaVideoRange.hdr10Plus) return label;
    return '$label + HDR10+';
  }

  String? _dolbyVisionLayers(MediaDolbyVisionInfo info) {
    final layers = [
      if (info.blPresent ?? false) 'BL',
      if (info.elPresent ?? false) 'EL',
      if (info.rpuPresent ?? false) 'RPU',
    ];
    return layers.isEmpty ? null : layers.join(' + ');
  }
}

/// A titled card holding a responsive field grid.
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<String> chips;
  final List<_InfoField?> fields;

  /// Rendered above the grid — used for the full-width path row.
  final Widget? leading;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.fields,
    this.subtitle,
    this.chips = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final populated = fields.whereType<_InfoField>().toList(growable: false);
    if (populated.isEmpty && leading == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final mono = tokens(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        // Flat: a tonal step off whatever the sheet is sitting on, no stroke.
        // `bg` would collapse against the sheet on the OLED theme, where
        // background and surface are one shade apart, so the fill is derived
        // from the text colour the way the theme's own hover overlay is.
        color: mono.text.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(mono.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 18, fill: 1, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips) StatChip(label: chip, backgroundColor: mono.text.withValues(alpha: 0.1)),
              ],
            ),
          ],
          if (leading != null) ...[const SizedBox(height: 8), leading!],
          if (populated.isNotEmpty) ...[const SizedBox(height: 4), _FieldGrid(fields: populated)],
        ],
      ),
    );
  }
}

/// Two columns when there is room, one when there is not.
class _FieldGrid extends StatelessWidget {
  static const double _minColumnWidth = 220;
  static const double _columnGap = 16;

  final List<_InfoField> fields;

  const _FieldGrid({required this.fields});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= _minColumnWidth * 2 + _columnGap ? 2 : 1;
        final cellWidth = columns == 1 ? width : (width - _columnGap) / 2;
        return Wrap(
          spacing: _columnGap,
          children: [
            for (final field in fields)
              SizedBox(
                width: field.fullWidth ? width : cellWidth,
                child: _FocusableField(field: field),
              ),
          ],
        );
      },
    );
  }
}

/// Label above value. Focusable so D-pad users can walk (and auto-scroll)
/// through a long table; there is nothing to activate.
class _FocusableField extends StatefulWidget {
  final _InfoField field;

  const _FocusableField({required this.field});

  @override
  State<_FocusableField> createState() => _FocusableFieldState();
}

class _FocusableFieldState extends State<_FocusableField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'FileInfoField(${widget.field.label})');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) scrollContextToCenter(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = widget.field;
    return Focus(
      focusNode: _focusNode,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(
              field.value,
              style: field.monospace
                  ? theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
                  : theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// A populated label/value pair. The `text`/`boolean` factories return null for
/// absent data so the grids can be declared as flat lists.
class _InfoField {
  final String label;
  final String value;
  final bool monospace;
  final bool fullWidth;

  const _InfoField({required this.label, required this.value, this.monospace = false, this.fullWidth = false});

  static _InfoField? text(String label, String? value, {bool monospace = false}) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    return _InfoField(label: label, value: trimmed, monospace: monospace, fullWidth: trimmed.length > 42);
  }

  static _InfoField? boolean(String label, bool? value) {
    if (value == null) return null;
    return _InfoField(label: label, value: value ? t.common.yes : t.common.no);
  }
}
