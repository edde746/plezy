import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_registry.dart';
import '../../services/jellyfin_auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
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
///   1. Probe URL (`/System/Info/Public`).
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

  const AddJellyfinScreen({super.key, this.targetProfile});

  @override
  State<AddJellyfinScreen> createState() => _AddJellyfinScreenState();
}

class _AddJellyfinScreenState extends State<AddJellyfinScreen> with AsyncFormStateMixin {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // Owned so the username field can advance focus on Enter; mobile keyboards
  // act on `textInputAction: next` automatically but TV remotes / hardware
  // keyboards need the explicit `onFieldSubmitted` handler below.
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  JellyfinServerInfo? _serverInfo;
  bool _quickConnectEnabled = false;
  JellyfinQuickConnectInitiation? _qcInitiation;
  bool _qcCancelled = false;
  int _qcAttemptId = 0;

  @override
  void dispose() {
    // Short-circuit any in-flight Quick Connect poll so it doesn't try to
    // setState after the widget is gone.
    _qcCancelled = true;
    _qcAttemptId++;
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setErrorText(t.addServer.enterJellyfinUrlError);
      return;
    }
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        // Run the probe and the QC capability check in parallel — the latter
        // is independent and just tells the UI whether to surface the button.
        final probeFuture = auth.probe(url);
        final qcFuture = auth.isQuickConnectEnabled(url);
        final info = await probeFuture;
        final qcEnabled = await qcFuture;
        if (!mounted) return;
        setState(() {
          _serverInfo = info;
          _quickConnectEnabled = qcEnabled;
        });
        // On TV, typing a username/password with a remote is misery — auto-jump
        // to Quick Connect when the server supports it. Mirrors the
        // PlatformDetector.isTV() default in add_plex_account_screen.dart.
        if (qcEnabled && PlatformDetector.isTV()) {
          unawaited(_startQuickConnect());
        }
      },
      errorMapper: (e) =>
          e is MediaServerUrlException ? e.message : t.addServer.couldNotReachServer(error: e.toString()),
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final info = _serverInfo;
    if (info == null) {
      await _probe();
      return;
    }
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final storage = await StorageService.getInstance();
        final deviceId = await storage.getOrCreateClientIdentifier();

        final connection = await auth.authenticateByName(
          baseUrl: _urlController.text,
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
    if (info == null) return;
    final attemptId = ++_qcAttemptId;
    setState(() => _qcCancelled = false);
    await runAsync<void>(
      () async {
        final auth = await _buildAuthService();
        final storage = await StorageService.getInstance();
        final deviceId = await storage.getOrCreateClientIdentifier();

        final initiation = await auth.initiateQuickConnect(baseUrl: _urlController.text, deviceId: deviceId);
        if (!_isCurrentQuickConnectAttempt(attemptId)) return;
        // Show the waiting panel without a spinner — opt-out of busy mid-flow
        // so the user-visible state matches "we're polling, nothing for you to do".
        setState(() => _qcInitiation = initiation);
        setBusy(false);

        final connection = await auth.authenticateByQuickConnect(
          baseUrl: _urlController.text,
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
      final profile = Profile(
        id: 'local-${const Uuid().v4()}',
        kind: ProfileKind.local,
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExcludeFocus(child: CustomAppBar(title: Text(t.addServer.addJellyfinTitle), pinned: true)),
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
      ),
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
      Text(t.addServer.jellyfinUrlIntro, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      TextFormField(
        controller: _urlController,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addServer.serverUrl,
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
      ),
      if (_serverInfo == null) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : _probe,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
          label: Text(t.addServer.findServer),
        ),
      ] else ...[
        const SizedBox(height: 16),
        _buildServerCard(theme),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: busy ? null : (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: t.addServer.username,
            prefixIcon: const AppIcon(Symbols.person_rounded, fill: 1),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
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
        FilledButton.icon(
          onPressed: busy ? null : _signIn,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
          label: Text(t.addServer.signIn),
        ),
        if (_quickConnectEnabled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _startQuickConnect,
            icon: const AppIcon(Symbols.tap_and_play_rounded, fill: 1),
            label: Text(t.auth.useQuickConnect),
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
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    _serverInfo = null;
                    _quickConnectEnabled = false;
                  }),
            child: Text(t.addServer.change),
          ),
        ],
      ),
    );
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
      OutlinedButton.icon(
        onPressed: _cancelQuickConnect,
        icon: const AppIcon(Symbols.close_rounded, fill: 1),
        label: Text(t.auth.quickConnectCancel),
      ),
    ];
  }
}
