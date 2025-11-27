/// Represents an audio track in the media.
class MpvAudioTrack {
  /// Unique identifier for the track.
  final String id;

  /// Human-readable title of the track.
  final String? title;

  /// Language code (e.g., 'eng', 'jpn').
  final String? language;

  /// Audio codec (e.g., 'aac', 'ac3', 'dts').
  final String? codec;

  /// Number of audio channels.
  final int? channels;

  /// Alias for channels (media_kit compatibility).
  int? get channelsCount => channels;

  /// Sample rate in Hz.
  final int? sampleRate;

  /// Bitrate in bits per second.
  final int? bitrate;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this track is forced.
  final bool isForced;

  const MpvAudioTrack({
    required this.id,
    this.title,
    this.language,
    this.codec,
    this.channels,
    this.sampleRate,
    this.bitrate,
    this.isDefault = false,
    this.isForced = false,
  });

  /// Auto-select track.
  static const auto = MpvAudioTrack(id: 'auto', title: 'Auto');

  /// Disable audio.
  static const off = MpvAudioTrack(id: 'no', title: 'Off');

  /// Returns a display name for the track.
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    return 'Track $id';
  }

  @override
  String toString() => 'MpvAudioTrack($id, $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MpvAudioTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
