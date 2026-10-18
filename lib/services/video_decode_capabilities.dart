import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/async_singleton.dart';
import '../utils/device_channel.dart';
import 'settings_service.dart';

/// The video codecs Plezy negotiates with a media server, most efficient
/// first. Every transcode target lists them in this order so a server able to
/// encode more than one picks the best; the hardware probe and the user's
/// refusals only remove entries, never reorder them.
enum RankedVideoCodec {
  av1('av1'),
  hevc('hevc'),
  h264('h264');

  const RankedVideoCodec(this.id);

  /// Codec name on the wire and in [SettingsService.refusedVideoCodecs].
  final String id;

  /// H.264 is the one output every server can encode to. Refusing it would
  /// leave a transcode with nothing to produce, so it is always accepted.
  bool get isRefusable => this != h264;

  /// The entry a server-reported codec name belongs to, aliases included, or
  /// null for a codec outside the ranked list (VP9, MPEG-2, …).
  static RankedVideoCodec? fromServerCodec(String? codec) => switch (codec?.toLowerCase()) {
    'av1' => av1,
    'hevc' || 'h265' || 'hev1' => hevc,
    'h264' || 'avc' || 'avc1' => h264,
    _ => null,
  };
}

/// Which [RankedVideoCodec]s this device accepts from a media server.
///
/// Two inputs narrow the list. The hardware probe: mpv software-decodes HEVC
/// and AV1 everywhere, so the probe answers "can we decode it without
/// dropping frames", not "can we decode it". Without a hardware decoder a
/// phone or TV box has to ask the server to transcode instead of taking the
/// original stream, and must not offer that codec as a transcode target.
///
/// Only Android (`MediaCodecList`) and iOS/tvOS (`VTIsHardwareDecodeSupported`)
/// answer the probe. Desktop deliberately does not implement it: a
/// pre-Kaby-Lake Mac has no hardware HEVC decoder and an M1 no hardware AV1
/// one, yet both software-decode in real time, so narrowing there would force
/// transcodes for nothing. An unanswered or failed probe reports support — the
/// advertised codec list must never narrow on missing data.
///
/// The user's refusals cover what the probe cannot: a desktop too weak to
/// software-decode a codec (a dual-core Atom, #2443). The setting is shown
/// only on desktop and is device-local, so elsewhere the probe alone decides.
///
/// The probe is latched once during the startup device-capabilities phase;
/// refusals are read live, so a changed setting applies to the next
/// negotiation.
class VideoDecodeCapabilities {
  VideoDecodeCapabilities._();

  static final AsyncSingleton<VideoDecodeCapabilities> _singleton = AsyncSingleton();

  /// Null until the platform answers, so [describeSync] can tell a measured
  /// "yes" from an assumed one. Both are set together or not at all.
  bool? _hardwareHevc;
  bool? _hardwareAv1;

  /// Get the singleton, probing the platform's decoders on first call.
  static Future<VideoDecodeCapabilities> getInstance() =>
      _singleton.getInstance(VideoDecodeCapabilities._, (instance) => instance._detect());

  Future<void> _detect() async {
    try {
      final result = await deviceChannel.invokeMapMethod<String, dynamic>('getVideoDecodeCapabilities');
      if (result == null) return;
      _hardwareHevc = result['hevc'] == true;
      _hardwareAv1 = result['av1'] == true;
    } on MissingPluginException {
      // Desktop, or a stale native build — keep advertising both.
    } on PlatformException {
      // Decoder enumeration failed — keep advertising both.
    }
  }

  /// Whether [codec] should be advertised to a media server. Safe before init.
  static bool accepts(RankedVideoCodec codec) {
    if (isRefusedByUser(codec)) return false;
    final instance = _singleton.instance;
    return switch (codec) {
      RankedVideoCodec.av1 => instance?._hardwareAv1 ?? true,
      RankedVideoCodec.hevc => instance?._hardwareHevc ?? true,
      RankedVideoCodec.h264 => true,
    };
  }

  /// Transcode outputs to offer, in [RankedVideoCodec] order. Never empty:
  /// H.264 cannot be refused.
  static List<RankedVideoCodec> get transcodeVideoCodecs => [
    for (final codec in RankedVideoCodec.values)
      if (accepts(codec)) codec,
  ];

  /// Whether the user refused [codec] in settings, independent of the probe.
  static bool isRefusedByUser(RankedVideoCodec codec) {
    if (!codec.isRefusable) return false;
    final settings = SettingsService.instanceOrNull;
    return settings != null && settings.read(SettingsService.refusedVideoCodecs).contains(codec.id);
  }

  /// One-line summary for the startup log and bug-report headers, e.g.
  /// `hevc=hw av1=none` on an Apple TV 4K, or `unprobed` on desktop, with
  /// ` refused=hevc` appended when the user refused a codec. Answers "did
  /// this device really report an AV1 decoder" when a transcode stutters.
  static String describeSync() {
    final instance = _singleton.instance;
    if (instance == null) return 'unknown';
    final hevc = instance._hardwareHevc;
    final av1 = instance._hardwareAv1;
    final probe = hevc == null || av1 == null ? 'unprobed' : 'hevc=${hevc ? 'hw' : 'none'} av1=${av1 ? 'hw' : 'none'}';
    final refused = [
      for (final codec in RankedVideoCodec.values)
        if (isRefusedByUser(codec)) codec.id,
    ];
    return refused.isEmpty ? probe : '$probe refused=${refused.join(',')}';
  }

  /// Test-only: drop the memoized probe, optionally seeding measured results
  /// so the sync accessors can be exercised without a platform channel.
  @visibleForTesting
  static void debugReset({bool? hardwareHevc, bool? hardwareAv1}) {
    if (hardwareHevc == null && hardwareAv1 == null) {
      _singleton.debugReset();
      return;
    }
    final instance = _singleton.instance ?? VideoDecodeCapabilities._();
    _singleton.debugReset(instance: instance);
    instance._hardwareHevc = hardwareHevc;
    instance._hardwareAv1 = hardwareAv1;
  }
}
