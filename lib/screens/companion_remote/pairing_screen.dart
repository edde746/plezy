import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/companion_remote_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/app_logger.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _hostAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _errorMessage;
  bool _showManualEntry = false;
  bool _cryptoReady = false;

  StreamSubscription<List<DiscoveredHost>>? _discoverySubscription;
  List<DiscoveredHost> _hosts = [];
  bool _isSearching = true;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    _initCryptoAndDiscover();
  }

  Future<void> _initCryptoAndDiscover() async {
    final provider = context.read<CompanionRemoteProvider>();
    final home = context.read<UserProfileProvider>().home;
    await provider.ensureCryptoReady(home);
    if (!mounted) return;

    if (provider.isCryptoReady) {
      setState(() => _cryptoReady = true);
      _startDiscovery();
    } else {
      setState(() {
        _cryptoReady = false;
        _isSearching = false;
        _errorMessage = t.companionRemote.pairing.cryptoInitFailed;
      });
    }
  }

  void _startDiscovery() {
    final provider = context.read<CompanionRemoteProvider>();
    final stream = provider.discoverHosts();
    if (stream == null) return;

    _discoverySubscription = stream.listen((hosts) {
      if (mounted) {
        setState(() {
          _hosts = hosts;
          if (hosts.isNotEmpty) _isSearching = false;
        });
      }
    });

    // Show "no devices found" after 10 seconds of no results
    _searchTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _hosts.isEmpty) {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _hostAddressController.dispose();
    _discoverySubscription?.cancel();
    _searchTimeout?.cancel();
    context.read<CompanionRemoteProvider>().stopDiscovery();
    super.dispose();
  }

  Future<void> _connectToHost(DiscoveredHost host) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<CompanionRemoteProvider>();
      await provider.connectToDiscoveredHost(host);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      appLogger.e('Failed to connect to host', error: e);
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = _parseErrorMessage(e.toString());
      });
    }
  }

  Future<void> _connectManual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<CompanionRemoteProvider>();
      await provider.connectToManualHost(_hostAddressController.text.trim());

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      appLogger.e('Failed to connect to manual host', error: e);
      if (!mounted) return;
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
    } else if (error.contains('Authentication failed')) {
      return t.companionRemote.pairing.authFailed;
    }
    return t.companionRemote.pairing.failedToConnect(error: error.replaceAll('Exception: ', ''));
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'macos':
        return Icons.desktop_mac;
      case 'windows':
        return Icons.desktop_windows;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.companionRemote.connectToDevice),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.devices, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            t.companionRemote.pairing.pairWithDesktop,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.companionRemote.pairing.discoveryDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

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

          // Discovered hosts
          _buildDiscoverySection(),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Manual entry fallback
          _buildManualEntrySection(),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection() {
    if (!_cryptoReady) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                t.companionRemote.pairing.cryptoInitFailed,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isSearching && _hosts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                t.companionRemote.pairing.searchingForDevices,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_hosts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.devices_other, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                t.companionRemote.pairing.noDevicesFound,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t.companionRemote.pairing.noDevicesHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.companionRemote.pairing.availableDevices,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._hosts.map((host) => Card(
              child: ListTile(
                leading: Icon(_platformIcon(host.platform), size: 32),
                title: Text(host.name),
                subtitle: Text(host.platform),
                trailing: _isConnecting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward),
                onTap: _isConnecting ? null : () => _connectToHost(host),
              ),
            )),
      ],
    );
  }

  Widget _buildManualEntrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showManualEntry = !_showManualEntry),
          child: Row(
            children: [
              Icon(
                _showManualEntry ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                t.companionRemote.pairing.manualConnection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        if (_showManualEntry) ...[
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _hostAddressController,
                  decoration: InputDecoration(
                    labelText: t.companionRemote.session.hostAddress,
                    hintText: t.companionRemote.pairing.hostAddressHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.computer),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.companionRemote.pairing.validationHostRequired;
                    }
                    final parts = value.split(':');
                    if (parts.length != 2) {
                      return t.companionRemote.pairing.validationHostFormat;
                    }
                    return null;
                  },
                  enabled: !_isConnecting,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isConnecting ? null : _connectManual,
                  icon: _isConnecting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.link),
                  label: Text(_isConnecting ? t.companionRemote.pairing.connecting : t.common.connect),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
