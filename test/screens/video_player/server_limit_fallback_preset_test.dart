import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/screens/video_player/playback_failure_action.dart';

TranscodeQualityPreset? resolve({
  bool isLive = false,
  bool isPlexBacked = true,
  bool serverSupportsTranscoding = true,
  TranscodeQualityPreset requestedPreset = TranscodeQualityPreset.original,
  bool fallbackAlreadyUsed = false,
}) {
  return serverLimitFallbackPreset(
    isLive: isLive,
    isPlexBacked: isPlexBacked,
    serverSupportsTranscoding: serverSupportsTranscoding,
    requestedPreset: requestedPreset,
    fallbackAlreadyUsed: fallbackAlreadyUsed,
  );
}

void main() {
  test('an on-demand Plex open at Original offers 1080p 8 Mbps', () {
    expect(resolve(), TranscodeQualityPreset.p1080_8mbps);
    expect(serverLimitFallbackCap, TranscodeQualityPreset.p1080_8mbps);
  });

  test('live TV gets no offer', () {
    expect(resolve(isLive: true), isNull);
  });

  test('a non-Plex item gets no offer', () {
    // Jellyfin and Emby answer a refused stream differently; the capped
    // transcode path is Plex's decision and start handshake.
    expect(resolve(isPlexBacked: false), isNull);
  });

  test('a server that cannot transcode gets no offer', () {
    expect(resolve(serverSupportsTranscoding: false), isNull);
  });

  test('a capped preset gets no offer', () {
    // The refused request was already a transcode: offering another one is a
    // retry of the same kind of request.
    for (final preset in TranscodeQualityPreset.values.where((p) => !p.isOriginal)) {
      expect(resolve(requestedPreset: preset), isNull, reason: preset.name);
    }
  });

  test('an item that already tried the capped transcode gets no second offer', () {
    expect(resolve(fallbackAlreadyUsed: true), isNull);
  });
}
