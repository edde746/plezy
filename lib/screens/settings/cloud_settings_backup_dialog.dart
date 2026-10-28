import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/cloud_settings_backup_service.dart';
import '../../services/storage_service.dart';
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
  final _urlFocus = FocusNode(debugLabel: 'CloudSettingsBackup:Url');
  final _usernameFocus = FocusNode(debugLabel: 'CloudSettingsBackup:Username');
  final _passwordFocus = FocusNode(debugLabel: 'CloudSettingsBackup:Password');
  final _saveFocus = FocusNode(debugLabel: 'CloudSettingsBackup:Save');
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
    _urlFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _saveFocus.dispose();
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
      final owner = await _captureOwner();
      await _backup.saveConfiguration(url: _url.text, username: _username.text, password: _password.text);
      await _backup.backUp(
        expectedProfileId: owner.profileId,
        expectedOwner: owner.owner,
        isCurrentSession: owner.isCurrent,
      );
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
      final owner = await _captureOwner();
      await _backup.saveConfiguration(url: _url.text, username: _username.text, password: _password.text);
      widget.beforeRestore();
      await _backup.restore(
        expectedProfileId: owner.profileId,
        expectedOwner: owner.owner,
        isCurrentSession: owner.isCurrent,
      );
      await widget.afterRestore();
      return t.settings.cloudBackupRestored;
    });
  }

  Future<({String? profileId, String? owner, bool Function() isCurrent})> _captureOwner() async {
    final profile = context.read<ActiveProfileProvider>();
    final expectedProfileId = profile.activeId;
    final expectedGeneration = profile.identityMutationGeneration;
    bool isCurrent() =>
        profile.identityMutationGeneration == expectedGeneration && profile.activeId == expectedProfileId;

    final storage = await StorageService.getInstance();
    if (!isCurrent() || storage.getActiveProfileId() != expectedProfileId) {
      throw const CloudSettingsBackupException('The active profile changed before the backup action started.');
    }
    return (profileId: expectedProfileId, owner: storage.activeUserScope(), isCurrent: isCurrent);
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
    scrollable: true,
    title: Text(t.settings.cloudBackup),
    content: SizedBox(
      width: double.maxFinite,
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
                    focusNode: _urlFocus,
                    autofocus: true,
                    tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
                    enabled: !_working,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    onNavigateDown: _usernameFocus.requestFocus,
                    onSubmitted: (_) => _usernameFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: t.settings.cloudBackupUrl,
                      prefixIcon: const AppIcon(Symbols.link_rounded),
                    ),
                  ),
                  FocusableTextField(
                    controller: _username,
                    focusNode: _usernameFocus,
                    enabled: !_working,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onNavigateUp: _urlFocus.requestFocus,
                    onNavigateDown: _passwordFocus.requestFocus,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: InputDecoration(labelText: t.settings.cloudBackupUsername),
                  ),
                  FocusableTextField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !_working,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onNavigateUp: _usernameFocus.requestFocus,
                    onNavigateDown: _saveFocus.requestFocus,
                    onSubmitted: (_) => _saveFocus.requestFocus(),
                    decoration: InputDecoration(labelText: t.settings.cloudBackupPassword),
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
      DialogActionButton(focusNode: _saveFocus, onPressed: _working || _loading ? null : _save, label: t.common.save),
      DialogActionButton(onPressed: _working || _loading ? null : _backUp, label: t.settings.cloudBackupNow),
      DialogActionButton(onPressed: _working || _loading ? null : _restore, label: t.settings.cloudBackupRestore),
    ],
  );
}
