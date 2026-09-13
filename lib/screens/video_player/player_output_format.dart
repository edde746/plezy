import '../../mpv/player/player.dart';

/// What the player is about to present, read from the player alone once its
/// video chain exists. This is the only source display matching consults:
/// server metadata describes the file, not the stream — it is missing or
/// wrong for transcodes and Live TV, and it cannot know what the filter chain
/// does to the rate (#1299, #2322).
class PlayerOutputFormat {
  const PlayerOutputFormat({required this.fps, required this.width, required this.height});

  /// The presented frame rate, or null while the container carries no usable
  /// rate (ExoPlayer detects it only after a few rendered frames).
  final double? fps;

  /// Decoded dimensions (0 = unknown), so a transcode targets the server's
  /// output size rather than the original file's.
  final int width;
  final int height;

  bool get hasFrameRate => fps != null;
  bool get hasDimensions => width > 0 && height > 0;

  /// `container-fps`, doubled while the stream is presented one frame per
  /// field, so 29.97i is presented at 59.94 fps and an exact 29.97 Hz mode
  /// would drop every other frame (#2322). Two things double it: mpv's own
  /// deinterlacer (`deinterlace-active`: every backend `deinterlace=auto`
  /// picks — bwdif `send_field`, d3d11vpp, vavpp — emits fields), and a
  /// decoder that deinterlaces by itself (MediaCodec on Tegra and Amlogic),
  /// which no mpv filter reports and only the measured cadence reveals —
  /// see [presentsFields]. Backends without these properties (ExoPlayer)
  /// never deinterlace.
  static Future<PlayerOutputFormat> read(Player player) async {
    var fps = _positive(await player.getProperty('container-fps'));
    if (fps != null) {
      final deinterlacing = await player.getProperty('deinterlace-active') == 'yes';
      final presented = _positive(await player.getProperty('estimated-vf-fps'));
      if (deinterlacing || (presented != null && presentsFields(container: fps, presented: presented))) {
        fps *= 2;
      }
    }
    final width = int.tryParse(await player.getProperty('width') ?? '') ?? 0;
    final height = int.tryParse(await player.getProperty('height') ?? '') ?? 0;
    return PlayerOutputFormat(fps: fps, width: width, height: height);
  }

  /// Whether the measured output cadence (`estimated-vf-fps`, the frame
  /// duration mpv derives from consecutive output timestamps — one sample
  /// already at the first shown frame, since mpv decodes two frames before
  /// showing one) is the container rate doubled. The band absorbs Matroska's
  /// millisecond timestamp rounding (a 16.68 ms field reads as 16 or 17 ms)
  /// while rejecting duplicate, dropped, or telecined cadences. Mirrored by
  /// the Android core's `PresentedFrameRate` for the seamless surface vote.
  static bool presentsFields({required double container, required double presented}) {
    final ratio = presented / container;
    return ratio > 1.8 && ratio < 2.2;
  }

  static double? _positive(String? raw) {
    final value = double.tryParse(raw ?? '');
    return value != null && value > 0 ? value : null;
  }
}
