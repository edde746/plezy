import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/seerr/seerr_public_settings.dart';
import '../../models/seerr/seerr_session.dart';
import '../../providers/seerr_account_provider.dart';
import '../../services/seerr/seerr_auth_service.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../services/seerr/seerr_exceptions.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'async_form_state_mixin.dart';

/// Which credential form is on screen after the probe.
enum _CredentialForm { none, jellyfin, emby, local }

/// Two-step Seerr connect flow:
///   1. Probe the instance URL (`/settings/public`), expanding schemeless
///      input into https/http/default-port candidates like the MediaBrowser
///      add-server form.
///   2. Sign in with one of the methods the instance supports — one-tap
///      Plex (reusing the profile's stored token), Jellyfin/Emby
///      credentials, Jellyfin Quick Connect (Seerr 3.4+), or a local Seerr
///      account.
///
/// The finished [SeerrSession] is handed to [SeerrAccountProvider.adoptSession]
/// and the screen pops.
class SeerrConnectScreen extends StatefulWidget {
  const SeerrConnectScreen({super.key});

  @override
  State<SeerrConnectScreen> createState() => _SeerrConnectScreenState();
}

class _SeerrConnectScreenState extends State<SeerrConnectScreen> with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _urlController = createTextEditingController();
  late final _identifierController = createTextEditingController();
  late final _passwordController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'SeerrConnect:Url');
  final _continueFocus = FocusNode(debugLabel: 'SeerrConnect:Continue');
  final _changeServerFocus = FocusNode(debugLabel: 'SeerrConnect:ChangeServer');
  final _identifierFocus = FocusNode(debugLabel: 'SeerrConnect:Identifier');
  final _passwordFocus = FocusNode(debugLabel: 'SeerrConnect:Password');
  final _quickConnectFocus = FocusNode(debugLabel: 'SeerrConnect:QuickConnect');
  final _cancelQuickConnectFocus = FocusNode(debugLabel: 'SeerrConnect:CancelQuickConnect');
  final _formKey = GlobalKey<FormState>();

  SeerrPublicSettings? _instance;
  String _baseUrl = '';
  bool _plexTokenAvailable = false;
  _CredentialForm _form = _CredentialForm.none;
  SeerrQuickConnectInitiation? _qcInitiation;
  bool _qcCancelled = false;
  int _qcAttemptId = 0;

  @override
  void dispose() {
    // Short-circuit any in-flight Quick Connect poll so it doesn't try to
    // setState after the widget is gone.
    _qcCancelled = true;
    _qcAttemptId++;
    _urlFocus.dispose();
    _continueFocus.dispose();
    _changeServerFocus.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _quickConnectFocus.dispose();
    _cancelQuickConnectFocus.dispose();
    super.dispose();
  }

  bool get _offersPlex {
    final instance = _instance;
    return instance != null &&
        instance.mediaServerLogin &&
        instance.mediaServerType == SeerrMediaServerType.plex &&
        _plexTokenAvailable;
  }

  _CredentialForm get _mediaServerForm {
    final instance = _instance;
    if (instance == null || !instance.mediaServerLogin) return _CredentialForm.none;
    return switch (instance.mediaServerType) {
      SeerrMediaServerType.jellyfin => _CredentialForm.jellyfin,
      SeerrMediaServerType.emby => _CredentialForm.emby,
      _ => _CredentialForm.none,
    };
  }

  Future<void> _probe() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setErrorText(t.addServer.required);
      return;
    }
    await runAsync<void>(() async {
      final account = context.read<SeerrAccountProvider>();
      // Bare hosts are common ("seerr.example.com") — race https, plain http
      // and the default install port, like the MediaBrowser add-server form.
      final reached = await account.authService.probeFirstReachable(input);
      final settings = reached.settings;
      final plexToken = await account.resolvePlexToken();
      if (!mounted) return;
      setState(() {
        _instance = settings;
        _baseUrl = reached.baseUrl;
        _plexTokenAvailable = plexToken != null && plexToken.isNotEmpty;
        // With exactly one credential form on offer, skip the method list.
        final mediaForm = _mediaServerForm;
        if (!_offersPlex && mediaForm != _CredentialForm.none && !settings.localLogin) {
          _form = mediaForm;
        } else if (!_offersPlex && mediaForm == _CredentialForm.none && settings.localLogin) {
          _form = _CredentialForm.local;
        } else {
          _form = _CredentialForm.none;
        }
      });
    }, errorMapper: _describeError);
  }

  Future<void> _signInWithPlex() async {
    await runAsync<void>(() async {
      final account = context.read<SeerrAccountProvider>();
      final token = await account.resolvePlexToken();
      if (token == null || token.isEmpty) {
        throw SeerrAuthException('No Plex token available', display: t.seerr.noPlexTokenForReauth);
      }
      final session = await account.authService.signInWithPlex(baseUrl: _baseUrl, plexToken: token);
      await _finish(account, session);
    }, errorMapper: _describeError);
  }

  Future<void> _signInWithCredentials() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = _form;
    await runAsync<void>(() async {
      final account = context.read<SeerrAccountProvider>();
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;
      final session = switch (form) {
        _CredentialForm.jellyfin || _CredentialForm.emby => await account.authService.signInWithJellyfin(
          baseUrl: _baseUrl,
          username: identifier,
          password: password,
          emby: form == _CredentialForm.emby,
        ),
        _CredentialForm.local => await account.authService.signInWithLocal(
          baseUrl: _baseUrl,
          email: identifier,
          password: password,
        ),
        _CredentialForm.none => throw StateError('no credential form selected'),
      };
      await _finish(account, session);
    }, errorMapper: _describeError);
  }

  Future<void> _startQuickConnect() async {
    final attemptId = ++_qcAttemptId;
    setState(() => _qcCancelled = false);
    await runAsync<void>(
      () async {
        final account = context.read<SeerrAccountProvider>();
        final initiation = await account.authService.initiateQuickConnect(_baseUrl);
        if (!_isCurrentQuickConnectAttempt(attemptId)) return;
        // Show the waiting panel without a spinner — opt out of busy mid-flow
        // so the visible state matches "we're polling, nothing for you to do".
        setState(() => _qcInitiation = initiation);
        _requestFocusAfterFrame(_cancelQuickConnectFocus);
        setBusy(false);

        final session = await account.authService.signInWithQuickConnect(
          baseUrl: _baseUrl,
          secret: initiation.secret,
          shouldCancel: () => _qcCancelled || attemptId != _qcAttemptId,
        );
        if (!_isCurrentQuickConnectAttempt(attemptId)) return;
        if (session == null) {
          // Either the user cancelled or the secret expired before approval.
          // Cancellation is silent; expiry surfaces an error.
          setState(() => _qcInitiation = null);
          if (!_qcCancelled) setErrorText(t.auth.quickConnectExpired);
          return;
        }
        await _finish(account, session);
      },
      errorMapper: _describeError,
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

  Future<void> _finish(SeerrAccountProvider account, SeerrSession session) async {
    // The probe already answered /settings/public; carry its label and the
    // product discriminator (MediaStatus 6/7 decode per product) into the
    // persisted session.
    await account.adoptSession(session.copyWith(instanceLabel: _instance?.instanceLabel, product: _instance?.product));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _describeError(Object e) => switch (e) {
    SeerrUrlException(:final message, :final display) => display ?? message,
    SeerrAuthException(:final message, :final display) => display ?? message,
    _ => t.addServer.couldNotReachServer(error: e.toString()),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.seerr.connectTitle),
      slivers: [
        if (_qcInitiation != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
              child: Center(child: _buildQuickConnectPanel(theme)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _instance == null ? _buildUrlStep(theme) : _buildSignInStep(theme),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildUrlStep(ThemeData theme) {
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        autofocus: true,
        tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        onNavigateDown: () => _continueFocus.requestFocus(),
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.seerr.serverUrl,
          // URL example — intentionally not localized.
          hintText: 'https://seerr.example.com',
          helperText: t.seerr.serverUrlHelper,
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
      ),
      const SizedBox(height: 16),
      FocusableButton(
        focusNode: _continueFocus,
        useBackgroundFocus: true,
        onNavigateUp: () => _urlFocus.requestFocus(),
        onPressed: busy ? null : _probe,
        child: FilledButton.icon(
          onPressed: busy ? null : _probe,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
          label: Text(t.seerr.checkServer),
        ),
      ),
      ...buildInlineError(theme),
    ];
  }

  List<Widget> _buildSignInStep(ThemeData theme) {
    final instance = _instance!;
    final mediaForm = _mediaServerForm;
    final showLocalOption = instance.localLogin && _form != _CredentialForm.local;
    final showMediaOption = mediaForm != _CredentialForm.none && _form != mediaForm;
    final noMethods = !_offersPlex && mediaForm == _CredentialForm.none && !instance.localLogin;
    return [
      _buildInstanceCard(theme, instance),
      const SizedBox(height: 16),
      if (noMethods)
        Text(t.seerr.noSignInMethods, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))
      else ...[
        if (_offersPlex) ...[
          FocusableButton(
            useBackgroundFocus: true,
            onPressed: busy ? null : _signInWithPlex,
            child: FilledButton.icon(
              onPressed: busy ? null : _signInWithPlex,
              icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
              label: Text(t.auth.signInWithPlex),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_form != _CredentialForm.none) ..._buildCredentialFields(theme),
        if (showMediaOption)
          _buildMethodButton(
            label: mediaForm == _CredentialForm.emby ? t.seerr.signInWithEmby : t.seerr.signInWithJellyfin,
            onPressed: () => _switchForm(mediaForm),
          ),
        if (showLocalOption)
          _buildMethodButton(label: t.seerr.signInWithLocal, onPressed: () => _switchForm(_CredentialForm.local)),
      ],
      ...buildInlineError(theme),
    ];
  }

  void _switchForm(_CredentialForm form) {
    setState(() {
      _form = form;
      _identifierController.clear();
      _passwordController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _identifierFocus.canRequestFocus) _identifierFocus.requestFocus();
    });
  }

  Widget _buildMethodButton({required String label, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FocusableButton(
        useBackgroundFocus: true,
        onPressed: busy ? null : onPressed,
        child: OutlinedButton(onPressed: busy ? null : onPressed, child: Text(label)),
      ),
    );
  }

  List<Widget> _buildCredentialFields(ThemeData theme) {
    final isLocal = _form == _CredentialForm.local;
    return [
      FocusableTextFormField(
        controller: _identifierController,
        focusNode: _identifierFocus,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        keyboardType: isLocal ? TextInputType.emailAddress : TextInputType.text,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: busy ? null : (_) => _passwordFocus.requestFocus(),
        decoration: InputDecoration(
          labelText: isLocal ? t.seerr.email : t.addServer.username,
          prefixIcon: AppIcon(isLocal ? Symbols.mail_rounded : Symbols.person_rounded, fill: 1),
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
        onFieldSubmitted: busy ? null : (_) => _signInWithCredentials(),
        decoration: InputDecoration(
          labelText: t.addServer.password,
          prefixIcon: const AppIcon(Symbols.lock_rounded, fill: 1),
        ),
        validator: (v) => v == null || v.isEmpty ? t.addServer.required : null,
      ),
      const SizedBox(height: 16),
      FocusableButton(
        useBackgroundFocus: true,
        onPressed: busy ? null : _signInWithCredentials,
        child: FilledButton.icon(
          onPressed: busy ? null : _signInWithCredentials,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
          label: Text(t.addServer.signIn),
        ),
      ),
      const SizedBox(height: 12),
      // Seerr proxies Jellyfin Quick Connect from 3.4 on — and only for
      // Jellyfin: the server rejects it for Emby. Older instances answer the
      // initiate with a 404 the error text surfaces.
      if (_form == _CredentialForm.jellyfin) ...[
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
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildQuickConnectPanel(ThemeData theme) {
    final code = _qcInitiation!.code;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.auth.quickConnectInstructions,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: 32),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              // letterSpacing adds a trailing gap after the last glyph;
              // matching left padding keeps the code optically centered.
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                code,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingIndicatorBox(size: 16),
              const SizedBox(width: 10),
              Text(t.auth.quickConnectWaiting, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            ],
          ),
          const SizedBox(height: 32),
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
          ...buildInlineError(theme, gap: 16, center: true),
        ],
      ),
    );
  }

  Widget _buildInstanceCard(ThemeData theme, SeerrPublicSettings instance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        children: [
          const AppIcon(Symbols.cloud_done_rounded, fill: 1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instance.instanceLabel, style: theme.textTheme.titleSmall),
                Text(
                  _baseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          FocusableButton(
            focusNode: _changeServerFocus,
            useBackgroundFocus: true,
            onPressed: busy ? null : _resetToUrlStep,
            child: TextButton(onPressed: busy ? null : _resetToUrlStep, child: Text(t.addServer.change)),
          ),
        ],
      ),
    );
  }

  void _resetToUrlStep() {
    setState(() {
      _instance = null;
      _form = _CredentialForm.none;
      _identifierController.clear();
      _passwordController.clear();
    });
  }
}
