import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../services/remote_streams/real_debrid_client.dart';
import '../../services/remote_streams/additional_debrid_clients.dart';
import '../../services/remote_streams/remote_stream_models.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../services/remote_streams/stremio_addon_client.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/pending_auth_dialog.dart';
import '../../widgets/settings_section.dart';
import '../remote_streams/remote_cloud_files_screen.dart';

class RemoteStreamingSettingsScreen extends StatefulWidget {
  const RemoteStreamingSettingsScreen({super.key});

  @override
  State<RemoteStreamingSettingsScreen> createState() => _RemoteStreamingSettingsScreenState();
}

class _RemoteStreamingSettingsScreenState extends State<RemoteStreamingSettingsScreen> {
  bool _connecting = false;

  Future<void> _copyAuthorizationCode(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showAppSnackBar(context, t.services.deviceCode.codeCopied);
  }

  Widget _copyableAuthorizationCode(String value, {required String copyLabel}) {
    final theme = Theme.of(context);
    return Center(
      child: CopyTapRegion(
        onCopy: () => _copyAuthorizationCode(value),
        semanticLabel: copyLabel,
        semanticValue: value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(Symbols.content_copy_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(copyLabel, style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addAddon() async {
    final result = await showDialog<({String address, bool allowHttp})>(
      context: context,
      builder: (context) => const _AddAddonDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<RemoteStreamingProvider>().installAddon(result.address, allowHttp: result.allowHttp);
      if (mounted) showAppSnackBar(context, t.streaming.addonInstalled);
    } on StremioAddonException {
      if (mounted) showAppSnackBar(context, t.streaming.addonError);
    } on Object {
      if (mounted) showAppSnackBar(context, t.streaming.addonError);
    }
  }

  Future<void> _connectRealDebrid() async {
    if (_connecting) return;
    final streaming = context.read<RemoteStreamingProvider>();
    final profile = streaming.profileId;
    if (profile == null || !streaming.isReady) return;
    setState(() => _connecting = true);
    var cancelled = false;
    var dialogOpen = false;
    try {
      final code = await RealDebridClient.startDeviceAuthorization();
      if (!mounted) return;
      final dialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PendingAuthDialog(
          title: t.streaming.realDebrid,
          body: t.streaming.realDebridInstructions,
          url: code.verificationUrl.toString(),
          displayUrl: code.verificationUrl.host,
          openLabel: t.streaming.realDebridActivate,
          onCancel: () => cancelled = true,
          children: [
            const SizedBox(height: 10),
            Text(t.streaming.realDebridCode, style: Theme.of(context).textTheme.labelMedium),
            _copyableAuthorizationCode(code.userCode, copyLabel: t.services.deviceCode.copyCode),
          ],
        ),
      );
      dialogOpen = true;
      final account = await RealDebridClient.finishDeviceAuthorization(
        code,
        shouldCancel: () => cancelled || streaming.profileId != profile,
      );
      if (account != null && !cancelled && mounted && streaming.profileId == profile && streaming.isReady) {
        await streaming.saveAccount(account);
        if (mounted) showAppSnackBar(context, t.streaming.realDebridConnected(username: account.displayName));
      }
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      await dialogFuture;
    } on RealDebridException {
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      if (mounted && !cancelled) showAppSnackBar(context, t.streaming.realDebridConnectFailed);
    } on Object {
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      if (mounted && !cancelled) showAppSnackBar(context, t.streaming.realDebridConnectFailed);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connectAllDebrid() async {
    if (_connecting) return;
    final streaming = context.read<RemoteStreamingProvider>();
    final profile = streaming.profileId;
    if (profile == null || !streaming.isReady) return;
    setState(() => _connecting = true);
    var cancelled = false;
    var dialogOpen = false;
    try {
      final code = await AllDebridClient.startDeviceAuthorization();
      if (!mounted) return;
      final dialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PendingAuthDialog(
          title: t.streaming.allDebrid,
          body: t.streaming.allDebridInstructions,
          url: code.userUrl.toString(),
          displayUrl: code.userUrl.host,
          openLabel: t.streaming.allDebridActivate,
          onCancel: () => cancelled = true,
          children: [
            const SizedBox(height: 10),
            Text(t.streaming.allDebridCode, style: Theme.of(context).textTheme.labelMedium),
            _copyableAuthorizationCode(code.pin, copyLabel: t.common.copy),
          ],
        ),
      );
      dialogOpen = true;
      final account = await AllDebridClient.finishDeviceAuthorization(
        code,
        shouldCancel: () => cancelled || streaming.profileId != profile,
      );
      if (account != null && !cancelled && mounted && streaming.profileId == profile && streaming.isReady) {
        await streaming.saveAccount(account);
        if (mounted) showAppSnackBar(context, t.streaming.accountConnected(username: account.displayName));
      }
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      await dialogFuture;
      if (account == null && mounted && !cancelled) showAppSnackBar(context, t.streaming.allDebridConnectFailed);
    } on RealDebridException {
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      if (mounted && !cancelled) showAppSnackBar(context, t.streaming.allDebridConnectFailed);
    } on Object {
      if (dialogOpen && mounted && !cancelled) Navigator.of(context, rootNavigator: true).pop();
      if (mounted && !cancelled) showAppSnackBar(context, t.streaming.allDebridConnectFailed);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connectWithApiKey(RemoteStreamService service, String label) async {
    if (_connecting) return;
    final key = await showDialog<String>(
      context: context,
      builder: (_) => _ApiKeyDialog(service: label),
    );
    if (key == null || !mounted) return;
    final streaming = context.read<RemoteStreamingProvider>();
    final profile = streaming.profileId;
    if (profile == null || !streaming.isReady) return;
    setState(() => _connecting = true);
    try {
      final account = switch (service) {
        RemoteStreamService.premiumize => await PremiumizeClient.connectWithApiKey(key),
        RemoteStreamService.torbox => await TorBoxClient.connectWithApiKey(key),
        _ => throw const RealDebridException(RealDebridFailure.unsupported),
      };
      if (mounted && streaming.profileId == profile && streaming.isReady) {
        await streaming.saveAccount(account);
        if (mounted) showAppSnackBar(context, t.streaming.accountConnected(username: account.displayName));
      }
    } on Object {
      if (mounted && streaming.profileId == profile) showAppSnackBar(context, t.streaming.apiKeyConnectFailed);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnectAccount(RemoteStreamService service, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.streaming.disconnectConfirm(service: label)),
        content: Text(t.streaming.disconnectBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.common.disconnect)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<RemoteStreamingProvider>().removeAccount(service);
  }

  Future<void> _clearUnreadableSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.streaming.clearUnreadableSettingsConfirm),
        content: Text(t.streaming.clearUnreadableSettingsBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.streaming.clearUnreadableSettings),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<RemoteStreamingProvider>().clearUnreadableSettings();
    } on Object {
      if (mounted) showAppSnackBar(context, t.streaming.clearUnreadableSettingsFailed);
    }
  }

  Future<void> _browseCloud(RemoteStreamService service) async {
    final streaming = context.read<RemoteStreamingProvider>();
    final account = streaming.accountFor(service);
    final profileId = streaming.profileId;
    if (!streaming.isReady || account == null || profileId == null) return;
    final settingsRoute = ModalRoute.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteCloudFilesScreen(
          service: service,
          onManageConnections: () async {
            if (!mounted || settingsRoute == null) return;
            Navigator.of(context).popUntil((route) => identical(route, settingsRoute));
          },
          expectedAccountId: account.id,
          expectedProfileId: profileId,
        ),
      ),
    );
  }

  Widget _providerTile({
    required RemoteStreamService service,
    required String label,
    required String description,
    required RemoteStreamAccount? account,
    required bool canConnect,
    required Future<void> Function() onConnect,
    required Future<void> Function() onBrowse,
  }) => FocusableListTile(
    leading: const AppIcon(Symbols.cloud_rounded),
    title: Text(label),
    subtitle: Text(account == null ? description : t.streaming.accountConnected(username: account.displayName)),
    trailing: account == null
        ? _connecting
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: canConnect ? onConnect : null,
                  child: Text(
                    service == RemoteStreamService.realDebrid
                        ? t.streaming.connectRealDebrid
                        : service == RemoteStreamService.allDebrid
                        ? t.streaming.connectAllDebrid
                        : t.streaming.connectApiKey,
                  ),
                )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: canConnect ? onBrowse : null, child: Text(t.streaming.browseCloud)),
              IconButton(
                tooltip: t.common.disconnect,
                onPressed: () => _disconnectAccount(service, label),
                icon: const AppIcon(Symbols.link_off_rounded),
              ),
            ],
          ),
    onTap: account == null ? (canConnect ? onConnect : null) : (canConnect ? onBrowse : null),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteStreamingProvider>(
      builder: (context, streaming, _) {
        final realDebrid = streaming.accountFor(RemoteStreamService.realDebrid);
        final allDebrid = streaming.accountFor(RemoteStreamService.allDebrid);
        final premiumize = streaming.accountFor(RemoteStreamService.premiumize);
        final torbox = streaming.accountFor(RemoteStreamService.torbox);
        return FocusedScrollScaffold(
        title: Text(t.streaming.title),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SettingsHelpHint(text: t.streaming.subtitle),
              ),
              if (streaming.loadFailed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streaming.settingsUnreadable
                            ? t.streaming.settingsUnreadable
                            : t.streaming.settingsLoadFailed,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          if (streaming.settingsUnreadable)
                            TextButton(
                              onPressed: _clearUnreadableSettings,
                              child: Text(t.streaming.clearUnreadableSettings),
                            ),
                          TextButton(
                            onPressed: streaming.retrySettingsLoad,
                            child: Text(t.streaming.retrySettingsLoad),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              SettingsGroup(
                title: t.streaming.addons,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(t.streaming.addonsDescription, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  if (streaming.loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (streaming.addons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(t.streaming.addonEmpty, style: Theme.of(context).textTheme.bodyMedium),
                    )
                  else
                    for (final addon in streaming.addons)
                      FocusableListTile(
                        leading: const AppIcon(Symbols.extension_rounded),
                        title: Text(addon.name),
                        subtitle: Text(addon.enabled ? t.streaming.addonInstalled : t.streaming.addonToggle),
                        onTap: () => unawaited(streaming.setAddonEnabled(addon.id, !addon.enabled)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch.adaptive(
                              value: addon.enabled,
                              onChanged: (value) => unawaited(streaming.setAddonEnabled(addon.id, value)),
                            ),
                            IconButton(
                              tooltip: t.common.remove,
                              onPressed: () async {
                                await streaming.removeAddon(addon.id);
                                if (context.mounted) showAppSnackBar(context, t.streaming.addonRemoved);
                              },
                              icon: const AppIcon(Symbols.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: FilledButton.tonalIcon(
                      onPressed: streaming.isReady ? _addAddon : null,
                      icon: const AppIcon(Symbols.add_rounded),
                      label: Text(t.streaming.addAddon),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Text(t.streaming.addonPrivacy, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
              SettingsGroup(
                title: t.streaming.providers,
                children: [
                  _providerTile(
                    service: RemoteStreamService.realDebrid,
                    label: t.streaming.realDebrid,
                    description: t.streaming.realDebridDescription,
                    account: realDebrid,
                    canConnect: streaming.isReady,
                    onConnect: _connectRealDebrid,
                    onBrowse: () => _browseCloud(RemoteStreamService.realDebrid),
                  ),
                  _providerTile(
                    service: RemoteStreamService.allDebrid,
                    label: t.streaming.allDebrid,
                    description: t.streaming.allDebridDescription,
                    account: allDebrid,
                    canConnect: streaming.isReady,
                    onConnect: _connectAllDebrid,
                    onBrowse: () => _browseCloud(RemoteStreamService.allDebrid),
                  ),
                  _providerTile(
                    service: RemoteStreamService.premiumize,
                    label: t.streaming.premiumize,
                    description: t.streaming.premiumizeDescription,
                    account: premiumize,
                    canConnect: streaming.isReady,
                    onConnect: () => _connectWithApiKey(RemoteStreamService.premiumize, t.streaming.premiumize),
                    onBrowse: () => _browseCloud(RemoteStreamService.premiumize),
                  ),
                  _providerTile(
                    service: RemoteStreamService.torbox,
                    label: t.streaming.torbox,
                    description: t.streaming.torboxDescription,
                    account: torbox,
                    canConnect: streaming.isReady,
                    onConnect: () => _connectWithApiKey(RemoteStreamService.torbox, t.streaming.torbox),
                    onBrowse: () => _browseCloud(RemoteStreamService.torbox),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
      );
      },
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.service});
  final String service;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.streaming.apiKeyTitle(service: widget.service)),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.streaming.apiKeyHint(service: widget.service)),
          const SizedBox(height: 16),
          FocusableTextField(
            controller: _controller,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: t.streaming.apiKey),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _controller.text.trim()),
        child: Text(t.common.connect),
      ),
    ],
  );
}

class _AddAddonDialog extends StatefulWidget {
  const _AddAddonDialog();

  @override
  State<_AddAddonDialog> createState() => _AddAddonDialogState();
}

class _AddAddonDialogState extends State<_AddAddonDialog> {
  final _address = TextEditingController();
  bool _allowHttp = false;
  bool _valid = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.streaming.addAddon),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.streaming.manifestUrlHint),
            const SizedBox(height: 16),
            FocusableTextField(
              controller: _address,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: t.streaming.manifestUrl),
              onChanged: (value) => setState(() => _valid = value.trim().isNotEmpty),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowHttp,
              onChanged: (value) => setState(() => _allowHttp = value),
              title: Text(t.streaming.allowHttp),
              subtitle: Text(t.streaming.allowHttpDescription),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
      FilledButton(
        onPressed: _valid ? () => Navigator.pop(context, (address: _address.text.trim(), allowHttp: _allowHttp)) : null,
        child: Text(t.streaming.installAddon),
      ),
    ],
  );
}
