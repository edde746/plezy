import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../providers/theme_provider.dart';
import '../../services/settings_mutation_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/supporter/supporter_mode.dart';
import '../../services/supporter/supporter_service.dart';
import '../../theme/mono_theme.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/palette_swatch.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/supporter_sheet.dart';
import 'custom_theme_editor_screen.dart';
import 'settings_utils.dart';

const _builtIns = [
  settings.ThemeMode.system,
  settings.ThemeMode.light,
  settings.ThemeMode.dark,
  settings.ThemeMode.oled,
];

const _presets = [
  settings.ThemeMode.ember,
  settings.ThemeMode.glacier,
  settings.ThemeMode.forest,
  settings.ThemeMode.plum,
  settings.ThemeMode.paper,
];

/// Whether this build carries the perk UI at all. Release builds without a
/// Supporter mode compile the presets' tiles and the editor out. Debug and
/// profile builds keep the code so tests can drive it; runtime availability
/// still hides it there.
const _perksCompiled = supporterBuildMode != SupporterMode.off || !kReleaseMode;

/// Appearance → Theme: the free built-ins, then the Supporter presets and the
/// Custom theme wherever this install offers the perks.
///
/// A pick applies at once, so the screen itself previews it. A locked perk
/// opens the Supporter sheet first and applies only if that unlocked it.
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key, this.openSupporterSheet = showSupporterSheet});

  /// Offers the Supporter purchase for a locked perk and completes when the
  /// sheet closes.
  final Future<void> Function(BuildContext context) openSupporterSheet;

  @override
  Widget build(BuildContext context) {
    // Hosts the Supporter sheet a locked perk opens; content builds below the
    // host so the sheet finds it instead of falling back to a modal route.
    return OverlaySheetHost(canPop: true, child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final supporter = context.watch<SupporterService>();
    final showPerks = _perksCompiled && supporter.isAvailable;
    final locked = !supporter.isUnlocked;
    final current = theme.themeMode;
    final lockedStored = theme.lockedStoredThemeMode;
    final customPalette = theme.customPalette;
    // D-pad/keyboard users land on the theme in use, like the selection
    // dialogs; autofocus only acts when the tile first builds.
    final focusSelected = InputModeTracker.isKeyboardMode(context, listen: false);

    _ThemeOptionTile option(settings.ThemeMode mode) => _ThemeOptionTile(
      mode: mode,
      palette: ThemeProvider.paletteFor(mode, customPalette: customPalette),
      selected: current == mode,
      autofocus: focusSelected && current == mode,
      locked: locked && mode.isSupporterPerk,
      // The radio follows what paints; the saved-but-locked choice says it
      // is kept, so losing the entitlement doesn't read as losing the theme.
      subtitle: mode == lockedStored
          ? t.themeEditor.savedLocked
          : mode == settings.ThemeMode.custom && customPalette == null
          ? t.themeEditor.customEmpty
          : null,
      onTap: () => _choose(context, mode),
    );

    return SettingsPage(
      title: Text(t.settings.theme),
      children: [
        SettingsGroup(
          title: showPerks ? t.themeEditor.builtIn : null,
          children: [for (final mode in _builtIns) option(mode)],
        ),
        if (showPerks) ...[
          SettingsGroup(title: t.themeEditor.presets, children: [for (final mode in _presets) option(mode)]),
          SettingsGroup(
            title: t.themeEditor.custom,
            children: [
              option(settings.ThemeMode.custom),
              FocusableListTile(
                key: const ValueKey('theme_edit_custom'),
                leading: const AppIcon(Symbols.edit_rounded, fill: 1),
                title: Text(t.themeEditor.editCustom),
                subtitle: Text(t.themeEditor.editCustomDescription),
                trailing: AppIcon(locked ? Symbols.lock_rounded : Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _editCustom(context),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Applies [mode]. A locked perk first offers the Supporter sheet; Custom
  /// with no saved palette opens the editor instead, which applies it on Save.
  Future<void> _choose(BuildContext context, settings.ThemeMode mode) async {
    if (!await _ensureUnlocked(context, mode) || !context.mounted) return;
    if (mode == settings.ThemeMode.custom && context.read<ThemeProvider>().customPalette == null) {
      await _openEditor(context);
      return;
    }
    final failure = await const SettingsMutationService().write(context, settings.SettingsService.themeMode, mode);
    if (failure != null && context.mounted) showErrorSnackBar(context, failure.display);
  }

  Future<void> _editCustom(BuildContext context) async {
    if (!await _ensureUnlocked(context, settings.ThemeMode.custom) || !context.mounted) return;
    await _openEditor(context);
  }

  /// Whether [mode] is usable now. A locked perk opens the Supporter sheet and
  /// answers from the entitlement once the sheet closes.
  Future<bool> _ensureUnlocked(BuildContext context, settings.ThemeMode mode) async {
    if (!mode.isSupporterPerk) return true;
    final supporter = context.read<SupporterService>();
    if (supporter.isUnlocked) return true;
    await openSupporterSheet(context);
    return supporter.isUnlocked;
  }
}

/// The editor starts from the saved Custom palette, or the first time from a
/// copy of the theme on screen.
Future<void> _openEditor(BuildContext context) async {
  if (_perksCompiled) {
    final theme = context.read<ThemeProvider>();
    final initial = theme.customPalette ?? theme.activePalette;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => CustomThemeEditorScreen(initialPalette: initial)),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.mode,
    required this.palette,
    required this.selected,
    required this.autofocus,
    required this.locked,
    required this.onTap,
    this.subtitle,
  });

  final settings.ThemeMode mode;

  /// Null draws System's Light/Dark split, or an empty slot for a Custom
  /// theme that has no palette yet.
  final MonoPalette? palette;
  final bool selected;
  final bool autofocus;
  final bool locked;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FocusableListTile(
      key: ValueKey(mode),
      leading: palette == null && mode == settings.ThemeMode.custom
          ? const _EmptySwatch()
          : PaletteSwatch(palette: palette),
      title: Text(themeModeLabel(mode)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                label: t.themeEditor.locked,
                child: const AppIcon(Symbols.lock_rounded, fill: 1, size: 20),
              ),
            ),
          AppIcon(
            selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
            fill: 1,
            color: selected ? primary : null,
          ),
        ],
      ),
      autofocus: autofocus,
      onTap: onTap,
    );
  }
}

class _EmptySwatch extends StatelessWidget {
  const _EmptySwatch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tokens(context).outline),
      ),
      child: const AppIcon(Symbols.add_rounded, fill: 1, size: 20),
    );
  }
}
