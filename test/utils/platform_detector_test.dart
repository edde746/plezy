import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  setUp(() {
    TvDetectionService.debugReset();
    addTearDown(TvDetectionService.debugReset);
  });

  test('concurrent callers wait for TV detection', () async {
    final detection = Completer<void>();
    TvDetectionService.debugDetectionGate = detection.future;

    final first = TvDetectionService.getInstance(forceTv: true);
    var secondCompleted = false;
    final second = TvDetectionService.getInstance();
    unawaited(second.then((_) => secondCompleted = true));
    await Future<void>.delayed(Duration.zero);

    expect(secondCompleted, isFalse);
    detection.complete();

    final instances = await Future.wait([first, second]);
    expect(identical(instances.first, instances.last), isTrue);
    expect(instances.first.isTV, isTrue);
  });

  group('detectAndroidTvFromSystemFeatures', () {
    test('detects leanback devices', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.software.leanback',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('leanback'));
      expect(detection.reasons, isNot(contains('no_touchscreen')));
    });

    test('detects Fire TV even when touchscreen is present', () {
      final detection = detectAndroidTvFromSystemFeatures(['amazon.hardware.fire_tv', 'android.hardware.touchscreen']);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('fire_tv'));
      expect(detection.reasons, isNot(contains('no_touchscreen')));
    });

    test('detects devices without real touchscreen capability', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.faketouch']);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('no_touchscreen'));
    });

    test('detects television feature', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.hardware.type.television',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('television_feature'));
    });

    test('does not classify touchscreen-only devices as TV', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.touchscreen']);

      expect(detection.isTv, isFalse);
      expect(detection.reasons, isEmpty);
    });

    test('does not classify empty feature lists as no-touchscreen TVs', () {
      final detection = detectAndroidTvFromSystemFeatures(const []);

      expect(detection.isTv, isFalse);
      expect(detection.reasons, isEmpty);
    });

    test('classifies automotive head units as cars, not TVs', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.hardware.type.automotive',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isAutomotive, isTrue);
      expect(detection.isTv, isFalse);
    });

    test('rotary-only head units are cars despite reporting no touchscreen', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.type.automotive']);

      expect(detection.isAutomotive, isTrue);
      expect(detection.isTv, isFalse);
      expect(detection.reasons, contains('no_touchscreen'));
    });

    test('automotive vetoes a stray leanback flag from an OEM image', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.hardware.type.automotive',
        'android.software.leanback',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isAutomotive, isTrue);
      expect(detection.isTv, isFalse);
    });

    test('ordinary devices are not automotive', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.touchscreen']);

      expect(detection.isAutomotive, isFalse);
    });
  });

  group('pictureInPictureAllowed', () {
    bool allowed({bool host = true, bool appleTv = false, bool tv = false, bool automotive = false}) =>
        pictureInPictureAllowed(
          hostSupportsPictureInPicture: host,
          isAppleTv: appleTv,
          isTv: tv,
          isAutomotive: automotive,
        );

    test('a plain handheld host may float a player', () {
      expect(allowed(), isTrue);
    });

    test('automotive vetoes a host that otherwise supports PiP', () {
      expect(allowed(automotive: true), isFalse);
    });

    test('TV form factors veto a host that otherwise supports PiP', () {
      expect(allowed(tv: true), isFalse);
      expect(allowed(appleTv: true), isFalse);
    });

    test('a host without PiP is never allowed, whatever the form factor', () {
      expect(allowed(host: false), isFalse);
      expect(allowed(host: false, automotive: true), isFalse);
    });
  });

  group('isPackagedExecutablePath', () {
    test('a WindowsApps executable path is a packaged install', () {
      expect(
        PlatformDetector.isPackagedExecutablePath(
          r'C:\Program Files\WindowsApps\edde746.Plezy_2.11.0.0_x64__13q3sv6jzathm\plezy.exe',
        ),
        isTrue,
      );
    });

    test('the package directory is matched however it is cased', () {
      expect(
        PlatformDetector.isPackagedExecutablePath(
          r'c:\program files\windowsapps\edde746.Plezy_2.11.0.0_x64__13q3sv6jzathm\plezy.exe',
        ),
        isTrue,
        reason:
            'Windows paths are case-insensitive; a casing difference must not restore '
            'the updater and donation link inside a read-only package',
      );
    });

    test('installed and portable executable paths are not packaged installs', () {
      expect(PlatformDetector.isPackagedExecutablePath(r'C:\Program Files\Plezy\plezy.exe'), isFalse);
      expect(PlatformDetector.isPackagedExecutablePath(r'D:\portable\plezy-windows-x64\plezy.exe'), isFalse);
    });

    test('a directory whose name merely starts the same is not a package', () {
      expect(
        PlatformDetector.isPackagedExecutablePath(r'C:\Users\someone\Downloads\WindowsApps-backup\plezy.exe'),
        isFalse,
      );
    });
  });
}
