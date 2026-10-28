/// Local receiver counters. Targets come from Steam's control messages, never
/// from the selected quality preset. No network/account identifiers are stored.
class SteamStreamMetrics {
  SteamStreamMetrics._(this._values);
  final Map<String, int> _values;

  factory SteamStreamMetrics.fromNative(Map<Object?, Object?> input) {
    const fields = [
      'epoch',
      'sampledAtUs',
      'receivedFrames',
      'presentedFrames',
      'droppedFrames',
      'resetFrames',
      'videoBytes',
      'completionTotalUs',
      'completedFrames',
      'width',
      'height',
      'codec',
      'audioChannels',
      'fpsNumerator',
      'fpsDenominator',
      'fpsReasons',
      'targetBitrate',
      'reliableRetries',
      'reliableGiveUps',
      'reliableOutstanding',
      'maxAckLatencyMs',
      'hidPending',
      'hidInFlight',
    ];
    if (input['version'] != 1) throw const FormatException('Unsupported stream measurements');
    final values = <String, int>{};
    for (final key in fields) {
      final value = input[key];
      if (value is! int || value < 0) throw const FormatException('Invalid stream measurement');
      values[key] = value;
    }
    if (values['epoch'] == 0 ||
        values['width']! > 4096 ||
        values['height']! > 2160 ||
        ![0, 4, 5, 9].contains(values['codec']) ||
        values['audioChannels']! > 8 ||
        values['fpsReasons']! > 0x5f ||
        values['targetBitrate']! > 1000000000) {
      throw const FormatException('Stream measurement out of range');
    }
    for (final entry in {'decoderKind': 3, 'videoQueue': 4, 'audioQueue': 8}.entries) {
      final value = input[entry.key] ?? 0;
      if (value is! int || value < 0 || value > entry.value) throw const FormatException('Invalid decoder measurement');
      values[entry.key] = value;
    }
    return SteamStreamMetrics._(Map.unmodifiable(values));
  }

  int get epoch => _values['epoch']!;
  int get sampledAtUs => _values['sampledAtUs']!;
  int get receivedFrames => _values['receivedFrames']!;
  int get presentedFrames => _values['presentedFrames']!;
  int get droppedFrames => _values['droppedFrames']!;
  int get resetFrames => _values['resetFrames']!;
  int get videoBytes => _values['videoBytes']!;
  int get completionTotalUs => _values['completionTotalUs']!;
  int get completedFrames => _values['completedFrames']!;
  int get width => _values['width']!;
  int get height => _values['height']!;
  String? get codec => switch (_values['codec']) {
    4 => 'H.264',
    5 => 'HEVC',
    9 => 'Pyrowave',
    _ => null,
  };
  int get audioChannels => _values['audioChannels']!;
  double? get hostFps {
    final denominator = _values['fpsDenominator']!;
    if (denominator == 0) return null;
    final fps = _values['fpsNumerator']! / denominator;
    return fps > 0 && fps <= 240 ? fps : null;
  }

  int get hostFpsReasons => _values['fpsReasons']!;
  double? get hostMbps => _values['targetBitrate'] == 0 ? null : _values['targetBitrate']! / 1000000;
  int get reliableRetries => _values['reliableRetries']!;
  int get reliableGiveUps => _values['reliableGiveUps']!;
  int get reliableOutstanding => _values['reliableOutstanding']!;
  int get maxAckLatencyMs => _values['maxAckLatencyMs']!;
  int get hidPending => _values['hidPending']!;
  int get hidInFlight => _values['hidInFlight']!;
  int get decoderKind => _values['decoderKind']!;
  int get videoQueue => _values['videoQueue']!;
  int get audioQueue => _values['audioQueue']!;
}

class SteamStreamRates {
  const SteamStreamRates._(this.presentedFps, this.videoMbps, this.completionMs);
  final double presentedFps, videoMbps;

  /// Receiver queue + decoder + surface-submission time, not network RTT or
  /// display scanout. Includes completed dropped frames as well as presented.
  final double? completionMs;

  static SteamStreamRates? between(SteamStreamMetrics before, SteamStreamMetrics after) {
    final elapsed = after.sampledAtUs - before.sampledAtUs;
    if (before.epoch != after.epoch || elapsed < 200000 || elapsed > 10000000) return null;
    final deltas = [
      after.presentedFrames - before.presentedFrames,
      after.videoBytes - before.videoBytes,
      after.completionTotalUs - before.completionTotalUs,
      after.completedFrames - before.completedFrames,
      after.receivedFrames - before.receivedFrames,
      after.droppedFrames - before.droppedFrames,
    ];
    if (deltas.any((delta) => delta < 0)) return null;
    return SteamStreamRates._(
      deltas[0] * 1000000 / elapsed,
      deltas[1] * 8 / elapsed,
      deltas[3] == 0 ? null : deltas[2] / deltas[3] / 1000,
    );
  }
}
