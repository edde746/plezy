import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/screens/video_player/playback_failure_action.dart';

bool offers({
  bool isLive = false,
  bool isPlexBacked = true,
  bool serverSupportsTranscoding = true,
  TranscodeQualityPreset requestedPreset = TranscodeQualityPreset.original,
  bool fallbackAlreadyUsed = false,
}) {
  return offersServerLimitTranscode(
    isLive: isLive,
    isPlexBacked: isPlexBacked,
    serverSupportsTranscoding: serverSupportsTranscoding,
    requestedPreset: requestedPreset,
    fallbackAlreadyUsed: fallbackAlreadyUsed,
  );
}

void main() {
  test('an on-demand Plex open at Original offers a transcode', () {
    expect(offers(), isTrue);
  });

  test('live TV gets no offer', () {
    expect(offers(isLive: true), isFalse);
  });

  test('a non-Plex item gets no offer', () {
    // Jellyfin and Emby answer a refused stream differently; the forced
    // transcode path is Plex's decision and start handshake.
    expect(offers(isPlexBacked: false), isFalse);
  });

  test('a server that cannot transcode gets no offer', () {
    expect(offers(serverSupportsTranscoding: false), isFalse);
  });

  test('a capped preset gets no offer', () {
    // The refused request was already a transcode: offering another one is a
    // retry of the same kind of request.
    for (final preset in TranscodeQualityPreset.values.where((p) => !p.isOriginal)) {
      expect(offers(requestedPreset: preset), isFalse, reason: preset.name);
    }
  });

  test('an item that already tried the transcode gets no second offer', () {
    expect(offers(fallbackAlreadyUsed: true), isFalse);
  });
}
