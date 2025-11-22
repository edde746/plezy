import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../../services/settings_service.dart';
import '../../../i18n/strings.g.dart';

/// A volume control widget that displays a mute/unmute button and volume slider.
///
/// This widget integrates with [Player] to control volume and persists
/// the volume setting using [SettingsService].
class VolumeControl extends StatelessWidget {
  final Player player;

  const VolumeControl({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.stream.volume,
      initialData: player.state.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 100.0;
        final isMuted = volume == 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: isMuted
                  ? t.videoControls.unmuteButton
                  : t.videoControls.muteButton,
              button: true,
              excludeSemantics: true,
              child: IconButton(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final newVolume = isMuted ? 100.0 : 0.0;
                  player.setVolume(newVolume);
                  final settings = await SettingsService.getInstance();
                  await settings.setVolume(newVolume);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Semantics(
                  label: t.videoControls.volumeSlider,
                  slider: true,
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 100.0,
                    onChanged: (value) {
                      player.setVolume(value);
                    },
                    onChangeEnd: (value) async {
                      final settings = await SettingsService.getInstance();
                      await settings.setVolume(value);
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
