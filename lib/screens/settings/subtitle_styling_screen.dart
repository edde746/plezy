import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../focus/focusable_button.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/tv_color_picker.dart';
import 'settings_utils.dart';

class SubtitleStylingScreen extends StatefulWidget {
  const SubtitleStylingScreen({super.key});

  @override
  State<SubtitleStylingScreen> createState() => _SubtitleStylingScreenState();
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
  SubAssOverride _assOverride = SubAssOverride.no;
  bool _bold = false;
  bool _italic = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    if (!mounted) return;
    setState(() {
      _fontSize = _settingsService.read(SettingsService.subtitleFontSize);
      _textColor = _settingsService.read(SettingsService.subtitleTextColor);
      _borderSize = _settingsService.read(SettingsService.subtitleBorderSize);
      _borderColor = _settingsService.read(SettingsService.subtitleBorderColor);
      _backgroundColor = _settingsService.read(SettingsService.subtitleBackgroundColor);
      _backgroundOpacity = _settingsService.read(SettingsService.subtitleBackgroundOpacity);
      _subtitlePosition = _settingsService.read(SettingsService.subtitlePosition);
      _assOverride = _settingsService.read(SettingsService.subAssOverride);
      _bold = _settingsService.read(SettingsService.subtitleBold);
      _italic = _settingsService.read(SettingsService.subtitleItalic);
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

  Future<void> _showColorPicker(String title, String currentColor, Function(String) onColorSelected) async {
    final Color initialColor = _hexToColor(currentColor);

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
                FocusableButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                ),
                FocusableButton(
                  focusNode: saveFocusNode,
                  onPressed: () {
                    onColorSelected(_colorToHex(pickerColor));
                    Navigator.pop(dialogContext);
                  },
                  child: TextButton(
                    onPressed: () {
                      onColorSelected(_colorToHex(pickerColor));
                      Navigator.pop(dialogContext);
                    },
                    child: Text(t.common.save),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => saveFocusNode.dispose());
  }

  void _openColorPicker(String title, String currentColor, Function(String) onColorSelected) {
    if (InputModeTracker.isKeyboardMode(context)) {
      _showTvColorPicker(title, currentColor, onColorSelected);
    } else {
      _showColorPicker(title, currentColor, onColorSelected);
    }
  }

  String _assOverrideLabel(SubAssOverride value) {
    return switch (value) {
      SubAssOverride.no => 'No',
      SubAssOverride.yes => 'Yes',
      SubAssOverride.scale => 'Scale',
      SubAssOverride.force => 'Force',
      SubAssOverride.strip => 'Strip',
    };
  }

  String _formatPosition(int value) {
    if (value == 0) return 'Top';
    if (value == 100) return 'Bottom';
    return '$value%';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FocusedScrollScaffold(
        title: Text(t.screens.subtitleStyling),
        slivers: [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    return FocusedScrollScaffold(
      title: Text(t.screens.subtitleStyling),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingsSectionHeader(t.subtitlingStyling.text),
            ListTile(
              leading: const AppIcon(Symbols.subtitles_rounded, fill: 1),
              title: Text(t.subtitlingStyling.assOverride),
              subtitle: Text(_assOverrideLabel(_assOverride)),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () async {
                final value = await showSelectionDialog<SubAssOverride>(
                  context: context,
                  title: t.subtitlingStyling.assOverride,
                  options: SubAssOverride.values
                      .map((v) => DialogOption(value: v, title: _assOverrideLabel(v)))
                      .toList(),
                  currentValue: _assOverride,
                );
                if (value != null) {
                  setState(() => _assOverride = value);
                  await _settingsService.write(SettingsService.subAssOverride, value);
                }
              },
            ),
            ListTile(
              leading: const AppIcon(Symbols.format_size_rounded, fill: 1),
              title: Text(t.subtitlingStyling.fontSize),
              subtitle: Text('$_fontSize'),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => showNumericInputDialog(
                context: context,
                title: t.subtitlingStyling.fontSize,
                labelText: t.subtitlingStyling.fontSize,
                suffixText: '',
                min: 10,
                max: 80,
                currentValue: _fontSize,
                onSave: (value) async {
                  setState(() => _fontSize = value);
                  await _settingsService.write(SettingsService.subtitleFontSize, value);
                },
              ),
            ),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hexToColor(_textColor),
                  border: const Border.fromBorderSide(BorderSide(color: Colors.grey)),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              title: Text(t.subtitlingStyling.textColor),
              subtitle: Text(_textColor),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _openColorPicker(t.subtitlingStyling.textColor, _textColor, (color) {
                setState(() => _textColor = color);
                _settingsService.write(SettingsService.subtitleTextColor, color);
              }),
            ),
            ListTile(
              leading: const AppIcon(Symbols.vertical_align_bottom_rounded, fill: 1),
              title: Text(t.subtitlingStyling.position),
              subtitle: Text(_formatPosition(_subtitlePosition)),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => showNumericInputDialog(
                context: context,
                title: t.subtitlingStyling.position,
                labelText: t.subtitlingStyling.position,
                suffixText: '%',
                min: 0,
                max: 100,
                currentValue: _subtitlePosition,
                onSave: (value) async {
                  setState(() => _subtitlePosition = value);
                  await _settingsService.write(SettingsService.subtitlePosition, value);
                },
              ),
            ),
            SwitchListTile(
              secondary: const AppIcon(Symbols.format_bold_rounded, fill: 1),
              title: Text(t.subtitlingStyling.bold),
              value: _bold,
              onChanged: (value) async {
                setState(() => _bold = value);
                await _settingsService.write(SettingsService.subtitleBold, value);
              },
            ),
            SwitchListTile(
              secondary: const AppIcon(Symbols.format_italic_rounded, fill: 1),
              title: Text(t.subtitlingStyling.italic),
              value: _italic,
              onChanged: (value) async {
                setState(() => _italic = value);
                await _settingsService.write(SettingsService.subtitleItalic, value);
              },
            ),

            SettingsSectionHeader(t.subtitlingStyling.border),
            ListTile(
              leading: const AppIcon(Symbols.border_style_rounded, fill: 1),
              title: Text(t.subtitlingStyling.borderSize),
              subtitle: Text('$_borderSize'),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => showNumericInputDialog(
                context: context,
                title: t.subtitlingStyling.borderSize,
                labelText: t.subtitlingStyling.borderSize,
                suffixText: '',
                min: 0,
                max: 5,
                currentValue: _borderSize,
                onSave: (value) async {
                  setState(() => _borderSize = value);
                  await _settingsService.write(SettingsService.subtitleBorderSize, value);
                },
              ),
            ),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hexToColor(_borderColor),
                  border: const Border.fromBorderSide(BorderSide(color: Colors.grey)),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              title: Text(t.subtitlingStyling.borderColor),
              subtitle: Text(_borderColor),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _openColorPicker(t.subtitlingStyling.borderColor, _borderColor, (color) {
                setState(() => _borderColor = color);
                _settingsService.write(SettingsService.subtitleBorderColor, color);
              }),
            ),

            SettingsSectionHeader(t.subtitlingStyling.background),
            ListTile(
              leading: const AppIcon(Symbols.opacity_rounded, fill: 1),
              title: Text(t.subtitlingStyling.backgroundOpacity),
              subtitle: Text('$_backgroundOpacity%'),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => showNumericInputDialog(
                context: context,
                title: t.subtitlingStyling.backgroundOpacity,
                labelText: t.subtitlingStyling.backgroundOpacity,
                suffixText: '%',
                min: 0,
                max: 100,
                currentValue: _backgroundOpacity,
                onSave: (value) async {
                  setState(() => _backgroundOpacity = value);
                  await _settingsService.write(SettingsService.subtitleBackgroundOpacity, value);
                },
              ),
            ),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hexToColor(_backgroundColor),
                  border: const Border.fromBorderSide(BorderSide(color: Colors.grey)),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              title: Text(t.subtitlingStyling.backgroundColor),
              subtitle: Text(_backgroundColor),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _openColorPicker(t.subtitlingStyling.backgroundColor, _backgroundColor, (color) {
                setState(() => _backgroundColor = color);
                _settingsService.write(SettingsService.subtitleBackgroundColor, color);
              }),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}
