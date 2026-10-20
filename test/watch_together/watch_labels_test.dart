import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/widgets/watch_labels.dart';

import '../test_helpers/media_items.dart';

MediaVersion _version({String? name}) =>
    MediaVersion(id: 'v1', height: 1080, videoCodec: 'h264', container: 'mkv', name: name);

final _bigTrouble = testMediaItem(
  id: 'bt',
  backend: MediaBackend.jellyfin,
  title: 'Big Trouble',
  year: 2002,
  serverId: 'jf',
  serverName: 'jf-test',
  durationMs: 5106528,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('watchVersionLabel', () {
    final technical = _version().displayLabel;

    test('drops a version name that only restates the title, with or without its year', () {
      for (final name in ['Big Trouble', 'big trouble', 'Big Trouble (2002)', 'Big.Trouble.2002']) {
        expect(watchVersionLabel(_bigTrouble, _version(name: name)), technical, reason: name);
      }
    });

    test("keeps a name that tells versions apart, or that isn't quite the title", () {
      for (final name in ["Director's Cut", 'Big Trouble Extended', 'Big Trouble (1986)']) {
        expect(
          watchVersionLabel(_bigTrouble, _version(name: name)),
          _version(name: name).displayLabel,
          reason: name,
        );
      }
    });

    test('is null without a version, or when the title was all the version said', () {
      expect(watchVersionLabel(_bigTrouble, null), isNull);
      expect(watchVersionLabel(_bigTrouble, const MediaVersion(id: 'v1', name: 'Big Trouble')), isNull);
    });
  });

  test("a copy's details give its version, server and length without the title again", () {
    final copy = WatchCopy.of(_bigTrouble, _version(name: 'Big Trouble (2002)'));

    final details = watchCopyDetails(copy);

    expect(details, startsWith(_version().displayLabel));
    expect(details, contains('jf-test'));
    expect(details, isNot(contains('Big Trouble')));
    expect(watchCopyTitle(copy), contains('Big Trouble'));
  });
}
