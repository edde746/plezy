import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/hotkey_model.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/shader_service.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../focus/focusable_button.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import 'hotkey_recorder_widget.dart';

class KeyboardShortcutsScreen extends StatelessWidget {
  final KeyboardShortcutsService keyboardService;

  const KeyboardShortcutsScreen({super.key, required this.keyboardService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: keyboardService,
      builder: (context, _) {
        final hotkeys = keyboardService.hotkeys;
        final actions = hotkeys.keys
            .where((action) => action != 'shader_toggle' || ShaderService.isPlatformSupported)
            .toList();
        return FocusedScrollScaffold(
          title: Text(t.settings.keyboardShortcuts),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                child: Align(
                  alignment: .centerRight,
                  child: FocusableButton(
                    onPressed: () => _resetShortcuts(context),
                    child: TextButton(onPressed: () => _resetShortcuts(context), child: Text(t.common.reset)),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: SettingsGroup(
                  children: [
                    for (final action in actions)
                      ListTile(
                        title: Text(keyboardService.getActionDisplayName(action)),
                        subtitle: Text(action),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
                            borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                          ),
                          child: Text(
                            keyboardService.formatHotkey(hotkeys[action]!),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        onTap: () => _editHotkey(context, action, hotkeys[action]!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetShortcuts(BuildContext context) async {
    await keyboardService.resetToDefaults();
    if (context.mounted) showSuccessSnackBar(context, t.settings.shortcutsReset);
  }

  void _editHotkey(BuildContext screenContext, String action, HotKey currentHotkey) {
    showScopedDialog<void>(
      context: screenContext,
      builder: (BuildContext context) {
        return HotKeyRecorderWidget(
          actionName: keyboardService.getActionDisplayName(action),
          currentHotKey: currentHotkey,
          onHotKeyRecorded: (newHotkey) async {
            final navigator = Navigator.of(context);

            // Check for conflicts
            final existingAction = keyboardService.getActionForHotkey(newHotkey);
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              showErrorSnackBar(
                context,
                t.settings.shortcutAlreadyAssigned(action: keyboardService.getActionDisplayName(existingAction)),
              );
              return;
            }

            // Save the new hotkey
            await keyboardService.setHotkey(action, newHotkey);

            navigator.pop();

            if (screenContext.mounted) {
              showSuccessSnackBar(
                screenContext,
                t.settings.shortcutUpdated(action: keyboardService.getActionDisplayName(action)),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
