/// Utility class for codec-related operations.
///
/// Provides centralized codec name mappings, file extension lookups,
/// and display name formatting.
class CodecUtils {
  CodecUtils._();

  static String getSubtitleExtension(String? codec) {
    if (codec == null) return 'srt';

    switch (codec.toLowerCase()) {
      case 'subrip':
      case 'srt':
        return 'srt';
      case 'ass':
      case 'ssa':
        return 'ass';
      case 'webvtt':
      case 'vtt':
        return 'vtt';
      case 'mov_text':
        return 'srt';
      case 'pgs':
      case 'pgssub':
      case 'hdmv_pgs_subtitle':
        return 'sup';
      case 'dvd_subtitle':
      case 'dvdsub':
      case 'vobsub':
      case 'dvb_sub':
      case 'dvb_subtitle':
        return 'sub';
      default:
        return 'srt';
    }
  }

  static bool isTextSubtitleCodec(String? codec) {
    if (codec == null) return false;
    return switch (codec.toLowerCase()) {
      'srt' || 'subrip' || 'ass' || 'ssa' || 'webvtt' || 'vtt' || 'mov_text' => true,
      _ => false,
    };
  }

  /// Image-based (bitmap) subtitle codecs. These can't be converted to text;
  /// during an HTTP/MKV transcode Plex copies the stream into the container and
  /// the player renders it natively.
  static bool isImageSubtitleCodec(String? codec) {
    if (codec == null) return false;
    return switch (codec.toLowerCase()) {
      'pgs' ||
      'pgssub' ||
      'hdmv_pgs_subtitle' ||
      'dvd_subtitle' ||
      'dvdsub' ||
      'vobsub' ||
      'dvb_sub' ||
      'dvb_subtitle' => true,
      _ => false,
    };
  }

  /// Subtitle codecs that can be carried inside the HTTP/MKV transcode stream
  /// (`subtitles=embedded`): text codecs plus the image codecs the MKV target
  /// supports. Keyed sidecars are delivered separately and are not covered here.
  static bool isEmbeddableSubtitleCodec(String? codec) {
    return isTextSubtitleCodec(codec) || isImageSubtitleCodec(codec);
  }

  /// Formats a subtitle codec name to a user-friendly display format.
  ///
  /// Converts internal codec names like 'SUBRIP' to friendly names like 'SRT'.
  static String formatSubtitleCodec(String codec) {
    final upper = codec.toUpperCase();
    return switch (upper) {
      'SUBRIP' => 'SRT',
      'DVD_SUBTITLE' => 'DVD',
      'WEBVTT' => 'VTT',
      'HDMV_PGS_SUBTITLE' => 'PGS',
      'MOV_TEXT' => 'MOV',
      _ => upper,
    };
  }

  /// Formats a video codec name to a user-friendly display format.
  ///
  /// Converts internal codec names like 'hevc' to friendly names like 'HEVC'.
  static String formatVideoCodec(String codec) {
    final lower = codec.toLowerCase();
    return switch (lower) {
      'h264' || 'avc1' || 'avc' => 'H.264',
      'hevc' || 'h265' || 'hev1' => 'HEVC',
      'av1' => 'AV1',
      'vp8' => 'VP8',
      'vp9' => 'VP9',
      'mpeg2video' || 'mpeg2' => 'MPEG-2',
      'mpeg4' => 'MPEG-4',
      'vc1' => 'VC-1',
      _ => codec.toUpperCase(),
    };
  }

  /// Formats an audio channel count as a friendly layout name (2 → 'Stereo',
  /// 6 → '5.1'). Returns null when [channels] is null or not positive.
  static String? formatAudioChannels(int? channels) {
    if (channels == null || channels <= 0) return null;
    return switch (channels) {
      1 => 'Mono',
      2 => 'Stereo',
      3 => '3.0',
      4 => '4.0',
      5 => '4.1',
      6 => '5.1',
      7 => '6.1',
      8 => '7.1',
      _ => '${channels}ch',
    };
  }

  /// Formats an audio codec name to a user-friendly display format.
  static String formatAudioCodec(String codec) {
    final lower = codec.toLowerCase();
    return switch (lower) {
      'aac' => 'AAC',
      'ac3' => 'AC3',
      'eac3' || 'ec3' => 'E-AC3',
      'truehd' => 'TrueHD',
      'dts' => 'DTS',
      'dca' => 'DTS',
      'dtshd' || 'dts-hd' => 'DTS-HD',
      'flac' => 'FLAC',
      'mp3' || 'mp3float' => 'MP3',
      'opus' => 'Opus',
      'vorbis' => 'Vorbis',
      'pcm_s16le' || 'pcm_s24le' || 'pcm' => 'PCM',
      _ => codec.toUpperCase(),
    };
  }
}
