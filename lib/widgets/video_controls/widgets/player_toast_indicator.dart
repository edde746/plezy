import 'dart:async';

import 'package:flutter/material.dart';
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
      alignment: Alignment.topCenter,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, fill: 1, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
  ({IconData icon, String text})? _current;
  Timer? _timer;

  ({IconData icon, String text})? get current => _current;

  void show(IconData icon, String text, {Duration duration = const Duration(milliseconds: 1200)}) {
    _timer?.cancel();
    _current = (icon: icon, text: text);
    notifyListeners();
    _timer = Timer(duration, () {
      _current = null;
      _timer = null;
      notifyListeners();
    });
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
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
