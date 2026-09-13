import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import 'settings_utils.dart';

/// Provisional styling values published by an open settings dialog, keyed by
/// pref key.
///
/// A dialog does not write its pref until Save, so without this the preview
/// would sit unchanged through the whole adjustment and only catch up once the
/// dialog closed - the one stretch where seeing the result actually matters.
/// Entries are cleared when the dialog goes away, so a cancelled edit leaves
/// nothing behind.
final ValueNotifier<Map<String, Object?>> subtitleStylePreviewOverrides = ValueNotifier(const {});

void clearSubtitleStylePreviewOverrides() {
  if (subtitleStylePreviewOverrides.value.isEmpty) return;
  subtitleStylePreviewOverrides.value = const {};
}

void setSubtitleStylePreviewOverride(String key, Object? value) {
  final next = Map<String, Object?>.from(subtitleStylePreviewOverrides.value);
  if (value == null) {
    if (next.remove(key) == null) return;
  } else {
    if (next[key] == value) return;
    next[key] = value;
  }
  subtitleStylePreviewOverrides.value = next;
}

/// Live sample of the current subtitle styling, so the knobs below it can be
/// judged by eye instead of by number.
///
/// An approximation, deliberately: the real thing is drawn by libass or the
/// platform text renderer against real video. Size and border are expressed by
/// mpv relative to a 720-high window, so both are scaled by this widget's own
/// height to keep the sample proportionate to what plays back.
class SubtitleStylePreview extends StatelessWidget {
  const SubtitleStylePreview({super.key, this.height = defaultHeight, this.padding = _defaultPadding});

  static const EdgeInsets _defaultPadding = EdgeInsets.fromLTRB(16, 8, 16, 12);

  /// Tall enough to judge outline weight and background opacity, small enough
  /// to sit in a corner without burying the control being adjusted.
  static const double defaultHeight = 160;

  final double height;

  /// Zero when the caller draws its own frame around the sample — an outer
  /// shadow has to hug the visible box, not the padding around it.
  final EdgeInsets padding;

  /// mpv sizes `sub-font-size` and `sub-border-size` against a 720-high window.
  static const double _referenceHeight = 720;

  static final List<Pref<Object?>> watchedPrefs = [
    SettingsService.subtitleFontSize,
    SettingsService.subtitleTextColor,
    SettingsService.subtitleBorderSize,
    SettingsService.subtitleBorderColor,
    SettingsService.subtitleBackgroundColor,
    SettingsService.subtitleBackgroundOpacity,
    SettingsService.subtitleBold,
    SettingsService.subtitleItalic,
    SettingsService.subtitlePosition,
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: watchedPrefs,
      builder: (context) => ValueListenableBuilder<Map<String, Object?>>(
        valueListenable: subtitleStylePreviewOverrides,
        builder: (context, overrides, _) => _build(context, overrides),
      ),
    );
  }

  Widget _build(BuildContext context, Map<String, Object?> overrides) {
    final settings = SettingsService.instance;
    T read<T>(Pref<T> pref) {
      final override = overrides[pref.key];
      return override is T ? override : settings.read(pref);
    }

    final scale = 1 / _referenceHeight;
    final fontSize = read(SettingsService.subtitleFontSize) * scale;
    final borderSize = read(SettingsService.subtitleBorderSize) * scale;
    final textColor = hexToColor(read(SettingsService.subtitleTextColor));
    final borderColor = hexToColor(read(SettingsService.subtitleBorderColor));
    final backgroundOpacity = read(SettingsService.subtitleBackgroundOpacity) / 100;
    final backgroundColor = hexToColor(
      read(SettingsService.subtitleBackgroundColor),
    ).withValues(alpha: backgroundOpacity);
    final bold = read(SettingsService.subtitleBold);
    final italic = read(SettingsService.subtitleItalic);
    // 0 % is the top of the frame, 100 % the bottom — the same reading as
    // the position tile's own labels.
    final position = read(SettingsService.subtitlePosition) / 100;

    return SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          // Height-driven rather than width-driven: floating in a corner,
          // height is the scarce dimension and the 16:9 frame is sized from
          // it instead of from the page width.
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                fit: .expand,
                children: [
                  const _PreviewBackdrop(),
                  Align(
                    // -1 is the top edge, 1 the bottom: the same 0-100 range
                    // mapped onto Alignment's own axis.
                    alignment: Alignment(0, position * 2 - 1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: constraints.maxHeight * 0.04),
                      child: _SampleLine(
                        text: t.subtitlingStyling.previewSample,
                        fontSize: fontSize * constraints.maxHeight,
                        borderSize: borderSize * constraints.maxHeight,
                        textColor: textColor,
                        borderColor: borderColor,
                        backgroundColor: backgroundColor,
                        bold: bold,
                        italic: italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for video. Deliberately not flat: a subtitle that disappears over
/// one part of the picture and not another is exactly the problem this preview
/// exists to expose, so the sample is judged against both a light and a dark
/// area.
class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [Color(0xFF1B2430), Color(0xFF8C93A0), Color(0xFF0B0D12)],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _SampleLine extends StatelessWidget {
  const _SampleLine({
    required this.text,
    required this.fontSize,
    required this.borderSize,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.bold,
    required this.italic,
  });

  final String text;
  final double fontSize;
  final double borderSize;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final bool bold;
  final bool italic;

  TextStyle get _base => TextStyle(
    fontSize: fontSize,
    fontWeight: bold ? .bold : .normal,
    fontStyle: italic ? .italic : .normal,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    // Flutter has no text-stroke property, so the outline is a second copy of
    // the same string painted underneath in stroke mode — the standard trick,
    // and the reason both copies must keep identical metrics.
    final outline = borderSize <= 0
        ? null
        : Text(
            text,
            textAlign: .center,
            style: _base.copyWith(
              foreground: Paint()
                ..style = .stroke
                ..strokeWidth = borderSize * 2
                ..strokeJoin = .round
                ..color = borderColor,
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.3, vertical: fontSize * 0.1),
        child: Stack(
          alignment: .center,
          children: [
            ?outline,
            Text(
              text,
              textAlign: .center,
              style: _base.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floats the preview above everything on the styling screen, including the
/// dialogs the colour and size tiles open.
///
/// It lives in the root [Overlay] rather than in the page's own tree for
/// exactly that reason: a dialog is a route of its own, so anything inside the
/// page is painted underneath it, and the sample would be hidden at the one
/// moment it is needed — while a colour or a size is actually being changed.
class SubtitleStylePreviewOverlay {
  SubtitleStylePreviewOverlay._(this._entry);

  final OverlayEntry _entry;

  /// Inserts the overlay. Call from a post-frame callback so the root overlay
  /// exists, and keep the handle to [remove] it when the screen goes away.
  static SubtitleStylePreviewOverlay? insert(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;
    final entry = OverlayEntry(builder: (context) => const _FloatingPreview());
    overlay.insert(entry);
    return SubtitleStylePreviewOverlay._(entry);
  }

  void remove() => _entry.remove();
}

class _FloatingPreview extends StatelessWidget {
  const _FloatingPreview();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Positioned(
      right: insets.right + 24,
      bottom: insets.bottom + 24,
      // Never a hit target: it sits over real controls, and a dialog behind it
      // must stay operable.
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16)],
            ),
            child: const SubtitleStylePreview(padding: EdgeInsets.zero),
          ),
        ),
      ),
    );
  }
}
