import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../i18n/strings.g.dart';
import '../services/settings_service.dart';
import '../widgets/desktop_app_bar.dart';

class SubtitleStylingScreen extends StatefulWidget {
  const SubtitleStylingScreen({super.key});

  @override
  State<SubtitleStylingScreen> createState() => _SubtitleStylingScreenState();
}

class _SubtitleStylingScreenState extends State<SubtitleStylingScreen> {
  static const EdgeInsets _sliderPadding = EdgeInsets.fromLTRB(16, 16, 16, 8);

  late SettingsService _settingsService;
  bool _isLoading = true;

  int _fontSize = 55;
  String _textColor = '#FFFFFF';
  int _borderSize = 3;
  String _borderColor = '#000000';
  String _backgroundColor = '#000000';
  int _backgroundOpacity = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    setState(() {
      _fontSize = _settingsService.getSubtitleFontSize();
      _textColor = _settingsService.getSubtitleTextColor();
      _borderSize = _settingsService.getSubtitleBorderSize();
      _borderColor = _settingsService.getSubtitleBorderColor();
      _backgroundColor = _settingsService.getSubtitleBackgroundColor();
      _backgroundOpacity = _settingsService.getSubtitleBackgroundOpacity();
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

  Future<void> _showColorPicker(
    String title,
    String currentColor,
    Function(String) onColorSelected,
  ) async {
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
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
    );

    final hexColor = _colorToHex(selectedColor);
    onColorSelected(hexColor);
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStylingCard(),
                const SizedBox(height: 24),
              ]),
            ),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Font Size Slider
          Padding(
            padding: _sliderPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.subtitlingStyling.fontSize),
                    Text('$_fontSize'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '30',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: _fontSize.toDouble(),
                        min: 30,
                        max: 80,
                        divisions: 50,
                        label: _fontSize.toString(),
                        onChanged: (value) {
                          setState(() {
                            _fontSize = value.toInt();
                          });
                        },
                        onChangeEnd: (value) {
                          _settingsService.setSubtitleFontSize(_fontSize);
                        },
                      ),
                    ),
                    const Text(
                      '80',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Text Color
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hexToColor(_textColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(t.subtitlingStyling.textColor),
            subtitle: Text(_textColor),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showColorPicker(t.subtitlingStyling.textColor, _textColor, (
                color,
              ) {
                setState(() {
                  _textColor = color;
                });
                _settingsService.setSubtitleTextColor(color);
              });
            },
          ),
          const Divider(),
          // Border Size Slider
          Padding(
            padding: _sliderPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.subtitlingStyling.borderSize),
                    Text('$_borderSize'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '0',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: _borderSize.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _borderSize.toString(),
                        onChanged: (value) {
                          setState(() {
                            _borderSize = value.toInt();
                          });
                        },
                        onChangeEnd: (value) {
                          _settingsService.setSubtitleBorderSize(_borderSize);
                        },
                      ),
                    ),
                    const Text(
                      '5',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Border Color
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hexToColor(_borderColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(t.subtitlingStyling.borderColor),
            subtitle: Text(_borderColor),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showColorPicker(t.subtitlingStyling.borderColor, _borderColor, (
                color,
              ) {
                setState(() {
                  _borderColor = color;
                });
                _settingsService.setSubtitleBorderColor(color);
              });
            },
          ),
          const Divider(),
          // Background Opacity Slider
          Padding(
            padding: _sliderPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.subtitlingStyling.backgroundOpacity),
                    Text('$_backgroundOpacity%'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '0%',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: _backgroundOpacity.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '$_backgroundOpacity%',
                        onChanged: (value) {
                          setState(() {
                            _backgroundOpacity = value.toInt();
                          });
                        },
                        onChangeEnd: (value) {
                          _settingsService.setSubtitleBackgroundOpacity(
                            _backgroundOpacity,
                          );
                        },
                      ),
                    ),
                    const Text(
                      '100%',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Background Color
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hexToColor(_backgroundColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(t.subtitlingStyling.backgroundColor),
            subtitle: Text(_backgroundColor),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showColorPicker(
                t.subtitlingStyling.backgroundColor,
                _backgroundColor,
                (color) {
                  setState(() {
                    _backgroundColor = color;
                  });
                  _settingsService.setSubtitleBackgroundColor(color);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
