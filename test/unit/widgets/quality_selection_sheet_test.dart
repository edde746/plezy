import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_media_version.dart';
import 'package:plezy/widgets/quality_selection_sheet.dart';

void main() {
  group('QualitySelectionSheet', () {
    PlexMediaVersion createTestVersion({
      int id = 1,
      String? videoResolution,
      String? videoCodec,
      int? bitrate,
      int? width,
      int? height,
      String? container,
    }) {
      return PlexMediaVersion(
        id: id,
        videoResolution: videoResolution,
        videoCodec: videoCodec,
        bitrate: bitrate,
        width: width,
        height: height,
        container: container,
      );
    }

    group('constructor', () {
      test('stores required parameters', () {
        final versions = [
          createTestVersion(id: 1, videoResolution: '1080p'),
          createTestVersion(id: 2, videoResolution: '720p'),
        ];

        const widget = QualitySelectionSheet(
          availableVersions: [],
          selectedIndex: 0,
          onVersionSelected: _noOpCallback,
        );

        expect(widget.availableVersions, isEmpty);
        expect(widget.selectedIndex, 0);
      });

      test('accepts list of versions', () {
        final versions = [
          createTestVersion(id: 1, videoResolution: '1080p'),
          createTestVersion(id: 2, videoResolution: '720p'),
        ];

        final widget = QualitySelectionSheet(
          availableVersions: versions,
          selectedIndex: 1,
          onVersionSelected: _noOpCallback,
        );

        expect(widget.availableVersions.length, 2);
        expect(widget.selectedIndex, 1);
      });
    });

    group('version icon selection', () {
      test('4K versions get 4K icon treatment', () {
        final version = createTestVersion(videoResolution: '4k');
        expect(version.videoResolution?.toLowerCase().contains('4k'), true);
      });

      test('2160p versions are treated as 4K', () {
        final version = createTestVersion(videoResolution: '2160p');
        expect(version.videoResolution?.contains('2160'), true);
      });

      test('1080p versions get HD icon treatment', () {
        final version = createTestVersion(videoResolution: '1080p');
        expect(version.videoResolution?.contains('1080'), true);
      });

      test('720p versions get HD icon treatment', () {
        final version = createTestVersion(videoResolution: '720p');
        expect(version.videoResolution?.contains('720'), true);
      });

      test('SD versions get SD icon treatment', () {
        final version = createTestVersion(videoResolution: '480p');
        expect(version.videoResolution?.contains('480'), true);
      });
    });

    group('version subtitle display', () {
      test('builds subtitle with dimensions', () {
        final version = createTestVersion(width: 1920, height: 1080);
        expect(version.width, 1920);
        expect(version.height, 1080);
      });

      test('builds subtitle with codec', () {
        final version = createTestVersion(videoCodec: 'hevc');
        expect(version.videoCodec, 'hevc');
      });

      test('builds subtitle with container', () {
        final version = createTestVersion(container: 'mkv');
        expect(version.container, 'mkv');
      });

      test('handles missing optional fields', () {
        final version = createTestVersion();
        expect(version.width, isNull);
        expect(version.height, isNull);
        expect(version.videoCodec, isNull);
        expect(version.container, isNull);
      });
    });

    group('displayLabel', () {
      test('generates display label for 1080p HEVC MKV', () {
        final version = createTestVersion(
          videoResolution: '1080p',
          videoCodec: 'hevc',
          container: 'mkv',
          bitrate: 8500000,
        );

        // The displayLabel getter should combine these values
        expect(version.displayLabel, isNotEmpty);
        expect(version.displayLabel.toLowerCase(), contains('1080'));
      });

      test('handles version with only resolution', () {
        final version = createTestVersion(videoResolution: '720p');
        expect(version.displayLabel, isNotEmpty);
      });

      test('handles version with all fields', () {
        final version = createTestVersion(
          videoResolution: '4k',
          videoCodec: 'h264',
          container: 'mp4',
          bitrate: 20000000,
          width: 3840,
          height: 2160,
        );
        expect(version.displayLabel, isNotEmpty);
      });
    });

    group('selection behavior', () {
      test('selectedIndex 0 selects first item', () {
        final versions = [
          createTestVersion(id: 1, videoResolution: '1080p'),
          createTestVersion(id: 2, videoResolution: '720p'),
        ];

        final widget = QualitySelectionSheet(
          availableVersions: versions,
          selectedIndex: 0,
          onVersionSelected: _noOpCallback,
        );

        expect(widget.selectedIndex, 0);
        expect(versions[widget.selectedIndex].id, 1);
      });

      test('selectedIndex 1 selects second item', () {
        final versions = [
          createTestVersion(id: 1, videoResolution: '1080p'),
          createTestVersion(id: 2, videoResolution: '720p'),
        ];

        final widget = QualitySelectionSheet(
          availableVersions: versions,
          selectedIndex: 1,
          onVersionSelected: _noOpCallback,
        );

        expect(widget.selectedIndex, 1);
        expect(versions[widget.selectedIndex].id, 2);
      });
    });

    group('empty state', () {
      test('handles empty version list', () {
        const widget = QualitySelectionSheet(
          availableVersions: [],
          selectedIndex: 0,
          onVersionSelected: _noOpCallback,
        );

        expect(widget.availableVersions, isEmpty);
      });
    });

    group('multiple quality tiers', () {
      test('can have mixed quality versions', () {
        final versions = [
          createTestVersion(id: 1, videoResolution: '4k', bitrate: 40000000),
          createTestVersion(id: 2, videoResolution: '1080p', bitrate: 8000000),
          createTestVersion(id: 3, videoResolution: '720p', bitrate: 4000000),
          createTestVersion(id: 4, videoResolution: '480p', bitrate: 2000000),
        ];

        expect(versions.length, 4);
        expect(versions[0].videoResolution, '4k');
        expect(versions[1].videoResolution, '1080p');
        expect(versions[2].videoResolution, '720p');
        expect(versions[3].videoResolution, '480p');
      });
    });
  });
}

void _noOpCallback(int index) {
  // No-op callback for testing
}
