import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_slider.dart';
import '../../../i18n/strings.g.dart';
import '../../../i18n/presentation_formats.dart';
import '../../../mpv/mpv.dart';
import '../../../services/settings_service.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../widgets/setting_tile.dart';
import 'base_video_control_sheet.dart';

/// Subtitle appearance controls available without leaving playback.
class InPlayerSubtitleStyleSheet extends StatefulWidget {
  const InPlayerSubtitleStyleSheet({super.key, required this.player});

  final Player player;

  @override
  State<InPlayerSubtitleStyleSheet> createState() => _InPlayerSubtitleStyleSheetState();
}

class _InPlayerSubtitleStyleSheetState extends State<InPlayerSubtitleStyleSheet> {
  int _fontSize = SettingsService.subtitleFontSize.defaultValue;
  int _position = SettingsService.subtitlePosition.defaultValue;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = settings.read(SettingsService.subtitleFontSize);
      _position = settings.read(SettingsService.subtitlePosition);
      _loaded = true;
    });
  }

  String _safeColor(String value, String fallback) =>
      RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value) ? value : fallback;

  Future<void> _setMpvProperty(String name, String value) async {
    try {
      await widget.player.setProperty(name, value);
    } catch (error, stackTrace) {
      appLogger.w('Could not apply subtitle style property $name', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _apply() async {
    final settings = await SettingsService.getInstance();
    try {
      if (widget.player.playerType == 'exoplayer') {
        await widget.player.setSubtitleStyle(
          fontSize: _fontSize.toDouble(),
          textColor: _safeColor(
            settings.read(SettingsService.subtitleTextColor),
            SettingsService.subtitleTextColor.defaultValue,
          ),
          borderSize: settings.read(SettingsService.subtitleBorderSize).toDouble(),
          borderColor: _safeColor(
            settings.read(SettingsService.subtitleBorderColor),
            SettingsService.subtitleBorderColor.defaultValue,
          ),
          bgColor: _safeColor(
            settings.read(SettingsService.subtitleBackgroundColor),
            SettingsService.subtitleBackgroundColor.defaultValue,
          ),
          bgOpacity: settings.read(SettingsService.subtitleBackgroundOpacity).clamp(0, 100).toInt(),
          subtitlePosition: _position,
          bold: settings.read(SettingsService.subtitleBold),
          italic: settings.read(SettingsService.subtitleItalic),
          anchorToScreen: settings.read(SettingsService.subtitleAnchorToScreen),
        );
      } else {
        final textColor = _safeColor(
          settings.read(SettingsService.subtitleTextColor),
          SettingsService.subtitleTextColor.defaultValue,
        );
        final borderColor = _safeColor(
          settings.read(SettingsService.subtitleBorderColor),
          SettingsService.subtitleBorderColor.defaultValue,
        );
        final backgroundColor = _safeColor(
          settings.read(SettingsService.subtitleBackgroundColor),
          SettingsService.subtitleBackgroundColor.defaultValue,
        );
        final backgroundOpacity = settings.read(SettingsService.subtitleBackgroundOpacity).clamp(0, 100).toInt();
        final alpha = (backgroundOpacity * 255 / 100).round().toRadixString(16).padLeft(2, '0').toUpperCase();

        await _setMpvProperty('sub-font-size', formatDecimal(_fontSize, maximumDecimals: 0));
        await _setMpvProperty('sub-pos', '$_position');
        await _setMpvProperty('sub-color', textColor);
        await _setMpvProperty('sub-bold', settings.read(SettingsService.subtitleBold) ? 'yes' : 'no');
        await _setMpvProperty('sub-italic', settings.read(SettingsService.subtitleItalic) ? 'yes' : 'no');
        await _setMpvProperty('sub-border-size', settings.read(SettingsService.subtitleBorderSize).toString());
        await _setMpvProperty('sub-border-color', borderColor);
        await _setMpvProperty('sub-back-color', '#' + alpha + backgroundColor.substring(1));
        await _setMpvProperty('sub-border-style', backgroundOpacity > 0 ? 'background-box' : 'outline-and-shadow');
      }
    } catch (error, stackTrace) {
      appLogger.w('Could not update subtitle style during playback', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _save() async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.subtitleFontSize, _fontSize);
    await settings.write(SettingsService.subtitlePosition, _position);
  }

  Future<void> _resetAppearance() async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.subtitleFontSize, SettingsService.subtitleFontSize.defaultValue);
    await settings.write(SettingsService.subtitlePosition, SettingsService.subtitlePosition.defaultValue);
    await settings.write(SettingsService.subtitleTextColor, SettingsService.subtitleTextColor.defaultValue);
    await settings.write(SettingsService.subtitleBold, SettingsService.subtitleBold.defaultValue);
    await settings.write(SettingsService.subtitleItalic, SettingsService.subtitleItalic.defaultValue);
    await settings.write(SettingsService.subtitleBorderSize, SettingsService.subtitleBorderSize.defaultValue);
    await settings.write(SettingsService.subtitleBorderColor, SettingsService.subtitleBorderColor.defaultValue);
    await settings.write(SettingsService.subtitleBackgroundOpacity, SettingsService.subtitleBackgroundOpacity.defaultValue);
    await settings.write(SettingsService.subtitleBackgroundColor, SettingsService.subtitleBackgroundColor.defaultValue);
    if (!mounted) return;
    setState(() {
      _fontSize = SettingsService.subtitleFontSize.defaultValue;
      _position = SettingsService.subtitlePosition.defaultValue;
    });
    await _apply();
  }

  @override
  Widget build(BuildContext context) {
    return BaseVideoControlSheet(
      title: t.screens.subtitleStyling,
      icon: Symbols.subtitles_rounded,
      onBack: OverlaySheetController.of(context).pop,
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StyleSlider(
                    title: t.subtitlingStyling.fontSize,
                    value: _fontSize.toDouble(),
                    label: formatDecimal(_fontSize, maximumDecimals: 0),
                    min: 12,
                    max: 72,
                    formatValue: (value) => formatDecimal(value, maximumDecimals: 0),
                    onChanged: (value) {
                      setState(() => _fontSize = value.round());
                      unawaited(_apply());
                    },
                    onChangeEnd: (_) => unawaited(_save()),
                  ),
                  const SizedBox(height: 12),
                  _StyleSlider(
                    title: t.subtitlingStyling.position,
                    value: _position.toDouble(),
                    label: formatPercent(_position / 100),
                    min: 0,
                    max: 150,
                    formatValue: (value) => formatPercent(value / 100),
                    onChanged: (value) {
                      setState(() => _position = value.round());
                      unawaited(_apply());
                    },
                    onChangeEnd: (_) => unawaited(_save()),
                  ),
                  const Divider(height: 28),
                  SettingColorTile(
                    pref: SettingsService.subtitleTextColor,
                    icon: Symbols.format_color_text_rounded,
                    title: t.subtitlingStyling.textColor,
                    description: t.subtitlingStyling.textColorDescription,
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingSwitchTile(
                    pref: SettingsService.subtitleBold,
                    icon: Symbols.format_bold_rounded,
                    title: t.subtitlingStyling.bold,
                    subtitle: t.subtitlingStyling.boldDescription,
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingSwitchTile(
                    pref: SettingsService.subtitleItalic,
                    icon: Symbols.format_italic_rounded,
                    title: t.subtitlingStyling.italic,
                    subtitle: t.subtitlingStyling.italicDescription,
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingNumberTile(
                    pref: SettingsService.subtitleBorderSize,
                    icon: Symbols.border_style_rounded,
                    title: t.subtitlingStyling.borderSize,
                    description: t.subtitlingStyling.borderSizeDescription,
                    subtitleBuilder: (value) => formatDecimal(value, maximumDecimals: 0),
                    labelText: t.subtitlingStyling.borderSize,
                    suffixText: '',
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingColorTile(
                    pref: SettingsService.subtitleBorderColor,
                    icon: Symbols.border_color_rounded,
                    title: t.subtitlingStyling.borderColor,
                    description: t.subtitlingStyling.borderColorDescription,
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingNumberTile(
                    pref: SettingsService.subtitleBackgroundOpacity,
                    icon: Symbols.opacity_rounded,
                    title: t.subtitlingStyling.backgroundOpacity,
                    description: t.subtitlingStyling.backgroundOpacityDescription,
                    subtitleBuilder: (value) => formatPercent(value / 100),
                    labelText: t.subtitlingStyling.backgroundOpacity,
                    suffixText: '%',
                    onAfterWrite: (_) => _apply(),
                  ),
                  SettingColorTile(
                    pref: SettingsService.subtitleBackgroundColor,
                    icon: Symbols.format_color_fill_rounded,
                    title: t.subtitlingStyling.backgroundColor,
                    description: t.subtitlingStyling.backgroundColorDescription,
                    onAfterWrite: (_) => _apply(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _resetAppearance,
                      icon: const Icon(Symbols.restart_alt_rounded),
                      label: Text(t.common.reset),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StyleSlider extends StatelessWidget {
  const _StyleSlider({
    required this.title,
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.formatValue,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final double value;
  final String label;
  final double min;
  final double max;
  final String Function(double) formatValue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
      FocusableSlider(
        value: value.clamp(min, max).toDouble(),
        min: min,
        max: max,
        semanticLabel: title,
        semanticFormatterCallback: formatValue,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    ],
  );
}
