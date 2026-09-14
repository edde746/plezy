import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_playback_mapper.dart';

void main() {
  group('parsePlexFileInfoFromJson', () {
    test('keeps every server-ordered media version with its own summary', () {
      final result = parsePlexFileInfoFromJson({
        'Media': [
          {
            'id': 'first',
            'title': 'Original',
            'container': 'mkv',
            'width': '3840',
            'height': '2160',
            'videoResolution': '4k',
          },
          {
            'id': 'second',
            'title': 'Mobile',
            'container': 'mp4',
            'width': 1280,
            'height': 720,
            'videoResolution': '720',
          },
        ],
      });

      expect(result, isNotNull);
      expect(result!.versions, hasLength(2));
      expect(result.versions.map((version) => version.id), ['first', 'second']);
      expect(result.versions.map((version) => version.title), ['Original', 'Mobile']);
      expect(result.versions.map((version) => version.container), ['mkv', 'mp4']);
      expect(result.versions.map((version) => version.resolutionFormatted), ['3840x2160', '1280x720']);
    });

    test('keeps every part with independent files and streams and sums their sizes', () {
      final result = parsePlexFileInfoFromJson({
        'Media': [
          {
            'Part': [
              {
                'id': 'part-1',
                'file': '/media/movie-cd1.mkv',
                'size': '1200',
                'Stream': [
                  {'id': '11', 'streamType': 1, 'codec': 'h264'},
                ],
              },
              {
                'id': 'part-2',
                'file': '/media/movie-cd2.mkv',
                'size': 3400,
                'Stream': [
                  {'id': '21', 'streamType': 2, 'codec': 'aac'},
                  {'id': '22', 'streamType': 3, 'codec': 'srt'},
                ],
              },
            ],
          },
        ],
      });

      final version = result!.versions.single;
      expect(version.parts, hasLength(2));
      expect(version.parts.map((part) => part.filePath), ['/media/movie-cd1.mkv', '/media/movie-cd2.mkv']);
      expect(version.parts.map((part) => part.fileSize), [1200, 3400]);
      expect(version.parts[0].streams.map((stream) => stream.kind), [MediaStreamKind.video]);
      expect(version.parts[1].streams.map((stream) => stream.kind), [MediaStreamKind.audio, MediaStreamKind.subtitle]);
      expect(version.totalFileSize, 4600);
    });

    test('accepts single Part and Stream objects instead of arrays', () {
      final result = parsePlexFileInfoFromJson({
        'Media': [
          {
            'Part': {
              'id': 9,
              'file': '/media/single.mp4',
              'Stream': {'id': 12, 'streamType': 1, 'codec': 'hevc'},
            },
          },
        ],
      });

      final part = result!.versions.single.parts.single;
      expect(part.id, '9');
      expect(part.filePath, '/media/single.mp4');
      expect(part.streams, hasLength(1));
      expect(part.streams.single.codec, 'hevc');
    });

    test('projects detailed video fields and leaves Plex bitrate in kbps', () {
      final result = parsePlexFileInfoFromJson({
        'Media': [
          {
            'Part': [
              {
                'Stream': [
                  {
                    'id': '101',
                    'streamType': '1',
                    'index': '7',
                    'codec': 'hevc',
                    'codecID': 'hvc1',
                    'profile': 'Main 10',
                    'level': '153',
                    'bitrate': '17758',
                    'width': '3840',
                    'height': 1608,
                    'codedWidth': '3840',
                    'codedHeight': '1616',
                    'frameRate': '23.976',
                    'bitDepth': '10',
                    'refFrames': '4',
                    'colorSpace': 'bt2020nc',
                    'colorRange': 'tv',
                    'colorPrimaries': 'bt2020',
                    'colorTrc': 'smpte2084',
                    'chromaSubsampling': '4:2:0',
                    'chromaLocation': 'topleft',
                    'displayTitle': 'fallback title',
                    'extendedDisplayTitle': '4K HEVC Main 10',
                  },
                ],
              },
            ],
          },
        ],
      });

      final stream = result!.versions.single.parts.single.streams.single;
      expect(stream.kind, MediaStreamKind.video);
      expect(stream.index, 7);
      expect(stream.codec, 'hevc');
      expect(stream.codecTag, 'hvc1');
      expect(stream.profile, 'Main 10');
      expect(stream.level, 153);
      expect(stream.bitrateKbps, 17758);
      expect(stream.width, 3840);
      expect(stream.height, 1608);
      expect(stream.codedWidth, 3840);
      expect(stream.codedHeight, 1616);
      expect(stream.frameRate, closeTo(23.976, 0.0001));
      expect(stream.bitDepth, 10);
      expect(stream.refFrames, 4);
      expect(stream.colorSpace, 'bt2020nc');
      expect(stream.colorRange, 'tv');
      expect(stream.colorPrimaries, 'bt2020');
      expect(stream.colorTransfer, 'smpte2084');
      expect(stream.chromaSubsampling, '4:2:0');
      expect(stream.chromaLocation, 'topleft');
      expect(stream.displayTitle, '4K HEVC Main 10');
    });

    test('numbers audio and subtitle streams independently while preserving container indexes', () {
      final streams = _plexStreams([
        {'streamType': 2, 'index': 5, 'codec': 'aac'},
        {'streamType': 3, 'index': 3, 'codec': 'srt'},
        {'streamType': 2, 'index': 8, 'codec': 'eac3'},
        {'streamType': 3, 'index': 9, 'codec': 'ass'},
      ]);

      final audio = streams.where((stream) => stream.kind == MediaStreamKind.audio).toList();
      final subtitles = streams.where((stream) => stream.kind == MediaStreamKind.subtitle).toList();
      expect(audio.map((stream) => stream.ordinal), [1, 2]);
      expect(audio.map((stream) => stream.index), [5, 8]);
      expect(subtitles.map((stream) => stream.ordinal), [1, 2]);
      expect(subtitles.map((stream) => stream.index), [3, 9]);
    });

    test('coerces string-ish flags without turning absent flags into false', () {
      final stream = _plexStreams([
        {'streamType': 3, 'selected': '1', 'forced': 1, 'default': true},
      ]).single;

      expect(stream.isSelected, isTrue);
      expect(stream.isForced, isTrue);
      expect(stream.isDefault, isTrue);
      expect(stream.isHearingImpaired, isNull);
    });

    test('maps Dolby Vision metadata only when DOVIPresent is true', () {
      final streams = _plexStreams([
        {
          'streamType': 1,
          'DOVIPresent': '1',
          'DOVIProfile': '8',
          'DOVILevel': 6,
          'DOVIVersion': '1.0',
          'DOVIBLCompatID': '6',
          'DOVIBLPresent': true,
          'DOVIELPresent': 0,
          'DOVIRPUPresent': '1',
        },
        {'streamType': 1, 'DOVIProfile': 5},
      ]);

      final dolbyVision = streams.first.dolbyVision!;
      expect(dolbyVision.profile, 8);
      expect(dolbyVision.level, 6);
      expect(dolbyVision.version, '1.0');
      expect(dolbyVision.blCompatibilityId, 6);
      expect(dolbyVision.blPresent, isTrue);
      expect(dolbyVision.elPresent, isFalse);
      expect(dolbyVision.rpuPresent, isTrue);
      expect(dolbyVision.profileFormatted, 'Profile 8.6');
      expect(streams.last.dolbyVision, isNull);
    });

    test('derives video range from Dolby Vision and transfer characteristics', () {
      final streams = _plexStreams([
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 8, 'DOVIBLCompatID': 1},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 8, 'DOVIBLCompatID': 6},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 8, 'DOVIBLCompatID': 4},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 8, 'DOVIBLCompatID': 2},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 7},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 5, 'DOVIBLCompatID': 0},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 7, 'DOVIBLCompatID': 4},
        {'streamType': 1, 'DOVIPresent': true, 'DOVIProfile': 5, 'colorTrc': 'smpte2084'},
        {'streamType': 1, 'colorTrc': 'smpte2084'},
        {'streamType': 1, 'colorTrc': 'arib-std-b67'},
        {'streamType': 1, 'colorTrc': 'bt709'},
        {'streamType': 1},
      ]);

      expect(streams.map((stream) => stream.videoRange), [
        MediaVideoRange.dolbyVisionHdr10,
        MediaVideoRange.dolbyVisionHdr10,
        MediaVideoRange.dolbyVisionHlg,
        MediaVideoRange.dolbyVision,
        MediaVideoRange.dolbyVisionHdr10,
        MediaVideoRange.dolbyVision,
        MediaVideoRange.dolbyVisionHlg,
        MediaVideoRange.dolbyVision,
        MediaVideoRange.hdr10,
        MediaVideoRange.hlg,
        MediaVideoRange.sdr,
        MediaVideoRange.unknown,
      ]);
      expect(streams[0].dolbyVision!.profileFormatted, 'Profile 8.1');
      expect(streams[5].dolbyVision!.profileFormatted, 'Profile 5');
      expect(streams[7].dolbyVision!.profileFormatted, 'Profile 5');
    });

    test('marks only keyed subtitle streams as external', () {
      final streams = _plexStreams([
        {'streamType': 3, 'key': '/library/streams/123'},
        {'streamType': 3},
        {'streamType': 1, 'key': '/library/streams/not-a-subtitle'},
      ]);

      expect(streams[0].isExternal, isTrue);
      expect(streams[1].isExternal, isFalse);
      expect(streams[2].isExternal, isNull);
    });

    test('a malformed stream map does not discard valid siblings', () {
      final streams = _plexStreams([
        {'streamType': 1, 'codec': 'h264'},
        {1: 'non-string map key'},
        {'streamType': 2, 'codec': 'aac'},
      ]);

      expect(streams.map((stream) => stream.codec), ['h264', 'aac']);
    });

    test('projects an audio-only track without inventing video fields', () {
      final result = parsePlexFileInfoFromJson({
        'Media': [
          {
            'id': 42,
            'container': 'flac',
            'bitrate': 989,
            'duration': 201000,
            'audioCodec': 'flac',
            'audioChannels': 2,
            'Part': [
              {
                'id': 'part-1',
                'file': '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac',
                'size': 35651584,
                'container': 'flac',
                'Stream': [
                  {
                    'id': '201',
                    'streamType': 2,
                    'codec': 'flac',
                    'channels': 2,
                    'audioChannelLayout': 'stereo',
                    'samplingRate': 44100,
                    'bitDepth': 16,
                  },
                ],
              },
            ],
          },
        ],
      });

      final version = result!.versions.single;
      expect(version.container, 'flac');
      expect(version.audioCodec, 'flac');
      expect(version.audioChannels, 2);
      expect(version.videoCodec, isNull);
      expect(version.videoResolutionLabel, isNull);
      expect(version.resolutionFormatted, isNull);
      expect(version.aspectRatioFormatted, isNull);

      final part = version.parts.single;
      expect(part.filePath, '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac');
      expect(part.fileSize, 35651584);
      expect(part.streamsOfKind(MediaStreamKind.video), isEmpty);

      final audio = part.streamsOfKind(MediaStreamKind.audio).single;
      expect(audio.codec, 'flac');
      expect(audio.channelsFormatted, 'stereo (2 ch)');
      expect(audio.sampleRateFormatted, '44.1 kHz');
      expect(audio.bitDepthFormatted, '16 bit');
    });

    test('classifies streamType 4 as lyrics rather than an embedded image', () {
      // Stream shapes copied from a live Plex music library: a sidecar LRC
      // arrives as streamType 4 with a `format` and a `/library/streams/{id}`
      // key, which the sheet renders as the Lyrics group.
      final streams = _plexStreams([
        {'id': '52586', 'streamType': 2, 'codec': 'flac'},
        {
          'id': '52594',
          'streamType': 4,
          'codec': 'lrc',
          'format': 'lrc',
          'key': '/library/streams/52594',
          'displayTitle': 'LRC',
        },
        {'id': '203', 'streamType': 9, 'codec': 'mystery'},
      ]);

      expect(streams.map((stream) => stream.kind), [
        MediaStreamKind.audio,
        MediaStreamKind.lyric,
        MediaStreamKind.unknown,
      ]);
      expect(streams[1].codec, 'lrc');
      expect(streams[1].externalKey, '/library/streams/52594');
    });

    test('returns null for null metadata or metadata without Media', () {
      expect(parsePlexFileInfoFromJson(null), isNull);
      expect(parsePlexFileInfoFromJson(const {}), isNull);
    });
  });

  group('parseJellyfinFileInfoFromJson', () {
    test('keeps every media source as a one-part version in server order', () {
      final result = parseJellyfinFileInfoFromJson({
        'MediaSources': [
          {'Id': 'source-1', 'Name': 'Original', 'Path': '/media/original.mkv', 'Size': 9000},
          {'Id': 'source-2', 'Name': 'Transcoded', 'Path': '/media/transcoded.mp4', 'Size': '4000'},
        ],
      });

      expect(result, isNotNull);
      expect(result!.versions.map((version) => version.id), ['source-1', 'source-2']);
      expect(result.versions.every((version) => version.parts.length == 1), isTrue);
      expect(result.versions.map((version) => version.parts.single.filePath), [
        '/media/original.mkv',
        '/media/transcoded.mp4',
      ]);
      expect(result.versions.map((version) => version.parts.single.fileSize), [9000, 4000]);
    });

    test('normalizes bitrates and converts ticks into duration fields', () {
      final version = _jellyfinVersions([
        {
          'Id': 'source',
          'Bitrate': 3184421,
          'RunTimeTicks': 50250000000,
          'MediaStreams': [
            {'Type': 'Video', 'BitRate': 1775759},
          ],
        },
      ]).single;

      expect(version.bitrateKbps, 3184);
      expect(version.durationMs, 5025000);
      expect(version.durationFormatted, '1h 23m 45s');
      expect(version.parts.single.durationMs, 5025000);
      expect(version.parts.single.streams.single.bitrateKbps, 1776);
    });

    test('prefers declared aspect ratio then dimensions and otherwise leaves it absent', () {
      final versions = _jellyfinVersions([
        {
          'MediaStreams': [
            {'Type': 'Video', 'AspectRatio': '2.35:1', 'Width': 1920, 'Height': 1080},
          ],
        },
        {
          'MediaStreams': [
            {'Type': 'Video', 'Width': 1920, 'Height': 1080},
          ],
        },
        {
          'MediaStreams': [
            {'Type': 'Video'},
          ],
        },
      ]);

      expect(versions[0].aspectRatio, closeTo(2.35, 0.0001));
      expect(versions[1].aspectRatio, closeTo(16 / 9, 0.0001));
      expect(versions[2].aspectRatio, isNull);
    });

    test('rolls up summary fields from the first video and audio streams', () {
      final version = _jellyfinVersions([
        {
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'hevc', 'Profile': 'Main 10', 'Width': 3840, 'Height': 1608},
            {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High', 'Width': 1920, 'Height': 1080},
            {'Type': 'Audio', 'Codec': 'eac3', 'Profile': 'Dolby Digital Plus', 'Channels': 6},
            {'Type': 'Audio', 'Codec': 'aac', 'Channels': 2},
          ],
        },
      ]).single;

      expect(version.videoCodec, 'hevc');
      expect(version.videoProfile, 'Main 10');
      expect(version.audioCodec, 'eac3');
      expect(version.audioProfile, 'Dolby Digital Plus');
      expect(version.audioChannels, 6);
      expect(version.videoResolutionLabel, '4k');
    });

    test('maps every VideoRangeType and falls back to VideoRange', () {
      final streams = _jellyfinStreams([
        {'Type': 'Video', 'VideoRangeType': 'SDR'},
        {'Type': 'Video', 'VideoRangeType': 'HDR10'},
        {'Type': 'Video', 'VideoRangeType': 'HDR10Plus'},
        {'Type': 'Video', 'VideoRangeType': 'HLG'},
        {'Type': 'Video', 'VideoRangeType': 'DOVI'},
        {'Type': 'Video', 'VideoRangeType': 'DOVIWithHDR10'},
        {'Type': 'Video', 'VideoRangeType': 'DOVIWithHDR10Plus'},
        {'Type': 'Video', 'VideoRangeType': 'DOVIWithHLG'},
        {'Type': 'Video', 'VideoRangeType': 'Unknown', 'VideoRange': 'HDR'},
        {'Type': 'Video', 'VideoRangeType': 'Unknown', 'VideoRange': 'SDR'},
        {'Type': 'Video'},
      ]);

      expect(streams.map((stream) => stream.videoRange), [
        MediaVideoRange.sdr,
        MediaVideoRange.hdr10,
        MediaVideoRange.hdr10Plus,
        MediaVideoRange.hlg,
        MediaVideoRange.dolbyVision,
        MediaVideoRange.dolbyVisionHdr10,
        MediaVideoRange.dolbyVisionHdr10,
        MediaVideoRange.dolbyVisionHlg,
        MediaVideoRange.hdr,
        MediaVideoRange.sdr,
        MediaVideoRange.unknown,
      ]);
    });

    test('maps Dolby Vision fields only when present', () {
      final streams = _jellyfinStreams([
        {
          'Type': 'Video',
          'DvProfile': 8,
          'DvLevel': '6',
          'DvVersionMajor': 1,
          'DvVersionMinor': 0,
          'DvBlSignalCompatibilityId': 6,
          'BlPresentFlag': true,
          'ElPresentFlag': false,
          'RpuPresentFlag': true,
          'VideoDoViTitle': 'Dolby Vision Profile 8.6',
        },
        {'Type': 'Video', 'Codec': 'h264'},
      ]);

      final dolbyVision = streams.first.dolbyVision!;
      expect(dolbyVision.profile, 8);
      expect(dolbyVision.level, 6);
      expect(dolbyVision.version, '1.0');
      expect(dolbyVision.blCompatibilityId, 6);
      expect(dolbyVision.blPresent, isTrue);
      expect(dolbyVision.elPresent, isFalse);
      expect(dolbyVision.rpuPresent, isTrue);
      expect(dolbyVision.title, 'Dolby Vision Profile 8.6');
      expect(streams.last.dolbyVision, isNull);
    });

    test('derives progressive and interlaced scan types from IsInterlaced', () {
      final streams = _jellyfinStreams([
        {'Type': 'Video', 'IsInterlaced': false},
        {'Type': 'Video', 'IsInterlaced': true},
      ]);

      expect(streams[0].isInterlaced, isFalse);
      expect(streams[0].scanType, 'progressive');
      expect(streams[1].isInterlaced, isTrue);
      expect(streams[1].scanType, 'interlaced');
    });

    test('keeps embedded image and data streams', () {
      final streams = _jellyfinStreams([
        {'Type': 'EmbeddedImage', 'Codec': 'mjpeg'},
        {'Type': 'Data', 'Codec': 'bin_data'},
      ]);

      expect(streams.map((stream) => stream.kind), [MediaStreamKind.image, MediaStreamKind.data]);
      expect(streams.map((stream) => stream.codec), ['mjpeg', 'bin_data']);
    });

    test('maps CodecTag attachments and prefers an explicit Codec', () {
      final version = _jellyfinVersions([
        {
          'MediaAttachments': [
            {'Index': 4, 'FileName': 'OpenSans.ttf', 'MimeType': 'font/ttf', 'CodecTag': 'ttf'},
            {
              'Index': 5,
              'FileName': 'metadata.bin',
              'MimeType': 'application/octet-stream',
              'Codec': 'explicit-codec',
              'CodecTag': 'fallback-tag',
            },
          ],
        },
      ]).single;

      expect(version.attachments, hasLength(2));
      expect(version.attachments.first.index, 4);
      expect(version.attachments.first.fileName, 'OpenSans.ttf');
      expect(version.attachments.first.mimeType, 'font/ttf');
      expect(version.attachments.first.codec, 'ttf');
      expect(version.attachments.last.codec, 'explicit-codec');
    });

    test('projects an audio-only media source without inventing video fields', () {
      final result = parseJellyfinFileInfoFromJson({
        'MediaSources': [
          {
            'Id': 'source-1',
            'Name': 'Ready Lets Go',
            'Container': 'flac',
            'Path': '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac',
            'Size': 35651584,
            'Bitrate': 989000,
            'RunTimeTicks': 2010000000,
            'MediaStreams': [
              {
                'Type': 'Audio',
                'Codec': 'flac',
                'Channels': 2,
                'ChannelLayout': 'stereo',
                'SampleRate': 44100,
                'BitDepth': 16,
              },
              {'Type': 'EmbeddedImage', 'Codec': 'mjpeg'},
              {'Type': 'Lyric', 'Codec': 'lrc', 'Path': '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.lrc'},
            ],
          },
        ],
      });

      final version = result!.versions.single;
      expect(version.container, 'flac');
      expect(version.audioCodec, 'flac');
      expect(version.videoCodec, isNull);
      expect(version.videoResolutionLabel, isNull);
      expect(version.resolutionFormatted, isNull);
      expect(version.aspectRatioFormatted, isNull);

      final part = version.parts.single;
      expect(part.filePath, '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac');
      expect(part.streamsOfKind(MediaStreamKind.video), isEmpty);

      final audio = part.streamsOfKind(MediaStreamKind.audio).single;
      expect(audio.channelsFormatted, 'stereo (2 ch)');
      expect(audio.sampleRateFormatted, '44.1 kHz');
      expect(audio.bitDepthFormatted, '16 bit');

      expect(part.streamsOfKind(MediaStreamKind.image).single.codec, 'mjpeg');
      final lyric = part.streamsOfKind(MediaStreamKind.lyric).single;
      expect(lyric.codec, 'lrc');
      expect(lyric.filePath, '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.lrc');
    });

    test('returns null for missing empty or non-list MediaSources', () {
      expect(parseJellyfinFileInfoFromJson(const {}), isNull);
      expect(parseJellyfinFileInfoFromJson(const {'MediaSources': []}), isNull);
      expect(
        parseJellyfinFileInfoFromJson(const {
          'MediaSources': {'Id': 'source'},
        }),
        isNull,
      );
    });
  });

  group('Media file-info formatting', () {
    test('formats channel layouts and counts without empty punctuation', () {
      expect(_stream(channels: 6, channelLayout: '5.1').channelsFormatted, '5.1 (6 ch)');
      expect(_stream(channelLayout: '5.1').channelsFormatted, '5.1');
      expect(_stream(channels: 6).channelsFormatted, '6 ch');
      expect(_stream().channelsFormatted, isNull);
    });

    test('formats whole and fractional sample rates in kHz', () {
      expect(_stream(sampleRate: 48000).sampleRateFormatted, '48 kHz');
      expect(_stream(sampleRate: 44100).sampleRateFormatted, '44.1 kHz');
    });

    test('formats whole and fractional frame rates without spurious decimals', () {
      expect(_stream(frameRate: 24.0).frameRateFormatted, '24 fps');
      expect(_stream(frameRate: 23.976).frameRateFormatted, '23.976 fps');
    });

    test('extracts filenames from POSIX and Windows paths', () {
      expect(const MediaFilePart(filePath: '/media/movies/Movie.mkv').fileName, 'Movie.mkv');
      expect(const MediaFilePart(filePath: r'C:\Media\Movies\Movie.mkv').fileName, 'Movie.mkv');
      expect(const MediaFilePart(filePath: '').fileName, isNull);
    });

    test('formats durations at hour minute second boundaries', () {
      expect(formatMediaDuration(5025000), '1h 23m 45s');
      expect(formatMediaDuration(1425000), '23m 45s');
      expect(formatMediaDuration(45000), '45s');
      expect(formatMediaDuration(null), isNull);
    });

    test('headline falls back through display title title language codec and ordinal', () {
      expect(_stream(displayTitle: 'Display', title: 'Title', language: 'English', codec: 'aac').headline, 'Display');
      expect(_stream(title: 'Title', language: 'English', codec: 'aac').headline, 'Title');
      expect(_stream(language: 'English', codec: 'aac').headline, 'English');
      expect(_stream(codec: 'aac').headline, 'aac');
      expect(_stream(ordinal: 7).headline, '#7');
    });
  });
}

List<MediaStreamDetails> _plexStreams(List<Object?> streams) {
  return parsePlexFileInfoFromJson({
    'Media': [
      {
        'Part': [
          {'Stream': streams},
        ],
      },
    ],
  })!.versions.single.parts.single.streams;
}

List<MediaFileVersion> _jellyfinVersions(List<Map<String, dynamic>> sources) {
  return parseJellyfinFileInfoFromJson({'MediaSources': sources})!.versions;
}

List<MediaStreamDetails> _jellyfinStreams(List<Map<String, dynamic>> streams) {
  return _jellyfinVersions([
    {'MediaStreams': streams},
  ]).single.parts.single.streams;
}

MediaStreamDetails _stream({
  int ordinal = 1,
  String? displayTitle,
  String? title,
  String? language,
  String? codec,
  int? channels,
  String? channelLayout,
  int? sampleRate,
  double? frameRate,
}) {
  return MediaStreamDetails(
    kind: MediaStreamKind.audio,
    ordinal: ordinal,
    displayTitle: displayTitle,
    title: title,
    language: language,
    codec: codec,
    channels: channels,
    channelLayout: channelLayout,
    sampleRate: sampleRate,
    frameRate: frameRate,
  );
}
