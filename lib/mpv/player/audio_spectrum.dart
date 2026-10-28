import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Compact audio-analysis metadata produced by MPV's FFmpeg audio filter.
///
/// The player bridge carries these two scalar measurements, never decoded PCM
/// samples or frequency-bin arrays.
@immutable
class AudioSpectrumSample {
  const AudioSpectrumSample({required this.centroidHz, required this.flatness});

  final double centroidHz;
  final double flatness;

  double get normalizedCentroid => (centroidHz.clamp(0.0, 24000.0) / 24000).toDouble();

  static final RegExp _measurement = RegExp(r'(?:^|\.)lavfi\.aspectralstats\.(\d+)\.(centroid|flatness)$');

  /// Decodes both MPV node maps and Android's JSON-encoded node format.
  static AudioSpectrumSample? tryParse(Object? value) {
    Object? node = value;
    if (node is String) {
      try {
        node = jsonDecode(node);
      } on FormatException {
        return null;
      }
    }
    if (node is! Map) return null;

    final centroids = <int, double>{};
    final flatnesses = <int, double>{};
    void visit(Object? current, String prefix) {
      if (current is Map) {
        for (final entry in current.entries) {
          final key = entry.key.toString();
          visit(entry.value, prefix.isEmpty ? key : '$prefix.$key');
        }
        return;
      }
      final match = _measurement.firstMatch(prefix);
      if (match == null) return;
      final channel = int.tryParse(match.group(1)!);
      final measurement = double.tryParse(current?.toString() ?? '');
      if (channel == null || measurement == null || !measurement.isFinite || measurement < 0) return;
      switch (match.group(2)) {
        case 'centroid':
          centroids[channel] = measurement;
        case 'flatness':
          flatnesses[channel] = measurement;
      }
    }

    visit(node, '');
    final channels = centroids.keys.toSet().intersection(flatnesses.keys.toSet());
    if (channels.isEmpty) return null;
    final centroid = channels.map((channel) => centroids[channel]!).reduce((a, b) => a + b) / channels.length;
    final flatness = channels.map((channel) => flatnesses[channel]!).reduce((a, b) => a + b) / channels.length;
    return AudioSpectrumSample(centroidHz: centroid, flatness: flatness.clamp(0.0, 1.0).toDouble());
  }
}

/// Optional MPV capability for visualizers that can consume derived FFT stats.
abstract interface class AudioSpectrumAnalyzer {
  Stream<AudioSpectrumSample?> get audioSpectrumStream;

  bool get audioPassthroughActive;

  /// Requests analysis for the current session. Returns whether the filter is
  /// currently active; callers may keep listening when passthrough suspends it.
  Future<bool> setAudioSpectrumAnalysisEnabled(bool enabled);
}
