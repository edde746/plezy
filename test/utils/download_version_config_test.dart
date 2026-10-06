import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/utils/download_version_utils.dart';

MediaVersion _version(String id, String? name) =>
    MediaVersion(id: id, videoResolution: '1080', videoCodec: 'h264', container: 'mkv', name: name);

void main() {
  group('DownloadVersionConfig', () {
    test('matches the picked version by name before signature', () {
      final config = DownloadVersionConfig.fromVersion(_version('a3', '# 3 Third'), mediaIndex: 2);
      final episode = [_version('b1', '# 1 Primary'), _version('b3', '# 3 Third'), _version('b2', '# 2 Secondary')];
      expect(config.findAcceptedIndex(episode), 1);
    });

    test('falls back to the signature when no version carries the name', () {
      final config = DownloadVersionConfig.fromVersion(_version('a3', '# 3 Third'));
      expect(config.findAcceptedIndex([_version('b1', null), _version('b2', null)]), 0);
    });

    test('a version picked on mismatch is accepted by name too', () {
      final config = DownloadVersionConfig.fromVersion(_version('a1', '# 1 Primary'));
      config.accept(_version('b2', '# 2 Secondary'));
      expect(config.findAcceptedIndex([_version('c1', 'Other'), _version('c2', '# 2 Secondary')]), 1);
    });
  });
}
