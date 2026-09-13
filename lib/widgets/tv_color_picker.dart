import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_text_field.dart';
import '../mixins/controller_disposer_mixin.dart';
import 'tv_number_spinner.dart';

/// How the three channel rows are expressed.
///
/// HSV is the better model for finding a colour, RGB the better one for
/// reproducing a known one - a subtitle palette matched to a style guide or
/// another player is given in RGB, and converting it by hand to reach the same
/// result through hue and saturation is busywork.
enum TvColorPickerMode { hsv, rgb }

/// A TV-friendly color picker using HSV or RGB spinners for D-pad navigation.
///
/// Each channel row responds to LEFT/RIGHT for value adjustment while
/// letting UP/DOWN pass through for normal focus traversal between rows.
class TvColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  /// Called when the user presses SELECT on a channel row.
  /// Use this to move focus to a confirm/save button.
  final VoidCallback? onConfirm;

  const TvColorPicker({super.key, required this.initialColor, required this.onColorChanged, this.onConfirm});

  @override
  State<TvColorPicker> createState() => _TvColorPickerState();
}

class _TvColorPickerState extends State<TvColorPicker> with ControllerDisposerMixin {
  late int _hue;
  late int _saturation;
  late int _value;
  late int _red;
  late int _green;
  late int _blue;
  TvColorPickerMode _mode = TvColorPickerMode.hsv;
  late TextEditingController _hexController;
  late FocusNode _hexFocusNode;

  @override
  void initState() {
    super.initState();
    _adoptColor(widget.initialColor);
    _hexController = createTextEditingController(text: _currentHex());
    _hexFocusNode = FocusNode(debugLabel: 'TvColorPicker_hex', onKeyEvent: _handleHexKeyEvent);
  }

  /// Both channel sets are kept in step with one colour, so switching mode
  /// mid-edit shows the colour on screen rather than whatever the other set
  /// was last left at.
  void _adoptColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue.round();
    _saturation = (hsv.saturation * 100).round();
    _value = (hsv.value * 100).round();
    _red = (color.r * 255.0).round();
    _green = (color.g * 255.0).round();
    _blue = (color.b * 255.0).round();
  }

  @override
  void dispose() {
    _hexFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleHexKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    // Intercept UP/DOWN before the TextField consumes them,
    // so D-pad focus traversal works normally.
    if (key.isUpKey || key.isDownKey) {
      if (event is KeyDownEvent) {
        if (key.isUpKey) {
          node.previousFocus();
        } else {
          node.nextFocus();
        }
        return KeyEventResult.handled;
      }
      // Consume repeat/up events too so TextField doesn't act on them.
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Color _currentColor() {
    return switch (_mode) {
      TvColorPickerMode.hsv => HSVColor.fromAHSV(
        1.0,
        _hue.toDouble().clamp(0, 360),
        _saturation / 100.0,
        _value / 100.0,
      ).toColor(),
      TvColorPickerMode.rgb => Color.fromARGB(255, _red, _green, _blue),
    };
  }

  String _currentHex() {
    final c = _currentColor();
    return '${((c.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
            '${((c.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
            '${((c.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _onChannelChanged() {
    final color = _currentColor();
    // Re-derive the other model from the colour just built, so the two sets
    // never drift apart.
    _adoptColor(color);
    _hexController.text = _currentHex();
    widget.onColorChanged(color);
  }

  void _onHexChanged(String text) {
    final cleaned = text.replaceAll('#', '').trim();
    if (cleaned.length != 6) return;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return;

    final color = Color(0xFF000000 | parsed);
    setState(() => _adoptColor(color));
    widget.onColorChanged(color);
  }

  Widget _channelRow({
    required String label,
    required String semanticLabel,
    required int value,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
    bool autofocus = false,
  }) {
    return TvNumberSpinner(
      label: label,
      semanticLabel: semanticLabel,
      value: value,
      min: 0,
      max: max,
      step: 5,
      suffix: suffix,
      autofocus: autofocus,
      onConfirm: widget.onConfirm,
      onChanged: onChanged,
      verticalKeysAdjustValue: false,
      density: TvNumberSpinnerDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _currentColor();

    return Column(
      mainAxisSize: .min,
      children: [
        Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: const Border.fromBorderSide(BorderSide(color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 12),
        _ModeToggle(
          mode: _mode,
          onChanged: (mode) {
            if (mode == _mode) return;
            setState(() => _mode = mode);
          },
        ),
        const SizedBox(height: 12),
        if (_mode == TvColorPickerMode.hsv) ...[
          _channelRow(
            label: t.accessibility.hueShort,
            semanticLabel: Translations.of(context).accessibility.hue,
            value: _hue,
            max: 360,
            suffix: '°',
            autofocus: true,
            onChanged: (v) {
              setState(() => _hue = v);
              _onChannelChanged();
            },
          ),
          const SizedBox(height: 8),
          _channelRow(
            label: t.accessibility.saturationShort,
            semanticLabel: Translations.of(context).accessibility.saturation,
            value: _saturation,
            max: 100,
            suffix: '%',
            onChanged: (v) {
              setState(() => _saturation = v);
              _onChannelChanged();
            },
          ),
          const SizedBox(height: 8),
          _channelRow(
            label: t.accessibility.valueShort,
            semanticLabel: Translations.of(context).accessibility.brightness,
            value: _value,
            max: 100,
            suffix: '%',
            onChanged: (v) {
              setState(() => _value = v);
              _onChannelChanged();
            },
          ),
        ] else ...[
          _channelRow(
            label: t.accessibility.redShort,
            semanticLabel: Translations.of(context).accessibility.red,
            value: _red,
            max: 255,
            suffix: '',
            autofocus: true,
            onChanged: (v) {
              setState(() => _red = v);
              _onChannelChanged();
            },
          ),
          const SizedBox(height: 8),
          _channelRow(
            label: t.accessibility.greenShort,
            semanticLabel: Translations.of(context).accessibility.green,
            value: _green,
            max: 255,
            suffix: '',
            onChanged: (v) {
              setState(() => _green = v);
              _onChannelChanged();
            },
          ),
          const SizedBox(height: 8),
          _channelRow(
            label: t.accessibility.blueShort,
            semanticLabel: Translations.of(context).accessibility.blue,
            value: _blue,
            max: 255,
            suffix: '',
            onChanged: (v) {
              setState(() => _blue = v);
              _onChannelChanged();
            },
          ),
        ],
        const SizedBox(height: 16),
        FocusableTextField(
          controller: _hexController,
          focusNode: _hexFocusNode,
          decoration: InputDecoration(
            prefixText: '#',
            labelText: Translations.of(context).accessibility.hexColor,
            border: const OutlineInputBorder(),
          ),
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))],
          onChanged: _onHexChanged,
        ),
      ],
    );
  }
}

/// HSV/RGB switch. A focusable pair rather than a segmented control so the
/// D-pad reaches it the same way it reaches the channel rows.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final TvColorPickerMode mode;
  final ValueChanged<TvColorPickerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        for (final option in TvColorPickerMode.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FocusableButton(
              onPressed: () => onChanged(option),
              child: Text(switch (option) {
                TvColorPickerMode.hsv => t.accessibility.colorModeHsv,
                TvColorPickerMode.rgb => t.accessibility.colorModeRgb,
              }, style: TextStyle(fontWeight: option == mode ? .bold : .normal)),
            ),
          ),
      ],
    );
  }
}
