import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../models/plex/plex_home.dart';
import '../../profiles/active_plex_identity.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../providers/companion_remote_provider.dart';
import '../../services/base_peer_service.dart';
import '../../services/settings_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';

import '../loading_indicator_box.dart';
import '../app_icon.dart';

@visibleForTesting
String companionRemotePairingErrorMessage(Object error) {
  if (error is PeerError) {
    return switch (error.type) {
      PeerErrorType.timeout => t.companionRemote.pairing.connectionTimedOut,
      PeerErrorType.connectionFailed || PeerErrorType.invalidSession => t.companionRemote.pairing.sessionNotFound,
      PeerErrorType.authFailed => t.companionRemote.pairing.authFailed,
      _ => error.message,
    };
  }

  final message = error.toString().replaceFirst('Exception: ', '');
  if (message.contains('timeout') || message.contains('Timed out')) {
    return t.companionRemote.pairing.connectionTimedOut;
  } else if (message.contains('Failed to connect')) {
    return t.companionRemote.pairing.sessionNotFound;
  } else if (message.contains('Authentication failed')) {
    return t.companionRemote.pairing.authFailed;
  }
  return t.companionRemote.pairing.failedToConnect(error: message);
}

/// Discovers LAN hosts and provides UI to connect to them.
class DiscoveryView extends StatefulWidget {
  const DiscoveryView({super.key});

  @override
  State<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<DiscoveryView> with ControllerDisposerMixin, MountedSetStateMixin {
  late final _hostAddressController = createTextEditingController();
  final _manualToggleFocusNode = FocusNode(debugLabel: 'CompanionManualToggle');
  final _hostAddressFocusNode = FocusNode(debugLabel: 'CompanionHostAddress');
  final _connectFocusNode = FocusNode(debugLabel: 'CompanionConnect');
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _errorMessage;
  bool _showManualEntry = false;
  bool _cryptoReady = false;
  bool _initializing = true;

  late final CompanionRemoteProvider _provider;
  StreamSubscription<List<DiscoveredHost>>? _discoverySubscription;
  List<DiscoveredHost> _hosts = [];
  bool _isSearching = true;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    _provider = context.read<CompanionRemoteProvider>();
    unawaited(_loadSavedManualHostAddress());
    _initCryptoAndDiscover();
  }

  Future<void> _loadSavedManualHostAddress() async {
    final settings = SettingsService.instanceOrNull ?? await SettingsService.getInstance();
    final hostAddress = settings.read(SettingsService.companionRemoteLastHostAddress);
    if (!mounted || hostAddress == null || _hostAddressController.text.isNotEmpty) return;
    setState(() {
      _hostAddressController.text = hostAddress;
      _showManualEntry = true;
    });
  }

  Future<void> _initCryptoAndDiscover() async {
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
      final home = await _resolveHome(identity?.account.id);
      if (!mounted) return;
      await _provider.ensureCryptoReady(
        home,
        connections: connections,
        activeProfile: activeProfile,
        profileConnections: profileConnections,
        identity: identity,
        plexHomeForConnection: plexHome.materializePlexHomeForConnection,
      );
    } catch (e) {
      appLogger.e('CompanionRemote: crypto init failed', error: e);
    }
    if (!mounted) return;

    // The "crypto init failed" card only surfaces once init has actually
    // finished — while it's running the section shows a loading state so we
    // don't flash an error at open, and a thrown init still resolves to a
    // stable (non-stuck) failure card.
    if (_provider.isCryptoReady) {
      setState(() {
        _cryptoReady = true;
        _initializing = false;
      });
      _startDiscovery();
    } else {
      setState(() {
        _cryptoReady = false;
        _initializing = false;
        _isSearching = false;
      });
    }
  }

  Future<PlexHome?> _resolveHome(String? connectionId) {
    if (connectionId == null) return Future<PlexHome?>.value();
    return context.read<PlexHomeService>().materializePlexHomeForConnection(connectionId);
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
    _discoverySubscription?.cancel();
    _searchTimeout?.cancel();
    _provider.stopDiscovery();
    _manualToggleFocusNode.dispose();
    _hostAddressFocusNode.dispose();
    _connectFocusNode.dispose();
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
      setState(() => _errorMessage = companionRemotePairingErrorMessage(e));
    } finally {
      setStateIfMounted(() => _isConnecting = false);
    }
  }

  Future<void> _saveManualHostAddress(String hostAddress) async {
    try {
      final settings = SettingsService.instanceOrNull ?? await SettingsService.getInstance();
      await settings.write(SettingsService.companionRemoteLastHostAddress, hostAddress);
    } catch (e) {
      appLogger.w('Failed to save companion remote host address', error: e);
    }
  }

  void _submitManualHost() {
    if (!_formKey.currentState!.validate()) return;
    final hostAddress = _hostAddressController.text.trim();
    unawaited(
      _connect(() async {
        await _provider.connectToManualHost(hostAddress);
        await _saveManualHostAddress(hostAddress);
      }),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'macos':
        return Symbols.desktop_mac_rounded;
      case 'windows':
        return Symbols.desktop_windows_rounded;
      case 'linux':
        return Symbols.computer_rounded;
      default:
        return Symbols.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: .stretch,
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
                    AppIcon(Symbols.error_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
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
    if (_initializing) {
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

    if (!_cryptoReady) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const AppIcon(Symbols.warning_amber_rounded, size: 48, color: Colors.orange),
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
              AppIcon(Symbols.devices_other_rounded, size: 48, color: tokens(context).textMuted),
              const SizedBox(height: 12),
              Text(
                t.companionRemote.pairing.noDevicesFound,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t.companionRemote.pairing.noDevicesHint,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.companionRemote.pairing.availableDevices, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._hosts.map(
          (host) => Card(
            child: ListTile(
              leading: AppIcon(_platformIcon(host.platform), size: 32),
              title: Text(host.name),
              subtitle: Text(host.platform),
              trailing: _isConnecting
                  ? const LoadingIndicatorBox(size: 24)
                  : const AppIcon(Symbols.arrow_forward_rounded),
              onTap: _isConnecting ? null : () => _connect(() => _provider.connectToDiscoveredHost(host)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntrySection() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        FocusableWrapper(
          focusNode: _manualToggleFocusNode,
          useBackgroundFocus: true,
          disableScale: true,
          borderRadius: 8,
          onSelect: () => setState(() => _showManualEntry = !_showManualEntry),
          child: InkWell(
            canRequestFocus: false,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            onTap: () => setState(() => _showManualEntry = !_showManualEntry),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AppIcon(
                    _showManualEntry ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.companionRemote.pairing.manualConnection,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showManualEntry) ...[
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                FocusableTextFormField(
                  controller: _hostAddressController,
                  focusNode: _hostAddressFocusNode,
                  decoration: InputDecoration(
                    labelText: t.companionRemote.session.hostAddress,
                    hintText: t.companionRemote.pairing.hostAddressHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const AppIcon(Symbols.computer_rounded),
                  ),
                  validator: (value) {
                    final hostAddress = value?.trim() ?? '';
                    if (hostAddress.isEmpty) {
                      return t.companionRemote.pairing.validationHostRequired;
                    }
                    if (hostAddress.split(':').length != 2) {
                      return t.companionRemote.pairing.validationHostFormat;
                    }
                    return null;
                  },
                  enabled: !_isConnecting,
                ),
                const SizedBox(height: 16),
                FocusableButton(
                  focusNode: _connectFocusNode,
                  onPressed: _isConnecting ? null : _submitManualHost,
                  child: FilledButton.icon(
                    onPressed: _isConnecting ? null : _submitManualHost,
                    icon: _isConnecting ? const LoadingIndicatorBox(size: 16) : const AppIcon(Symbols.link_rounded),
                    label: Text(_isConnecting ? t.companionRemote.pairing.connecting : t.common.connect),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
