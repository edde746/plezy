import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/external_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final uri = Uri.parse('https://plex.tv/link');

  group('launchExternalUrl', () {
    test('returns true and skips the fallback when the primary launch succeeds', () async {
      var fallbackCalls = 0;
      final result = await launchExternalUrl(
        uri,
        launcher: (uri, {mode = LaunchMode.externalApplication}) async => true,
        fallback: (url) async {
          fallbackCalls++;
          return true;
        },
        isLinuxOverride: true,
      );

      expect(result, isTrue);
      expect(fallbackCalls, 0);
    });

    test('forwards the requested mode to the primary launcher', () async {
      LaunchMode? seenMode;
      await launchExternalUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        launcher: (uri, {mode = LaunchMode.externalApplication}) async {
          seenMode = mode;
          return true;
        },
        fallback: (url) async => false,
        isLinuxOverride: false,
      );

      expect(seenMode, LaunchMode.inAppBrowserView);
    });

    test('falls back to xdg-open on Linux when the primary launch throws (gio missing)', () async {
      String? fallbackUrl;
      final result = await launchExternalUrl(
        uri,
        launcher: (uri, {mode = LaunchMode.externalApplication}) async {
          throw Exception('Failed to execute child process "gio-launch-desktop"');
        },
        fallback: (url) async {
          fallbackUrl = url;
          return true;
        },
        isLinuxOverride: true,
      );

      expect(result, isTrue);
      expect(fallbackUrl, uri.toString());
    });

    test('falls back on Linux when the primary launch returns false', () async {
      var fallbackCalls = 0;
      final result = await launchExternalUrl(
        uri,
        launcher: (uri, {mode = LaunchMode.externalApplication}) async => false,
        fallback: (url) async {
          fallbackCalls++;
          return true;
        },
        isLinuxOverride: true,
      );

      expect(result, isTrue);
      expect(fallbackCalls, 1);
    });

    test('rethrows on non-Linux platforms without invoking the fallback', () async {
      var fallbackCalls = 0;
      await expectLater(
        launchExternalUrl(
          uri,
          launcher: (uri, {mode = LaunchMode.externalApplication}) async {
            throw Exception('custom tabs unavailable');
          },
          fallback: (url) async {
            fallbackCalls++;
            return true;
          },
          isLinuxOverride: false,
        ),
        throwsException,
      );
      expect(fallbackCalls, 0);
    });

    test('returns false on non-Linux when the primary launch returns false', () async {
      final result = await launchExternalUrl(
        uri,
        launcher: (uri, {mode = LaunchMode.externalApplication}) async => false,
        fallback: (url) async => true,
        isLinuxOverride: false,
      );

      expect(result, isFalse);
    });
  });
}
