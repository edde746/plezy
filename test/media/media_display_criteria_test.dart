import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_display_criteria.dart';

void main() {
  group('classifyMediaDisplayColor', () {
    final cases = [
      const _ColorCase('Dolby Vision', MediaDisplayColorType.dolbyVision, isDolbyVision: true),
      const _ColorCase(
        'Dolby Vision ignores incidental SDR tags',
        MediaDisplayColorType.dolbyVision,
        isDolbyVision: true,
        primaries: 'bt709',
      ),
      const _ColorCase('HLG compatibility ID', MediaDisplayColorType.hlg, doviCompatibilityId: 4),
      const _ColorCase('HLG range', MediaDisplayColorType.hlg, range: 'HLG'),
      const _ColorCase('ARIB transfer', MediaDisplayColorType.hlg, transfer: 'ARIB-STD-B67'),
      const _ColorCase('HDR10 compatibility ID', MediaDisplayColorType.pq, doviCompatibilityId: 1),
      const _ColorCase('PQ compatibility ID', MediaDisplayColorType.pq, doviCompatibilityId: 6),
      const _ColorCase('HDR10 range', MediaDisplayColorType.pq, range: 'DOVIWithHDR10Plus'),
      const _ColorCase('PQ transfer', MediaDisplayColorType.pq, transfer: 'PQ'),
      const _ColorCase('SMPTE 2084 transfer', MediaDisplayColorType.pq, transfer: 'smpte2084'),
      const _ColorCase('ST 2084 transfer', MediaDisplayColorType.pq, transfer: 'ST-2084'),
      const _ColorCase('BT.2020 primaries', MediaDisplayColorType.pq, primaries: 'BT.2020'),
      const _ColorCase('BT.2020 matrix', MediaDisplayColorType.pq, matrix: 'bt2020nc'),
      const _ColorCase('SDR compatibility ID', MediaDisplayColorType.sdr, doviCompatibilityId: 2),
      const _ColorCase('SDR range', MediaDisplayColorType.sdr, range: 'SDR'),
      const _ColorCase('BT.709 primaries', MediaDisplayColorType.sdr, primaries: 'BT.709'),
      const _ColorCase('assumed SDR', MediaDisplayColorType.sdr, assumeSdr: true),
      const _ColorCase('missing metadata', MediaDisplayColorType.unknown),
      const _ColorCase('unrecognized metadata', MediaDisplayColorType.unknown, transfer: 'gamma22'),
      const _ColorCase(
        'HLG takes precedence over PQ and SDR',
        MediaDisplayColorType.hlg,
        doviCompatibilityId: 2,
        transfer: 'arib-std-b67',
        primaries: 'bt2020',
      ),
      const _ColorCase(
        'PQ takes precedence over SDR and Dolby Vision',
        MediaDisplayColorType.pq,
        isDolbyVision: true,
        doviCompatibilityId: 2,
        transfer: 'smpte2084',
      ),
      const _ColorCase(
        'SDR takes precedence over Dolby Vision',
        MediaDisplayColorType.sdr,
        isDolbyVision: true,
        doviCompatibilityId: 2,
      ),
    ];

    for (final testCase in cases) {
      test(testCase.name, () {
        expect(
          classifyMediaDisplayColor(
            isDolbyVision: testCase.isDolbyVision,
            doviCompatibilityId: testCase.doviCompatibilityId,
            range: testCase.range,
            transfer: testCase.transfer,
            primaries: testCase.primaries,
            matrix: testCase.matrix,
            assumeSdr: testCase.assumeSdr,
          ),
          testCase.expected,
        );
      });
    }

    test('provides defaults and HDR state for every classification', () {
      const expected = <MediaDisplayColorType, ({bool isHdr, MediaDisplayColorTags tags})>{
        MediaDisplayColorType.dolbyVision: (isHdr: true, tags: (transfer: null, primaries: null, matrix: null)),
        MediaDisplayColorType.hlg: (
          isHdr: true,
          tags: (transfer: 'arib-std-b67', primaries: 'bt2020', matrix: 'bt2020nc'),
        ),
        MediaDisplayColorType.pq: (isHdr: true, tags: (transfer: 'smpte2084', primaries: 'bt2020', matrix: 'bt2020nc')),
        MediaDisplayColorType.sdr: (isHdr: false, tags: (transfer: 'bt709', primaries: 'bt709', matrix: 'bt709')),
        MediaDisplayColorType.unknown: (isHdr: false, tags: (transfer: null, primaries: null, matrix: null)),
      };

      expect(expected.keys, unorderedEquals(MediaDisplayColorType.values));
      for (final entry in expected.entries) {
        expect(entry.key.isHdr, entry.value.isHdr, reason: entry.key.name);
        expect(entry.key.defaultTags, entry.value.tags, reason: entry.key.name);
      }
    });
  });

  group('MediaDisplayCriteria', () {
    test('can prime native display criteria from frame rate and dimensions', () {
      const criteria = MediaDisplayCriteria(fps: 23.976, width: 1920, height: 1080);

      expect(criteria.canPrimeNativeDisplayCriteria, isTrue);
    });

    test('cannot prime native display criteria without dimensions', () {
      const criteria = MediaDisplayCriteria(fps: 23.976);

      expect(criteria.canPrimeNativeDisplayCriteria, isFalse);
    });
  });
}

class _ColorCase {
  final String name;
  final MediaDisplayColorType expected;
  final bool isDolbyVision;
  final int? doviCompatibilityId;
  final String? range;
  final String? transfer;
  final String? primaries;
  final String? matrix;
  final bool assumeSdr;

  const _ColorCase(
    this.name,
    this.expected, {
    this.isDolbyVision = false,
    this.doviCompatibilityId,
    this.range,
    this.transfer,
    this.primaries,
    this.matrix,
    this.assumeSdr = false,
  });
}
