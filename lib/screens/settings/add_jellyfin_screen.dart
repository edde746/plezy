import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_browser_dialect.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../services/jellyfin_auth_service.dart';
import '../../services/jellyfin_endpoint_discovery.dart';
import '../../services/jellyfin_lan_discovery_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/device_identity.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/quick_connect_code_panel.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';
import 'discovered_server_section.dart';
import 'probed_server_card.dart';
import 'quick_connect_flow_mixin.dart';

@visibleForTesting
Future<String> resolveJellyfinClientVersion({Future<PackageInfo> Function()? packageInfoLoader}) async {
  const fallbackVersion = '1.0';
  try {
    final packageInfo = await (packageInfoLoader == null ? PackageInfo.fromPlatform() : packageInfoLoader());
    final version = packageInfo.version.trim();
    if (version.isNotEmpty) return version;
    appLogger.w('Package version is empty; using Jellyfin client version $fallbackVersion');
  } catch (error, stackTrace) {
    appLogger.w(
      'Failed to resolve package version; using Jellyfin client version $fallbackVersion',
      error: error,
      stackTrace: stackTrace,
    );
  }
  return fallbackVersion;
}

@visibleForTesting
bool shouldCreateLocalJellyfinProfile({
  required Profile? targetProfile,
  required Profile? activeProfile,
  required bool hasProfiles,
}) {
  return targetProfile == null && activeProfile == null && !hasProfiles;
}

@visibleForTesting
bool shouldPromptForJellyfinProfileSelection({
  required Profile? targetProfile,
  required Profile? activeProfile,
  required bool hasProfiles,
}) {
  return targetProfile == null && activeProfile == null && hasProfiles;
}

/// Three-step form to add a Jellyfin or Emby server:
///   1. Probe URL candidates (`/System/Info/Public`).
///   2. Username + password (`/Users/AuthenticateByName`) or Quick Connect
///      when supported by the selected [dialect].
///   3. Persist via [ConnectionRegistry] and create a [ProfileConnection]
///      row binding the server to [targetProfile] (or the active profile,
///      if not provided). When the target *is* the active profile we also
///      register the client with the manager so libraries refresh
///      immediately; otherwise the binder picks it up on the next switch.
class AddJellyfinScreen extends StatefulWidget {
  /// When set, the new MediaBrowser connection is bound to this profile via a
  /// [ProfileConnection] row. When null, falls back to the currently active
  /// profile (typical for the global Connections screen entry point).
  final Profile? targetProfile;
  final MediaBrowserDialect dialect;
  final FutureOr<JellyfinConnectionAuthService> Function()? _authServiceFactory;
  final FutureOr<List<DiscoveredJellyfinServer>> Function()? _localDiscoveryFactory;

  const AddJellyfinScreen({
    super.key,
    this.targetProfile,
    this.dialect = MediaBrowserDialect.jellyfin,
    @visibleForTesting this._authServiceFactory,
    @visibleForTesting this._localDiscoveryFactory,
  });

  @override
  State<AddJellyfinScreen> createState() => _AddJellyfinScreenState();
}

class _AddJellyfinScreenState extends State<AddJellyfinScreen>
    with AsyncFormStateMixin, QuickConnectFlowMixin, ControllerDisposerMixin {
  late final _urlController = createTextEditingController();
  late final _usernameController = createTextEditingController();
  late final _passwordController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'AddJellyfin:Url');
  final _findServerFocus = FocusNode(debugLabel: 'AddJellyfin:FindServer');
  final _changeServerFocus = FocusNode(debugLabel: 'AddJellyfin:ChangeServer');
  final _usernameFocus = FocusNode(debugLabel: 'AddJellyfin:Username');
  // Owned so the username field can advance focus on Enter; mobile keyboards
  // act on `textInputAction: next` automatically but TV remotes / hardware
  // keyboards need the explicit `onFieldSubmitted` handler below.
  final _passwordFocus = FocusNode(debugLabel: 'AddJellyfin:Password');
  final _signInFocus = FocusNode(debugLabel: 'AddJellyfin:SignIn');
  final _quickConnectFocus = FocusNode(debugLabel: 'AddJellyfin:QuickConnect');
  final _cancelQuickConnectFocus = FocusNode(debugLabel: 'AddJellyfin:CancelQuickConnect');
  final _discoveredServerFocusNodes = <String, FocusNode>{};
  final _formKey = GlobalKey<FormState>();

  JellyfinServerInfo? _serverInfo;
  JellyfinEndpointRaceResult? _serverEndpoint;
  List<DiscoveredJellyfinServer> _localServers = const [];
  bool _isDiscoveringLocalServers = true;
  bool _quickConnectEnabled = false;
  int _localDiscoveryAttemptId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_discoverLocalServers());
  }

  @override
  void dispose() {
    // Short-circuit any in-flight Quick Connect poll so it doesn't try to
    // setState after the widget is gone.
    endQuickConnectFlow();
    _urlFocus.dispose();
    _findServerFocus.dispose();
    _changeServerFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _signInFocus.dispose();
    _quickConnectFocus.dispose();
    _cancelQuickConnectFocus.dispose();
    for (final node in _discoveredServerFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _discoverLocalServers() async {
    final attemptId = ++_localDiscoveryAttemptId;
    try {
      List<Connection> existingConnections = const <Connection>[];
      try {
        existingConnections = await context.read<ConnectionRegistry>().list();
      } on ProviderNotFoundException {
        // No ConnectionRegistry in the tree (tests / isolated subtrees).
      }
      final existing = existingConnections
          .whereType<JellyfinConnection>()
          .where((c) => c.dialect == widget.dialect)
          .map(
            (c) => DiscoveredJellyfinServer(
              address: c.baseUrl,
              id: c.serverMachineId,
              name: c.serverName,
              dialect: c.dialect,
            ),
          );

      final factory = widget._localDiscoveryFactory;
      final lanServers = factory != null
          ? await factory()
          : await JellyfinLanDiscoveryService().discover(
              dialect: widget.dialect,
              responseWindow: const Duration(milliseconds: 1300),
            );
      if (!mounted || attemptId != _localDiscoveryAttemptId) return;

      // Deduplicate by machine ID
      final combined = [...existing, ...lanServers];
      final seen = <String>{};
      final servers = JellyfinLanDiscoveryService.sortDiscoveredServers(combined.where((s) => seen.add(s.id)));
      setState(() {
        _localServers = servers;
        _isDiscoveringLocalServers = false;
        _syncDiscoveredServerFocusNodes(servers);
      });
    } catch (e, st) {
      appLogger.w('Add ${widget.dialect.productName} local discovery failed', error: e, stackTrace: st);
      if (!mounted || attemptId != _localDiscoveryAttemptId) return;
      setState(() => _isDiscoveringLocalServers = false);
    }
  }

  void _syncDiscoveredServerFocusNodes(List<DiscoveredJellyfinServer> servers) {
    syncDiscoveredFocusNodes(
      _discoveredServerFocusNodes,
      servers.map((s) => s.id),
      debugPrefix: 'AddJellyfin:Discovered',
    );
  }

  void _clearResolvedServer() {
    _serverEndpoint = null;
    _serverInfo = null;
    _quickConnectEnabled = false;
  }

  Future<void> _useDiscoveredServer(DiscoveredJellyfinServer server) async {
    if (busy) return;
    setState(() {
      _urlController.text = server.address;
      _clearResolvedServer();
    });
    await _probe();
  }

  Future<void> _probe() async {
    final input = JellyfinEndpointDiscovery.buildUserInputCandidates(_enteredUrls(), dialect: widget.dialect);
    if (input.probeBaseUrls.isEmpty) {
      setErrorText(t.addServer.enterMediaBrowserUrlError(product: widget.dialect.productName));
      return;
    }
    final autoStartQuickConnect = await runAsync<bool>(
      () async {
        final auth = await _buildAuthService();
        final endpoint = await auth.raceEndpoints(
          input.probeBaseUrls,
          baseUrlsToPersist: input.explicitBaseUrls,
          baseUrlValidationGroups: input.validationBaseUrlGroups,
        );
        final serverDialect = endpoint.serverInfo.dialect ?? widget.dialect;
        final qcEnabled = widget.dialect.supportsQuickConnect && serverDialect.supportsQuickConnect
            ? await auth.isQuickConnectEnabled(endpoint.activeBaseUrl)
            : false;
        if (!mounted) return false;
        setState(() {
          _serverEndpoint = endpoint;
          _serverInfo = endpoint.serverInfo;
          _quickConnectEnabled = qcEnabled;
          _urlController.text = endpoint.baseUrls.join('\n');
        });
        // On TV, typing a username/password with a remote is misery — auto-jump
        // to Quick Connect when the server supports it. Mirrors the
        // PlatformDetector.isTV() default in add_plex_account_screen.dart.
        final autoStart = qcEnabled && PlatformDetector.isTV();
        if (!autoStart) requestFocusAfterFrame(_usernameFocus);
        return autoStart;
      },
      errorMapper: (e) =>
          e is MediaServerUrlException ? e.display ?? e.message : t.addServer.couldNotReachServer(error: e.toString()),
    );
    // Sequenced after the probe's runAsync so busy stays set straight through
    // /QuickConnect/Initiate. Started from inside the probe body, the probe's
    // `finally` cleared busy mid-initiate, re-enabling the form — the focus
    // fallback from the removed tile/button then landed on the URL field and
    // auto-opened the TV keyboard over the Quick Connect panel.
    if (autoStartQuickConnect == true && mounted) await _startQuickConnect();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final info = _serverInfo;
    final endpoint = _serverEndpoint;
    if (info == null || endpoint == null) {
      await _probe();
      return;
    }
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final storage = await StorageService.getInstance();
        final deviceId = await storage.getOrCreateClientIdentifier();

        final connection = await auth.authenticateByName(
          baseUrl: endpoint.activeBaseUrl,
          baseUrls: endpoint.baseUrls,
          username: _usernameController.text,
          password: _passwordController.text,
          deviceId: deviceId,
          serverInfo: info,
        );

        if (!mounted) return;
        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        if (e is MediaServerAuthException) return e.display ?? e.message;
        appLogger.e('Add ${widget.dialect.productName} failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
  }

  Future<void> _startQuickConnect() async {
    final info = _serverInfo;
    final endpoint = _serverEndpoint;
    if (info == null || endpoint == null) return;
    if (!widget.dialect.supportsQuickConnect || !(info.dialect ?? widget.dialect).supportsQuickConnect) return;
    final attemptId = beginQuickConnectAttempt();
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final storage = await StorageService.getInstance();
        final deviceId = await storage.getOrCreateClientIdentifier();

        final initiation = await auth.initiateQuickConnect(baseUrl: endpoint.activeBaseUrl, deviceId: deviceId);
        if (!isCurrentQuickConnectAttempt(attemptId)) return;
        // Show the waiting panel without a spinner — opt-out of busy mid-flow
        // so the user-visible state matches "we're polling, nothing for you to do".
        showQuickConnectCode(initiation.code);
        requestFocusAfterFrame(_cancelQuickConnectFocus);
        setBusy(false);

        final connection = await auth.authenticateByQuickConnect(
          baseUrl: endpoint.activeBaseUrl,
          baseUrls: endpoint.baseUrls,
          secret: initiation.secret,
          deviceId: deviceId,
          serverInfo: info,
          shouldCancel: () => quickConnectAborted(attemptId),
        );

        if (!isCurrentQuickConnectAttempt(attemptId)) return;
        if (connection == null) {
          // Either user cancelled or the secret expired before approval.
          // Cancellation is silent; expiry surfaces an error.
          hideQuickConnectCode();
          if (!quickConnectCancelled) setErrorText(t.auth.quickConnectExpired);
          return;
        }
        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        if (e is MediaServerAuthException) return e.display ?? e.message;
        appLogger.e('Jellyfin Quick Connect failed', error: e);
        return t.addServer.quickConnectFailed(error: e.toString());
      },
      shouldApplyState: () => isCurrentQuickConnectAttempt(attemptId),
    );
    // Clear the QC panel after any error so the form re-shows.
    if (isCurrentQuickConnectAttempt(attemptId) && errorText != null && quickConnectCode != null) {
      hideQuickConnectCode();
    }
  }

  void _focusFirstDiscoveredServerOrFind() {
    if (_localServers.isEmpty) {
      _findServerFocus.requestFocus();
      return;
    }
    _discoveredServerFocusNodes[_localServers.first.id]?.requestFocus();
  }

  void _focusLastDiscoveredServerOrUrl() {
    if (_localServers.isEmpty) {
      _urlFocus.requestFocus();
      return;
    }
    _discoveredServerFocusNodes[_localServers.last.id]?.requestFocus();
  }

  List<String> _enteredUrls() => JellyfinEndpointDiscovery.parseUserEnteredUrls(_urlController.text);

  Future<void> _persistAndExit(JellyfinConnection connection) async {
    if (!mounted) return;
    await persistDirectServerConnectionAndExit(
      context: context,
      connection: connection,
      userIdentifier: connection.userId,
      userToken: connection.accessToken,
      defaultProfileName: connection.userName.isNotEmpty ? connection.userName : connection.serverName,
      targetProfile: widget.targetProfile,
      onError: setErrorText,
    );
  }

  Future<JellyfinConnectionAuthService> _buildAuthService() async {
    final authServiceFactory = widget._authServiceFactory;
    if (authServiceFactory != null) return await authServiceFactory();
    final clientVersion = await resolveJellyfinClientVersion();
    final deviceName = await _resolveDeviceName();
    return JellyfinConnectionAuthService(
      clientName: 'Plezy',
      clientVersion: clientVersion,
      deviceName: deviceName,
      dialect: widget.dialect,
    );
  }

  /// The raw name, not a header-sanitized one: the Jellyfin `MediaBrowser`
  /// header percent-encodes it, so the device list shows it verbatim.
  Future<String> _resolveDeviceName() async {
    final identity = await DeviceIdentityService.resolve();
    final name = identity.deviceName?.trim();
    return name == null || name.isEmpty ? 'Plezy' : name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.addServer.addMediaBrowserTitle(product: widget.dialect.productName)),
      slivers: [
        if (widget.dialect.supportsQuickConnect && quickConnectCode != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: .fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
              child: Center(
                child: QuickConnectCodePanel(
                  code: quickConnectCode!,
                  cancelFocusNode: _cancelQuickConnectFocus,
                  onCancel: cancelQuickConnect,
                  errorText: errorText,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: .stretch, children: _buildBodyChildren(theme)),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildBodyChildren(ThemeData theme) {
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        // Native on every TV: on Apple TV `automatic` would route this
        // wrap-to-4-lines field to the Flutter overlay, but it is logically
        // single-line URL input the system keyboard handles (#1051, #1079).
        tvTextInputPresentation: TvTextInputPresentation.platform,
        autofocus: true,
        tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
        keyboardType: TextInputType.url,
        minLines: 1,
        maxLines: 4,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        onChanged: (_) {
          if (_serverInfo == null && _serverEndpoint == null && !_quickConnectEnabled) return;
          setState(() {
            _clearResolvedServer();
          });
        },
        onNavigateDown: _serverInfo == null
            ? _focusFirstDiscoveredServerOrFind
            : () => _changeServerFocus.requestFocus(),
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addServer.serverUrls,
          // URL example — intentionally not localized.
          hintText: widget.dialect.exampleBaseUrl,
          helperText: _serverInfo == null ? t.addServer.serverUrlsHelper : null,
          prefixIcon: BackendBadge(backend: widget.dialect.backend, size: 20),
        ),
        validator: (_) => _enteredUrls().isEmpty ? t.addServer.required : null,
      ),
      if (_serverInfo == null) ...[
        DiscoveredServerSection<DiscoveredJellyfinServer>(
          isDiscovering: _isDiscoveringLocalServers,
          discoveringText: t.addServer.searchingLocalMediaBrowserServers(product: widget.dialect.productName),
          sectionTitle: t.addServer.localMediaBrowserServers(product: widget.dialect.productName),
          servers: _localServers,
          idOf: (s) => s.id,
          nameOf: (s) => s.name,
          addressOf: (s) => s.address,
          leadingBuilder: (s) => BackendBadge(backend: s.dialect.backend, size: 24),
          focusNodes: _discoveredServerFocusNodes,
          navigateUpFromFirst: _urlFocus,
          navigateDownFromLast: _findServerFocus,
          onSelect: (server) => unawaited(_useDiscoveredServer(server)),
          enabled: !busy,
        ),
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _findServerFocus,
          useBackgroundFocus: true,
          onNavigateUp: _focusLastDiscoveredServerOrUrl,
          onPressed: busy ? null : _probe,
          child: FilledButton.icon(
            onPressed: busy ? null : _probe,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
            label: Text(t.addServer.findServer),
          ),
        ),
      ] else ...[
        const SizedBox(height: 16),
        ProbedServerCard(
          leading: BackendBadge(backend: (_serverInfo!.dialect ?? widget.dialect).backend, size: 28),
          title: _serverInfo!.serverName,
          subtitle: '${widget.dialect.productName} ${_serverInfo!.version}',
          changeFocusNode: _changeServerFocus,
          onNavigateUp: () => _urlFocus.requestFocus(),
          onNavigateDown: () => _usernameFocus.requestFocus(),
          onChange: () => setState(() {
            _clearResolvedServer();
          }),
          enabled: !busy,
        ),
        const SizedBox(height: 16),
        FocusableTextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !busy,
          onNavigateUp: () => _changeServerFocus.requestFocus(),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: busy ? null : (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: t.addServer.username,
            prefixIcon: const AppIcon(Symbols.person_rounded, fill: 1),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
        ),
        const SizedBox(height: 12),
        FocusableTextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: busy ? null : (_) => _signIn(),
          decoration: InputDecoration(
            labelText: t.addServer.password,
            prefixIcon: const AppIcon(Symbols.lock_rounded, fill: 1),
          ),
          // Empty passwords are valid on some MediaBrowser servers, so don't
          // require a value.
        ),
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _signInFocus,
          useBackgroundFocus: true,
          onPressed: busy ? null : _signIn,
          child: FilledButton.icon(
            onPressed: busy ? null : _signIn,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
            label: Text(t.addServer.signIn),
          ),
        ),
        if (widget.dialect.supportsQuickConnect && _quickConnectEnabled) ...[
          const SizedBox(height: 12),
          FocusableButton(
            focusNode: _quickConnectFocus,
            useBackgroundFocus: true,
            onPressed: busy ? null : _startQuickConnect,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _startQuickConnect,
              icon: const AppIcon(Symbols.tap_and_play_rounded, fill: 1),
              label: Text(t.auth.useQuickConnect),
            ),
          ),
        ],
      ],
      ...buildInlineError(theme),
    ];
  }
}
