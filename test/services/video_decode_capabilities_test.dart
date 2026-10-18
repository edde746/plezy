import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_decode_capabilities.dart';
import 'package:plezy/utils/device_channel.dart';

import '../test_helpers/prefs.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  /// Answers `com.plezy/device` with [reply] and records each call. A null
  /// [reply] leaves the method unimplemented, which is what desktop and a
  /// stale native build look like.
  List<String> stubProbe(Object? reply) {
    final calls = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(deviceChannel, (call) async {
      calls.add(call.method);
      if (reply == null) throw MissingPluginException();
      if (reply is PlatformException) throw reply;
      return reply;
    });
    addTearDown(() => binding.defaultBinaryMessenger.setMockMethodCallHandler(deviceChannel, null));
    return calls;
  }

  bool acceptsHevc() => VideoDecodeCapabilities.accepts(RankedVideoCodec.hevc);
  bool acceptsAv1() => VideoDecodeCapabilities.accepts(RankedVideoCodec.av1);

  setUp(() {
    VideoDecodeCapabilities.debugReset();
    addTearDown(VideoDecodeCapabilities.debugReset);
  });

  test('advertises both codecs before the probe has run', () {
    expect(acceptsHevc(), isTrue);
    expect(acceptsAv1(), isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unknown');
  });

  test('reports the decoders the platform found', () async {
    stubProbe(<String, Object?>{'hevc': true, 'av1': false});

    await VideoDecodeCapabilities.getInstance();

    expect(acceptsHevc(), isTrue);
    expect(acceptsAv1(), isFalse);
    expect(VideoDecodeCapabilities.describeSync(), 'hevc=hw av1=none');
  });

  test('a missing codec entry counts as no hardware decoder', () async {
    stubProbe(<String, Object?>{'hevc': true});

    await VideoDecodeCapabilities.getInstance();

    expect(acceptsAv1(), isFalse);
  });

  // Desktop implements no probe at all, so the advertised codec list must stay
  // wide there: those platforms software-decode both codecs in real time.
  test('an unanswered probe keeps both codecs advertised', () async {
    stubProbe(null);

    await VideoDecodeCapabilities.getInstance();

    expect(acceptsHevc(), isTrue);
    expect(acceptsAv1(), isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unprobed');
  });

  test('a failed probe keeps both codecs advertised', () async {
    stubProbe(PlatformException(code: 'error', message: 'MediaCodecList exploded'));

    await VideoDecodeCapabilities.getInstance();

    expect(acceptsHevc(), isTrue);
    expect(acceptsAv1(), isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unprobed');
  });

  test('the probe runs once and is shared by concurrent callers', () async {
    final calls = stubProbe(<String, Object?>{'hevc': false, 'av1': false});

    final instances = await (VideoDecodeCapabilities.getInstance(), VideoDecodeCapabilities.getInstance()).wait;

    expect(calls, ['getVideoDecodeCapabilities']);
    expect(identical(instances.$1, instances.$2), isTrue);
    expect(acceptsHevc(), isFalse);
    expect(VideoDecodeCapabilities.describeSync(), 'hevc=none av1=none');
  });

  group('user refusals (#2443)', () {
    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      await SettingsService.getInstance();
    });

    Future<void> refuse(List<String> ids) => SettingsService.instance.write(SettingsService.refusedVideoCodecs, ids);

    // Desktop's probe never answers, so a refusal is the only thing that can
    // narrow the list there — and it must, or a weak machine keeps being
    // handed a codec it cannot decode.
    test('a refused codec is dropped without narrowing the ranked order', () async {
      stubProbe(null);
      await VideoDecodeCapabilities.getInstance();
      await refuse(['hevc']);

      expect(acceptsHevc(), isFalse);
      expect(acceptsAv1(), isTrue);
      expect(VideoDecodeCapabilities.transcodeVideoCodecs, [RankedVideoCodec.av1, RankedVideoCodec.h264]);
    });

    test('H.264 stays accepted even when stored as refused', () async {
      await refuse(['av1', 'hevc', 'h264']);

      expect(VideoDecodeCapabilities.isRefusedByUser(RankedVideoCodec.h264), isFalse);
      expect(VideoDecodeCapabilities.transcodeVideoCodecs, [RankedVideoCodec.h264]);
    });

    test('a refusal and a missing hardware decoder each remove their own codec', () async {
      stubProbe(<String, Object?>{'hevc': true, 'av1': false});
      await VideoDecodeCapabilities.getInstance();
      await refuse(['hevc']);

      expect(VideoDecodeCapabilities.transcodeVideoCodecs, [RankedVideoCodec.h264]);
      // Only the refusal counts as the user's: Plex gates direct play on it alone.
      expect(VideoDecodeCapabilities.isRefusedByUser(RankedVideoCodec.hevc), isTrue);
      expect(VideoDecodeCapabilities.isRefusedByUser(RankedVideoCodec.av1), isFalse);
    });

    test('a changed refusal applies without re-probing', () async {
      await refuse(['av1']);
      expect(acceptsAv1(), isFalse);

      await refuse(const []);
      expect(acceptsAv1(), isTrue);
    });
  });
}
