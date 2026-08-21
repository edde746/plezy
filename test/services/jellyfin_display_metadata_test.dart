import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_display_metadata.dart';

/// HDR/Dolby Vision classification from a MediaBrowser `MediaStreams[]` entry.
///
/// The fixtures are verbatim video-stream shapes captured from Jellyfin 10.11
/// and Emby 4.9.5 for the same HDR10 HEVC file. They differ: Jellyfin sends
/// `VideoRangeType`, Emby does not — it sends `VideoRange: 'HDR 10'` plus its
/// own `ExtendedVideoType`. Detection must not depend on the Jellyfin-only
/// field, which is why both shapes are pinned here.
void main() {
  group('HDR detection across MediaBrowser dialects', () {
    // Emby 4.9.5, HDR10 HEVC. Note the absent VideoRangeType.
    const embyHdr10 = <String, dynamic>{
      'Type': 'Video',
      'Codec': 'hevc',
      'Profile': 'Main 10',
      'BitDepth': 10,
      'VideoRange': 'HDR 10',
      'ColorTransfer': 'smpte2084',
      'ColorPrimaries': 'bt2020',
      'ColorSpace': 'bt2020nc',
      'ExtendedVideoType': 'Hdr10',
      'Width': 640,
      'Height': 360,
      'AverageFrameRate': 24,
    };

    // Jellyfin 10.11 shape for the same content.
    const jellyfinHdr10 = <String, dynamic>{
      'Type': 'Video',
      'Codec': 'hevc',
      'Profile': 'Main 10',
      'BitDepth': 10,
      'VideoRange': 'HDR',
      'VideoRangeType': 'HDR10',
      'ColorTransfer': 'smpte2084',
      'ColorPrimaries': 'bt2020',
      'ColorSpace': 'bt2020nc',
      'Width': 640,
      'Height': 360,
      'AverageFrameRate': 24,
    };

    const sdr = <String, dynamic>{
      'Type': 'Video',
      'Codec': 'h264',
      'VideoRange': 'SDR',
      'Width': 640,
      'Height': 360,
      'AverageFrameRate': 24,
    };

    test('Emby HDR10 is detected without the Jellyfin-only VideoRangeType', () {
      expect(embyHdr10.containsKey('VideoRangeType'), isFalse, reason: 'fixture must reflect the real Emby shape');
      expect(jellyfinVideoStreamIsHdr(const {}, embyHdr10), isTrue);

      final criteria = jellyfinDisplayCriteriaFromStream(const {}, embyHdr10);
      expect(criteria, isNotNull);
      expect(criteria!.isHdr, isTrue);
      expect(criteria.transfer, 'smpte2084');
      expect(criteria.primaries, 'bt2020');
    });

    test('Jellyfin HDR10 is detected from its own field set', () {
      expect(jellyfinVideoStreamIsHdr(const {}, jellyfinHdr10), isTrue);
      expect(jellyfinDisplayCriteriaFromStream(const {}, jellyfinHdr10)!.isHdr, isTrue);
    });

    test('an SDR stream is not misreported as HDR on either dialect', () {
      expect(jellyfinVideoStreamIsHdr(const {}, sdr), isFalse);
      expect(jellyfinVideoStreamIsHdr(const {}, {...sdr, 'VideoRangeType': 'SDR'}), isFalse);
    });

    test('Dolby Vision is detected from the Dv* fields both dialects share', () {
      const dovi = <String, dynamic>{
        'Type': 'Video',
        'Codec': 'hevc',
        'VideoRange': 'HDR',
        'DvProfile': 8,
        'DvBlSignalCompatibilityId': 1,
        'DvVersionMajor': 1,
        'Width': 3840,
        'Height': 2160,
      };

      expect(jellyfinVideoStreamIsDolbyVision(dovi), isTrue);
      expect(jellyfinDolbyVisionProfile(dovi), 8);
      expect(jellyfinVideoStreamIsHdr(const {}, dovi), isTrue);
    });

    test('a stream carrying no range signal at all is treated as SDR, not unknown', () {
      const bare = <String, dynamic>{'Type': 'Video', 'Codec': 'h264', 'Width': 1920, 'Height': 1080};

      expect(jellyfinVideoStreamIsHdr(const {}, bare), isFalse);
      expect(jellyfinVideoStreamIsDolbyVision(bare), isFalse);
    });
  });
}
