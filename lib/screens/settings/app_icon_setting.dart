import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../services/app_icon/app_icon_catalog.dart';
import '../../services/app_icon/app_icon_service.dart';
import '../../services/supporter/supporter_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/supporter_sheet.dart';

/// Settings > Appearance row for the home-screen icon; opens [AppIconPickerSheet].
///
/// A `SettingsGroup` child cannot hide itself, so build this only where
/// [AppIconSetting.isShown] holds.
class AppIconSetting extends StatelessWidget {
  const AppIconSetting({super.key});

  /// Whether this install offers alternate icons: the Supporter perks are not
  /// hidden in this build and the device can switch its icon (iOS, iPadOS,
  /// tvOS, Android phones and Android TV). Rebuilds [context] when either
  /// changes.
  static bool isShown(BuildContext context) =>
      context.select<SupporterService?, bool>((supporter) => supporter?.isAvailable ?? false) &&
      context.select<AppIconService?, bool>((appIcons) => appIcons?.isSupported ?? false);

  @override
  Widget build(BuildContext context) {
    final currentId = context.select<AppIconService, String>((appIcons) => appIcons.currentId);
    return SettingNavigationTile(
      icon: Symbols.apps_rounded,
      title: t.appIcon.title,
      subtitle: appIconById(currentId)?.label(t),
      onTap: () => OverlaySheetController.showAdaptive<void>(
        context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const AppIconPickerSheet(),
      ),
    );
  }
}

/// Grid of every app icon, default first, with the current one marked. Locked
/// alternates open the Supporter sheet and apply only once it unlocks them.
class AppIconPickerSheet extends StatefulWidget {
  const AppIconPickerSheet({super.key, @visibleForTesting this.openSupporterSheet = showSupporterSheet});

  /// Opens the Supporter purchase sheet for a locked icon.
  final Future<void> Function(BuildContext context) openSupporterSheet;

  @override
  State<AppIconPickerSheet> createState() => _AppIconPickerSheetState();
}

class _AppIconPickerSheetState extends State<AppIconPickerSheet> {
  static const _minTileWidth = 76.0;
  static const _maxColumns = 8;

  bool _applying = false;

  Future<void> _choose(AppIconOption option) async {
    if (_applying) return;
    final appIcons = context.read<AppIconService>();
    final supporter = context.read<SupporterService>();
    if (option.id == appIcons.currentId) return;
    _applying = true;
    try {
      if (!option.isDefault && !supporter.isUnlocked) {
        await widget.openSupporterSheet(context);
        // The Supporter sheet may have replaced this one, so the purchase
        // decides, not whether the picker is still on screen.
        if (!supporter.isUnlocked) return;
      }
      await appIcons.setIcon(option.id);
    } on AppIconException catch (e, stackTrace) {
      appLogger.w('Could not switch the app icon to ${option.id}', error: e, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.appIcon.changeFailed);
    } finally {
      _applying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId = context.select<AppIconService, String>((appIcons) => appIcons.currentId);
    final unlocked = context.select<SupporterService, bool>((supporter) => supporter.isUnlocked);
    final tokensRef = tokens(context);
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: tokensRef.textMuted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomSheetHeader(title: t.appIcon.title),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!unlocked) ...[Text(t.appIcon.lockedHint, style: hintStyle), const SizedBox(height: 12)],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = tokensRef.space * 1.5;
                    final columns = ((constraints.maxWidth + spacing) / (_minTileWidth + spacing)).floor().clamp(
                      3,
                      _maxColumns,
                    );
                    final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final option in appIconCatalog)
                          SizedBox(
                            width: math.max(0, tileWidth),
                            child: _AppIconTile(
                              key: ValueKey(option.id),
                              option: option,
                              isCurrent: option.id == currentId,
                              isLocked: !option.isDefault && !unlocked,
                              onSelect: () => _choose(option),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 16),
                  Text(
                    PlatformDetector.isTVDevice() ? t.appIcon.tvLauncherHint : t.appIcon.launcherHint,
                    style: hintStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppIconTile extends StatelessWidget {
  const _AppIconTile({
    super.key,
    required this.option,
    required this.isCurrent,
    required this.isLocked,
    required this.onSelect,
  });

  final AppIconOption option;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tokensRef = tokens(context);
    final name = option.label(t);
    final iconRadius = BorderRadius.circular(tokensRef.radiusLg);
    return FocusableWrapper(
      semanticLabel: name,
      semanticValue: isCurrent
          ? t.appIcon.current
          : isLocked
          ? t.appIcon.locked
          : null,
      borderRadius: tokensRef.radiusLg,
      onSelect: onSelect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: iconRadius, child: _AppIconPreview(option)),
                  if (isCurrent)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: iconRadius,
                        border: Border.all(color: tokensRef.accent, width: 3),
                      ),
                    ),
                  if (isCurrent || isLocked)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _Badge(icon: isCurrent ? Symbols.check_rounded : Symbols.lock_rounded, filled: isCurrent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isCurrent ? tokensRef.text : tokensRef.textMuted,
                fontWeight: isCurrent ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The icon as the home screen shows it.
class _AppIconPreview extends StatelessWidget {
  const _AppIconPreview(this.option);

  final AppIconOption option;

  @override
  Widget build(BuildContext context) {
    final asset = option.previewAsset;
    if (asset == null) return const _DefaultIconPreview();
    return Image.asset(asset, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
  }
}

/// The shipping icon as this device's launcher draws it, so picking Default
/// looks like what comes back on the home screen:
/// * tvOS and Android TV: dark plates, from the thumbnails
///   scripts/codegen/generate_app_icons.py renders from the shipping image
///   stack and banner.
/// * Android phones: the adaptive foreground on `ic_launcher_background`, white
///   or #1A1A1A with the system night mode the launcher resolves it in
///   (res/values/colors.xml, res/values-night/colors.xml).
/// * iOS: ios/plezy.icon's one light fill, which its dark appearance inherits.
class _DefaultIconPreview extends StatelessWidget {
  const _DefaultIconPreview();

  static const _iosFill = Color(0xFFF1F1F1);
  static const _androidDayFill = Color(0xFFFFFFFF);
  static const _androidNightFill = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final tvPreview = PlatformDetector.isAppleTV()
        ? defaultAppIconTvosPreview
        : PlatformDetector.isTVDevice()
        ? defaultAppIconAndroidTvPreview
        : null;
    if (tvPreview != null) return Image.asset(tvPreview, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
    final fill = defaultTargetPlatform != TargetPlatform.android
        ? _iosFill
        : MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? _androidNightFill
        : _androidDayFill;
    return ColoredBox(
      color: fill,
      child: SvgPicture.asset('assets/plezy_adaptive_foreground.svg', fit: BoxFit.contain),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.filled});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tokensRef = tokens(context);
    final background = filled ? tokensRef.accent : tokensRef.surface;
    final foreground = filled ? tokensRef.bg : tokensRef.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: tokensRef.bg, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AppIcon(icon, fill: 1, size: 14, color: foreground),
      ),
    );
  }
}
