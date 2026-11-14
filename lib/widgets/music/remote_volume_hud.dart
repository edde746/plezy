import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/music/remote_volume_buttons.dart';

/// Shows the speaker's level for a moment after each hardware volume press.
///
/// While a speaker is selected the buttons drive that speaker, and iOS's own
/// pop-up is suppressed because it could only show the phone's pinned level
/// (see [RemoteVolumeButtons]). Without this a press changes the room with no
/// sign on the phone that anything happened.
class RemoteVolumeHud extends StatefulWidget {
  const RemoteVolumeHud({super.key});

  /// How long the indicator stays after the last press.
  static const Duration visibleFor = Duration(milliseconds: 1500);

  @override
  State<RemoteVolumeHud> createState() => _RemoteVolumeHudState();
}

class _RemoteVolumeHudState extends State<RemoteVolumeHud> {
  RemoteVolumeButtons? _buttons;
  RemoteVolumePress? _press;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final buttons = context.read<RemoteVolumeButtons?>();
    if (identical(buttons, _buttons)) return;
    _buttons?.lastPress.removeListener(_onPress);
    _buttons = buttons;
    buttons?.lastPress.addListener(_onPress);
  }

  void _onPress() {
    final press = _buttons?.lastPress.value;
    if (press == null || !mounted) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(RemoteVolumeHud.visibleFor, () {
      if (mounted) setState(() => _visible = false);
    });
    setState(() {
      _press = press;
      _visible = true;
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _buttons?.lastPress.removeListener(_onPress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final press = _press;
    if (press == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final level = press.level.round();
    final icon = level == 0
        ? Icons.volume_off_rounded
        : level < 50
        ? Icons.volume_down_rounded
        : Icons.volume_up_rounded;

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                label: '${press.outputName} $level%',
                child: ExcludeSemantics(
                  child: Material(
                    elevation: 6,
                    color: theme.colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
                      child: SizedBox(
                        width: 220,
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: theme.colorScheme.onInverseSurface),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    press.outputName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onInverseSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: press.level / 100,
                                      minHeight: 4,
                                      color: theme.colorScheme.onInverseSurface,
                                      backgroundColor: theme.colorScheme.onInverseSurface.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$level',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onInverseSurface,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
