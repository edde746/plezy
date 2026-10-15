import '../../mpv/player/player.dart';
import '../../utils/app_logger.dart';

/// A frame step the caller measured: [frames] shown frames advanced the
/// video timestamp by [advanced].
typedef SteppedFrames = ({int frames, Duration advanced});

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
  /// would drop every other frame (#2322). Three things can say so: mpv's
  /// own deinterlacer (`deinterlace-active`: every backend
  /// `deinterlace=auto` picks — bwdif `send_field`, d3d11vpp, vavpp — emits
  /// fields); mpv's own cadence estimate (`estimated-vf-fps`); and, for a
  /// decoder that deinterlaces by itself (MediaCodec on Tegra, MediaTek,
  /// Amlogic) where that estimate has not converged on the video plane, the
  /// media time the caller measured a frame [step] advancing — see
  /// [presentsFields]. Backends without these properties (ExoPlayer) never
  /// deinterlace.
  ///
  /// Without `container-fps` — a Matroska track with no DefaultDuration,
  /// for which mpv's own demuxer has no other source (#2607) — the rate is
  /// the [standardRate] the [step] identifies, already the presented one.
  static Future<PlayerOutputFormat> read(Player player, {SteppedFrames? step}) async {
    final steppedFps = step == null ? null : steppedRate(frames: step.frames, advanced: step.advanced);
    var fps = _positive(await player.getProperty('container-fps'));
    if (fps != null) {
      final container = fps;
      final deinterlacing = await player.getProperty('deinterlace-active') == 'yes';
      final estimated = _positive(await player.getProperty('estimated-vf-fps'));
      final fieldOutput =
          deinterlacing ||
          (estimated != null && presentsFields(container: container, presented: estimated)) ||
          (steppedFps != null && presentsFields(container: container, presented: steppedFps));
      if (fieldOutput) fps *= 2;
    } else if (step != null) {
      fps = standardRate(frames: step.frames, advanced: step.advanced);
      appLogger.d(
        'Display matching: no container frame rate; the frame step '
        '${fps == null ? 'matches no standard rate' : 'identifies ${fps.toStringAsFixed(3)}fps'}',
      );
    }
    final width = int.tryParse(await player.getProperty('width') ?? '') ?? 0;
    final height = int.tryParse(await player.getProperty('height') ?? '') ?? 0;
    return PlayerOutputFormat(fps: fps, width: width, height: height);
  }

  /// The rate a frame step revealed: [frames] shown frames advanced the
  /// video timestamp by [advanced]. Independent of mpv's frame-duration
  /// averaging, which on the MediaCodec plane stays unavailable long after
  /// ten stepped frames; the decoder's own output timestamps are what
  /// `time-pos` follows while video plays. Null for a step that showed no
  /// media time (a stalled or seeked window).
  static double? steppedRate({required int frames, required Duration advanced}) {
    if (frames <= 0 || advanced <= Duration.zero) return null;
    return frames / (advanced.inMicroseconds / Duration.microsecondsPerSecond);
  }

  /// Rates a frame step may identify.
  static const _standardRates = <double>[
    24000 / 1001,
    24,
    25,
    30000 / 1001,
    30,
    48000 / 1001,
    48,
    50,
    60000 / 1001,
    60,
    100,
    120000 / 1001,
    120,
  ];

  /// How far a step may miss a standard rate's span: each end is a
  /// timestamp rounded to Matroska's default millisecond scale.
  static const _timestampRounding = Duration(milliseconds: 1);

  /// The standard rate whose span for [frames] lies nearest [advanced],
  /// within [_timestampRounding], or null when none does. A ten-frame step
  /// cannot resolve a rate by itself: ten 23.976 fps frames span 417.08 ms,
  /// which millisecond timestamps read as 417 or 418 (23.98 or 23.92 fps),
  /// and ten 24 fps frames may read as 417 too, landing on 23.976 — one
  /// repeated frame every ~42 s rather than the 3:2 judder of no switch.
  /// Variable-rate content, a duplicated timestamp, or a misdetected rate
  /// (24.417, #2607) matches nothing, so it switches nothing.
  static double? standardRate({required int frames, required Duration advanced}) {
    if (frames <= 0 || advanced <= Duration.zero) return null;
    double? nearest;
    var nearestError = double.infinity;
    for (final rate in _standardRates) {
      final error = (frames * Duration.microsecondsPerSecond / rate - advanced.inMicroseconds).abs();
      if (error < nearestError) {
        nearest = rate;
        nearestError = error;
      }
    }
    return nearestError <= _timestampRounding.inMicroseconds ? nearest : null;
  }

  /// Whether a measured output cadence is the container rate doubled. The
  /// band absorbs Matroska's millisecond timestamp rounding (a 16.68 ms
  /// field reads as 16 or 17 ms) and one duplicated timestamp inside a
  /// ten-frame step (MediaTek's first field pair shares one: 10/9 × 2 =
  /// 2.22), while rejecting duplicate-every-frame, dropped, or telecined
  /// cadences (3.0, 0.5, 1.25). Mirrored by the Android core's
  /// `PresentedFrameRate` for the seamless surface vote and the Apple core.
  static bool presentsFields({required double container, required double presented}) {
    final ratio = presented / container;
    return ratio > 1.7 && ratio < 2.3;
  }

  static double? _positive(String? raw) {
    final value = double.tryParse(raw ?? '');
    return value != null && value > 0 ? value : null;
  }
}
