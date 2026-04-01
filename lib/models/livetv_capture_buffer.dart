/// Represents the seekable capture buffer for a live TV transcode session.
///
/// Extracted from the `TranscodeSession` element in the tune response:
/// - [startedAt] = `timeStamp` (epoch seconds, the buffer origin)
/// - [seekStartSeconds] = `minOffsetAvailable` (earliest seekable offset)
/// - [seekEndSeconds] = `maxOffsetAvailable` (latest seekable offset / live edge)
class CaptureBuffer {
  final double startedAt;
  final double seekStartSeconds;
  final double seekEndSeconds;

  const CaptureBuffer({
    required this.startedAt,
    required this.seekStartSeconds,
    required this.seekEndSeconds,
  });

  /// Absolute epoch second of the earliest seekable point.
  int get seekableStartEpoch => (startedAt + seekStartSeconds).round();

  /// Absolute epoch second of the latest seekable point (≈ live edge).
  int get seekableEndEpoch => (startedAt + seekEndSeconds).round();

  /// Duration of the seekable range in seconds.
  int get seekableDurationSeconds => (seekEndSeconds - seekStartSeconds).round();

  /// Parse from a TranscodeSession JSON map. Returns null if required fields are missing.
  /// Values may be num or String depending on whether the server returned JSON or XML.
  static CaptureBuffer? fromTranscodeSession(Map<String, dynamic> session) {
    final timeStamp = _parseDouble(session['timeStamp']);
    final minOffset = _parseDouble(session['minOffsetAvailable']);
    final maxOffset = _parseDouble(session['maxOffsetAvailable']);
    if (timeStamp == null || minOffset == null || maxOffset == null) return null;
    return CaptureBuffer(
      startedAt: timeStamp,
      seekStartSeconds: minOffset,
      seekEndSeconds: maxOffset,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'CaptureBuffer(startedAt: $startedAt, seek: $seekStartSeconds..$seekEndSeconds, '
      'range: $seekableStartEpoch..$seekableEndEpoch)';
}
