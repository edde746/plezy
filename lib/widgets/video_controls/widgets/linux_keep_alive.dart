import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// A 1x1 pixel widget that continuously repaints to keep Flutter's frame clock
/// active on Linux, where GTK's frame clock goes idle and freezes animations.
///
/// Linux-only by design. Mounting this on other platforms is harmful: on
/// Windows the 10Hz repaints become DirectComposition commits during playback,
/// and once fullscreen focus engages VRR (FreeSync/G-Sync) each commit forces a
/// scanout off the video's cadence — the micro-stutter of issue #1707. Every
/// non-Linux platform must instead uphold the invariant that the player UI
/// schedules no frames while its chrome is hidden.
class LinuxKeepAlive extends StatefulWidget {
  const LinuxKeepAlive({super.key});

  /// Forces the platform decision so tests can exercise both the ticking and
  /// the inert path regardless of host OS.
  @visibleForTesting
  static bool? debugIsLinuxOverride;

  /// Whether this widget repaints on the current platform. Exposed so the
  /// quiescence test can pin the policy to exactly [Platform.isLinux].
  @visibleForTesting
  static bool get ticksOnThisPlatform => debugIsLinuxOverride ?? Platform.isLinux;

  @override
  State<LinuxKeepAlive> createState() => _LinuxKeepAliveState();
}

class _LinuxKeepAliveState extends State<LinuxKeepAlive> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    if (!LinuxKeepAlive.ticksOnThisPlatform) return;
    // Repaint every 100ms to keep Flutter's frame scheduler active.
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _tick++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null) return const SizedBox.shrink();
    return SizedBox(width: 1, height: 1, child: ColoredBox(color: Color.fromRGBO(0, 0, 0, _tick % 2 == 0 ? 0.1 : 0.2)));
  }
}
