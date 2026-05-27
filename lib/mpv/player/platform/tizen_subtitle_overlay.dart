import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/settings_service.dart';
import '../subtitle_stream_support.dart';

/// Parses a hex color string (`#RRGGBB` or `#AARRGGBB`) into a [Color].
/// Returns [fallback] if parsing fails.
Color parseTizenHexColor(String? hex, {Color fallback = Colors.white}) {
  if (hex == null) return fallback;
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return cleaned.length == 6 ? Color(0xFF000000 | value) : Color(value);
}

/// Builds a [TextStyle] from the current [SettingsService] subtitle preferences.
/// Falls back to sensible defaults when settings are unavailable.
TextStyle tizenSubtitleTextStyle(SettingsService? settings) {
  final fontSize = (settings?.read(SettingsService.subtitleFontSize) ?? 28).toDouble();
  final textColor = parseTizenHexColor(settings?.read(SettingsService.subtitleTextColor), fallback: Colors.white);
  final borderSize = (settings?.read(SettingsService.subtitleBorderSize) ?? 3).toDouble();
  final borderColor = parseTizenHexColor(settings?.read(SettingsService.subtitleBorderColor), fallback: Colors.black);
  final bold = settings?.read(SettingsService.subtitleBold) ?? false;
  final italic = settings?.read(SettingsService.subtitleItalic) ?? false;
  final bgOpacity = ((settings?.read(SettingsService.subtitleBackgroundOpacity) ?? 0) * 255 / 100).round();
  final bgHex = settings?.read(SettingsService.subtitleBackgroundColor);
  final bgBase = parseTizenHexColor(bgHex, fallback: Colors.black);
  final backgroundColor = bgOpacity > 0 ? bgBase.withAlpha(bgOpacity) : null;

  return TextStyle(
    color: textColor,
    fontSize: fontSize,
    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    backgroundColor: backgroundColor,
    height: 1.3,
    shadows: [
      Shadow(color: borderColor, offset: Offset(borderSize * 0.33, borderSize * 0.33), blurRadius: borderSize),
      Shadow(color: borderColor, offset: Offset(-borderSize * 0.33, -borderSize * 0.33), blurRadius: borderSize),
    ],
  );
}

/// Returns the bottom inset in logical pixels for the subtitle position preference.
/// [position] is 0 (top) to 100 (bottom); [screenHeight] is the available height.
double tizenSubtitleBottomInset(int position, double screenHeight, {double baseInset = 60}) {
  if (position >= 95) return baseInset;
  final fraction = position / 100.0;
  return baseInset + (1.0 - fraction) * (screenHeight * 0.7);
}

/// Primary subtitle overlay for [SubtitleStreamSupport] players (Tizen).
/// Renders subtitle text emitted by [SubtitleStreamSupport.subtitleTextStream]
/// using Flutter's [Text] widget, styled from [SettingsService] preferences.
class TizenSubtitleOverlay extends StatefulWidget {
  final SubtitleStreamSupport player;
  const TizenSubtitleOverlay({super.key, required this.player});

  @override
  State<TizenSubtitleOverlay> createState() => _TizenSubtitleOverlayState();
}

class _TizenSubtitleOverlayState extends State<TizenSubtitleOverlay> {
  String _text = '';
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.subtitleTextStream.listen((t) {
      if (mounted) setState(() => _text = t);
    });
  }

  @override
  void didUpdateWidget(TizenSubtitleOverlay old) {
    super.didUpdateWidget(old);
    if (old.player != widget.player) {
      _sub?.cancel();
      _sub = widget.player.subtitleTextStream.listen((t) {
        if (mounted) setState(() => _text = t);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    final settings = SettingsService.instanceOrNull;
    final position = settings?.read(SettingsService.subtitlePosition) ?? 100;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = tizenSubtitleBottomInset(position, screenHeight);
    return Positioned(
      left: 20,
      right: 20,
      bottom: bottomInset,
      child: IgnorePointer(
        child: Text(_text, textAlign: TextAlign.center, style: tizenSubtitleTextStyle(settings)),
      ),
    );
  }
}

/// Secondary subtitle overlay for [SubtitleStreamSupport] players (Tizen).
/// Renders secondary subtitle text, stacked above the primary overlay.
class TizenSecondarySubtitleOverlay extends StatefulWidget {
  final SubtitleStreamSupport player;
  const TizenSecondarySubtitleOverlay({super.key, required this.player});

  @override
  State<TizenSecondarySubtitleOverlay> createState() => _TizenSecondarySubtitleOverlayState();
}

class _TizenSecondarySubtitleOverlayState extends State<TizenSecondarySubtitleOverlay> {
  String _text = '';
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.secondarySubtitleTextStream.listen((t) {
      if (mounted) setState(() => _text = t);
    });
  }

  @override
  void didUpdateWidget(TizenSecondarySubtitleOverlay old) {
    super.didUpdateWidget(old);
    if (old.player != widget.player) {
      _sub?.cancel();
      _sub = widget.player.secondarySubtitleTextStream.listen((t) {
        if (mounted) setState(() => _text = t);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    final settings = SettingsService.instanceOrNull;
    final position = settings?.read(SettingsService.subtitlePosition) ?? 100;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Stack secondary above primary with a ~50px gap.
    final bottomInset = tizenSubtitleBottomInset(position, screenHeight) + 50;
    return Positioned(
      left: 20,
      right: 20,
      bottom: bottomInset,
      child: IgnorePointer(
        child: Text(_text, textAlign: TextAlign.center, style: tizenSubtitleTextStyle(settings)),
      ),
    );
  }
}
