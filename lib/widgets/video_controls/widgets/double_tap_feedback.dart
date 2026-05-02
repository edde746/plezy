import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../app_icon.dart';

class DoubleTapFeedback extends StatelessWidget {
  final bool isForward;
  final int seconds;

  const DoubleTapFeedback({super.key, required this.isForward, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              isForward ? Symbols.forward_media_rounded : Symbols.replay_rounded,
              fill: 1,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '$seconds${t.settings.secondsShort}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
