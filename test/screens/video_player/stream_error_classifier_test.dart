import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/screens/video_player/stream_error_classifier.dart';

void main() {
  test('transient recovery is limited to online VOD', () {
    const error = PlayerError('network timeout');
    expect(shouldRecoverTransientVodPlayerError(isLive: false, isOffline: false, error: error), isTrue);
    expect(shouldRecoverTransientVodPlayerError(isLive: true, isOffline: false, error: error), isFalse);
    expect(shouldRecoverTransientVodPlayerError(isLive: false, isOffline: true, error: error), isFalse);
  });

  group('isTransientStreamPlayerError', () {
    test('accepts the native machine-readable network cause', () {
      expect(
        isTransientStreamPlayerError(const PlayerError('Playback failed', cause: PlayerError.transientNetwork)),
        isTrue,
      );
    });

    test('recognizes common libmpv and HTTP gateway failures', () {
      expect(isTransientStreamPlayerError(const PlayerError('Connection reset by peer')), isTrue);
      expect(isTransientStreamPlayerError(const PlayerError('Input/output error')), isTrue);
      expect(isTransientStreamPlayerError(const PlayerError('HTTP 408 Request Timeout')), isTrue);
      expect(isTransientStreamPlayerError(const PlayerError('HTTP 429 Too Many Requests')), isTrue);
      expect(isTransientStreamPlayerError(const PlayerError('HTTP 503 Service Unavailable')), isTrue);
      expect(
        isTransientStreamPlayerError(const PlayerError('Playback failed'), recentLog: 'SocketException: timed out'),
        isTrue,
      );
    });

    test('does not retry permanent decoder or server-limit failures', () {
      expect(
        isTransientStreamPlayerError(const PlayerError('Decoder initialization failed: unsupported codec')),
        isFalse,
      );
      expect(
        isTransientStreamPlayerError(
          const PlayerError('HTTP 500', cause: PlayerError.serverHttp500),
          recentLog: 'connection timed out',
        ),
        isFalse,
      );
    });
  });
}
