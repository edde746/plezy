import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../services/silo/silo_auth_service.dart';
import '../../services/silo/silo_identity.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import '../profile/pin_entry_dialog.dart';
import '../profile/profile_switch_screen.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';

/// Add a Silo server through Silo's native `/api/v2` API (no Jellyfin
/// compatibility layer):
///   1. Probe the address (`/system/info`, `/system/identity`).
///   2. Sign in with username and password (`/auth/login`).
///   3. Pick a household profile, verifying its PIN when it has one.
///   4. Persist a [SiloConnection] (tokens encrypted by the credential
///      vault) and bind it to [targetProfile] or the active Plezy profile.
class AddSiloScreen extends StatefulWidget {
  final Profile? targetProfile;

  const AddSiloScreen({super.key, this.targetProfile});

  @override
  State<AddSiloScreen> createState() => _AddSiloScreenState();
}

class _AddSiloScreenState extends State<AddSiloScreen> with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _urlController = createTextEditingController();
  late final _usernameController = createTextEditingController();
  late final _passwordController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'AddSilo:Url');
  final _findServerFocus = FocusNode(debugLabel: 'AddSilo:FindServer');
  final _changeServerFocus = FocusNode(debugLabel: 'AddSilo:ChangeServer');
  final _usernameFocus = FocusNode(debugLabel: 'AddSilo:Username');
  final _passwordFocus = FocusNode(debugLabel: 'AddSilo:Password');
  final _signInFocus = FocusNode(debugLabel: 'AddSilo:SignIn');
  final _formKey = GlobalKey<FormState>();

  SiloAuthService? _auth;
  SiloServerProbe? _server;
  SiloSignIn? _signIn;

  /// Set once the connection is persisted; until then a signed-in session
  /// is revoked when the screen closes so no orphan session is left behind.
  bool _completed = false;

  @override
  void dispose() {
    _discardSignIn();
    _urlFocus.dispose();
    _findServerFocus.dispose();
    _changeServerFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _signInFocus.dispose();
    super.dispose();
  }

  Future<SiloAuthService> _authService() async => _auth ??= SiloAuthService(identity: await resolveSiloClientIdentity());

  /// Revoke an unfinished sign-in (best effort) and release its client.
  void _discardSignIn() {
    final signIn = _signIn;
    _signIn = null;
    if (signIn == null) return;
    if (_completed) {
      signIn.api.close();
      return;
    }
    unawaited(signIn.api.logout().whenComplete(signIn.api.close));
  }

  void _changeServer() {
    setState(() {
      _discardSignIn();
      _server = null;
    });
    setErrorText(null);
    requestFocusAfterFrame(_urlFocus);
  }

  // ------------------------------------------------------------------ probe

  Future<void> _probe() async {
    if (_urlController.text.trim().isEmpty) {
      setErrorText(t.addServer.required);
      return;
    }
    final probe = await runAsync<SiloServerProbe>(
      () async => (await _authService()).probe(_urlController.text),
      errorMapper: (e) => switch (e) {
        MediaServerUrlException() => e.display ?? e.message,
        _ => t.addServer.couldNotReachServer(error: e.toString()),
      },
    );
    if (probe == null || !mounted) return;

    final host = Uri.parse(probe.baseUrl).host;
    if (probe.isCleartext && !SiloAuthService.isLocalNetworkHost(host)) {
      final proceed = await showConfirmDialog(
        context,
        title: t.addServer.silo.insecureTitle,
        message: t.addServer.silo.insecureMessage(host: host),
        confirmText: t.addServer.silo.insecureConfirm,
        isDestructive: true,
      );
      if (!proceed || !mounted) return;
    }

    setState(() {
      _server = probe;
      _urlController.text = probe.baseUrl;
      if (!probe.passwordLogin) setErrorText(t.addServer.silo.passwordLoginDisabled);
    });
    if (probe.passwordLogin) requestFocusAfterFrame(_usernameFocus);
  }

  // ---------------------------------------------------------------- sign in

  Future<void> _submitCredentials() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final server = _server;
    if (server == null) {
      await _probe();
      return;
    }
    final signIn = await runAsync<SiloSignIn>(
      () async => (await _authService()).signIn(
        server,
        username: _usernameController.text,
        password: _passwordController.text,
      ),
      errorMapper: (e) {
        if (e is MediaServerAuthException) return e.display ?? e.message;
        if (e is MediaServerException) return e.display ?? e.message;
        appLogger.w('Add Silo: sign-in failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
    if (signIn == null || !mounted) return;
    _passwordController.clear();
    setState(() => _signIn = signIn);

    // One profile without a PIN: nothing to choose.
    if (signIn.profiles.length == 1 && !signIn.profiles.single.hasPin) {
      await _chooseProfile(signIn.profiles.single);
    }
  }

  Future<void> _chooseProfile(SiloProfileChoice profile) async {
    final signIn = _signIn;
    if (signIn == null || busy) return;

    String? profileToken;
    DateTime? profileTokenExpiresAt;
    if (profile.hasPin) {
      String? error;
      while (true) {
        final pin = await showPinEntryDialog(context, profile.name, errorMessage: error);
        if (pin == null || !mounted) return;
        final auth = await _authService();
        final verified = await runAsync(
          () => auth.verifyPin(signIn, profile.id, pin),
          errorMapper: (e) => e is MediaServerException ? e.display ?? e.message : e.toString(),
        );
        if (!mounted) return;
        if (verified != null) {
          profileToken = verified.token;
          profileTokenExpiresAt = verified.expiresAt;
          break;
        }
        // `runAsync` returns null both for a wrong PIN and for an error; an
        // error (such as a lockout) is already on screen, so stop there.
        if (errorText != null) return;
        error = t.addServer.silo.wrongPin;
      }
    }

    await runAsync<void>(
      () async {
        final auth = await _authService();
        final connection = auth.buildConnection(
          signIn,
          profile: profile,
          profileToken: profileToken,
          profileTokenExpiresAt: profileTokenExpiresAt,
        );
        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        appLogger.e('Add Silo: saving the connection failed', error: e);
        return t.addServer.failedToRegisterAccount(error: e.toString());
      },
    );
  }

  /// Persist the connection and its profile binding atomically, then bind it
  /// if it belongs to the active Plezy profile. Mirrors the Jellyfin flow.
  Future<void> _persistAndExit(SiloConnection connection) async {
    if (!mounted) return;
    final activeProvider = context.read<ActiveProfileProvider>();
    await activeProvider.initialize();
    if (!mounted) return;
    final targetProfile = widget.targetProfile;
    var boundProfile = targetProfile ?? activeProvider.active;
    final hasProfiles = activeProvider.profiles.isNotEmpty;

    if (targetProfile == null && activeProvider.active == null && hasProfiles) {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
      if (!mounted) return;
      boundProfile = activeProvider.active;
      if (boundProfile == null) {
        setErrorText(t.messages.noProfilesAvailable);
        return;
      }
    }

    Profile? firstRunProfile;
    if (targetProfile == null && boundProfile == null && !hasProfiles) {
      final now = DateTime.now();
      firstRunProfile = Profile.local(
        id: 'local-${const Uuid().v4()}',
        displayName: connection.profileName.isNotEmpty ? connection.profileName : connection.userName,
        sortOrder: now.millisecondsSinceEpoch,
        createdAt: now,
      );
      boundProfile = firstRunProfile;
    }

    final bindProfile = boundProfile;
    if (bindProfile == null) {
      setErrorText(t.messages.noProfilesAvailable);
      return;
    }

    await persistAndBindConnection(
      context: context,
      connection: connection,
      // Silo credentials live on the connection (encrypted by the vault);
      // the join row only records which server profile this binding uses.
      bindToProfile: ProfileConnection(
        profileId: bindProfile.id,
        connectionId: connection.id,
        userToken: '',
        userIdentifier: connection.profileId,
        tokenAcquiredAt: DateTime.now(),
      ),
      firstRunProfile: firstRunProfile,
    );
    _completed = true;

    final boundToActive = bindProfile.id == activeProvider.activeId;
    if (!mounted) return;
    if (boundToActive) {
      await context.read<ActiveProfileBinder>().rebindIfActive(bindProfile.id);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.addServer.silo.title),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  if (_signIn != null) ..._buildProfileStep(theme) else ..._buildServerAndCredentialSteps(theme),
                  ...buildInlineError(theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildServerAndCredentialSteps(ThemeData theme) {
    final server = _server;
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        tvTextInputPresentation: TvTextInputPresentation.platform,
        autofocus: server == null,
        tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy && server == null,
        onNavigateDown: () => (server == null ? _findServerFocus : _changeServerFocus).requestFocus(),
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addServer.silo.serverAddress,
          // URL example — intentionally not localized.
          hintText: 'https://silo.example.com',
          helperText: server == null ? t.addServer.silo.serverAddressHelper : null,
          helperMaxLines: 2,
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
      ),
      if (server == null) ...[
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _findServerFocus,
          useBackgroundFocus: true,
          onNavigateUp: () => _urlFocus.requestFocus(),
          onPressed: busy ? null : _probe,
          child: FilledButton.icon(
            onPressed: busy ? null : _probe,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
            label: Text(t.addServer.findServer),
          ),
        ),
      ] else ...[
        const SizedBox(height: 16),
        _buildServerCard(theme, server),
        if (server.passwordLogin) ...[
          const SizedBox(height: 16),
          FocusableTextFormField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !busy,
            autofillHints: const [AutofillHints.username],
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
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: busy ? null : (_) => _submitCredentials(),
            decoration: InputDecoration(
              labelText: t.addServer.password,
              prefixIcon: const AppIcon(Symbols.lock_rounded, fill: 1),
            ),
            validator: (v) => v == null || v.isEmpty ? t.addServer.required : null,
          ),
          const SizedBox(height: 16),
          FocusableButton(
            focusNode: _signInFocus,
            useBackgroundFocus: true,
            onPressed: busy ? null : _submitCredentials,
            child: FilledButton.icon(
              onPressed: busy ? null : _submitCredentials,
              icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
              label: Text(t.addServer.signIn),
            ),
          ),
        ],
      ],
    ];
  }

  Widget _buildServerCard(ThemeData theme, SiloServerProbe server) {
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        children: [
          AppIcon(server.isCleartext ? Symbols.lock_open_rounded : Symbols.cloud_done_rounded, fill: 1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(server.displayName, style: theme.textTheme.titleSmall),
                if (server.serverVersion.isNotEmpty)
                  Text(t.addServer.silo.version(version: server.serverVersion), style: muted),
              ],
            ),
          ),
          FocusableButton(
            focusNode: _changeServerFocus,
            useBackgroundFocus: true,
            onNavigateUp: () => _urlFocus.requestFocus(),
            onNavigateDown: () => _usernameFocus.requestFocus(),
            onPressed: busy ? null : _changeServer,
            child: TextButton(onPressed: busy ? null : _changeServer, child: Text(t.addServer.change)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileStep(ThemeData theme) {
    final signIn = _signIn!;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));
    final tokensRef = tokens(context);
    return [
      _buildServerCard(theme, signIn.server),
      const SizedBox(height: 20),
      Text(t.addServer.silo.chooseProfile, style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(t.addServer.silo.chooseProfileHelper, style: muted),
      const SizedBox(height: 12),
      for (final (i, profile) in signIn.profiles.indexed) ...[
        if (i > 0) SizedBox(height: tokensRef.groupGap),
        _SiloProfileTile(
          profile: profile,
          autofocus: i == 0,
          borderRadius: groupItemRadii(context, i, signIn.profiles.length),
          onTap: busy ? null : () => unawaited(_chooseProfile(profile)),
        ),
      ],
      if (busy) ...[const SizedBox(height: 16), const Center(child: LoadingIndicatorBox())],
      const SizedBox(height: 16),
      TextButton(onPressed: busy ? null : _changeServer, child: Text(t.addServer.silo.signInAsAnotherAccount)),
    ];
  }
}

class _SiloProfileTile extends StatelessWidget {
  final SiloProfileChoice profile;
  final bool autofocus;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const _SiloProfileTile({required this.profile, required this.autofocus, required this.borderRadius, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (profile.isPrimary) t.addServer.silo.primaryProfile,
      if (profile.isChild) t.addServer.silo.childProfile,
      if (profile.hasPin) t.addServer.silo.pinRequired,
    ].join(', ');
    final initial = profile.name.trim().isEmpty ? '?' : profile.name.trim().characters.first.toUpperCase();
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      child: ListTile(
        autofocus: autofocus,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(initial),
        ),
        title: Text(profile.name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: AppIcon(profile.hasPin ? Symbols.lock_rounded : Symbols.chevron_right_rounded, fill: 1),
      ),
    );
  }
}
