import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_slider.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../providers/theme_provider.dart';
import '../../services/settings_mutation_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../theme/mono_theme.dart';
import '../../theme/mono_tokens.dart';
import '../../theme/palette_contrast.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/layout_constants.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/palette_swatch.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

/// The fixed palettes the editor can start from and offers quick swatches of.
const _sourceThemes = [
  settings.ThemeMode.light,
  settings.ThemeMode.dark,
  settings.ThemeMode.oled,
  settings.ThemeMode.ember,
  settings.ThemeMode.glacier,
  settings.ThemeMode.forest,
  settings.ThemeMode.plum,
  settings.ThemeMode.paper,
];

/// Appearance → Theme → Edit custom theme.
///
/// Edits a draft of [initialPalette]: the colours, the preview and the
/// contrast warnings update as the controls move, but nothing outside this
/// screen does until Save stores the palette and selects Custom. Leaving with
/// unsaved changes asks first.
class CustomThemeEditorScreen extends StatefulWidget {
  const CustomThemeEditorScreen({super.key, required this.initialPalette});

  final MonoPalette initialPalette;

  @override
  State<CustomThemeEditorScreen> createState() => _CustomThemeEditorScreenState();
}

class _CustomThemeEditorScreenState extends State<CustomThemeEditorScreen>
    with ControllerDisposerMixin, WidgetsBindingObserver {
  late MonoPalette _draft = widget.initialPalette;
  MonoPaletteSlot _slot = MonoPaletteSlot.bg;

  /// The edited colour in HSV, kept apart from [_draft] so a hue survives
  /// passing through grey (zero saturation or value), where RGB forgets it.
  late HSVColor _hsv = HSVColor.fromColor(widget.initialPalette[_slot]);
  late final TextEditingController _hexController = createTextEditingController(
    text: _hexFor(widget.initialPalette[_slot]),
  );
  final _saveFocusNode = FocusNode(debugLabel: 'custom_theme_save');
  final _pickerKey = GlobalKey();

  MonoPalette? _previewPalette;
  ThemeData? _previewTheme;
  bool _saving = false;
  bool _leaving = false;

  /// Whether the software keyboard was up at the last build.
  bool _keyboardOpen = false;

  bool get _dirty => _draft != widget.initialPalette;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveFocusNode.dispose();
    super.dispose();
  }

  /// The keyboard inset from the view itself: the app's root scaffold resizes
  /// for the keyboard and strips the inset from the MediaQuery below it.
  bool _isKeyboardOpen(BuildContext context) => View.of(context).viewInsets.bottom > 0;

  @override
  void didChangeMetrics() {
    if (mounted && _isKeyboardOpen(context) != _keyboardOpen) setState(() {});
  }

  static String _hexFor(Color color) {
    final argb = colorToArgbHex(color);
    return color.toARGB32() >>> 24 == 0xFF ? '#${argb.substring(3)}' : argb;
  }

  /// The preview's theme, rebuilt only when the draft changed. Uncached so a
  /// slider drag doesn't keep a theme alive for every palette it passed.
  ThemeData get _previewThemeData {
    if (_previewPalette != _draft || _previewTheme == null) {
      _previewPalette = _draft;
      _previewTheme = monoThemeUncached(_draft);
    }
    return _previewTheme!;
  }

  void _selectSlot(MonoPaletteSlot slot) {
    setState(() {
      _slot = slot;
      _syncEditedColor();
    });
    // On touch the picker can sit below the fold; bring it up so the tap
    // visibly lands. D-pad users move there themselves.
    if (!InputModeTracker.isKeyboardMode(context, listen: false) && _isNarrow(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pickerContext = _pickerKey.currentContext;
        if (pickerContext == null || !pickerContext.mounted) return;
        unawaited(Scrollable.ensureVisible(pickerContext, alignment: 0.2, duration: const Duration(milliseconds: 200)));
      });
    }
  }

  /// Re-reads the edited colour after something other than the channel
  /// sliders changed it.
  void _syncEditedColor() {
    final color = _draft[_slot];
    _hsv = HSVColor.fromColor(color);
    _hexController.text = _hexFor(color);
  }

  /// Applies a slider move. Quantized to 8 bits per channel so the draft is
  /// exactly what Save stores and the hex field shows.
  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      final color = Color(hsv.toColor().toARGB32());
      _draft = _draft.withColor(_slot, color);
      _hexController.text = _hexFor(color);
    });
  }

  void _setColor(Color color) {
    setState(() {
      _draft = _draft.withColor(_slot, color);
      _syncEditedColor();
    });
  }

  void _onHexChanged(String text) {
    final color = tryParseHexColor(text);
    if (color == null) {
      setState(() {});
      return;
    }
    // Leave the field as typed; only the draft and the sliders follow.
    setState(() {
      _draft = _draft.withColor(_slot, color);
      _hsv = HSVColor.fromColor(color);
    });
  }

  void _onHexSubmitted(String _) {
    setState(() => _hexController.text = _hexFor(_draft[_slot]));
  }

  Future<void> _startFrom() async {
    final picked = await showSelectionDialog<settings.ThemeMode?>(
      context: context,
      title: t.themeEditor.startFrom,
      options: [for (final mode in _sourceThemes) DialogOption(value: mode, title: themeModeLabel(mode))],
      currentValue: null,
    );
    final palette = picked?.value == null ? null : ThemeProvider.paletteFor(picked!.value!);
    if (palette == null || !mounted) return;
    setState(() {
      _draft = palette;
      _syncEditedColor();
    });
  }

  void _reset() {
    setState(() {
      _draft = widget.initialPalette;
      _syncEditedColor();
    });
    // Reset disables itself; keep D-pad focus on a live button.
    if (InputModeTracker.isKeyboardMode(context, listen: false)) _saveFocusNode.requestFocus();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final palette = _draft;
    const mutation = SettingsMutationService();
    try {
      final paletteFailure = await mutation.write(context, settings.SettingsService.customThemePalette, palette);
      if (!mounted) return;
      final modeFailure = await mutation.write(context, settings.SettingsService.themeMode, settings.ThemeMode.custom);
      if (!mounted) return;
      final failure = paletteFailure ?? modeFailure;
      if (failure != null) showErrorSnackBar(context, failure.display);
    } catch (error, stackTrace) {
      appLogger.e('Custom theme save failed', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, t.settings.saveFailed);
      return;
    }
    setState(() => _leaving = true);
    Navigator.pop(context);
  }

  Future<void> _confirmDiscard() async {
    final discard = await showConfirmDialog(
      context,
      title: t.themeEditor.discardTitle,
      message: t.themeEditor.discardMessage,
      confirmText: t.themeEditor.discard,
      isDestructive: true,
    );
    if (!discard || !mounted) return;
    setState(() => _leaving = true);
    Navigator.pop(context);
  }

  static bool _isNarrow(BuildContext context) =>
      !PlatformDetector.isTV() && MediaQuery.sizeOf(context).width < ScreenBreakpoints.mobile;

  @override
  Widget build(BuildContext context) {
    final narrow = _isNarrow(context);
    _keyboardOpen = _isKeyboardOpen(context);
    // While typing on a phone the bar rides on the keyboard. The preview
    // would leave about one row for the field, so the bar trades it for this
    // colour's contrast warnings, which then stay in view as the hex changes.
    final warningsInBar = narrow && _keyboardOpen;
    final failing = PaletteContrastCheck.failing(_draft);
    final slotWarnings = [
      for (final check in failing)
        if (check.slots.contains(_slot)) check,
    ];
    final controls = _buildControls(context, failing, warningsInBar ? const [] : slotWarnings);

    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _leaving) return;
        if (BackKeyCoordinator.consumeIfHandled()) return;
        BackKeyUpSuppressor.suppressBackUntilKeyUp();
        unawaited(_confirmDiscard());
      },
      child: FocusedScrollScaffold(
        title: Text(t.themeEditor.title),
        bottomBar: narrow
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!warningsInBar)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _ThemePreview(theme: _previewThemeData),
                    )
                  else if (slotWarnings.isNotEmpty)
                    Padding(
                      key: const ValueKey('custom_theme_bar_warnings'),
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: _ContrastWarnings(checks: slotWarnings, palette: _draft),
                    ),
                  _buildActions(context),
                ],
              )
            : _buildActions(context),
        slivers: narrow
            ? [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList(delegate: SliverChildListDelegate(controls)),
                ),
              ]
            : [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: controls),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width * 0.4).clamp(300.0, 440.0),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
                                child: Text(
                                  t.themeEditor.preview,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: tokens(context).textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _ThemePreview(theme: _previewThemeData),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  List<Widget> _buildControls(
    BuildContext context,
    List<PaletteContrastCheck> failing,
    List<PaletteContrastCheck> slotWarnings,
  ) {
    return [
      SettingsGroup(
        children: [
          FocusableListTile(
            key: const ValueKey('custom_theme_start_from'),
            leading: const AppIcon(Symbols.palette_rounded, fill: 1),
            title: Text(t.themeEditor.startFrom),
            subtitle: Text(t.themeEditor.startFromDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: _startFrom,
          ),
        ],
      ),
      SettingsGroup(
        title: t.themeEditor.colors,
        children: [
          for (final slot in MonoPaletteSlot.values)
            _SlotTile(
              slot: slot,
              color: _draft[slot],
              selected: slot == _slot,
              warning: failing.any((check) => check.slots.contains(slot)),
              onTap: () => _selectSlot(slot),
            ),
        ],
      ),
      SettingsGroup(key: _pickerKey, title: _slotLabel(_slot), children: [_buildPicker(context, slotWarnings)]),
    ];
  }

  Widget _buildPicker(BuildContext context, List<PaletteContrastCheck> warnings) {
    final color = _draft[_slot];
    final hexValid = tryParseHexColor(_hexController.text) != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ColorDot(color: color, size: 44),
              const SizedBox(width: 16),
              Expanded(
                child: FocusableTextField(
                  key: const ValueKey('custom_theme_hex'),
                  controller: _hexController,
                  decoration: InputDecoration(
                    labelText: t.accessibility.hexColor,
                    helperText: hexValid ? t.themeEditor.hexHint : null,
                    errorText: hexValid ? null : t.themeEditor.hexHint,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(9),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: _onHexChanged,
                  onSubmitted: _onHexSubmitted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChannelSlider(
            key: const ValueKey('custom_theme_hue'),
            label: t.accessibility.hue,
            valueLabel: '${_hsv.hue.round()}°',
            value: _hsv.hue,
            max: 360,
            onChanged: (value) => _setHsv(_hsv.withHue(value)),
          ),
          _ChannelSlider(
            key: const ValueKey('custom_theme_saturation'),
            label: t.accessibility.saturation,
            valueLabel: '${(_hsv.saturation * 100).round()}%',
            value: _hsv.saturation,
            max: 1,
            onChanged: (value) => _setHsv(_hsv.withSaturation(value)),
          ),
          _ChannelSlider(
            key: const ValueKey('custom_theme_value'),
            label: t.accessibility.brightness,
            valueLabel: '${(_hsv.value * 100).round()}%',
            value: _hsv.value,
            max: 1,
            onChanged: (value) => _setHsv(_hsv.withValue(value)),
          ),
          _ChannelSlider(
            key: const ValueKey('custom_theme_alpha'),
            label: t.themeEditor.opacity,
            valueLabel: '${(_hsv.alpha * 100).round()}%',
            value: _hsv.alpha,
            max: 1,
            onChanged: (value) => _setHsv(_hsv.withAlpha(value)),
          ),
          if (warnings.isNotEmpty) ...[const SizedBox(height: 8), _ContrastWarnings(checks: warnings, palette: _draft)],
          const SizedBox(height: 12),
          Text(t.themeEditor.fromOtherThemes, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _quickSwatches(color)),
        ],
      ),
    );
  }

  /// This colour in every other theme, once each.
  List<Widget> _quickSwatches(Color current) {
    final themeByColor = <Color, settings.ThemeMode>{};
    for (final mode in _sourceThemes) {
      themeByColor.putIfAbsent(ThemeProvider.paletteFor(mode)![_slot], () => mode);
    }
    return [
      for (final MapEntry(key: color, value: mode) in themeByColor.entries)
        _QuickSwatch(
          key: ValueKey('custom_theme_swatch_${colorToArgbHex(color)}'),
          color: color,
          label: t.themeEditor.swatchLabel(theme: themeModeLabel(mode), color: _slotLabel(_slot)),
          selected: color == current,
          onPressed: () => _setColor(color),
        ),
    ];
  }

  Widget _buildActions(BuildContext context) {
    final save = _saving ? null : _save;
    final reset = _dirty && !_saving ? _reset : null;
    void cancel() => unawaited(Navigator.maybePop(context));
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: tokens(context).outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Reset takes what Cancel and Save leave, so a narrow phone or a
              // long translation shortens its label instead of overflowing.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  heightFactor: 1,
                  child: FocusableButton(
                    key: const ValueKey('custom_theme_reset'),
                    useBackgroundFocus: true,
                    onPressed: reset,
                    child: TextButton.icon(
                      onPressed: reset,
                      icon: const AppIcon(Symbols.restart_alt_rounded, fill: 1),
                      label: Text(t.common.reset, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FocusableButton(
                key: const ValueKey('custom_theme_cancel'),
                useBackgroundFocus: true,
                onPressed: cancel,
                child: OutlinedButton(onPressed: cancel, child: Text(t.common.cancel)),
              ),
              const SizedBox(width: 12),
              FocusableButton(
                key: const ValueKey('custom_theme_save'),
                focusNode: _saveFocusNode,
                useBackgroundFocus: true,
                onPressed: save,
                child: FilledButton(onPressed: save, child: Text(t.common.save)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _slotLabel(MonoPaletteSlot slot) => switch (slot) {
  MonoPaletteSlot.bg => t.themeEditor.slots.bg,
  MonoPaletteSlot.surface => t.themeEditor.slots.surface,
  MonoPaletteSlot.outline => t.themeEditor.slots.outline,
  MonoPaletteSlot.text => t.themeEditor.slots.text,
  MonoPaletteSlot.textMuted => t.themeEditor.slots.textMuted,
  MonoPaletteSlot.accent => t.themeEditor.slots.accent,
};

String _checkLabel(PaletteContrastCheck check) => switch (check) {
  PaletteContrastCheck.textOnBg => t.themeEditor.contrast.textOnBg,
  PaletteContrastCheck.textOnSurface => t.themeEditor.contrast.textOnSurface,
  PaletteContrastCheck.textMutedOnBg => t.themeEditor.contrast.textMutedOnBg,
  PaletteContrastCheck.textMutedOnSurface => t.themeEditor.contrast.textMutedOnSurface,
  PaletteContrastCheck.accentOnBg => t.themeEditor.contrast.accentOnBg,
  PaletteContrastCheck.accentOnSurface => t.themeEditor.contrast.accentOnSurface,
  PaletteContrastCheck.labelOnAccent => t.themeEditor.contrast.labelOnAccent,
};

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.color,
    required this.selected,
    required this.warning,
    required this.onTap,
  });

  final MonoPaletteSlot slot;
  final Color color;
  final bool selected;
  final bool warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusableListTile(
      key: ValueKey('custom_theme_slot_${slot.id}'),
      leading: ColorDot(color: color),
      title: Text(_slotLabel(slot)),
      subtitle: Text(_CustomThemeEditorScreenState._hexFor(color)),
      selected: selected,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warning)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppIcon(Symbols.warning_rounded, fill: 1, size: 20, color: scheme.error),
            ),
          AppIcon(
            selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
            fill: 1,
            color: selected ? scheme.primary : null,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// A labelled channel slider; LEFT/RIGHT adjust it on a D-pad.
class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: settingsOptionTitleStyle(context))),
              Text(valueLabel, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          Semantics(
            label: label,
            child: FocusableSlider(value: value.clamp(0.0, max), max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _QuickSwatch extends StatelessWidget {
  const _QuickSwatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ring = selected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    return FocusableButton(
      onPressed: onPressed,
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          selected: selected,
          button: true,
          child: InkResponse(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            canRequestFocus: false,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
              child: ColorDot(color: color, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

/// The failing [checks] for the colour being edited, measured in [palette].
class _ContrastWarnings extends StatelessWidget {
  const _ContrastWarnings({required this.checks, required this.palette});

  final List<PaletteContrastCheck> checks;
  final MonoPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final check in checks) _ContrastWarning(check: check, ratio: check.ratioIn(palette))],
    );
  }
}

class _ContrastWarning extends StatelessWidget {
  const _ContrastWarning({required this.check, required this.ratio});

  final PaletteContrastCheck check;
  final double ratio;

  /// Truncated, not rounded, so a pair just under the bar never reads as
  /// meeting it (4.46 shows 4.4, not 4.5).
  static String _formatRatio(double value) => ((value * 10).floor() / 10).toStringAsFixed(1);

  static String _formatMinimum(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(Symbols.warning_rounded, fill: 1, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.themeEditor.lowContrast(
                pair: _checkLabel(check),
                ratio: _formatRatio(ratio),
                minimum: _formatMinimum(check.minimum),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the app looks like in the draft palette: an app bar, cards (one with
/// the D-pad focus ring), a filled button, a switch, a slider and secondary
/// text. Decorative only, so it takes no focus or input.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: t.themeEditor.preview,
      container: true,
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: IgnorePointer(
            child: Theme(
              data: theme,
              child: Builder(builder: _buildContent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final tokens = theme.extension<MonoTokens>()!;
    final textTheme = theme.textTheme;
    final radius = BorderRadius.circular(tokens.radiusLg);
    return Material(
      color: tokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  const AppIcon(Symbols.arrow_back_rounded, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.app.title, style: textTheme.titleMedium)),
                  const AppIcon(Symbols.search_rounded, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _PreviewCard(number: 1, progress: 0.35, focused: false, tokens: tokens)),
                const SizedBox(width: 12),
                Expanded(child: _PreviewCard(number: 2, progress: 0.7, focused: true, tokens: tokens)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 20),
                  label: Text(t.common.play),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    t.themeEditor.previewSwitch,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(value: true, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ],
            ),
            SizedBox(height: 32, child: Slider(value: 0.6, onChanged: (_) {})),
            Text(t.themeEditor.previewMutedText, style: textTheme.bodySmall?.copyWith(color: tokens.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.number, required this.progress, required this.focused, required this.tokens});

  final int number;
  final double progress;
  final bool focused;
  final MonoTokens tokens;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = tokens.radiusMd;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.outline),
      ),
      foregroundDecoration: FocusTheme.focusDecoration(context, isFocused: focused, borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: tokens.outline, borderRadius: BorderRadius.circular(tokens.radiusSm)),
                child: AppIcon(Symbols.movie_rounded, size: 18, color: tokens.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.themeEditor.previewCardTitle(number: number),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      t.themeEditor.previewCardSubtitle(minutes: number * 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: progress, minHeight: 4),
          ),
        ],
      ),
    );
  }
}
