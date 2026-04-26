import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_plex_identity.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../providers/companion_remote_provider.dart';
import '../../focus/focusable_button.dart';
import '../../utils/app_logger.dart';

class RemoteSessionDialog extends StatefulWidget {
  const RemoteSessionDialog({super.key});

  @override
  State<RemoteSessionDialog> createState() => _RemoteSessionDialogState();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RemoteSessionDialog(),
    );
  }
}

class _RemoteSessionDialogState extends State<RemoteSessionDialog> {
  bool _isStarting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureServerRunning());
  }

  Future<void> _ensureServerRunning() async {
    final provider = context.read<CompanionRemoteProvider>();

    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final connections = context.read<ConnectionRegistry>();
      final activeProfile = context.read<ActiveProfileProvider>();
      final profileConnections = context.read<ProfileConnectionRegistry>();
      final plexHome = context.read<PlexHomeService>();
      final identity = await resolveActivePlexIdentity(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
      );
      if (!mounted) return;
      final home = identity == null ? null : await plexHome.materializePlexHomeForConnection(identity.account.id);
      if (!mounted) return;
      final ok = await provider.ensureCryptoReady(
        home,
        connections: connections,
        activeProfile: activeProfile,
        profileConnections: profileConnections,
        identity: identity,
        plexHomeForConnection: plexHome.materializePlexHomeForConnection,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _isStarting = false;
          _errorMessage = t.companionRemote.pairing.cryptoInitFailed;
        });
        return;
      }
      if (!provider.isHostServerRunning) {
        await provider.startHostServer();
      }

      if (mounted) setState(() => _isStarting = false);
    } catch (e) {
      appLogger.e('Failed to start companion remote server', error: e);
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleServer() async {
    final provider = context.read<CompanionRemoteProvider>();
    if (provider.isHostServerRunning) {
      await provider.stopHostServer();
    } else {
      await _ensureServerRunning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanionRemoteProvider>(
      builder: (context, provider, child) {
        if (_isStarting) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.companionRemote.session.failedToCreate),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.close)),
              TextButton(onPressed: _ensureServerRunning, child: Text(t.common.retry)),
            ],
          );
        }

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.companionRemote.title, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            _buildStatusLine(context, provider),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Server status card
                  _buildServerStatus(context, provider),

                  // Connected device info
                  if (provider.connectedDevice != null) ...[
                    const SizedBox(height: 16),
                    _buildConnectedDevice(context, provider),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _toggleServer,
                        icon: Icon(provider.isHostServerRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          provider.isHostServerRunning
                              ? t.companionRemote.session.stopServer
                              : t.companionRemote.session.startServer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FocusableButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(t.companionRemote.session.minimize),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
      );
    }
    return Text(
      t.companionRemote.session.serverStopped,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: isRunning ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
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
