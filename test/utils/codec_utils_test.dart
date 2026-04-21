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

    test('maps pgs/hdmv_pgs_subtitle -> sup', () {
      expect(CodecUtils.getSubtitleExtension('pgs'), 'sup');
      expect(CodecUtils.getSubtitleExtension('HDMV_PGS_SUBTITLE'), 'sup');
    });

    test('maps dvd_subtitle/dvdsub -> sub', () {
      expect(CodecUtils.getSubtitleExtension('dvd_subtitle'), 'sub');
      expect(CodecUtils.getSubtitleExtension('dvdsub'), 'sub');
    });

    test('defaults to srt for unknown codec', () {
      expect(CodecUtils.getSubtitleExtension('weirdcodec'), 'srt');
      expect(CodecUtils.getSubtitleExtension(''), 'srt');
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
  });
}
