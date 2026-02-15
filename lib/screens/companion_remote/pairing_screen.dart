import '../../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/companion_remote_provider.dart';
import '../../utils/formatters.dart';
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

  bool get _isMobile => AppPlatform.isAndroid || AppPlatform.isIOS;

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
        _errorMessage = t.companionRemote.pairing.failedToLoadRecent(error: e.toString());
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
      return t.companionRemote.pairing.connectionTimedOut;
    } else if (error.contains('Failed to connect')) {
      return t.companionRemote.pairing.sessionNotFound;
    }
    return t.companionRemote.pairing.failedToConnect(error: error.replaceAll('Exception: ', ''));
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
        _errorMessage = t.companionRemote.pairing.invalidQrCode;
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
        title: Text(t.companionRemote.connectToDevice),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isDiscovering ? null : _loadRecentSessions,
              tooltip: t.common.refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(t.companionRemote.pairing.recent), icon: const Icon(Icons.history)),
              if (_isMobile)
                ButtonSegment(value: _scanTabIndex, label: Text(t.companionRemote.pairing.scan), icon: const Icon(Icons.qr_code_scanner)),
              ButtonSegment(value: _manualTabIndex, label: Text(t.companionRemote.pairing.manual), icon: const Icon(Icons.keyboard)),
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
                                  ? t.companionRemote.pairing.cameraPermissionRequired
                                  : t.companionRemote.pairing.cameraError(error: error.errorDetails?.message ?? error.errorCode.name),
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
                t.companionRemote.pairing.scanInstruction,
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
                t.companionRemote.pairing.recentConnections,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t.companionRemote.pairing.quickReconnect,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isDiscovering) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(t.common.loading, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ] else if (sessions.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.devices_other, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(t.companionRemote.pairing.noRecentConnections, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          t.companionRemote.pairing.connectUsingManual,
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
    return formatRelativeTime(date);
  }

  Future<void> _showRemoveSessionDialog(RecentRemoteSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.companionRemote.pairing.removeRecentConnection),
        content: Text(t.companionRemote.pairing.removeConfirm(name: session.deviceName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.common.remove)),
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
            Text(t.companionRemote.pairing.pairWithDesktop, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              t.companionRemote.pairing.enterSessionDetails,
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
                labelText: t.companionRemote.session.hostAddress,
                hintText: t.companionRemote.pairing.hostAddressHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.computer),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_hostAddressController),
                  tooltip: t.common.paste,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return t.companionRemote.pairing.validationHostRequired;
                }
                // Validate IP:port format
                final parts = value.split(':');
                if (parts.length != 2) {
                  return t.companionRemote.pairing.validationHostFormat;
                }
                return null;
              },
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sessionIdController,
              decoration: InputDecoration(
                labelText: t.companionRemote.session.sessionId,
                hintText: t.companionRemote.pairing.sessionIdHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_sessionIdController),
                  tooltip: t.common.paste,
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
                  return t.companionRemote.pairing.validationSessionIdRequired;
                }
                if (value.length != 8) {
                  return t.companionRemote.pairing.validationSessionIdLength;
                }
                return null;
              },
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: t.companionRemote.session.pin,
                hintText: t.companionRemote.pairing.pinHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(_pinController),
                  tooltip: t.common.paste,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return t.companionRemote.pairing.validationPinRequired;
                }
                if (value.length != 6) {
                  return t.companionRemote.pairing.validationPinLength;
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
              label: Text(_isConnecting ? t.companionRemote.pairing.connecting : t.common.connect),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(t.companionRemote.pairing.tips, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildTipCard(
              context,
              Icons.computer,
              t.companionRemote.pairing.tipDesktop,
            ),
            if (_isMobile) ...[
              const SizedBox(height: 8),
              _buildTipCard(
                context,
                Icons.qr_code,
                t.companionRemote.pairing.tipScan,
              ),
            ],
            const SizedBox(height: 8),
            _buildTipCard(context, Icons.wifi, t.companionRemote.pairing.tipWifi),
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
