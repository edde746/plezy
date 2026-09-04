import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/video_decode_capabilities.dart';
import 'package:plezy/utils/device_channel.dart';

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

  setUp(() {
    VideoDecodeCapabilities.debugReset();
    addTearDown(VideoDecodeCapabilities.debugReset);
  });

  test('advertises both codecs before the probe has run', () {
    expect(VideoDecodeCapabilities.supportsHevc, isTrue);
    expect(VideoDecodeCapabilities.supportsAv1, isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unknown');
  });

  test('reports the decoders the platform found', () async {
    stubProbe(<String, Object?>{'hevc': true, 'av1': false});

    await VideoDecodeCapabilities.getInstance();

    expect(VideoDecodeCapabilities.supportsHevc, isTrue);
    expect(VideoDecodeCapabilities.supportsAv1, isFalse);
    expect(VideoDecodeCapabilities.describeSync(), 'hevc=hw av1=none');
  });

  test('a missing codec entry counts as no hardware decoder', () async {
    stubProbe(<String, Object?>{'hevc': true});

    await VideoDecodeCapabilities.getInstance();

    expect(VideoDecodeCapabilities.supportsAv1, isFalse);
  });

  // Desktop implements no probe at all, so the advertised codec list must stay
  // wide there: those platforms software-decode both codecs in real time.
  test('an unanswered probe keeps both codecs advertised', () async {
    stubProbe(null);

    await VideoDecodeCapabilities.getInstance();

    expect(VideoDecodeCapabilities.supportsHevc, isTrue);
    expect(VideoDecodeCapabilities.supportsAv1, isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unprobed');
  });

  test('a failed probe keeps both codecs advertised', () async {
    stubProbe(PlatformException(code: 'error', message: 'MediaCodecList exploded'));

    await VideoDecodeCapabilities.getInstance();

    expect(VideoDecodeCapabilities.supportsHevc, isTrue);
    expect(VideoDecodeCapabilities.supportsAv1, isTrue);
    expect(VideoDecodeCapabilities.describeSync(), 'unprobed');
  });

  test('the probe runs once and is shared by concurrent callers', () async {
    final calls = stubProbe(<String, Object?>{'hevc': false, 'av1': false});

    final instances = await (VideoDecodeCapabilities.getInstance(), VideoDecodeCapabilities.getInstance()).wait;

    expect(calls, ['getVideoDecodeCapabilities']);
    expect(identical(instances.$1, instances.$2), isTrue);
    expect(VideoDecodeCapabilities.supportsHevc, isFalse);
    expect(VideoDecodeCapabilities.describeSync(), 'hevc=none av1=none');
  });
}
