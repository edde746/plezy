import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../i18n/strings.g.dart';
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
  bool _isCreatingSession = false;
  String? _errorMessage;
  List<String>? _hostAddresses; // Each format: "ip:port"

  @override
  void initState() {
    super.initState();
    // Defer to avoid notifyListeners() during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) => _createSession());
  }

  Future<void> _createSession() async {
    setState(() {
      _isCreatingSession = true;
      _errorMessage = null;
      _hostAddresses = null;
    });

    try {
      final provider = context.read<CompanionRemoteProvider>();
      final result = await provider.createSession();

      if (!mounted) return;
      setState(() {
        _isCreatingSession = false;
        _hostAddresses = result.addresses;
      });
    } catch (e) {
      appLogger.e('Failed to create companion remote session', error: e);
      if (!mounted) return;
      setState(() {
        _isCreatingSession = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.companionRemote.session.copiedToClipboard(label: label)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanionRemoteProvider>(
      builder: (context, provider, child) {
        if (_isCreatingSession) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t.companionRemote.session.creatingSession, style: Theme.of(context).textTheme.titleMedium),
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
              TextButton(onPressed: _createSession, child: Text(t.common.retry)),
            ],
          );
        }

        final session = provider.session;
        if (session == null || _hostAddresses == null || _hostAddresses!.isEmpty) {
          return AlertDialog(
            title: Text(t.common.error),
            content: Text(t.companionRemote.session.noSession),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.close))],
          );
        }

        // Extract port from first address (all share the same port)
        final port = _hostAddresses!.first.split(':').last;
        final ips = _hostAddresses!.map((a) => a.split(':').first).join(',');

        // URL-wrapped QR format: comma-separated IPs for multi-NIC support
        final qrData = 'https://plezy.app/scan#$ips|$port|${session.sessionId}|${session.pin}';

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
                            Text(
                              session.connectedDevice != null
                                  ? t.companionRemote.connectedTo(name: session.connectedDevice!.name)
                                  : t.companionRemote.session.waitingForConnection,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: session.connectedDevice != null
                                    ? Colors.green
                                    : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (session.connectedDevice == null) ...[
                    Text(
                      t.companionRemote.session.scanQrCode,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      t.companionRemote.session.orEnterManually,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ..._hostAddresses!.map(
                      (addr) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCodeCard(
                          context,
                          t.companionRemote.session.hostAddress,
                          addr,
                          onCopy: () => _copyToClipboard(addr, t.companionRemote.session.hostAddress),
                        ),
                      ),
                    ),
                    _buildCodeCard(
                      context,
                      t.companionRemote.session.sessionId,
                      session.sessionId,
                      onCopy: () => _copyToClipboard(session.sessionId, t.companionRemote.session.sessionId),
                    ),
                    const SizedBox(height: 12),
                    _buildCodeCard(
                      context,
                      t.companionRemote.session.pin,
                      session.pin,
                      onCopy: () => _copyToClipboard(session.pin, t.companionRemote.session.pin),
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 48),
                            const SizedBox(height: 8),
                            Text(t.companionRemote.session.connected, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(session.connectedDevice!.name, style: Theme.of(context).textTheme.bodyLarge),
                            Text(session.connectedDevice!.platform, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.companionRemote.session.usePhoneToControl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (session.connectedDevice != null)
                        TextButton.icon(
                          onPressed: () async {
                            await provider.leaveSession();
                            await _createSession();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(t.companionRemote.session.newSession),
                        ),
                      const SizedBox(width: 8),
                      FocusableButton(
                        onPressed: () async {
                          await provider.leaveSession();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: TextButton(
                          onPressed: () async {
                            await provider.leaveSession();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(t.common.disconnect),
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

  Widget _buildCodeCard(BuildContext context, String label, String code, {VoidCallback? onCopy}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: t.companionRemote.session.copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }
}
