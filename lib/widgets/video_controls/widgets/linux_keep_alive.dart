import 'dart:async' show Timer;

import 'package:flutter/material.dart';

/// A 1x1 pixel widget that continuously repaints to keep Flutter's frame clock active on Linux.
/// This prevents animations from freezing when GTK's frame clock goes idle.
class LinuxKeepAlive extends StatefulWidget {
  const LinuxKeepAlive({super.key});

  @override
  State<LinuxKeepAlive> createState() => _LinuxKeepAliveState();
}

class _LinuxKeepAliveState extends State<LinuxKeepAlive> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
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
    return SizedBox(width: 1, height: 1, child: ColoredBox(color: Color.fromRGBO(0, 0, 0, _tick % 2 == 0 ? 0.1 : 0.2)));
  }
}
