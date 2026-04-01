import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/hotkey_model.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'hotkey_recorder_widget.dart';

class KeyboardShortcutsScreen extends StatefulWidget {
  final KeyboardShortcutsService keyboardService;

  const KeyboardShortcutsScreen({super.key, required this.keyboardService});

  @override
  State<KeyboardShortcutsScreen> createState() => _KeyboardShortcutsScreenState();
}

class _KeyboardShortcutsScreenState extends State<KeyboardShortcutsScreen> {
  Map<String, HotKey> _hotkeys = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotkeys();
  }

  Future<void> _loadHotkeys() async {
    await widget.keyboardService.refreshFromStorage();
    if (!mounted) return;
    setState(() {
      _hotkeys = widget.keyboardService.hotkeys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.settings.keyboardShortcuts),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.keyboardService.resetToDefaults();
            await _loadHotkeys();
            if (mounted) {
              showSuccessSnackBar(this.context, t.settings.shortcutsReset);
            }
          },
          child: Text(t.common.reset),
        ),
      ],
      slivers: _isLoading
          ? [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]
          : [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final actions = _hotkeys.keys.toList();
                    final action = actions[index];
                    final hotkey = _hotkeys[action]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(widget.keyboardService.getActionDisplayName(action)),
                        subtitle: Text(action),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
                            borderRadius: const BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Text(
                            widget.keyboardService.formatHotkey(hotkey),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        onTap: () => _editHotkey(action, hotkey),
                      ),
                    );
                  }, childCount: _hotkeys.length),
                ),
              ),
            ],
    );
  }

  void _editHotkey(String action, HotKey currentHotkey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HotKeyRecorderWidget(
          actionName: widget.keyboardService.getActionDisplayName(action),
          currentHotKey: currentHotkey,
          onHotKeyRecorded: (newHotkey) async {
            final navigator = Navigator.of(context);

            // Check for conflicts
            final existingAction = widget.keyboardService.getActionForHotkey(newHotkey);
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              showErrorSnackBar(
                context,
                t.settings.shortcutAlreadyAssigned(action: widget.keyboardService.getActionDisplayName(existingAction)),
              );
              return;
            }

            // Save the new hotkey
            await widget.keyboardService.setHotkey(action, newHotkey);

            if (mounted) {
              setState(() {
                _hotkeys[action] = newHotkey;
              });

              navigator.pop();

              showSuccessSnackBar(
                this.context,
                t.settings.shortcutUpdated(action: widget.keyboardService.getActionDisplayName(action)),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
