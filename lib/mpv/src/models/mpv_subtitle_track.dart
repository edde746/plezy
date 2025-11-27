/// Represents a subtitle track in the media.
class MpvSubtitleTrack {
  /// Unique identifier for the track.
  final String id;

  /// Human-readable title of the track.
  final String? title;

  /// Language code (e.g., 'eng', 'jpn').
  final String? language;

  /// Subtitle codec/format (e.g., 'subrip', 'ass', 'pgs').
  final String? codec;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this track is forced (e.g., for foreign language segments).
  final bool isForced;

  /// Whether this is an external subtitle file.
  final bool isExternal;

  /// URI of external subtitle file (if isExternal is true).
  final String? uri;

  const MpvSubtitleTrack({
    required this.id,
    this.title,
    this.language,
    this.codec,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.uri,
  });

  /// Create a subtitle track from an external URI.
  factory MpvSubtitleTrack.uri(
    String uri, {
    String? title,
    String? language,
  }) {
    return MpvSubtitleTrack(
      id: 'external:$uri',
      title: title,
      language: language,
      isExternal: true,
      uri: uri,
    );
  }

  /// Auto-select track.
  static const auto = MpvSubtitleTrack(id: 'auto', title: 'Auto');

  /// Disable subtitles.
  static const off = MpvSubtitleTrack(id: 'no', title: 'Off');

  /// Returns a display name for the track.
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    if (isExternal) return 'External';
    return 'Track $id';
  }

  @override
  String toString() => 'MpvSubtitleTrack($id, $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MpvSubtitleTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
