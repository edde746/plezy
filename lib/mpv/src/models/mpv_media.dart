/// Represents a media source for the MPV player.
class MpvMedia {
  /// The URI of the media (file path, HTTP URL, etc.).
  final String uri;

  /// Optional HTTP headers for network requests.
  final Map<String, String>? headers;

  /// Optional start position for playback.
  final Duration? start;

  const MpvMedia(
    this.uri, {
    this.headers,
    this.start,
  });

  @override
  String toString() => 'MpvMedia($uri)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MpvMedia &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          start == other.start;

  @override
  int get hashCode => uri.hashCode ^ start.hashCode;
}
