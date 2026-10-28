import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/steam_stream_metrics.dart';
import 'package:plezy/screens/games/steam_stream_diagnostics.dart';

import 'steam_stream_metrics_test.dart' show metricsFixture;

void main() {
  testWidgets('measurements wrap in a narrow RTL dialog and polling stops when closed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SteamStreamDiagnostics(
              readMetrics: () async {
                reads++;
                return SteamStreamMetrics.fromNative({
                  ...metricsFixture(time: reads * 1000000),
                  'decoderKind': 1,
                  'targetBitrate': 12000000,
                  'fpsNumerator': 30,
                  'fpsDenominator': 1,
                  'fpsReasons': 0x18,
                  'videoBytes': reads * 1500000,
                  'presentedFrames': reads * 30,
                });
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(reads, 2);
    expect(tester.takeException(), isNull);
  });
}
