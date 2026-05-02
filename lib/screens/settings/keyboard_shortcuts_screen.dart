import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/hotkey_model.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/focused_scroll_scaffold.dart';
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
        final actions = hotkeys.keys.toList();
        return FocusedScrollScaffold(
          title: Text(t.settings.keyboardShortcuts),
          actions: [
            TextButton(
              onPressed: () async {
                await keyboardService.resetToDefaults();
                if (context.mounted) showSuccessSnackBar(context, t.settings.shortcutsReset);
              },
              child: Text(t.common.reset),
            ),
          ],
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final action = actions[index];
                  final hotkey = hotkeys[action]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(keyboardService.getActionDisplayName(action)),
                      subtitle: Text(action),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                        ),
                        child: Text(
                          keyboardService.formatHotkey(hotkey),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      onTap: () => _editHotkey(context, action, hotkey),
                    ),
                  );
                }, childCount: actions.length),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editHotkey(BuildContext screenContext, String action, HotKey currentHotkey) {
    showDialog(
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
