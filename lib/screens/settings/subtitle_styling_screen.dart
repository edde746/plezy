import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/tv_color_picker.dart';
import '../../widgets/tv_number_spinner.dart';

class SubtitleStylingScreen extends StatefulWidget {
  const SubtitleStylingScreen({super.key});

  @override
  State<SubtitleStylingScreen> createState() => _SubtitleStylingScreenState();
}

// Composable widget for slider sections
class _StylingSliderSection extends StatelessWidget {
  final String label;
  final int value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String Function(int)? valueFormatter;

  const _StylingSliderSection({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onChangeEnd,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final formattedValue = valueFormatter?.call(value) ?? value.toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(formattedValue)]),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                valueFormatter?.call(min.toInt()) ?? min.toInt().toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: formattedValue,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              Text(
                valueFormatter?.call(max.toInt()) ?? max.toInt().toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Composable widget for color picker tiles
class _ColorSettingTile extends StatelessWidget {
  final String label;
  final String currentColor;
  final VoidCallback onTap;
  final Color Function(String) hexToColor;

  const _ColorSettingTile({
    required this.label,
    required this.currentColor,
    required this.onTap,
    required this.hexToColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hexToColor(currentColor),
          border: const Border.fromBorderSide(BorderSide(color: Colors.grey)),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      ),
      title: Text(label),
      subtitle: Text(currentColor),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: onTap,
    );
  }
}

class _SubtitleStylingScreenState extends State<SubtitleStylingScreen> {
  late SettingsService _settingsService;
  bool _isLoading = true;

  int _fontSize = 55;
  String _textColor = '#FFFFFF';
  int _borderSize = 3;
  String _borderColor = '#000000';
  String _backgroundColor = '#000000';
  int _backgroundOpacity = 0;
  int _subtitlePosition = 100;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    if (!mounted) return;
    setState(() {
      _fontSize = _settingsService.getSubtitleFontSize();
      _textColor = _settingsService.getSubtitleTextColor();
      _borderSize = _settingsService.getSubtitleBorderSize();
      _borderColor = _settingsService.getSubtitleBorderColor();
      _backgroundColor = _settingsService.getSubtitleBackgroundColor();
      _backgroundOpacity = _settingsService.getSubtitleBackgroundOpacity();
      _subtitlePosition = _settingsService.getSubtitlePosition();
      _isLoading = false;
    });
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}${((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}${((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _showTvSpinnerDialog({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    int step = 1,
    String? suffix,
    required ValueChanged<int> onSave,
  }) {
    int spinnerValue = currentValue;
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvNumberSpinner(
                    value: spinnerValue,
                    min: min,
                    max: max,
                    step: step,
                    suffix: suffix,
                    autofocus: true,
                    onChanged: (value) {
                      setDialogState(() {
                        spinnerValue = value;
                      });
                    },
                    onConfirm: () => saveFocusNode.requestFocus(),
                    onCancel: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                TextButton(
                  focusNode: saveFocusNode,
                  onPressed: () {
                    onSave(spinnerValue);
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => saveFocusNode.dispose());
  }

  Future<void> _showColorPicker(String title, String currentColor, Function(String) onColorSelected) async {
    Color initialColor = _hexToColor(currentColor);

    final Color selectedColor = await showColorPickerDialog(
      context,
      initialColor,
      title: Text(title),
      barrierColor: Colors.black54,
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 4,
      wheelDiameter: 165,
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: false,
        ColorPickerType.wheel: true,
        ColorPickerType.custom: false,
      },
      actionButtons: const ColorPickerActionButtons(okButton: true, closeButton: true, dialogActionButtons: false),
    );

    final hexColor = _colorToHex(selectedColor);
    onColorSelected(hexColor);
  }

  void _showTvColorPicker(String title, String currentColor, Function(String) onColorSelected) {
    Color pickerColor = _hexToColor(currentColor);
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TvColorPicker(
                initialColor: pickerColor,
                onColorChanged: (color) => setDialogState(() => pickerColor = color),
                onConfirm: () => saveFocusNode.requestFocus(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                TextButton(
                  focusNode: saveFocusNode,
                  onPressed: () {
                    onColorSelected(_colorToHex(pickerColor));
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => saveFocusNode.dispose());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: Text(t.screens.subtitleStyling), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([_buildStylingCard(), const SizedBox(height: 24)])),
          ),
        ],
      ),
    );
  }

  Widget _buildStylingCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.subtitlingStyling.stylingOptions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Font Size Slider
          if (PlatformDetector.isTV())
            ListTile(
              title: Text(t.subtitlingStyling.fontSize),
              trailing: Text('$_fontSize'),
              onTap: () => _showTvSpinnerDialog(
                title: t.subtitlingStyling.fontSize,
                currentValue: _fontSize,
                min: 10,
                max: 80,
                onSave: (value) {
                  setState(() => _fontSize = value);
                  _settingsService.setSubtitleFontSize(value);
                },
              ),
            )
          else
            _StylingSliderSection(
              label: t.subtitlingStyling.fontSize,
              value: _fontSize,
              min: 10,
              max: 80,
              divisions: 70,
              onChanged: (value) {
                setState(() {
                  _fontSize = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _settingsService.setSubtitleFontSize(_fontSize);
              },
            ),
          const Divider(),
          // Subtitle Position Slider
          if (PlatformDetector.isTV())
            ListTile(
              title: Text(t.subtitlingStyling.position),
              trailing: Text(() {
                if (_subtitlePosition == 0) return 'Top';
                if (_subtitlePosition == 100) return 'Bottom';
                return '$_subtitlePosition%';
              }()),
              onTap: () => _showTvSpinnerDialog(
                title: t.subtitlingStyling.position,
                currentValue: _subtitlePosition,
                min: 0,
                max: 100,
                step: 5,
                onSave: (value) {
                  setState(() => _subtitlePosition = value);
                  _settingsService.setSubtitlePosition(value);
                },
              ),
            )
          else
            _StylingSliderSection(
              label: t.subtitlingStyling.position,
              value: _subtitlePosition,
              min: 0,
              max: 100,
              divisions: 20,
              valueFormatter: (value) {
                if (value == 0) return 'Top';
                if (value == 100) return 'Bottom';
                return '$value%';
              },
              onChanged: (value) {
                setState(() {
                  _subtitlePosition = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _settingsService.setSubtitlePosition(_subtitlePosition);
              },
            ),
          const Divider(),
          // Text Color
          _ColorSettingTile(
            label: t.subtitlingStyling.textColor,
            currentColor: _textColor,
            hexToColor: _hexToColor,
            onTap: () {
              void onColorSelected(String color) {
                setState(() => _textColor = color);
                _settingsService.setSubtitleTextColor(color);
              }

              if (PlatformDetector.isTV()) {
                _showTvColorPicker(t.subtitlingStyling.textColor, _textColor, onColorSelected);
              } else {
                _showColorPicker(t.subtitlingStyling.textColor, _textColor, onColorSelected);
              }
            },
          ),
          const Divider(),
          // Border Size Slider
          if (PlatformDetector.isTV())
            ListTile(
              title: Text(t.subtitlingStyling.borderSize),
              trailing: Text('$_borderSize'),
              onTap: () => _showTvSpinnerDialog(
                title: t.subtitlingStyling.borderSize,
                currentValue: _borderSize,
                min: 0,
                max: 5,
                onSave: (value) {
                  setState(() => _borderSize = value);
                  _settingsService.setSubtitleBorderSize(value);
                },
              ),
            )
          else
            _StylingSliderSection(
              label: t.subtitlingStyling.borderSize,
              value: _borderSize,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (value) {
                setState(() {
                  _borderSize = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _settingsService.setSubtitleBorderSize(_borderSize);
              },
            ),
          const Divider(),
          // Border Color
          _ColorSettingTile(
            label: t.subtitlingStyling.borderColor,
            currentColor: _borderColor,
            hexToColor: _hexToColor,
            onTap: () {
              void onColorSelected(String color) {
                setState(() => _borderColor = color);
                _settingsService.setSubtitleBorderColor(color);
              }

              if (PlatformDetector.isTV()) {
                _showTvColorPicker(t.subtitlingStyling.borderColor, _borderColor, onColorSelected);
              } else {
                _showColorPicker(t.subtitlingStyling.borderColor, _borderColor, onColorSelected);
              }
            },
          ),
          const Divider(),
          // Background Opacity Slider
          if (PlatformDetector.isTV())
            ListTile(
              title: Text(t.subtitlingStyling.backgroundOpacity),
              trailing: Text('$_backgroundOpacity%'),
              onTap: () => _showTvSpinnerDialog(
                title: t.subtitlingStyling.backgroundOpacity,
                currentValue: _backgroundOpacity,
                min: 0,
                max: 100,
                step: 5,
                suffix: '%',
                onSave: (value) {
                  setState(() => _backgroundOpacity = value);
                  _settingsService.setSubtitleBackgroundOpacity(value);
                },
              ),
            )
          else
            _StylingSliderSection(
              label: t.subtitlingStyling.backgroundOpacity,
              value: _backgroundOpacity,
              min: 0,
              max: 100,
              divisions: 20,
              valueFormatter: (value) => '$value%',
              onChanged: (value) {
                setState(() {
                  _backgroundOpacity = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _settingsService.setSubtitleBackgroundOpacity(_backgroundOpacity);
              },
            ),
          const Divider(),
          // Background Color
          _ColorSettingTile(
            label: t.subtitlingStyling.backgroundColor,
            currentColor: _backgroundColor,
            hexToColor: _hexToColor,
            onTap: () {
              void onColorSelected(String color) {
                setState(() => _backgroundColor = color);
                _settingsService.setSubtitleBackgroundColor(color);
              }

              if (PlatformDetector.isTV()) {
                _showTvColorPicker(t.subtitlingStyling.backgroundColor, _backgroundColor, onColorSelected);
              } else {
                _showColorPicker(t.subtitlingStyling.backgroundColor, _backgroundColor, onColorSelected);
              }
            },
          ),
        ],
      ),
    );
  }
}
