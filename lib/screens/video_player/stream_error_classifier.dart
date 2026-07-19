import '../../mpv/models.dart';

bool shouldRecoverTransientVodPlayerError({
  required bool isLive,
  required bool isOffline,
  required PlayerError error,
  String? recentLog,
}) {
  return !isLive && !isOffline && isTransientStreamPlayerError(error, recentLog: recentLog);
}

/// Whether a VOD player failure is likely to recover after resolving and
/// reopening the same stream.
///
/// Native players should prefer [PlayerError.transientNetwork] so this does
/// not depend on localized or backend-specific text. The message fallback is
/// retained for libmpv/FFmpeg errors, which currently arrive without a
/// machine-readable cause.
bool isTransientStreamPlayerError(PlayerError error, {String? recentLog}) {
  if (error.cause == PlayerError.serverHttp500) return false;
  if (error.cause == PlayerError.transientNetwork) return true;

  final text = '${error.message}\n${recentLog ?? ''}'.toLowerCase();

  // Decoder, demuxer, and unsupported-format failures need a source/codec
  // change rather than repeatedly reopening the same URL.
  const permanentMarkers = <String>[
    'decoder',
    'decoding failed',
    'codec not supported',
    'unsupported codec',
    'unsupported format',
    'format not supported',
  ];
  if (permanentMarkers.any(text.contains)) return false;

  const transientMarkers = <String>[
    'timed out',
    'timeout',
    'connection reset',
    'connection aborted',
    'connection refused',
    'connection closed',
    'connection lost',
    'broken pipe',
    'network error',
    'network is unreachable',
    'network unreachable',
    'host is unreachable',
    'no route to host',
    'socketexception',
    'socket exception',
    'input/output error',
    'i/o error',
    'remote end closed connection',
    'unexpected end of stream',
    'unexpected end of input',
    'unexpected eof',
    'http 408',
    'http 429',
    'http 502',
    'http 503',
    'http 504',
    'response code: 408',
    'response code: 429',
    'response code: 502',
    'response code: 503',
    'response code: 504',
    'status code: 408',
    'status code: 429',
    'status code: 502',
    'status code: 503',
    'status code: 504',
  ];
  return transientMarkers.any(text.contains);
}
