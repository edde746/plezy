import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../services/screen_lock_capabilities.dart';
import '../../services/settings_service.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/video_controls/widgets/screen_lock_overlay.dart';
import 'settings_utils.dart';

class ScreenLockSettingsGroup extends StatefulWidget {
  const ScreenLockSettingsGroup({super.key});

  @override
  State<ScreenLockSettingsGroup> createState() => _ScreenLockSettingsGroupState();
}

class _ScreenLockSettingsGroupState extends State<ScreenLockSettingsGroup> {
  late final _capabilities = ScreenLockCapabilities.load();
  bool _dialogPending = false;

  String _fingerLabel(int count) =>
      count == 1 ? t.settings.screenLockOneFinger : t.settings.screenLockFingers(count: count.toString());

  String _durationLabel(int milliseconds) =>
      t.settings.screenLockSeconds(seconds: (milliseconds / 1000).toStringAsFixed(milliseconds % 1000 == 0 ? 0 : 1));

  int _effectiveFingers(ScreenLockCapabilities capabilities) {
    final settings = SettingsService.instance;
    return capabilities.effectiveFingerCount(
      settings.read(SettingsService.screenLockFingerCount),
      verifiedFingerCount: settings.read(SettingsService.screenLockVerifiedFingerCount),
      verifiedDeviceKey: settings.read(SettingsService.screenLockVerifiedDeviceKey),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ScreenLockCapabilities>(
    future: _capabilities,
    builder: (context, snapshot) => SettingsBuilder(
      prefs: [
        SettingsService.screenLockHoldDurationMs,
        SettingsService.screenLockFingerCount,
        SettingsService.screenLockVerifiedFingerCount,
        SettingsService.screenLockVerifiedDeviceKey,
      ],
      builder: (context) {
        final capabilities = snapshot.data;
        final fingers = capabilities == null ? 1 : _effectiveFingers(capabilities);
        return SettingsGroup(
          title: t.settings.controlLock,
          children: [
            SettingSelectionTile<int>(
              pref: SettingsService.screenLockHoldDurationMs,
              icon: Symbols.timer_rounded,
              title: t.settings.unlockHoldDuration,
              subtitleBuilder: _durationLabel,
              options: [
                for (final milliseconds in [500, 1000, 1500, 2000, 3000, 4000, 5000, 7500, 10000])
                  DialogOption(value: milliseconds, title: _durationLabel(milliseconds)),
              ],
            ),
            SettingNavigationTile(
              key: const ValueKey('screen-lock-finger-count'),
              icon: Symbols.touch_app_rounded,
              title: t.settings.unlockFingerCount,
              subtitle: _fingerLabel(fingers),
              onTap: _chooseFingers,
            ),
            SettingNavigationTile(
              key: const ValueKey('screen-lock-preview'),
              icon: Symbols.lock_rounded,
              title: t.settings.testUnlockGesture,
              onTap: _testCurrentGesture,
            ),
          ],
        );
      },
    ),
  );

  Future<void> _chooseFingers() async {
    if (_dialogPending) return;
    _dialogPending = true;
    try {
      final capabilities = await _capabilities;
      if (!mounted) return;
      final maximum = capabilities.canRememberVerification ? 5 : 1;
      final selected = await showSelectionDialog<int>(
        context: context,
        title: t.settings.unlockFingerCount,
        options: [
          for (var count = 1; count <= maximum; count++)
            DialogOption(
              value: count,
              title: _fingerLabel(count),
              subtitle: !capabilities.canRememberVerification ? t.settings.lockGestureUnavailable : null,
            ),
        ],
        currentValue: _effectiveFingers(capabilities),
      );
      if (!mounted || selected == null) return;
      final count = selected.value;
      if (count > 1 && !await _preview(count)) return;
      if (!mounted) return;
      final saved = await guardSettingsOperation<bool, FormatException>(
        context,
        operation: 'Save control lock gesture',
        body: () async {
          final settings = SettingsService.instance;
          if (count > 1 && capabilities.canRememberVerification) {
            // Invalidate old verification first so interrupted writes stay safe.
            await settings.write(SettingsService.screenLockVerifiedFingerCount, 1);
            await settings.write(SettingsService.screenLockVerifiedDeviceKey, capabilities.deviceKey);
            await settings.write(SettingsService.screenLockVerifiedFingerCount, count);
          }
          await settings.write(SettingsService.screenLockFingerCount, count);
          return true;
        },
      );
      if (mounted && saved == true && count > 1) showSuccessSnackBar(context, t.settings.lockGestureVerified);
    } finally {
      _dialogPending = false;
    }
  }

  Future<void> _testCurrentGesture() async {
    if (_dialogPending) return;
    _dialogPending = true;
    try {
      final capabilities = await _capabilities;
      if (!mounted) return;
      final verified = await _preview(_effectiveFingers(capabilities));
      if (mounted && verified) showSuccessSnackBar(context, t.settings.lockGestureVerified);
    } finally {
      _dialogPending = false;
    }
  }

  Future<bool> _preview(int fingers) async {
    final milliseconds = SettingsService.instance.read(SettingsService.screenLockHoldDurationMs);
    final result = await showScopedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(t.settings.testUnlockGesture),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.settings.lockGestureTestDescription),
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('screen-lock-test-area'),
                width: double.infinity,
                height: 240,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                child: ScreenLockOverlay(
                  requiredFingers: fingers,
                  holdDuration: Duration(milliseconds: milliseconds),
                  autoHideHint: false,
                  instruction: t.videoControls.lockHoldInstruction(
                    fingers: _fingerLabel(fingers),
                    duration: _durationLabel(milliseconds),
                  ),
                  touchProgressLabelBuilder: (current) =>
                      t.videoControls.lockTouchCount(current: current.toString(), required: fingers.toString()),
                  onUnlock: () {
                    if (dialogContext.mounted && ModalRoute.of(dialogContext)?.isCurrent == true) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [DialogActionButton(label: t.common.cancel, onPressed: () => Navigator.of(dialogContext).pop(false))],
      ),
    );
    return result == true;
  }
}
