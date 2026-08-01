import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../providers/companion_remote_provider.dart';
import '../../services/companion_remote/companion_remote_host_controller.dart';
import '../../services/settings_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../focus/focusable_button.dart';
import '../../focus/key_event_utils.dart';
import '../dialog_action_button.dart';
import '../app_icon.dart';

class RemoteSessionDialog extends StatefulWidget {
  const RemoteSessionDialog({super.key});

  @override
  State<RemoteSessionDialog> createState() => _RemoteSessionDialogState();

  static Future<void> show(BuildContext context) {
    return showScopedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RemoteSessionDialog(),
    );
  }
}

class _RemoteSessionDialogState extends State<RemoteSessionDialog> with MountedSetStateMixin {
  bool _isStarting = false;
  String? _errorMessage;
  final _closeFocusNode = FocusNode(debugLabel: 'RemoteSessionDialog.close');
  final _toggleFocusNode = FocusNode(debugLabel: 'RemoteSessionDialog.toggle');
  final _minimizeFocusNode = FocusNode(debugLabel: 'RemoteSessionDialog.minimize');
  final _errorCloseFocusNode = FocusNode(debugLabel: 'RemoteSessionDialog.errorClose');
  final _errorRetryFocusNode = FocusNode(debugLabel: 'RemoteSessionDialog.errorRetry');

  @override
  void dispose() {
    _closeFocusNode.dispose();
    _toggleFocusNode.dispose();
    _minimizeFocusNode.dispose();
    _errorCloseFocusNode.dispose();
    _errorRetryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.enableCompanionRemoteServer, true);
      if (!mounted) return;
      final started = await startCompanionRemoteHost(context);
      if (!mounted) return;
      final provider = context.read<CompanionRemoteProvider>();
      setState(() {
        _isStarting = false;
        _errorMessage = started ? null : provider.session?.errorMessage ?? t.companionRemote.pairing.cryptoInitFailed;
      });
    } catch (e) {
      setStateIfMounted(() {
        _isStarting = false;
        _errorMessage = t.companionRemote.errors.serverStartFailed(error: e.toString().replaceFirst('Exception: ', ''));
      });
    }
  }

  Future<void> _stopServer() async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.enableCompanionRemoteServer, false);
    if (!mounted) return;
    await context.read<CompanionRemoteProvider>().stopHostServer();
  }

  Future<void> _toggleServer() async {
    final provider = context.read<CompanionRemoteProvider>();
    if (provider.isHostServerRunning) {
      await _stopServer();
    } else {
      await _startServer();
    }
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) => handleBackKeyNavigation(context, event),
      child: Consumer<CompanionRemoteProvider>(
        builder: (context, provider, child) {
          if (_isStarting) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(t.companionRemote.session.startingServer, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }

          if (_errorMessage != null) {
            return AlertDialog(
              title: Text(t.common.error),
              content: Text(_errorMessage!, style: const TextStyle(fontFamily: 'monospace')),
              actions: [
                DialogActionButton(
                  autofocus: true,
                  focusNode: _errorCloseFocusNode,
                  onPressed: _close,
                  onBack: _close,
                  onNavigateRight: () => _errorRetryFocusNode.requestFocus(),
                  useBackgroundFocus: true,
                  label: t.common.close,
                ),
                DialogActionButton(
                  focusNode: _errorRetryFocusNode,
                  onPressed: _startServer,
                  onBack: _close,
                  onNavigateLeft: () => _errorCloseFocusNode.requestFocus(),
                  useBackgroundFocus: true,
                  label: t.common.retry,
                ),
              ],
            );
          }

          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Row(
                      children: [
                        const AppIcon(Symbols.phone_android_rounded, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(t.companionRemote.title, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              _buildStatusLine(context, provider),
                            ],
                          ),
                        ),
                        FocusableButton(
                          focusNode: _closeFocusNode,
                          onPressed: _close,
                          onBack: _close,
                          onNavigateDown: () => _toggleFocusNode.requestFocus(),
                          useBackgroundFocus: true,
                          child: IconButton(icon: const AppIcon(Symbols.close_rounded), onPressed: _close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildServerStatus(context, provider),

                    if (provider.connectedDevice != null) ...[
                      const SizedBox(height: 16),
                      _buildConnectedDevice(context, provider),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: .end,
                      children: [
                        FocusableButton(
                          autofocus: true,
                          focusNode: _toggleFocusNode,
                          onPressed: _toggleServer,
                          onBack: _close,
                          onNavigateUp: () => _closeFocusNode.requestFocus(),
                          onNavigateRight: () => _minimizeFocusNode.requestFocus(),
                          useBackgroundFocus: true,
                          child: TextButton.icon(
                            onPressed: _toggleServer,
                            icon: AppIcon(
                              provider.isHostServerRunning ? Symbols.stop_rounded : Symbols.play_arrow_rounded,
                            ),
                            label: Text(
                              provider.isHostServerRunning
                                  ? t.companionRemote.session.stopServer
                                  : t.companionRemote.session.startServer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FocusableButton(
                          focusNode: _minimizeFocusNode,
                          onPressed: _close,
                          onBack: _close,
                          onNavigateUp: () => _closeFocusNode.requestFocus(),
                          onNavigateLeft: () => _toggleFocusNode.requestFocus(),
                          useBackgroundFocus: true,
                          child: FilledButton(onPressed: _close, child: Text(t.companionRemote.session.minimize)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusLine(BuildContext context, CompanionRemoteProvider provider) {
    if (provider.connectedDevice != null) {
      return Text(
        t.companionRemote.connectedTo(name: provider.connectedDevice!.name),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green),
      );
    }
    if (provider.isHostServerRunning) {
      return Text(
        t.companionRemote.session.serverRunning,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted),
      );
    }
    return Text(
      t.companionRemote.session.serverStopped,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted),
    );
  }

  Widget _buildServerStatus(BuildContext context, CompanionRemoteProvider provider) {
    final isRunning = provider.isHostServerRunning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? Colors.green : tokens(context).textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    isRunning ? t.companionRemote.session.serverRunning : t.companionRemote.session.serverStopped,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRunning
                        ? t.companionRemote.session.serverRunningDescription
                        : t.companionRemote.session.serverStoppedDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDevice(BuildContext context, CompanionRemoteProvider provider) {
    final device = provider.connectedDevice!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const AppIcon(Symbols.check_circle_rounded, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            Text(t.companionRemote.session.connected, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(device.name, style: Theme.of(context).textTheme.bodyLarge),
            Text(device.platform, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
              t.companionRemote.session.usePhoneToControl,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
