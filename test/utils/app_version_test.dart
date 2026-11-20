import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/utils/app_version.dart';

PackageInfo _packageInfo({required String version, String buildNumber = '160'}) =>
    PackageInfo(appName: 'Plezy', packageName: 'com.example.plezy', version: version, buildNumber: buildNumber);

void main() {
  test('reports the package version and build number, trimmed', () async {
    final appVersion = await AppVersion.read(() async => _packageInfo(version: ' 2.26.0 ', buildNumber: ' 160 '));

    expect((appVersion.version, appVersion.buildNumber), ('2.26.0', '160'));
    expect(appVersion.versionOrUnknown, '2.26.0');
    expect(appVersion.label, '2.26.0+160');
  });

  test('a blank version, as a split Linux install reports, is unknown', () async {
    for (final version in ['', '   ']) {
      final appVersion = await AppVersion.read(() async => _packageInfo(version: version, buildNumber: ''));

      expect(appVersion.version, isNull, reason: '"$version"');
      expect(appVersion.versionOrUnknown, AppVersion.unknown);
      expect(appVersion.label, '${AppVersion.unknown}+${AppVersion.unknown}');
    }
  });

  test('a failed metadata read is unknown, not an error', () async {
    final appVersion = await AppVersion.read(() async => throw StateError('version resource unreadable'));

    expect((appVersion.version, appVersion.buildNumber), (null, null));
    expect(appVersion.versionOrUnknown, AppVersion.unknown);
  });
}
