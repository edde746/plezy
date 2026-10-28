import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/steam_stream_metrics.dart';

Map<String, Object> metricsFixture({int time = 1000000}) => {
  'version': 1,
  'epoch': 1,
  'sampledAtUs': time,
  'receivedFrames': 0,
  'presentedFrames': 0,
  'droppedFrames': 0,
  'resetFrames': 0,
  'videoBytes': 0,
  'completionTotalUs': 0,
  'completedFrames': 0,
  'width': 1920,
  'height': 1080,
  'codec': 4,
  'audioChannels': 2,
  'fpsNumerator': 0,
  'fpsDenominator': 0,
  'fpsReasons': 0,
  'targetBitrate': 0,
  'reliableRetries': 0,
  'reliableGiveUps': 0,
  'reliableOutstanding': 0,
  'maxAckLatencyMs': 0,
  'hidPending': 0,
  'hidInFlight': 0,
};

void main() {
  test('unknown targets remain unknown and negotiated fractions are preserved', () {
    var metrics = SteamStreamMetrics.fromNative(metricsFixture());
    expect(metrics.hostFps, isNull);
    expect(metrics.hostMbps, isNull);
    expect(metrics.codec, 'H.264');
    expect(metrics.decoderKind, 0);
    metrics = SteamStreamMetrics.fromNative({
      ...metricsFixture(),
      'fpsNumerator': 30000,
      'fpsDenominator': 1001,
      'targetBitrate': 12000000,
    });
    expect(metrics.hostFps, closeTo(29.970, .001));
    expect(metrics.hostMbps, 12);
  });

  test('rates use monotonic sample duration and completed frame deltas', () {
    final before = SteamStreamMetrics.fromNative(metricsFixture());
    final after = SteamStreamMetrics.fromNative({
      ...metricsFixture(time: 3000000),
      'receivedFrames': 120,
      'presentedFrames': 118,
      'droppedFrames': 2,
      'completedFrames': 120,
      'videoBytes': 3000000,
      'completionTotalUs': 1800000,
    });
    final rates = SteamStreamRates.between(before, after)!;
    expect(rates.presentedFps, 59);
    expect(rates.videoMbps, 12);
    expect(rates.completionMs, 15);
  });

  test('reconnects, clock rollback, missing intervals and counter reset invalidate rates', () {
    final before = SteamStreamMetrics.fromNative({...metricsFixture(), 'presentedFrames': 10});
    for (final patch in <Map<String, Object>>[
      {'epoch': 2},
      {'sampledAtUs': 1},
      {'sampledAtUs': 1000001},
      {'sampledAtUs': 20000000},
      {'presentedFrames': 0},
    ]) {
      final after = SteamStreamMetrics.fromNative({...metricsFixture(time: 2000000), 'presentedFrames': 20, ...patch});
      expect(SteamStreamRates.between(before, after), isNull);
    }
    final idle = SteamStreamRates.between(
      SteamStreamMetrics.fromNative(metricsFixture()),
      SteamStreamMetrics.fromNative(metricsFixture(time: 2000000)),
    )!;
    expect(idle.completionMs, isNull);
  });

  test('malformed native snapshots are rejected without inventing values', () {
    for (final patch in <Map<String, Object?>>[
      {'version': 2},
      {'epoch': 0},
      {'codec': 7},
      {'sampledAtUs': -1},
      {'videoBytes': '100'},
      {'videoQueue': 10000},
      {'decoderKind': 9},
      {'width': 9000},
      {'targetBitrate': 1000000001},
      {'completionTotalUs': double.nan},
      {'receivedFrames': null},
    ]) {
      expect(() => SteamStreamMetrics.fromNative({...metricsFixture(), ...patch}), throwsFormatException);
    }
  });
}
