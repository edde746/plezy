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

  /// `container-fps`, doubled while mpv's own deinterlacer is active: every
  /// backend `deinterlace=auto` picks (bwdif `send_field`, d3d11vpp, vavpp)
  /// emits one frame per field, so 29.97i is presented at 59.94 fps and an
  /// exact 29.97 Hz mode would drop every other frame (#2322). Backends
  /// without the property (ExoPlayer) never deinterlace.
  static Future<PlayerOutputFormat> read(Player player) async {
    var fps = double.tryParse(await player.getProperty('container-fps') ?? '');
    if (fps == null || fps <= 0) {
      fps = null;
    } else if (await player.getProperty('deinterlace-active') == 'yes') {
      fps *= 2;
    }
    final width = int.tryParse(await player.getProperty('width') ?? '') ?? 0;
    final height = int.tryParse(await player.getProperty('height') ?? '') ?? 0;
    return PlayerOutputFormat(fps: fps, width: width, height: height);
  }
}
