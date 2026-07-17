import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/app_icon.dart';

/// VLC-style dark pill shown at top-center of the video player.
/// Used for rate changes and other transient in-player notifications.
class PlayerToastIndicator extends StatelessWidget {
  const PlayerToastIndicator({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            mainAxisSize: .min,
            children: [
              AppIcon(icon, fill: 1, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns the currently-displayed toast + auto-hide timer.
/// Created per video-player session; disposed with the screen.
class PlayerToastController extends ChangeNotifier {
  ({IconData icon, String text, Object key})? _current;
  Timer? _timer;
  int _frameSteps = 0;

  ({IconData icon, String text, Object key})? get current => _current;

  void show(IconData icon, String text, {Duration duration = const Duration(milliseconds: 1200)}) {
    _frameSteps = 0;
    _show(icon, text, duration, key: '${icon.codePoint}:$text');
  }

  void showFrameStep(int step) {
    _frameSteps = _frameSteps.sign == step.sign ? _frameSteps + step : step;
    _show(
      step > 0 ? Symbols.fast_forward_rounded : Symbols.fast_rewind_rounded,
      t.videoControls.frameCount(n: _frameSteps.abs()),
      const Duration(milliseconds: 1200),
      key: 'frame:${step.sign}',
    );
  }

  void _show(IconData icon, String text, Duration duration, {required Object key}) {
    _timer?.cancel();
    _current = (icon: icon, text: text, key: key);
    notifyListeners();
    _timer = Timer(duration, () {
      _current = null;
      _timer = null;
      _frameSteps = 0;
      notifyListeners();
    });
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _frameSteps = 0;
    if (_current != null) {
      _current = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
