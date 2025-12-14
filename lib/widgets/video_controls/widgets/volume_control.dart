import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../mpv/mpv.dart';
import '../../../services/settings_service.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../focus/input_mode_tracker.dart';

/// A volume control widget that displays a mute/unmute button and volume slider.
///
/// This widget integrates with [Player] to control volume and persists
/// the volume setting using [SettingsService].
///
/// When using keyboard/D-pad navigation, pressing Select enters "adjust mode"
/// where left/right arrows adjust volume instead of navigating.
class VolumeControl extends StatefulWidget {
  final Player player;

  /// Optional FocusNode for D-pad/keyboard navigation.
  final FocusNode? focusNode;

  /// Custom key event handler for focus navigation (used when NOT in adjust mode).
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called on any keyboard activity (to reset hide timer).
  final VoidCallback? onFocusActivity;

  const VolumeControl({
    super.key,
    required this.player,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.onFocusActivity,
  });

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  /// Whether we're in volume adjust mode (left/right adjusts volume).
  bool _isAdjustMode = false;

  /// Volume step size for keyboard adjustment.
  static const double _volumeStep = 5.0;

  void _enterAdjustMode() {
    setState(() {
      _isAdjustMode = true;
    });
  }

  void _exitAdjustMode() {
    setState(() {
      _isAdjustMode = false;
    });
  }

  Future<void> _adjustVolume(double delta) async {
    final currentVolume = widget.player.state.volume;
    final newVolume = (currentVolume + delta).clamp(0.0, 100.0);
    widget.player.setVolume(newVolume);
    final settings = await SettingsService.getInstance();
    await settings.setVolume(newVolume);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (_isAdjustMode) {
      // Notify activity on any key in adjust mode (to reset hide timer)
      widget.onFocusActivity?.call();

      // In adjust mode: left/right adjusts volume, back/escape exits
      if (key == LogicalKeyboardKey.arrowLeft) {
        _adjustVolume(-_volumeStep);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        _adjustVolume(_volumeStep);
        return KeyEventResult.handled;
      }
      if (key.isBackKey || key.isSelectKey) {
        _exitAdjustMode();
        return KeyEventResult.handled;
      }
      // UP/DOWN exits adjust mode and lets navigation continue
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        _exitAdjustMode();
        // Pass through to normal navigation handler
        return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
      }
      // Consume other keys in adjust mode
      return KeyEventResult.handled;
    }

    // Not in adjust mode: use the provided key event handler for navigation
    return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
  }

  void _handleFocusChange(bool hasFocus) {
    // Exit adjust mode when focus is lost
    if (!hasFocus && _isAdjustMode) {
      _exitAdjustMode();
    }
    widget.onFocusChange?.call(hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.player.streams.volume,
      initialData: widget.player.state.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 100.0;
        final isMuted = volume == 0;
        final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

        final muteButton = Semantics(
          label: isMuted
              ? t.videoControls.unmuteButton
              : t.videoControls.muteButton,
          button: true,
          excludeSemantics: true,
          child: IconButton(
            icon: AppIcon(
              isMuted ? Symbols.volume_off_rounded : Symbols.volume_up_rounded,
              fill: 1,
              color: Colors.white,
            ),
            onPressed: () async {
              final newVolume = isMuted ? 100.0 : 0.0;
              widget.player.setVolume(newVolume);
              final settings = await SettingsService.getInstance();
              await settings.setVolume(newVolume);
            },
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.focusNode != null)
              FocusableWrapper(
                focusNode: widget.focusNode,
                onSelect: _enterAdjustMode,
                onKeyEvent: _handleKeyEvent,
                onFocusChange: _handleFocusChange,
                borderRadius: 20,
                autoScroll: false,
                useBackgroundFocus: true,
                disableScale: true,
                semanticLabel: _isAdjustMode
                    ? t.videoControls.volumeSlider
                    : (isMuted
                          ? t.videoControls.unmuteButton
                          : t.videoControls.muteButton),
                child: muteButton,
              )
            else
              muteButton,
            const SizedBox(width: 8),
            _buildVolumeSlider(volume, isKeyboardMode),
          ],
        );
      },
    );
  }

  Widget _buildVolumeSlider(double volume, bool isKeyboardMode) {
    // Show visual indicator when in adjust mode with keyboard
    final showAdjustIndicator = _isAdjustMode && isKeyboardMode;

    return SizedBox(
      width: 100,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: showAdjustIndicator ? 4 : 3,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: showAdjustIndicator ? 8 : 6,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Semantics(
          label: t.videoControls.volumeSlider,
          slider: true,
          child: Slider(
            value: volume,
            min: 0.0,
            max: 100.0,
            onChanged: (value) {
              widget.player.setVolume(value);
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
    );
  }
}
