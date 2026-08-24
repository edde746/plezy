import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/codec_utils.dart';

void main() {
  group('CodecUtils.getSubtitleExtension', () {
    test('returns srt for null', () {
      expect(CodecUtils.getSubtitleExtension(null), 'srt');
    });

    test('maps subrip/srt -> srt', () {
      expect(CodecUtils.getSubtitleExtension('subrip'), 'srt');
      expect(CodecUtils.getSubtitleExtension('SRT'), 'srt');
    });

    test('maps ass/ssa -> ass', () {
      expect(CodecUtils.getSubtitleExtension('ass'), 'ass');
      expect(CodecUtils.getSubtitleExtension('SSA'), 'ass');
    });

    test('maps webvtt/vtt -> vtt', () {
      expect(CodecUtils.getSubtitleExtension('webvtt'), 'vtt');
      expect(CodecUtils.getSubtitleExtension('VTT'), 'vtt');
    });

    test('maps mov_text -> srt', () {
      expect(CodecUtils.getSubtitleExtension('mov_text'), 'srt');
    });

    test('maps pgs codecs -> sup', () {
      expect(CodecUtils.getSubtitleExtension('pgs'), 'sup');
      expect(CodecUtils.getSubtitleExtension('pgssub'), 'sup');
      expect(CodecUtils.getSubtitleExtension('HDMV_PGS_SUBTITLE'), 'sup');
    });

    test('maps dvd/vobsub/dvb bitmap codecs -> sub', () {
      expect(CodecUtils.getSubtitleExtension('dvd_subtitle'), 'sub');
      expect(CodecUtils.getSubtitleExtension('dvdsub'), 'sub');
      expect(CodecUtils.getSubtitleExtension('vobsub'), 'sub');
      expect(CodecUtils.getSubtitleExtension('dvb_sub'), 'sub');
      expect(CodecUtils.getSubtitleExtension('dvb_subtitle'), 'sub');
    });

    test('defaults to srt for unknown codec', () {
      expect(CodecUtils.getSubtitleExtension('weirdcodec'), 'srt');
      expect(CodecUtils.getSubtitleExtension(''), 'srt');
    });
  });

  group('CodecUtils subtitle classification', () {
    test('isTextSubtitleCodec recognizes text codecs only', () {
      for (final codec in ['srt', 'subrip', 'ass', 'ssa', 'webvtt', 'vtt', 'mov_text', 'ASS']) {
        expect(CodecUtils.isTextSubtitleCodec(codec), isTrue, reason: codec);
      }
      for (final codec in ['pgs', 'dvd_subtitle', 'vobsub', 'weird', null]) {
        expect(CodecUtils.isTextSubtitleCodec(codec), isFalse, reason: '$codec');
      }
    });

    test('isImageSubtitleCodec recognizes bitmap codecs only', () {
      for (final codec in [
        'pgs',
        'pgssub',
        'hdmv_pgs_subtitle',
        'dvd_subtitle',
        'dvdsub',
        'vobsub',
        'dvb_sub',
        // Jellyfin's own spelling. The transcode profile asks it to burn `dvbsub`, so a picker that
        // does not recognise the name never offers the track it just negotiated.
        'dvbsub',
        'dvb_subtitle',
        'PGS',
      ]) {
        expect(CodecUtils.isImageSubtitleCodec(codec), isTrue, reason: codec);
      }
      for (final codec in ['srt', 'ass', 'mov_text', 'weird', null]) {
        expect(CodecUtils.isImageSubtitleCodec(codec), isFalse, reason: '$codec');
      }
    });

    test('isTranscodableSubtitleCodec covers text and image, not unknown', () {
      for (final codec in ['srt', 'ass', 'pgs', 'vobsub', 'dvd_subtitle']) {
        expect(CodecUtils.isTranscodableSubtitleCodec(codec), isTrue, reason: codec);
      }
      expect(CodecUtils.isTranscodableSubtitleCodec('weird'), isFalse);
      expect(CodecUtils.isTranscodableSubtitleCodec(null), isFalse);
    });
  });

  group('CodecUtils.formatSubtitleCodec', () {
    test('maps known codecs to friendly labels', () {
      expect(CodecUtils.formatSubtitleCodec('subrip'), 'SRT');
      expect(CodecUtils.formatSubtitleCodec('SUBRIP'), 'SRT');
      expect(CodecUtils.formatSubtitleCodec('dvd_subtitle'), 'DVD');
      expect(CodecUtils.formatSubtitleCodec('webvtt'), 'VTT');
      expect(CodecUtils.formatSubtitleCodec('hdmv_pgs_subtitle'), 'PGS');
      expect(CodecUtils.formatSubtitleCodec('mov_text'), 'MOV');
    });

    test('uppercases unknown codecs', () {
      expect(CodecUtils.formatSubtitleCodec('foo'), 'FOO');
      expect(CodecUtils.formatSubtitleCodec('ass'), 'ASS');
    });
  });

  group('CodecUtils.formatVideoCodec', () {
    test('h264 aliases -> H.264', () {
      expect(CodecUtils.formatVideoCodec('h264'), 'H.264');
      expect(CodecUtils.formatVideoCodec('avc1'), 'H.264');
      expect(CodecUtils.formatVideoCodec('avc'), 'H.264');
      expect(CodecUtils.formatVideoCodec('H264'), 'H.264');
    });

    test('hevc aliases -> HEVC', () {
      expect(CodecUtils.formatVideoCodec('hevc'), 'HEVC');
      expect(CodecUtils.formatVideoCodec('h265'), 'HEVC');
      expect(CodecUtils.formatVideoCodec('hev1'), 'HEVC');
    });

    test('av1/vp8/vp9', () {
      expect(CodecUtils.formatVideoCodec('av1'), 'AV1');
      expect(CodecUtils.formatVideoCodec('vp8'), 'VP8');
      expect(CodecUtils.formatVideoCodec('vp9'), 'VP9');
    });

    test('mpeg aliases', () {
      expect(CodecUtils.formatVideoCodec('mpeg2video'), 'MPEG-2');
      expect(CodecUtils.formatVideoCodec('mpeg2'), 'MPEG-2');
      expect(CodecUtils.formatVideoCodec('mpeg4'), 'MPEG-4');
    });

    test('vc1', () {
      expect(CodecUtils.formatVideoCodec('vc1'), 'VC-1');
    });

    test('unknown codec uppercases original input', () {
      expect(CodecUtils.formatVideoCodec('foo'), 'FOO');
      expect(CodecUtils.formatVideoCodec('Prores'), 'PRORES');
    });
  });

  group('CodecUtils.formatAudioCodec', () {
    test('common codecs', () {
      expect(CodecUtils.formatAudioCodec('aac'), 'AAC');
      expect(CodecUtils.formatAudioCodec('AAC'), 'AAC');
      expect(CodecUtils.formatAudioCodec('ac3'), 'AC3');
      expect(CodecUtils.formatAudioCodec('truehd'), 'TrueHD');
      expect(CodecUtils.formatAudioCodec('flac'), 'FLAC');
      expect(CodecUtils.formatAudioCodec('opus'), 'Opus');
      expect(CodecUtils.formatAudioCodec('vorbis'), 'Vorbis');
    });

    test('eac3/ec3 -> E-AC3', () {
      expect(CodecUtils.formatAudioCodec('eac3'), 'E-AC3');
      expect(CodecUtils.formatAudioCodec('ec3'), 'E-AC3');
    });

    test('dts family', () {
      expect(CodecUtils.formatAudioCodec('dts'), 'DTS');
      expect(CodecUtils.formatAudioCodec('dca'), 'DTS');
      expect(CodecUtils.formatAudioCodec('dtshd'), 'DTS-HD');
      expect(CodecUtils.formatAudioCodec('dts-hd'), 'DTS-HD');
    });

    test('RFC 6381 codec IDs from ExoPlayer map to friendly names', () {
      // AAC-LC as reported for MP4/HLS direct play (#1899).
      expect(CodecUtils.formatAudioCodec('mp4a.40.2'), 'AAC');
      expect(CodecUtils.formatAudioCodec('MP4A.40.2'), 'AAC');
      expect(CodecUtils.formatAudioCodec('mp4a.40.5'), 'AAC');
      expect(CodecUtils.formatAudioCodec('mp4a.40.29'), 'AAC');
      expect(CodecUtils.formatAudioCodec('mp4a'), 'AAC');
      // MPEG layer audio object types under the mp4a prefix.
      expect(CodecUtils.formatAudioCodec('mp4a.69'), 'MP3');
      expect(CodecUtils.formatAudioCodec('mp4a.6B'), 'MP3');
      // Dolby and DTS sample entry names.
      expect(CodecUtils.formatAudioCodec('ac-3'), 'AC3');
      expect(CodecUtils.formatAudioCodec('ec-3'), 'E-AC3');
      expect(CodecUtils.formatAudioCodec('ac-4'), 'AC4');
      expect(CodecUtils.formatAudioCodec('ac-4.02.01.01'), 'AC4');
      expect(CodecUtils.formatAudioCodec('mlpa'), 'TrueHD');
      expect(CodecUtils.formatAudioCodec('dtsc'), 'DTS');
      expect(CodecUtils.formatAudioCodec('dtse'), 'DTS');
      expect(CodecUtils.formatAudioCodec('dtsh'), 'DTS-HD');
      expect(CodecUtils.formatAudioCodec('dtsl'), 'DTS-HD');
      expect(CodecUtils.formatAudioCodec('dtsx'), 'DTS:X');
    });

    test('mp3 aliases', () {
      expect(CodecUtils.formatAudioCodec('mp3'), 'MP3');
      expect(CodecUtils.formatAudioCodec('mp3float'), 'MP3');
    });

    test('pcm aliases', () {
      expect(CodecUtils.formatAudioCodec('pcm'), 'PCM');
      expect(CodecUtils.formatAudioCodec('pcm_s16le'), 'PCM');
      expect(CodecUtils.formatAudioCodec('pcm_s24le'), 'PCM');
    });

    test('unknown codec uppercases original input', () {
      expect(CodecUtils.formatAudioCodec('alac'), 'ALAC');
      expect(CodecUtils.formatAudioCodec('weird'), 'WEIRD');
    });

    test('audio MIME types from ExoPlayer Format.sampleMimeType map to friendly names (#2063)', () {
      expect(CodecUtils.formatAudioCodec('audio/mp4a-latm'), 'AAC');
      expect(CodecUtils.formatAudioCodec('audio/mpeg'), 'MP3');
      expect(CodecUtils.formatAudioCodec('audio/ac3'), 'AC3');
      expect(CodecUtils.formatAudioCodec('audio/eac3'), 'E-AC3');
      expect(CodecUtils.formatAudioCodec('audio/eac3-joc'), 'E-AC3');
      expect(CodecUtils.formatAudioCodec('audio/true-hd'), 'TrueHD');
      expect(CodecUtils.formatAudioCodec('audio/vnd.dts'), 'DTS');
      expect(CodecUtils.formatAudioCodec('audio/vnd.dts.hd'), 'DTS-HD');
      expect(CodecUtils.formatAudioCodec('audio/vnd.dts.hd;profile=lbr'), 'DTS-HD');
      expect(CodecUtils.formatAudioCodec('audio/vnd.dts.uhd;audio=p2'), 'DTS:X');
      expect(CodecUtils.formatAudioCodec('audio/flac'), 'FLAC');
      expect(CodecUtils.formatAudioCodec('audio/opus'), 'Opus');
      expect(CodecUtils.formatAudioCodec('audio/vorbis'), 'Vorbis');
      expect(CodecUtils.formatAudioCodec('audio/ac4'), 'AC4');
      expect(CodecUtils.formatAudioCodec('audio/raw'), 'PCM');
      expect(CodecUtils.formatAudioCodec('audio/alac'), 'ALAC');
    });
  });

  group('CodecUtils.formatAudioChannels', () {
    test('maps counts to layout names', () {
      expect(CodecUtils.formatAudioChannels(1), 'Mono');
      expect(CodecUtils.formatAudioChannels(2), 'Stereo');
      expect(CodecUtils.formatAudioChannels(3), '3.0');
      expect(CodecUtils.formatAudioChannels(4), '4.0');
      expect(CodecUtils.formatAudioChannels(5), '4.1');
      expect(CodecUtils.formatAudioChannels(6), '5.1');
      expect(CodecUtils.formatAudioChannels(7), '6.1');
      expect(CodecUtils.formatAudioChannels(8), '7.1');
    });

    test('falls back to Nch above 8 channels', () {
      expect(CodecUtils.formatAudioChannels(10), '10ch');
    });

    test('returns null for null and non-positive counts', () {
      expect(CodecUtils.formatAudioChannels(null), null);
      expect(CodecUtils.formatAudioChannels(0), null);
      expect(CodecUtils.formatAudioChannels(-1), null);
    });
  });
}
