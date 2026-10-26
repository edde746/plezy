import '../../../i18n/presentation_formats.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../mpv/mpv.dart';
import '../../../services/settings_service.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';

/// Compact subtitle size/position controls available without leaving playback.
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

  Future<void> _apply() async {
    final settings = await SettingsService.getInstance();
    try {
      if (widget.player.playerType == 'exoplayer') {
        await widget.player.setSubtitleStyle(
          fontSize: _fontSize.toDouble(),
          textColor: settings.read(SettingsService.subtitleTextColor),
          borderSize: settings.read(SettingsService.subtitleBorderSize).toDouble(),
          borderColor: settings.read(SettingsService.subtitleBorderColor),
          bgColor: settings.read(SettingsService.subtitleBackgroundColor),
          bgOpacity: settings.read(SettingsService.subtitleBackgroundOpacity),
          subtitlePosition: _position,
          bold: settings.read(SettingsService.subtitleBold),
          italic: settings.read(SettingsService.subtitleItalic),
          anchorToScreen: settings.read(SettingsService.subtitleAnchorToScreen),
        );
      } else {
        await widget.player.setProperty('sub-font-size', formatDecimal(_fontSize, maximumDecimals: 0));
        await widget.player.setProperty('sub-pos', '$_position');
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

  @override
  Widget build(BuildContext context) {
    return BaseVideoControlSheet(
      title: t.screens.subtitleStyling,
      icon: Symbols.subtitles_rounded,
      onBack: OverlaySheetController.of(context).pop,
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                    onChanged: (value) {
                      setState(() => _position = value.round());
                      unawaited(_apply());
                    },
                    onChangeEnd: (_) => unawaited(_save()),
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
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final double value;
  final String label;
  final double min;
  final double max;
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
      Slider(
        value: value.clamp(min, max).toDouble(),
        min: min,
        max: max,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    ],
  );
}
