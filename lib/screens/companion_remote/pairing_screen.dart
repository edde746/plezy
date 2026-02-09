import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/companion_remote_provider.dart';
import '../../models/companion_remote/recent_remote_session.dart';
import '../../utils/app_logger.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _hostAddressController = TextEditingController();
  final _sessionIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _connectingSessionId;
  bool _isDiscovering = false;
  String? _errorMessage;
  int _selectedTab = 0;

  // QR scanner state
  MobileScannerController? _scannerController;
  String? _lastScannedCode;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // Tab indices shift when scan tab is present
  int get _scanTabIndex => _isMobile ? 1 : -1;
  int get _manualTabIndex => _isMobile ? 2 : 1;

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
  }

  @override
  void dispose() {
    _hostAddressController.dispose();
    _sessionIdController.dispose();
    _pinController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSessions() async {
    setState(() {
      _isDiscovering = true;
      _errorMessage = null;
    });

    try {
      await context.read<CompanionRemoteProvider>().loadRecentSessions();
      setState(() {
        _isDiscovering = false;
      });
    } catch (e) {
      appLogger.e('Failed to load recent sessions', error: e);
      setState(() {
        _isDiscovering = false;
        _errorMessage = 'Failed to load recent sessions: ${e.toString()}';
      });
    }
  }

  Future<void> _connectToRecentSession(RecentRemoteSession session) async {
    setState(() {
      _isConnecting = true;
      _connectingSessionId = session.sessionId;
      _errorMessage = null;
    });

    try {
      await context.read<CompanionRemoteProvider>().connectToRecentSession(session);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      appLogger.e('Failed to connect to recent session', error: e);
      setState(() {
        _isConnecting = false;
        _connectingSessionId = null;
        _errorMessage = _parseErrorMessage(e.toString());
      });
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<CompanionRemoteProvider>();
      await provider.joinSession(
        _sessionIdController.text.trim().toUpperCase(),
        _pinController.text.trim(),
        _hostAddressController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      appLogger.e('Failed to join remote session', error: e);
      setState(() {
        _isConnecting = false;
        _errorMessage = _parseErrorMessage(e.toString());
      });
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('timeout') || error.contains('Timed out')) {
      return 'Connection timed out. Please check the session ID and PIN.';
    } else if (error.contains('Failed to connect')) {
      return 'Could not find the session. Please check your credentials.';
    }
    return 'Failed to connect: ${error.replaceAll('Exception: ', '')}';
  }

  void _handleQrCode(String data) {
    // Debounce: don't process the same code twice
    if (data == _lastScannedCode) return;
    _lastScannedCode = data;

    // New format: ip|port|sessionId|pin (4 parts separated by pipe)
    final parts = data.split('|');
    if (parts.length == 4) {
      final ip = parts[0];
      final port = parts[1];
      final sessionId = parts[2];
      final pin = parts[3];
      final hostAddress = '$ip:$port';

      _scannerController?.stop();
      setState(() {
        _errorMessage = null;
        _isConnecting = true;
      });
      // Connect directly instead of going through _connect() which requires Form validation
      _connectWithCredentials(sessionId, pin, hostAddress);
    } else {
      setState(() {
        _errorMessage = 'Invalid QR code format - expected 4 parts (ip|port|sessionId|pin)';
      });
    }
  }

  Future<void> _connectWithCredentials(String sessionId, String pin, String hostAddress) async {
    try {
      final provider = context.read<CompanionRemoteProvider>();
      await provider.joinSession(sessionId.trim().toUpperCase(), pin.trim(), hostAddress.trim());

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      appLogger.e('Failed to join remote session', error: e);
      _lastScannedCode = null; // Allow re-scanning
      setState(() {
        _isConnecting = false;
        _errorMessage = _parseErrorMessage(e.toString());
      });
      _scannerController?.start();
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        controller.text = data!.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Device'),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isDiscovering ? null : _loadRecentSessions,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 0, label: Text('Recent'), icon: Icon(Icons.history)),
              if (_isMobile)
                ButtonSegment(value: _scanTabIndex, label: const Text('Scan'), icon: const Icon(Icons.qr_code_scanner)),
              ButtonSegment(value: _manualTabIndex, label: const Text('Manual'), icon: const Icon(Icons.keyboard)),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> selection) {
              setState(() {
                _selectedTab = selection.first;
              });
            },
          ),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) return _buildDiscoveryTab();
    if (_selectedTab == _scanTabIndex) return _buildScanTab();
    return _buildManualEntryTab();
  }

  Widget _buildScanTab() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scannerController ??= MobileScannerController(),
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _handleQrCode(barcode!.rawValue!);
                    }
                  },
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.no_photography, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              error.errorCode == MobileScannerErrorCode.permissionDenied
                                  ? 'Camera permission is required to scan QR codes.\nPlease grant camera access in your device settings.'
                                  : 'Could not start camera: ${error.errorDetails?.message ?? error.errorCode.name}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Text(
                'Point your camera at the QR code shown on your desktop',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryTab() {
    return Consumer<CompanionRemoteProvider>(
      builder: (context, provider, child) {
        final sessions = provider.recentSessions;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.history, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Recent Connections',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quickly reconnect to previously paired devices',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isDiscovering) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text('Loading...', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ] else if (sessions.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.devices_other, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No recent connections', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Connect to a device using Manual entry to get started',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...sessions.map((session) {
                  final isThisConnecting = _isConnecting && _connectingSessionId == session.sessionId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.computer, size: 40),
                      title: Text(session.deviceName),
                      subtitle: Text(
                        '${session.platform}\n'
                        'Session: ${session.sessionId}\n'
                        'Last used: ${_formatDate(session.lastConnected)}',
                      ),
                      isThreeLine: true,
                      trailing: isThisConnecting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward),
                      onTap: _isConnecting ? null : () => _connectToRecentSession(session),
                      onLongPress: () => _showRemoveSessionDialog(session),
                    ),
                  );
                }),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _showRemoveSessionDialog(RecentRemoteSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Recent Connection'),
        content: Text('Remove "${session.deviceName}" from recent connections?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<CompanionRemoteProvider>().removeRecentSession(session.sessionId);
    }
  }

  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.keyboard, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text('Pair with Desktop', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Enter the session details shown on your desktop device',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _hostAddressController,
              decoration: InputDecoration(
                labelText: 'Host Address',
                hintText: '192.168.1.100:48632',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.computer),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_hostAddressController),
                  tooltip: 'Paste',
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter host address';
                }
                // Validate IP:port format
                final parts = value.split(':');
                if (parts.length != 2) {
                  return 'Format must be IP:port (e.g., 192.168.1.100:48632)';
                }
                return null;
              },
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sessionIdController,
              decoration: InputDecoration(
                labelText: 'Session ID',
                hintText: 'Enter 8-character session ID',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_sessionIdController),
                  tooltip: 'Paste',
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(8),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(text: newValue.text.toUpperCase());
                }),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session ID';
                }
                if (value.length != 8) {
                  return 'Session ID must be 8 characters';
                }
                return null;
              },
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'Enter 6-digit PIN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_pinController),
                  tooltip: 'Paste',
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a PIN';
                }
                if (value.length != 6) {
                  return 'PIN must be 6 digits';
                }
                return null;
              },
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isConnecting ? null : _connect,
              icon: _isConnecting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('Tips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildTipCard(
              context,
              Icons.computer,
              'Open Plezy on your desktop and enable Companion Remote from settings or menu',
            ),
            if (_isMobile) ...[
              const SizedBox(height: 8),
              _buildTipCard(
                context,
                Icons.qr_code,
                'Use the Scan tab to quickly pair by scanning the QR code on your desktop',
              ),
            ],
            const SizedBox(height: 8),
            _buildTipCard(context, Icons.wifi, 'Make sure both devices are on the same WiFi network'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, IconData icon, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
