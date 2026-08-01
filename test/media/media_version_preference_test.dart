import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/media_version_preference.dart';

void main() {
  const versions = [
    MediaVersion(id: '101', videoResolution: '1080', videoCodec: 'h264', container: 'mkv'),
    MediaVersion(id: '102', videoResolution: '4k', videoCodec: 'hevc', container: 'mkv'),
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

    test('returns null for out-of-range index with no match', () {
      const pref = MediaVersionPreference(index: 5);
      expect(pref.resolveIndex(versions), isNull);
      expect(pref.resolveIndex(const []), isNull);
    });
  });
}
