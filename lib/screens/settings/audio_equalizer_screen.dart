import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focusable_wrapper.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../models/audio_equalizer.dart';
import '../../mpv/mpv.dart';
import '../../services/settings_service.dart';
import '../../services/equalizer_preferences.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

String equalizerProfileLabel(EqualizerAudioType profile) => switch (profile) {
  EqualizerAudioType.global => t.settings.equalizerGlobal,
  EqualizerAudioType.stereo => t.videoSettings.audioOutputStereo,
  EqualizerAudioType.surround => t.videoSettings.audioOutputSurround,
  EqualizerAudioType.ac3 => t.settings.equalizerDolbyDigital,
  EqualizerAudioType.eac3 => t.settings.equalizerDolbyDigitalPlus,
  EqualizerAudioType.truehd => t.settings.equalizerDolbyTrueHd,
  EqualizerAudioType.dts => 'DTS / DTS-HD',
};

class AudioEqualizerScreen extends StatelessWidget {
  const AudioEqualizerScreen({super.key, this.initialProfile = EqualizerAudioType.global});
  final EqualizerAudioType initialProfile;

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: Text(t.settings.equalizer),
    children: [AudioEqualizerEditor(initialProfile: initialProfile)],
  );
}

/// Shared by the normal settings page and the in-player settings subpage.
/// A missing format profile inherits Global until the user customizes it.
class AudioEqualizerEditor extends StatefulWidget {
  const AudioEqualizerEditor({super.key, this.initialProfile = EqualizerAudioType.global, this.player});
  final EqualizerAudioType initialProfile;
  final Player? player;

  @override
  State<AudioEqualizerEditor> createState() => _AudioEqualizerEditorState();
}

class _AudioEqualizerEditorState extends State<AudioEqualizerEditor> {
  late EqualizerAudioType _profile;
  late EqualizerPreferences _preferences;
  Stream<PlayerLog>? _equalizerLogs;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _preferences = EqualizerPreferences.forSettings(SettingsService.instance);
    _equalizerLogs = widget.player?.streams.log.where((entry) => entry.prefix == 'equalizer');
  }

  void _update(EqualizerSettings Function(EqualizerSettings) change) {
    unawaited(
      _preferences.update(change).catchError((Object error, StackTrace stack) {
        if (mounted) showSettingsFailure(context, operation: 'Save equalizer', error: error, stackTrace: stack);
      }),
    );
  }

  void _editProfile(EqualizerProfile Function(EqualizerProfile) edit) {
    final type = _profile;
    _update((settings) => settings.withProfile(type, edit(settings.resolve(type)).copyWith(useGlobal: false)));
  }

  Future<void> _selectProfile() async {
    final selection = await showSelectionDialog<EqualizerAudioType>(
      context: context,
      title: t.settings.equalizerScope,
      currentValue: _profile,
      options: [
        for (final profile in EqualizerAudioType.values)
          DialogOption(value: profile, title: equalizerProfileLabel(profile)),
      ],
    );
    if (mounted && selection != null) setState(() => _profile = selection.value);
  }

  String _presetLabel(EqualizerPreset? preset) => switch (preset) {
    EqualizerPreset.flat => t.settings.equalizerFlat,
    EqualizerPreset.bass => t.settings.equalizerBassBoost,
    EqualizerPreset.movie => t.settings.equalizerMovie,
    EqualizerPreset.speech => t.settings.equalizerSpeech,
    _ => t.settings.equalizerCustom,
  };

  Future<void> _selectPreset(List<double> gains) async {
    final selection = await showSelectionDialog<EqualizerPreset?>(
      context: context,
      title: t.settings.equalizerPreset,
      currentValue: AudioEqualizer.preset(gains),
      options: [
        DialogOption(value: null, title: t.settings.equalizerCustom),
        for (final preset in EqualizerPreset.values) DialogOption(value: preset, title: _presetLabel(preset)),
      ],
    );
    if (!mounted || selection == null || selection.value == null) return;
    _editProfile((profile) => profile.copyWith(gains: AudioEqualizer.presetGains[selection.value]!));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _preferences,
    builder: (context, _) {
      final settings = _preferences.value;
      final profile = settings.resolve(_profile);
      final gains = profile.gains;
      final inherited = settings.inherits(_profile);
      final headerRows = <Widget>[
        if (widget.player != null)
          StreamBuilder<PlayerLog>(
            stream: _equalizerLogs,
            builder: (context, _) => widget.player!.state.equalizerFailed
                ? Padding(padding: const EdgeInsets.all(12), child: Text(t.settings.equalizerFailed))
                : const SizedBox.shrink(),
          ),
        SettingSwitchTile(
          pref: SettingsService.audioEqualizerEnabled,
          icon: Symbols.graphic_eq_rounded,
          title: t.settings.equalizer,
        ),
        Row(
          children: [
            Expanded(child: _row(t.settings.equalizerScope, equalizerProfileLabel(_profile), _selectProfile)),
            Expanded(
              child: _row(
                t.settings.equalizerPreset,
                _presetLabel(AudioEqualizer.preset(gains)),
                () => _selectPreset(gains),
              ),
            ),
          ],
        ),
        if (_profile != EqualizerAudioType.global)
          FocusableSwitchListTile(
            title: Text(t.settings.equalizerInherit),
            value: inherited,
            onChanged: (inherit) {
              final type = _profile;
              _update((settings) => settings.setInheritance(type, inherit));
            },
          ),
      ];
      final inPlayer = widget.player != null;
      final header = inPlayer
          ? Column(mainAxisSize: MainAxisSize.min, children: headerRows)
          : SettingsGroup(margin: EdgeInsets.zero, children: headerRows);
      final details = <Widget>[
        if (widget.player?.audioPassthroughActive ?? false)
          Padding(padding: const EdgeInsets.all(8), child: Text(t.settings.equalizerPassthrough)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, 520.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: widget.player == null ? 190 : 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      bottom: 28,
                      top: 26,
                      child: CustomPaint(
                        painter: _EqualizerGraph(gains, Theme.of(context).colorScheme.primary, tokens(context).outline),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 10; i++)
                          Expanded(
                            child: EqualizerGainControl(
                              key: ValueKey('eq-band-$i'),
                              label: i < 5
                                  ? '${AudioEqualizer.frequencies[i].round()} Hz'
                                  : '${(AudioEqualizer.frequencies[i] / 1000).round()} kHz',
                              value: gains[i],
                              onChanged: (value) =>
                                  _editProfile((current) => current.copyWith(gains: [...current.gains]..[i] = value)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            for (final isPreamp in [true, false])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: EqualizerGainControl(
                    key: ValueKey(isPreamp ? 'eq-amp' : 'eq-bass'),
                    label: isPreamp ? t.settings.equalizerAmplifier : t.settings.equalizerBass,
                    value: isPreamp ? profile.preampDb : profile.bassDb,
                    vertical: false,
                    onChanged: (gain) => _editProfile(
                      (current) => isPreamp ? current.copyWith(preampDb: gain) : current.copyWith(bassDb: gain),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            t.settings.equalizerHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
          ),
        ),
      ];
      return Padding(
        padding: inPlayer ? EdgeInsets.zero : const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (widget.player != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: details),
                ),
              )
            else
              ...details,
          ],
        ),
      );
    },
  );

  Widget _row(String title, String value, VoidCallback onTap) => FocusableListTile(
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const AppIcon(Symbols.chevron_right_rounded),
    onTap: onTap,
  );
}

/// Navigation and editing are separate: Select starts editing; Up/Down adjusts.
/// Left/Right always moves between bands. Pointer dragging remains available.
class EqualizerGainControl extends StatefulWidget {
  const EqualizerGainControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.vertical = true,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool vertical;
  @override
  State<EqualizerGainControl> createState() => _EqualizerGainControlState();
}

class _EqualizerGainControlState extends State<EqualizerGainControl> {
  bool _editing = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final slider = ExcludeFocus(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          tickMarkShape: SliderTickMarkShape.noTickMark,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
          showValueIndicator: ShowValueIndicator.never,
        ),
        child: Slider(value: widget.value, min: -12, max: 12, divisions: 48, onChanged: widget.onChanged),
      ),
    );
    return FocusableWrapper(
      semanticLabel: widget.label,
      semanticValue: '${widget.value.toStringAsFixed(1)} dB',
      disableScale: true,
      descendantsAreFocusable: false,
      borderRadius: 8,
      onFocusChange: (focused) => setState(() {
        _focused = focused;
        if (!focused) _editing = false;
      }),
      onSelect: () => setState(() => _editing = !_editing),
      onKeyEvent: (_, event) {
        if (!_editing) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key.isBackKey) return handleBackKeyAction(event, () => setState(() => _editing = false));
        if (key.isUpKey || key.isDownKey) {
          if (event.isActionable) widget.onChanged((widget.value + (key.isUpKey ? 0.5 : -0.5)).clamp(-12.0, 12.0));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          color: _editing ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: widget.vertical
            ? Column(
                children: [
                  Text(widget.value.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: _focused ? color : null)),
                  Expanded(child: RotatedBox(quarterTurns: 3, child: slider)),
                  Text(widget.label, style: const TextStyle(fontSize: 10)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.label}  ${widget.value.toStringAsFixed(1)} dB',
                    style: settingsOptionTitleStyle(context),
                  ),
                  SizedBox(height: 28, child: slider),
                ],
              ),
      ),
    );
  }
}

class _EqualizerGraph extends CustomPainter {
  _EqualizerGraph(this.gains, this.color, this.grid);
  final List<double> gains;
  final Color color;
  final Color grid;
  @override
  void paint(Canvas canvas, Size size) {
    for (final fraction in [0.0, 0.5, 1.0]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        Paint()
          ..color = grid
          ..strokeWidth = 0.5,
      );
    }
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final x = size.width * (i + 0.5) / 10;
      final y = size.height * (12 - gains[i]) / 24;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_EqualizerGraph oldDelegate) =>
      !listEquals(gains, oldDelegate.gains) || color != oldDelegate.color || grid != oldDelegate.grid;
}
