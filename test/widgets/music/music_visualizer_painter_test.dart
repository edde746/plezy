import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/widgets/music/music_visualizer_painter.dart';
import 'package:plezy/widgets/music/music_visualizer_preset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repaints when the animation listenable is replaced', () {
    final oldFrame = ValueNotifier(const MusicVisualizerFrame());
    final newFrame = ValueNotifier(const MusicVisualizerFrame());
    addTearDown(oldFrame.dispose);
    addTearDown(newFrame.dispose);

    const preset = MusicVisualizerPreset.bloom;
    final palette = MusicVisualizerPalette.fromTheme(
      accent: const Color(0xFF6B8DFF),
      background: const Color(0xFF10141D),
      surface: const Color(0xFF1A202A),
      outline: const Color(0xFF8892A3),
      preset: preset,
    );
    final oldPainter = MusicVisualizerPainter(frame: oldFrame, preset: preset, palette: palette, profile: null);
    final newPainter = MusicVisualizerPainter(frame: newFrame, preset: preset, palette: palette, profile: null);

    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });

  test('every preset produces a detailed 4K frame and handles a portrait canvas', () async {
    final highResolutionHashes = <int>{};
    for (final preset in MusicVisualizerPreset.values) {
      final frame = await _render(
        preset,
        const Size(1920, 1080),
        pixelRatio: 2,
        profile: _testProfile(),
        time: 2.4,
        energy: 0.72,
        transient: 0.32,
        progress: 0.41,
      );
      expect(frame.width, 3840);
      expect(frame.height, 2160);
      expect(frame.distinctColors, greaterThan(32), reason: '$preset should draw a detailed 4K scene');
      highResolutionHashes.add(frame.hash);

      final portrait = await _render(
        preset,
        const Size(360, 640),
        profile: _testProfile(),
        time: 2.4,
        energy: 0.72,
        transient: 0.32,
        progress: 0.41,
      );
      expect(portrait.distinctColors, greaterThan(16), reason: '$preset should remain visible in portrait');
    }
    expect(highResolutionHashes, hasLength(MusicVisualizerPreset.values.length));
  });

  test('loudness and motion change the rendered pixels deterministically', () async {
    final quiet = await _render(
      MusicVisualizerPreset.bloom,
      const Size(600, 360),
      profile: _testProfile(level: -58),
      time: 1.25,
      energy: 0.14,
      transient: 0,
      progress: 0.2,
    );
    final energetic = await _render(
      MusicVisualizerPreset.bloom,
      const Size(600, 360),
      profile: _testProfile(level: -12),
      time: 1.25,
      energy: 0.98,
      transient: 0.8,
      progress: 0.2,
    );
    final later = await _render(
      MusicVisualizerPreset.bloom,
      const Size(600, 360),
      profile: _testProfile(level: -12),
      time: 4.5,
      energy: 0.98,
      transient: 0.8,
      progress: 0.2,
    );

    expect(quiet.hash, isNot(energetic.hash));
    expect(energetic.hash, isNot(later.hash));
  });

  test('track map reflects the profile and playhead, including missing-profile fallback', () async {
    final firstHalf = await _render(
      MusicVisualizerPreset.trackMap,
      const Size(720, 240),
      profile: _testProfile(level: -24),
      time: 1,
      energy: 0.55,
      transient: 0,
      progress: 0.25,
    );
    final secondHalf = await _render(
      MusicVisualizerPreset.trackMap,
      const Size(720, 240),
      profile: _testProfile(level: -24),
      time: 1,
      energy: 0.55,
      transient: 0,
      progress: 0.75,
    );
    final noProfile = await _render(
      MusicVisualizerPreset.trackMap,
      const Size(720, 240),
      profile: null,
      time: 1,
      energy: 0.55,
      transient: 0,
      progress: 0.25,
    );

    expect(firstHalf.hash, isNot(secondHalf.hash));
    expect(firstHalf.hash, isNot(noProfile.hash));
  });
}

Future<_FrameDigest> _render(
  MusicVisualizerPreset preset,
  Size size, {
  int pixelRatio = 1,
  required AudioLoudnessProfile? profile,
  required double time,
  required double energy,
  required double transient,
  required double progress,
}) async {
  final frame = ValueNotifier(
    MusicVisualizerFrame(timeSeconds: time, energy: energy, transient: transient, progress: progress),
  );
  final palette = MusicVisualizerPalette.fromTheme(
    accent: const Color(0xFF6B8DFF),
    background: const Color(0xFF10141D),
    surface: const Color(0xFF1A202A),
    outline: const Color(0xFF8892A3),
    preset: preset,
  );
  final painter = MusicVisualizerPainter(frame: frame, preset: preset, palette: palette, profile: profile);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio.toDouble());
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final width = (size.width * pixelRatio).round();
  final height = (size.height * pixelRatio).round();
  final image = await picture.toImage(width, height);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var hash = 0x811C9DC5;
    final sampledColors = <int>{};
    const columns = 48;
    const rows = 28;
    for (var row = 0; row < rows; row++) {
      final y = ((row + 0.5) * height / rows).floor();
      for (var column = 0; column < columns; column++) {
        final x = ((column + 0.5) * width / columns).floor();
        final offset = (y * width + x) * 4;
        final color =
            (data.getUint8(offset) << 24) |
            (data.getUint8(offset + 1) << 16) |
            (data.getUint8(offset + 2) << 8) |
            data.getUint8(offset + 3);
        sampledColors.add(color);
        hash = ((hash * 0x01000193) ^ color) & 0xFFFFFFFF;
      }
    }
    return _FrameDigest(hash: hash, distinctColors: sampledColors.length, width: width, height: height);
  } finally {
    image.dispose();
    picture.dispose();
    frame.dispose();
  }
}

AudioLoudnessProfile _testProfile({double level = -30}) => AudioLoudnessProfile(
  levelsDb: [for (var i = 0; i < 512; i++) level + 16 * (0.5 + 0.5 * (i % 37) / 36)],
  totalSamples: 40000,
);

class _FrameDigest {
  const _FrameDigest({required this.hash, required this.distinctColors, required this.width, required this.height});

  final int hash;
  final int distinctColors;
  final int width;
  final int height;
}
