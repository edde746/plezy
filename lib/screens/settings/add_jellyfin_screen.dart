import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_registry.dart';
import '../../services/jellyfin_auth_service.dart';
import '../../services/jellyfin_endpoint_discovery.dart';
import '../../services/jellyfin_lan_discovery_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../profile/profile_switch_screen.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';
import '../../widgets/loading_indicator_box.dart';

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

/// Three-step form to add a Jellyfin server:
///   1. Probe URL candidates (`/System/Info/Public`).
///   2. Username + password (`/Users/AuthenticateByName`) **or** Quick Connect
///      (`/QuickConnect/Initiate` → poll → `/Users/AuthenticateWithQuickConnect`).
///   3. Persist via [ConnectionRegistry] and create a [ProfileConnection]
///      row binding the server to [targetProfile] (or the active profile,
///      if not provided). When the target *is* the active profile we also
///      register the client with the manager so libraries refresh
///      immediately; otherwise the binder picks it up on the next switch.
class AddJellyfinScreen extends StatefulWidget {
  /// When set, the new Jellyfin connection is bound to this profile via a
  /// [ProfileConnection] row. When null, falls back to the currently active
  /// profile (typical for the global Connections screen entry point).
  final Profile? targetProfile;
  final FutureOr<JellyfinConnectionAuthService> Function()? _authServiceFactory;
  final FutureOr<List<DiscoveredJellyfinServer>> Function()? _localDiscoveryFactory;

  const AddJellyfinScreen({
    super.key,
    this.targetProfile,
    @visibleForTesting FutureOr<JellyfinConnectionAuthService> Function()? authServiceFactory,
    @visibleForTesting FutureOr<List<DiscoveredJellyfinServer>> Function()? localDiscoveryFactory,
  }) : _authServiceFactory = authServiceFactory,
       _localDiscoveryFactory = localDiscoveryFactory;

  @override
  State<AddJellyfinScreen> createState() => _AddJellyfinScreenState();
}

class _AddJellyfinScreenState extends State<AddJellyfinScreen> with AsyncFormStateMixin, ControllerDisposerMixin {
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
  JellyfinQuickConnectInitiation? _qcInitiation;
  bool _qcCancelled = false;
  int _qcAttemptId = 0;
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
    _qcCancelled = true;
    _qcAttemptId++;
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
      final factory = widget._localDiscoveryFactory;
      final servers = factory != null
          ? await factory()
          : await JellyfinLanDiscoveryService().discover(responseWindow: const Duration(milliseconds: 1300));
      if (!mounted || attemptId != _localDiscoveryAttemptId) return;
      setState(() {
        _localServers = servers;
        _isDiscoveringLocalServers = false;
        _syncDiscoveredServerFocusNodes(servers);
      });
    } catch (e, st) {
      appLogger.w('Add Jellyfin local discovery failed', error: e, stackTrace: st);
      if (!mounted || attemptId != _localDiscoveryAttemptId) return;
      setState(() => _isDiscoveringLocalServers = false);
    }
  }

  void _syncDiscoveredServerFocusNodes(List<DiscoveredJellyfinServer> servers) {
    final ids = servers.map((server) => server.id).toSet();
    final removed = _discoveredServerFocusNodes.keys.where((id) => !ids.contains(id)).toList(growable: false);
    for (final id in removed) {
      _discoveredServerFocusNodes.remove(id)?.dispose();
    }
    for (final server in servers) {
      _discoveredServerFocusNodes.putIfAbsent(
        server.id,
        () => FocusNode(debugLabel: 'AddJellyfin:Discovered:${server.id}'),
      );
    }
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
    final input = JellyfinEndpointDiscovery.buildUserInputCandidates(_enteredUrls());
    if (input.probeBaseUrls.isEmpty) {
      setErrorText(t.addServer.enterJellyfinUrlError);
      return;
    }
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final endpoint = await auth.raceEndpoints(
          input.probeBaseUrls,
          baseUrlsToPersist: input.explicitBaseUrls,
          baseUrlValidationGroups: input.validationBaseUrlGroups,
        );
        final qcEnabled = await auth.isQuickConnectEnabled(endpoint.activeBaseUrl);
        if (!mounted) return;
        setState(() {
          _serverEndpoint = endpoint;
          _serverInfo = endpoint.serverInfo;
          _quickConnectEnabled = qcEnabled;
          _urlController.text = endpoint.baseUrls.join('\n');
        });
        // On TV, typing a username/password with a remote is misery — auto-jump
        // to Quick Connect when the server supports it. Mirrors the
        // PlatformDetector.isTV() default in add_plex_account_screen.dart.
        if (qcEnabled && PlatformDetector.isTV()) {
          unawaited(_startQuickConnect());
        } else {
          _requestFocusAfterFrame(_usernameFocus);
        }
      },
      errorMapper: (e) =>
          e is MediaServerUrlException ? e.message : t.addServer.couldNotReachServer(error: e.toString()),
    );
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
        if (e is MediaServerAuthException) return e.message;
        appLogger.e('Add Jellyfin failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
  }

  Future<void> _startQuickConnect() async {
    final info = _serverInfo;
    final endpoint = _serverEndpoint;
    if (info == null || endpoint == null) return;
    final attemptId = ++_qcAttemptId;
    setState(() => _qcCancelled = false);
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final storage = await StorageService.getInstance();
        final deviceId = await storage.getOrCreateClientIdentifier();

        final initiation = await auth.initiateQuickConnect(baseUrl: endpoint.activeBaseUrl, deviceId: deviceId);
        if (!_isCurrentQuickConnectAttempt(attemptId)) return;
        // Show the waiting panel without a spinner — opt-out of busy mid-flow
        // so the user-visible state matches "we're polling, nothing for you to do".
        setState(() => _qcInitiation = initiation);
        _requestFocusAfterFrame(_cancelQuickConnectFocus);
        setBusy(false);

        final connection = await auth.authenticateByQuickConnect(
          baseUrl: endpoint.activeBaseUrl,
          baseUrls: endpoint.baseUrls,
          secret: initiation.secret,
          deviceId: deviceId,
          serverInfo: info,
          shouldCancel: () => _qcCancelled || attemptId != _qcAttemptId,
        );

        if (!_isCurrentQuickConnectAttempt(attemptId)) return;
        if (connection == null) {
          // Either user cancelled or the secret expired before approval.
          // Cancellation is silent; expiry surfaces an error.
          setState(() => _qcInitiation = null);
          if (!_qcCancelled) setErrorText(t.auth.quickConnectExpired);
          return;
        }
        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        if (e is MediaServerAuthException) return e.message;
        appLogger.e('Jellyfin Quick Connect failed', error: e);
        return t.addServer.quickConnectFailed(error: e.toString());
      },
      shouldApplyState: () => attemptId == _qcAttemptId,
    );
    // Clear the QC panel after any error so the form re-shows.
    if (_isCurrentQuickConnectAttempt(attemptId) && errorText != null && _qcInitiation != null) {
      setState(() => _qcInitiation = null);
    }
  }

  bool _isCurrentQuickConnectAttempt(int attemptId) => mounted && attemptId == _qcAttemptId;

  void _cancelQuickConnect() {
    _qcAttemptId++;
    setState(() {
      _qcCancelled = true;
      _qcInitiation = null;
    });
    setBusy(false);
  }

  void _requestFocusAfterFrame(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !node.canRequestFocus) return;
      node.requestFocus();
    });
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

  List<String> _enteredUrls() {
    return _urlController.text
        .split(RegExp(r'[\n,]+'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  /// Shared persistence path for both username/password and Quick Connect:
  /// upsert the connection, attach a ProfileConnection to the bound profile,
  /// register with the live manager when binding to the active profile, and
  /// pop with success.
  Future<void> _persistAndExit(JellyfinConnection connection) async {
    if (!mounted) return;
    // Bind to the target profile (caller's choice) or the active one. On a
    // first-run Jellyfin-only sign-in there is no profile yet, so create and
    // activate a local profile before registering the server.
    final activeProvider = context.read<ActiveProfileProvider>();
    await activeProvider.initialize();
    if (!mounted) return;
    final targetProfile = widget.targetProfile;
    var boundProfile = targetProfile ?? activeProvider.active;
    if (shouldPromptForJellyfinProfileSelection(
      targetProfile: targetProfile,
      activeProfile: activeProvider.active,
      hasProfiles: activeProvider.profiles.isNotEmpty,
    )) {
      await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
      if (!mounted) return;
      boundProfile = activeProvider.active;
      if (boundProfile == null) {
        setErrorText(t.messages.noProfilesAvailable);
        return;
      }
    }
    if (shouldCreateLocalJellyfinProfile(
      targetProfile: targetProfile,
      activeProfile: boundProfile,
      hasProfiles: activeProvider.profiles.isNotEmpty,
    )) {
      final now = DateTime.now();
      final profile = Profile.local(
        id: 'local-${const Uuid().v4()}',
        displayName: connection.userName.isNotEmpty ? connection.userName : connection.serverName,
        sortOrder: now.millisecondsSinceEpoch,
        createdAt: now,
      );
      await context.read<ProfileRegistry>().upsert(profile);
      await activeProvider.activate(profile);
      if (!mounted) return;
      boundProfile = activeProvider.active ?? profile;
    }
    final bindProfile = boundProfile;
    if (bindProfile == null) {
      setErrorText(t.messages.noProfilesAvailable);
      return;
    }
    final boundToActive = bindProfile.id == activeProvider.activeId;

    await persistAndBindConnection(
      context: context,
      connection: connection,
      bindToProfile: ProfileConnection(
        profileId: bindProfile.id,
        connectionId: connection.id,
        userToken: connection.accessToken,
        userIdentifier: connection.userId,
        tokenAcquiredAt: DateTime.now(),
      ),
      addToManager: null,
    );

    if (!mounted) return;
    if (boundToActive) {
      await context.read<ActiveProfileBinder>().rebindIfActive(bindProfile.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<JellyfinConnectionAuthService> _buildAuthService() async {
    final authServiceFactory = widget._authServiceFactory;
    if (authServiceFactory != null) return await authServiceFactory();
    final pkg = await PackageInfo.fromPlatform();
    final deviceName = await _resolveDeviceName();
    return JellyfinConnectionAuthService(clientName: 'Plezy', clientVersion: pkg.version, deviceName: deviceName);
  }

  Future<String> _resolveDeviceName() async {
    // PackageInfo doesn't expose a device name; fall back to a generic label.
    // Jellyfin only shows this in the admin "Devices" list — fine to keep
    // simple until we add proper device_info_plus integration.
    return 'Plezy';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.addServer.addJellyfinTitle),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildBodyChildren(theme)),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBodyChildren(ThemeData theme) {
    if (_qcInitiation != null) {
      return [
        ..._buildQuickConnectPanel(theme),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
      ];
    }
    return [
      Text(t.addServer.jellyfinUrlsIntro, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        autofocus: true,
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
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (_) => _enteredUrls().isEmpty ? t.addServer.required : null,
      ),
      if (_serverInfo == null) ...[
        ..._buildLocalDiscoverySection(theme),
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
        _buildServerCard(theme),
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
          // Empty password is valid for some Jellyfin setups, so don't
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
        if (_quickConnectEnabled) ...[
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
      if (errorText != null) ...[
        const SizedBox(height: 12),
        Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
      ],
    ];
  }

  Widget _buildServerCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const AppIcon(Symbols.cloud_done_rounded, fill: 1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_serverInfo!.serverName, style: theme.textTheme.titleSmall),
                Text(
                  'Jellyfin ${_serverInfo!.version}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          FocusableButton(
            focusNode: _changeServerFocus,
            useBackgroundFocus: true,
            onNavigateUp: () => _urlFocus.requestFocus(),
            onNavigateDown: () => _usernameFocus.requestFocus(),
            onPressed: busy
                ? null
                : () => setState(() {
                    _clearResolvedServer();
                  }),
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      _clearResolvedServer();
                    }),
              child: Text(t.addServer.change),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLocalDiscoverySection(ThemeData theme) {
    if (_isDiscoveringLocalServers) {
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const LoadingIndicatorBox(size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(t.addServer.searchingLocalServers, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
      ];
    }

    if (_localServers.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      Text(t.addServer.localServers, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final server in _localServers) ...[
        _DiscoveredJellyfinServerTile(
          server: server,
          focusNode: _discoveredServerFocusNodes[server.id],
          onNavigateUp: () {
            final index = _localServers.indexOf(server);
            if (index <= 0) {
              _urlFocus.requestFocus();
              return;
            }
            _discoveredServerFocusNodes[_localServers[index - 1].id]?.requestFocus();
          },
          onNavigateDown: () {
            final index = _localServers.indexOf(server);
            if (index < 0 || index == _localServers.length - 1) {
              _findServerFocus.requestFocus();
              return;
            }
            _discoveredServerFocusNodes[_localServers[index + 1].id]?.requestFocus();
          },
          onTap: busy ? null : () => unawaited(_useDiscoveredServer(server)),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _buildQuickConnectPanel(ThemeData theme) {
    final code = _qcInitiation!.code;
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              t.auth.quickConnectCode,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            Text(
              code,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(t.auth.quickConnectInstructions, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicatorBox(),
          const SizedBox(width: 12),
          Text(t.auth.quickConnectWaiting, style: theme.textTheme.bodyMedium),
        ],
      ),
      const SizedBox(height: 20),
      FocusableButton(
        focusNode: _cancelQuickConnectFocus,
        useBackgroundFocus: true,
        onPressed: _cancelQuickConnect,
        child: OutlinedButton.icon(
          onPressed: _cancelQuickConnect,
          icon: const AppIcon(Symbols.close_rounded, fill: 1),
          label: Text(t.auth.quickConnectCancel),
        ),
      ),
    ];
  }
}

class _DiscoveredJellyfinServerTile extends StatelessWidget {
  final DiscoveredJellyfinServer server;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onTap;

  const _DiscoveredJellyfinServerTile({
    required this.server,
    required this.focusNode,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableWrapper(
      focusNode: focusNode,
      disableScale: true,
      borderRadius: 12,
      useForegroundFocusDecoration: true,
      descendantsAreFocusable: false,
      onSelect: onTap,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const AppIcon(Symbols.dns_rounded, fill: 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(server.name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        server.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
