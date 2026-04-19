import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../models/trakt/trakt_device_code.dart';
import '../../providers/trakt_account_provider.dart';
import '../../services/settings_service.dart';
import '../../services/trakt/trakt_scrobble_service.dart';
import '../../services/trakt/trakt_sync_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';

/// Start the Trakt device-code OAuth flow from anywhere in the app.
///
/// Shows the code dialog + polls until the user completes authorization.
/// On pointer-driven platforms (desktop + mobile when dpad/keyboard mode
/// isn't active) this additionally auto-launches the browser at
/// `trakt.tv/activate` with the code prefilled — the dialog still shows
/// as a fallback/progress indicator.
Future<void> startTraktConnection(BuildContext context) async {
  final account = context.read<TraktAccountProvider>();
  if (account.isConnecting || account.isConnected) return;

  final autoLaunchBrowser = !InputModeTracker.isKeyboardMode(context);
  var dialogOpen = false;

  final ok = await account.connect(
    onCodeReady: (code) {
      if (!context.mounted) return;
      dialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DeviceCodeDialog(code: code, account: account),
      ).whenComplete(() => dialogOpen = false);
      if (autoLaunchBrowser) {
        final url = code.verificationUrlComplete ?? code.verificationUrl;
        unawaited(
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((Object e) {
            appLogger.d('Trakt: failed to auto-launch browser', error: e);
            return false;
          }),
        );
      }
    },
  );

  if (!context.mounted) return;

  // Close the dialog iff we showed one and it's still up (not already closed by
  // the Cancel button). This is the ONLY site that dismisses the dialog —
  // popping here and having the dialog self-pop would pop the screen behind.
  if (dialogOpen) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (!ok && account.session == null) {
    showAppSnackBar(context, t.trakt.connectFailed);
  }
}

class TraktSettingsScreen extends StatefulWidget {
  const TraktSettingsScreen({super.key});

  @override
  State<TraktSettingsScreen> createState() => _TraktSettingsScreenState();
}

class _TraktSettingsScreenState extends State<TraktSettingsScreen> {
  SettingsService? _settings;
  bool _scrobbleEnabled = true;
  bool _watchedSyncEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _scrobbleEnabled = s.getEnableTraktScrobble();
      _watchedSyncEnabled = s.getEnableTraktWatchedSync();
      _loaded = true;
    });
  }

  Future<void> _disconnect(TraktAccountProvider account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.trakt.disconnectConfirm),
        content: Text(t.trakt.disconnectConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.common.disconnect, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await account.disconnect();
    // build()'s post-frame handler pops the screen once the provider rebuilds
    // with isConnected == false — don't pop here too.
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return FocusedScrollScaffold(
        title: Text(t.trakt.title),
        slivers: const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    return Consumer<TraktAccountProvider>(
      builder: (context, account, _) {
        // Safety net: if we end up here while not connected (e.g. refresh failed
        // in the background and cleared the session), bail out. The settings
        // tile is the only supported entry point for the unauthed flow.
        if (!account.isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return FocusedScrollScaffold(
            title: Text(t.trakt.title),
            slivers: const [SliverFillRemaining(child: SizedBox.shrink())],
          );
        }

        final username = account.username;
        return FocusedScrollScaffold(
          title: Text(t.trakt.title),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
                  title: Text(username != null ? t.trakt.connectedAs(username: username) : t.trakt.connected),
                  subtitle: Text(t.trakt.connected),
                ),
                SettingsSectionHeader(t.settings.behavior),
                SwitchListTile(
                  secondary: const AppIcon(Symbols.auto_timer, fill: 1),
                  title: Text(t.trakt.scrobble),
                  subtitle: Text(t.trakt.scrobbleDescription),
                  value: _scrobbleEnabled,
                  onChanged: (value) async {
                    setState(() => _scrobbleEnabled = value);
                    await _settings!.setEnableTraktScrobble(value);
                    await TraktScrobbleService.instance.setEnabled(value);
                  },
                ),
                SwitchListTile(
                  secondary: const AppIcon(Symbols.check_circle_rounded, fill: 1),
                  title: Text(t.trakt.watchedSync),
                  subtitle: Text(t.trakt.watchedSyncDescription),
                  value: _watchedSyncEnabled,
                  onChanged: (value) async {
                    setState(() => _watchedSyncEnabled = value);
                    await _settings!.setEnableTraktWatchedSync(value);
                    await TraktSyncService.instance.setEnabled(value);
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                  title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => _disconnect(account),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _DeviceCodeDialog extends StatefulWidget {
  final TraktDeviceCode code;
  final TraktAccountProvider account;
  const _DeviceCodeDialog({required this.code, required this.account});

  @override
  State<_DeviceCodeDialog> createState() => _DeviceCodeDialogState();
}

class _DeviceCodeDialogState extends State<_DeviceCodeDialog> {
  Future<void> _open() async {
    final url = widget.code.verificationUrlComplete ?? widget.code.verificationUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code.userCode));
    if (!mounted) return;
    showAppSnackBar(context, t.trakt.codeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(t.trakt.deviceCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.trakt.deviceCodeBody(url: widget.code.verificationUrl), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: _copy,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  widget.code.userCode,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(t.trakt.openTraktActivate),
              onPressed: _open,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(child: Text(t.trakt.waitingForAuthorization, style: theme.textTheme.bodySmall)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.account.cancelConnect();
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}
