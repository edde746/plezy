import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/async_singleton.dart';
import '../utils/device_channel.dart';

/// Whether this device has a hardware decoder for HEVC and AV1.
///
/// mpv software-decodes both everywhere, so this is not "can we decode it" but
/// "can we decode it without dropping frames". Without a hardware decoder a
/// phone or TV box has to ask the server to transcode instead of taking the
/// original stream, and must not offer AV1 as a transcode target.
///
/// Only Android (`MediaCodecList`) and iOS/tvOS (`VTIsHardwareDecodeSupported`)
/// answer the probe. Desktop deliberately does not implement it: a
/// pre-Kaby-Lake Mac has no hardware HEVC decoder and an M1 no hardware AV1
/// one, yet both software-decode in real time, so narrowing there would force
/// transcodes for nothing. An unanswered or failed probe reports support — the
/// advertised codec list must never narrow on missing data.
///
/// Latched once during the startup device-capabilities phase and read
/// synchronously after, so every negotiation in a session advertises the same
/// codecs.
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

  /// Whether HEVC should be advertised to a media server. Safe before init.
  static bool get supportsHevc => _singleton.instance?._hardwareHevc ?? true;

  /// Whether AV1 should be advertised to a media server. Safe before init.
  static bool get supportsAv1 => _singleton.instance?._hardwareAv1 ?? true;

  /// One-line summary for the startup log and bug-report headers, e.g.
  /// `hevc=hw av1=none` on an Apple TV 4K, or `unprobed` on desktop. Answers
  /// "did this device really report an AV1 decoder" when a transcode stutters.
  static String describeSync() {
    final instance = _singleton.instance;
    if (instance == null) return 'unknown';
    final hevc = instance._hardwareHevc;
    final av1 = instance._hardwareAv1;
    if (hevc == null || av1 == null) return 'unprobed';
    return 'hevc=${hevc ? 'hw' : 'none'} av1=${av1 ? 'hw' : 'none'}';
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
