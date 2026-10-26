import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../services/cloud_settings_backup_service.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';

class CloudSettingsBackupDialog extends StatefulWidget {
  const CloudSettingsBackupDialog({super.key, required this.beforeRestore, required this.afterRestore});

  final VoidCallback beforeRestore;
  final Future<void> Function() afterRestore;

  @override
  State<CloudSettingsBackupDialog> createState() => _CloudSettingsBackupDialogState();
}

class _CloudSettingsBackupDialogState extends State<CloudSettingsBackupDialog> {
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _backup = CloudSettingsBackupService();
  bool _loading = true;
  bool _working = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    _backup.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final configuration = await _backup.loadConfiguration();
      if (!mounted) return;
      _url.text = configuration.url;
      _username.text = configuration.username;
      _password.text = configuration.password;
    } catch (error, stackTrace) {
      appLogger.e('Failed to load cloud settings backup configuration', error: error, stackTrace: stackTrace);
      if (mounted) setState(() => _message = t.errors.unableToLoad(context: t.settings.cloudBackup));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await _run(() async {
      await _backup.saveConfiguration(url: _url.text, username: _username.text, password: _password.text);
      return t.settings.cloudBackupSaved;
    });
  }

  Future<void> _backUp() async {
    await _run(() async {
      await _backup.saveConfiguration(url: _url.text, username: _username.text, password: _password.text);
      await _backup.backUp();
      return t.settings.cloudBackupComplete;
    });
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.settings.cloudBackupRestore),
        content: Text(t.settings.cloudBackupRestoreConfirm),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(context, false), label: t.common.cancel),
          DialogActionButton(onPressed: () => Navigator.pop(context, true), label: t.settings.cloudBackupRestore),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await _backup.saveConfiguration(url: _url.text, username: _username.text, password: _password.text);
      widget.beforeRestore();
      await _backup.restore();
      await widget.afterRestore();
      return t.settings.cloudBackupRestored;
    });
  }

  Future<void> _run(Future<String> Function() operation) async {
    if (_working || _loading) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final message = await operation();
      if (mounted) setState(() => _message = message);
    } catch (error, stackTrace) {
      appLogger.e('Cloud settings backup action failed', error: error, stackTrace: stackTrace);
      final message = error is CloudSettingsBackupException
          ? error.message
          : t.errors.unableToLoad(context: t.settings.cloudBackup);
      if (mounted) setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.settings.cloudBackup),
    content: SizedBox(
      width: 480,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.settings.cloudBackupDescription),
                  const SizedBox(height: 16),
                  FocusableTextField(
                    controller: _url,
                    enabled: !_working,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: t.settings.cloudBackupUrl,
                      prefixIcon: const AppIcon(Symbols.link_rounded),
                    ),
                  ),
                  FocusableTextField(
                    controller: _username,
                    enabled: !_working,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(labelText: t.settings.cloudBackupUsername),
                    textInputAction: TextInputAction.next,
                  ),
                  FocusableTextField(
                    controller: _password,
                    enabled: !_working,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(labelText: t.settings.cloudBackupPassword),
                    textInputAction: TextInputAction.done,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(liveRegion: true, child: Text(_message!)),
                    ),
                  ],
                  if (_working) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                ],
              ),
            ),
    ),
    actions: [
      DialogActionButton(onPressed: _working ? null : () => Navigator.pop(context), label: t.common.close),
      DialogActionButton(onPressed: _working || _loading ? null : _save, label: t.common.save),
      DialogActionButton(onPressed: _working || _loading ? null : _backUp, label: t.settings.cloudBackupNow),
      DialogActionButton(onPressed: _working || _loading ? null : _restore, label: t.settings.cloudBackupRestore),
    ],
  );
}
