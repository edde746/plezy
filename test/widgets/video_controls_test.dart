import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/mobile_skip_zones.dart';

void main() {
  group('effectiveVersionQualityControls', () {
    test('clears switchable version and quality state during offline playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: true,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
      );

      expect(result.canSwitch, isFalse);
      expect(result.availableVersions, isEmpty);
      expect(result.serverSupportsTranscoding, isFalse);
      expect(result.isTranscoding, isFalse);
      expect(result.sourceAudioTracks, isEmpty);
      expect(result.selectedAudioStreamId, isNull);
    });

    test('keeps switchable state during online playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: false,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
      );

      expect(result.canSwitch, isTrue);
      expect(result.availableVersions, [version]);
      expect(result.serverSupportsTranscoding, isTrue);
      expect(result.isTranscoding, isTrue);
      expect(result.sourceAudioTracks, [audio]);
      expect(result.selectedAudioStreamId, 1);
    });
  });

  group('mobileSkipZoneForTap', () {
    const size = Size(1000, 600);

    test('returns backward for left skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(100, 300), size: size), isFalse);
    });

    test('returns forward for right skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(900, 300), size: size), isTrue);
    });

    test('returns null outside skip zones', () {
      expect(mobileSkipZoneForTap(position: const Offset(500, 300), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(100, 20), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(900, 580), size: size), isNull);
    });
  });
}
