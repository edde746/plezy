import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/companion_remote_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/app_logger.dart';

/// Discovers LAN hosts and provides UI to connect to them.
class DiscoveryView extends StatefulWidget {
  const DiscoveryView({super.key});

  @override
  State<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<DiscoveryView> {
  final _hostAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _errorMessage;
  bool _showManualEntry = false;
  bool _cryptoReady = false;

  late final CompanionRemoteProvider _provider;
  StreamSubscription<List<DiscoveredHost>>? _discoverySubscription;
  List<DiscoveredHost> _hosts = [];
  bool _isSearching = true;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    _provider = context.read<CompanionRemoteProvider>();
    _initCryptoAndDiscover();
  }

  Future<void> _initCryptoAndDiscover() async {
    final home = context.read<UserProfileProvider>().home;
    await _provider.ensureCryptoReady(home);
    if (!mounted) return;

    if (_provider.isCryptoReady) {
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
    final stream = _provider.discoverHosts();
    if (stream == null) return;

    _discoverySubscription = stream.listen((hosts) {
      if (mounted) {
        setState(() {
          _hosts = hosts;
          if (hosts.isNotEmpty) _isSearching = false;
        });
      }
    });

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
    _provider.stopDiscovery();
    super.dispose();
  }

  Future<void> _connect(Future<void> Function() action) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      _provider.stopDiscovery();
      await action();
    } catch (e) {
      appLogger.e('Failed to connect', error: e);
      if (!mounted) return;
      setState(() => _errorMessage = _parseErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          _buildDiscoverySection(),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

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
              Text(t.companionRemote.pairing.cryptoInitFailed, textAlign: TextAlign.center),
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
              const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: 16),
              Text(t.companionRemote.pairing.searchingForDevices, style: Theme.of(context).textTheme.bodyMedium),
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
        Text(t.companionRemote.pairing.availableDevices, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._hosts.map((host) => Card(
              child: ListTile(
                leading: Icon(_platformIcon(host.platform), size: 32),
                title: Text(host.name),
                subtitle: Text(host.platform),
                trailing: _isConnecting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward),
                onTap: _isConnecting ? null : () => _connect(() => _provider.connectToDiscoveredHost(host)),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
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
                    if (value.split(':').length != 2) {
                      return t.companionRemote.pairing.validationHostFormat;
                    }
                    return null;
                  },
                  enabled: !_isConnecting,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : () {
                          if (!_formKey.currentState!.validate()) return;
                          _connect(() => _provider.connectToManualHost(_hostAddressController.text.trim()));
                        },
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
