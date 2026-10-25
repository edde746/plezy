import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/media_version_preference.dart';

void main() {
  const versions = [
    MediaVersion(id: '101', videoResolution: '1080', videoCodec: 'h264', container: 'mkv'),
    MediaVersion(id: '102', videoResolution: '4k', videoCodec: 'hevc', container: 'mkv'),
  ];

  const namedVersions = [
    MediaVersion(id: 'a', videoResolution: '1080', videoCodec: 'h264', container: 'mkv', name: '# 2 Secondary'),
    MediaVersion(id: 'b', videoResolution: '1080', videoCodec: 'h264', container: 'mkv', name: '# 1 Primary'),
  ];

  group('MediaVersionPreference.fromJson', () {
    test('decodes legacy bare int as index-only record', () {
      final pref = MediaVersionPreference.fromJson(1);
      expect(pref.index, 1);
      expect(pref.versionId, isNull);
      expect(pref.signature, isNull);
      expect(pref.updatedAt, isNull);
    });

    test('round-trips the record form', () {
      final pref = MediaVersionPreference.forVersion(versions[1], 1);
      final decoded = MediaVersionPreference.fromJson(pref.toJson());
      expect(decoded.versionId, '102');
      expect(decoded.signature, '4k:hevc:mkv');
      expect(decoded.index, 1);
      expect(decoded.updatedAt, pref.updatedAt);
    });

    test('round-trips the version name', () {
      final pref = MediaVersionPreference.forVersion(namedVersions[1], 1);
      final decoded = MediaVersionPreference.fromJson(pref.toJson());
      expect(decoded.versionName, '# 1 Primary');
    });

    test('omits the name for unnamed versions', () {
      final pref = MediaVersionPreference.forVersion(versions[0], 0);
      expect(pref.versionName, isNull);
      expect(pref.toJson().containsKey('name'), isFalse);
    });
  });

  group('MediaVersionPreference.resolveIndex', () {
    test('exact version id wins over stored index', () {
      const pref = MediaVersionPreference(versionId: '102', signature: '4k:hevc:mkv', index: 0);
      expect(pref.resolveIndex(versions), 1);
    });

    test('signature matches when the id is from a sibling episode', () {
      const pref = MediaVersionPreference(versionId: '999', signature: '4k:hevc:mkv', index: 0);
      expect(pref.resolveIndex(versions), 1);
    });

    test('signature matches by resolution when codec/container differ', () {
      const pref = MediaVersionPreference(versionId: '999', signature: '4k:av1:mp4', index: 0);
      expect(pref.resolveIndex(versions), 1);
    });

    test('falls back to stored index when id and signature miss', () {
      const pref = MediaVersionPreference(versionId: '999', signature: '720:vp9:webm', index: 1);
      expect(pref.resolveIndex(versions), 1);
    });

    test('name picks the same version on a sibling with reordered sources', () {
      // Picked "# 1 Primary" at index 0 on another episode; here the server
      // lists it second, and both share a signature.
      const pref = MediaVersionPreference(
        versionId: 'other-episode',
        versionName: '# 1 Primary',
        signature: '1080:h264:mkv',
        index: 0,
      );
      expect(pref.resolveIndex(namedVersions), 1);
    });

    test('exact version id still wins over the name', () {
      const pref = MediaVersionPreference(versionId: 'a', versionName: '# 1 Primary', index: 1);
      expect(pref.resolveIndex(namedVersions), 0);
    });

    test('unknown name falls through to signature and index', () {
      const pref = MediaVersionPreference(versionName: 'Extended', signature: '1080:h264:mkv', index: 1);
      expect(pref.resolveIndex(namedVersions), 0);
    });

    test('returns null for out-of-range index with no match', () {
      const pref = MediaVersionPreference(index: 5);
      expect(pref.resolveIndex(versions), isNull);
      expect(pref.resolveIndex(const []), isNull);
    });
  });

  group('MediaVersion.findNamedIndex', () {
    test('matches trimmed and case-insensitive', () {
      expect(MediaVersion.findNamedIndex(namedVersions, ' # 1 primary '), 1);
    });

    test('returns null for empty, missing or ambiguous names', () {
      expect(MediaVersion.findNamedIndex(namedVersions, null), isNull);
      expect(MediaVersion.findNamedIndex(namedVersions, ''), isNull);
      expect(MediaVersion.findNamedIndex(namedVersions, '# 3 Third'), isNull);
      const duplicated = [
        MediaVersion(id: 'x', name: 'Cut'),
        MediaVersion(id: 'y', name: 'cut'),
      ];
      expect(MediaVersion.findNamedIndex(duplicated, 'Cut'), isNull);
    });
  });
}
