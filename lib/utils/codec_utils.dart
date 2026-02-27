/// Utility class for codec-related operations.
///
/// Provides centralized codec name mappings, file extension lookups,
/// and display name formatting.
class CodecUtils {
  CodecUtils._();

  /// Maps Plex subtitle codec names to file extensions.
  ///
  /// Returns the appropriate file extension for a given subtitle codec.
  /// Defaults to 'srt' for unknown or null codecs.
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
      case 'hdmv_pgs_subtitle':
        return 'sup';
      case 'dvd_subtitle':
      case 'dvdsub':
        return 'sub';
      default:
        return 'srt';
    }
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
