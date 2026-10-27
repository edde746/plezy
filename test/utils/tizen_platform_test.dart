import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/video_decode_capabilities.dart';
import 'package:plezy/utils/device_identity.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Tizen selects TV UI and native player before async platform detection', () async {
    expect(PlatformDetector.isTV(), isTrue);
    expect(PlatformDetector.isTVDevice(), isTrue);
    expect(PlatformDetector.usesTvHomeLayout(), isTrue);
    expect(PlatformDetector.isDesktopOS(), isFalse);
    expect(PlayerNative.usesLinuxVideoPlane, isFalse);
    expect(PlatformDetector.supportsExternalPlayers(), isFalse);
    expect(PlatformDetector.supportsAudioPassthrough(), isFalse);
    expect(PlatformDetector.supportsPictureInPicture(), isFalse);
    final video = Player();
    final audio = Player.audio();
    expect(video.playerType, 'tizen');
    expect(audio.playerType, 'tizen');
    await video.dispose();
    await audio.dispose();
    final identity = await DeviceIdentityService.resolve();
    expect(identity.platform, 'Tizen');
    expect(identity.isTv, isTrue);
    expect(VideoDecodeCapabilities.transcodeVideoCodecs.map((c) => c.id), ['h264']);
  }, skip: !const bool.fromEnvironment('PLEZY_TIZEN'));
}
