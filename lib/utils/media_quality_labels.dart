import '../media/media_item.dart';
import '../media/media_stream.dart';
import '../media/media_version.dart';
import 'codec_utils.dart';
import 'resolution_label.dart';
import 'formatters.dart';

List<String> buildMediaQualityLabels(MediaItem item, {int versionIndex = 0}) {
  final version = _selectedVersion(item.mediaVersions, versionIndex);
  if (version == null) return const [];

  final labels = <String>[];
  final resolution = _formatResolution(version);
  if (resolution != null) labels.add(resolution);

  final video = _firstStreamOfKind(version, MediaStreamKind.video);
  if (video?.dolbyVision == true) {
    labels.add(_formatDolbyVision(video!));
  } else if (video?.hdr == true) {
    labels.add('HDR');
  }

  final audio = _selectedAudioStream(version);
  final audioLabel = _formatAudio(audio);
  if (audioLabel != null) labels.add(audioLabel);

  return labels;
}

String? buildMediaSizeLabel(MediaItem item, {int versionIndex = 0}) {
  final version = _selectedVersion(item.mediaVersions, versionIndex);
  if (version == null || version.parts.isEmpty) return null;

  var totalBytes = 0;
  for (final part in version.parts) {
    final sizeBytes = part.sizeBytes;
    if (sizeBytes == null || sizeBytes <= 0) return null;
    totalBytes += sizeBytes;
  }

  return ByteFormatter.formatBytes(totalBytes);
}

String _formatDolbyVision(MediaStream stream) {
  final profile = stream.dolbyVisionProfile;
  return profile == null || profile <= 0 ? 'DV' : 'DV P$profile';
}

MediaVersion? _selectedVersion(List<MediaVersion>? versions, int versionIndex) {
  if (versions == null || versions.isEmpty) return null;
  if (versionIndex >= 0 && versionIndex < versions.length) {
    return versions[versionIndex];
  }
  return versions.first;
}

String? _formatResolution(MediaVersion version) {
  final raw = version.videoResolution?.trim();
  if (raw != null && raw.isNotEmpty) return _formatResolutionValue(raw);

  final fallback = resolutionLabelFromDimensions(version.width, version.height);
  return fallback == null ? null : _formatResolutionValue(fallback);
}

String _formatResolutionValue(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == '4k' || normalized == 'uhd') return '4K';
  if (normalized == 'sd') return 'SD';

  final numeric = RegExp(r'^(\d+)(?:p)?$').firstMatch(normalized);
  if (numeric != null) {
    final height = int.tryParse(numeric.group(1)!);
    if (height != null && height >= 2160) return '4K';
    return '${numeric.group(1)}p';
  }

  return value.toUpperCase();
}

MediaStream? _firstStreamOfKind(MediaVersion version, MediaStreamKind kind) {
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if (stream.kind == kind) return stream;
    }
  }
  return null;
}

MediaStream? _selectedAudioStream(MediaVersion version) {
  MediaStream? first;
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if (stream.kind != MediaStreamKind.audio) continue;
      first ??= stream;
      if (stream.selected) return stream;
    }
  }
  return first;
}

String? _formatAudio(MediaStream? stream) {
  if (stream == null) return null;

  final parts = <String>[];
  final codec = stream.codec?.trim();
  if (codec != null && codec.isNotEmpty) parts.add(_formatAudioCodec(codec));

  if (_isAtmos(stream)) {
    parts.add('Atmos');
  } else {
    final channels = CodecUtils.formatAudioChannels(stream.channels);
    if (channels != null) parts.add(channels);
  }

  return parts.isEmpty ? null : parts.join(' ');
}

String _formatAudioCodec(String codec) {
  return switch (codec.toLowerCase()) {
    'eac3' || 'ec3' => 'EAC3',
    'ac3' => 'AC3',
    _ => CodecUtils.formatAudioCodec(codec),
  };
}

bool _isAtmos(MediaStream stream) {
  return [
    stream.codec,
    stream.title,
    stream.displayTitle,
  ].whereType<String>().any((value) => value.toLowerCase().contains('atmos'));
}
