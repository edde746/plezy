import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/update_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  const lastCheckKey = 'update_last_check_time';

  setUp(resetSharedPreferencesForTest);
  PackageInfo.setMockInitialValues(
    appName: 'Plezy',
    packageName: 'com.plezy.test',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  test(
    'malformed cooldown state fails open and removes the invalid value',
    () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString(lastCheckKey, 'not-an-instant');

      expect(await UpdateService.shouldCheckForUpdates(), isTrue);
      expect(prefs.getString(lastCheckKey), isNull);
    },
  );

  test(
    'future cooldown state fails open and removes the invalid value',
    () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString(
        lastCheckKey,
        DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      );

      expect(await UpdateService.shouldCheckForUpdates(), isTrue);
      expect(prefs.getString(lastCheckKey), isNull);
    },
  );

  test(
    'recent valid cooldown state suppresses a duplicate check and remains stored',
    () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final recent = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      await prefs.setString(lastCheckKey, recent);

      expect(await UpdateService.shouldCheckForUpdates(), isFalse);
      expect(prefs.getString(lastCheckKey), recent);
    },
  );

  test('old valid cooldown state permits a new check', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final old = DateTime.now()
        .subtract(const Duration(days: 2))
        .toIso8601String();
    await prefs.setString(lastCheckKey, old);

    expect(await UpdateService.shouldCheckForUpdates(), isTrue);
    expect(prefs.getString(lastCheckKey), old);
  });

  final failedResponses = <String, Future<http.Response> Function()>{
    'timeout': () async => throw TimeoutException('request timed out'),
    'non-200 response': () async => http.Response('unavailable', 503),
    'parse failure': () async => http.Response(
      'not-json',
      200,
      headers: {'content-type': 'application/json'},
    ),
  };

  for (final failure in failedResponses.entries) {
    test(
      'startup ${failure.key} records cooldown before request and manual check bypasses it',
      () async {
        final prefs = await BaseSharedPreferencesService.sharedCache();
        final cooldownAtRequest = <String?>[];
        var requestCount = 0;
        final client = MediaServerHttpClient(
          client: MockClient((_) async {
            requestCount++;
            cooldownAtRequest.add(prefs.getString(lastCheckKey));
            return failure.value();
          }),
        );
        addTearDown(client.close);

        expect(
          await UpdateService.debugPerformUpdateCheck(
            respectCooldown: true,
            client: client,
          ),
          isNull,
        );
        expect(requestCount, 1);
        expect(cooldownAtRequest.single, isNotNull);
        final recordedCooldown = prefs.getString(lastCheckKey);
        expect(recordedCooldown, cooldownAtRequest.single);
        expect(
          DateTime.now().difference(DateTime.parse(recordedCooldown!)),
          lessThan(const Duration(minutes: 1)),
        );

        expect(
          await UpdateService.debugPerformUpdateCheck(
            respectCooldown: true,
            client: client,
          ),
          isNull,
        );
        expect(
          requestCount,
          1,
          reason:
              'a simulated next launch must honor the failed attempt cooldown',
        );

        expect(
          await UpdateService.debugPerformUpdateCheck(
            respectCooldown: false,
            client: client,
          ),
          isNull,
        );
        expect(
          requestCount,
          2,
          reason:
              'an explicit manual check must bypass a recent startup cooldown',
        );
        expect(
          prefs.getString(lastCheckKey),
          recordedCooldown,
          reason: 'manual checks must not rewrite startup cooldown',
        );
      },
    );
  }

  group('Plezy Labs channel preference', () {
    test('Labs builds always use the Labs automatic update channel', () {
      expect(
        UpdateService.effectiveUpdateChannel(
          labsBuild: true,
          storedChannel: UpdateChannel.official,
        ),
        UpdateChannel.labs,
      );
      expect(
        UpdateService.effectiveUpdateChannel(
          labsBuild: false,
          storedChannel: UpdateChannel.official,
        ),
        UpdateChannel.official,
      );
    });

    test(
      'defaults to Labs and stores the first-launch choice using canonical keys',
      () async {
        expect(await UpdateService.getUpdateChannel(), UpdateChannel.labs);

        await UpdateService.completeUpdateChannelChoice(UpdateChannel.official);

        expect(await UpdateService.getUpdateChannel(), UpdateChannel.official);
        expect(await UpdateService.shouldPromptForUpdateChannel(), isFalse);
      },
    );
  });

  group('Plezy Labs release parsing', () {
    test('selects the newest published Labs release and keeps its notes', () {
      final release = UpdateService.latestLabsReleaseFromJson([
        {
          'tag_name': 'labs-v2.10.0-r2',
          'html_url': 'https://example.test/r2',
          'name': 'Plezy Labs 2.10.0 r2',
          'body': 'GitHub release notes',
          'published_at': '2026-07-28T12:00:00Z',
          'draft': false,
          'prerelease': false,
        },
        {
          'tag_name': 'labs-v2.10.0-r1',
          'html_url': 'https://example.test/r1',
          'draft': false,
          'prerelease': false,
        },
      ]);

      expect(release, isNotNull);
      expect(release!.version, '2.10.0');
      expect(release.revision, 2);
      expect(release.displayVersion, '2.10.0 r2');
      expect(release.releaseNotes, 'GitHub release notes');
    });

    test('ignores drafts, Labs prereleases, and unrelated stable releases', () {
      final release = UpdateService.latestLabsReleaseFromJson([
        {
          'tag_name': 'labs-v2.10.0-r3',
          'html_url': 'https://example.test/draft',
          'draft': true,
          'prerelease': false,
        },
        {
          'tag_name': 'labs-v2.10.0-r2',
          'html_url': 'https://example.test/prerelease',
          'draft': false,
          'prerelease': true,
        },
        {
          'tag_name': 'beta-v2.10.0',
          'html_url': 'https://example.test/beta',
          'draft': false,
          'prerelease': false,
        },
      ]);

      expect(release, isNull);
    });

    test('rejects prerelease data from the official latest source', () {
      final release = UpdateService.officialReleaseFromJson({
        'tag_name': '2.11.0-beta.1',
        'html_url': 'https://example.test/official',
        'draft': false,
        'prerelease': true,
      });

      expect(release, isNull);
    });
  });

  group('Plezy Labs source comparison', () {
    test('reports when Labs has not caught up to official Plezy', () {
      const sources = UpdateReleaseSources(
        official: PlezyRelease(
          version: '2.10.0',
          releaseUrl: 'https://example.test/official',
          releaseName: 'Plezy 2.10.0',
          releaseNotes: '',
          publishedAt: '',
          tag: '2.10.0',
        ),
        labs: PlezyRelease(
          version: '2.9.1',
          revision: 7,
          releaseUrl: 'https://example.test/labs',
          releaseName: 'Plezy Labs 2.9.1 r7',
          releaseNotes: '',
          publishedAt: '',
          tag: 'labs-v2.9.1-r7',
        ),
      );

      expect(sources.labsIsBehindOfficial, isTrue);
    });

    test('compares semantic version components numerically', () {
      expect(UpdateService.isNewerVersion('2.10.0', '2.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.10.0', '2.10.0'), isFalse);
      expect(UpdateService.isNewerVersion('2.9.9', '2.10.0'), isFalse);
    });
  });
}
