import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/companion_remote_provider.dart';
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
  String? _hostAddress; // Format: "ip:port"

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    setState(() {
      _isCreatingSession = true;
      _errorMessage = null;
      _hostAddress = null;
    });

    try {
      final provider = context.read<CompanionRemoteProvider>();
      final result = await provider.createSession();

      setState(() {
        _isCreatingSession = false;
        _hostAddress = result.address;
      });
    } catch (e) {
      appLogger.e('Failed to create companion remote session', error: e);
      setState(() {
        _isCreatingSession = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 2)));
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
                  Text('Creating remote session...', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          );
        }

        if (_errorMessage != null) {
          return AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Failed to create remote session:'),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              TextButton(onPressed: _createSession, child: const Text('Retry')),
            ],
          );
        }

        final session = provider.session;
        if (session == null || _hostAddress == null) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('No session available'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          );
        }

        // Parse IP and port from hostAddress
        final addressParts = _hostAddress!.split(':');
        final ip = addressParts[0];
        final port = addressParts[1];

        // New QR format: ip|port|sessionId|pin (using pipe separator)
        final qrData = '$ip|$port|${session.sessionId}|${session.pin}';

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
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
                            Text('Companion Remote', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              session.connectedDevice != null
                                  ? 'Connected to ${session.connectedDevice!.name}'
                                  : 'Waiting for connection...',
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
                    Text('Scan QR Code', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                      'Or enter manually',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildCodeCard(
                      context,
                      'Host Address',
                      _hostAddress!,
                      onCopy: () => _copyToClipboard(_hostAddress!, 'Host Address'),
                    ),
                    const SizedBox(height: 12),
                    _buildCodeCard(
                      context,
                      'Session ID',
                      session.sessionId,
                      onCopy: () => _copyToClipboard(session.sessionId, 'Session ID'),
                    ),
                    const SizedBox(height: 12),
                    _buildCodeCard(context, 'PIN', session.pin, onCopy: () => _copyToClipboard(session.pin, 'PIN')),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 48),
                            const SizedBox(height: 8),
                            Text('Connected', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(session.connectedDevice!.name, style: Theme.of(context).textTheme.bodyLarge),
                            Text(session.connectedDevice!.platform, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Use your mobile device to control this app',
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
                          label: const Text('New Session'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await provider.leaveSession();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Disconnect'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Minimize')),
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
            IconButton(icon: const Icon(Icons.copy), onPressed: onCopy, tooltip: 'Copy to clipboard'),
          ],
        ),
      ),
    );
  }
}
