import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_auth_service.dart';
import '../../services/seerr/seerr_exceptions.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'async_form_state_mixin.dart';

/// Two-step form to add a Seerr instance:
///   1. Probe URL — calls `/settings/public` + `/status` (no auth) to confirm
///      the URL points at an initialised Seerr.
///   2. Jellyfin credentials — POSTs `/auth/jellyfin`, captures the
///      `connect.sid` cookie, persists the [SeerrConnection] and binds it
///      to the active profile via [SeerrSessionProvider.connect].
class AddSeerrScreen extends StatefulWidget {
  const AddSeerrScreen({super.key});

  @override
  State<AddSeerrScreen> createState() => _AddSeerrScreenState();
}

class _AddSeerrScreenState extends State<AddSeerrScreen> with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _urlController = createTextEditingController();
  late final _usernameController = createTextEditingController();
  late final _passwordController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'AddSeerr:Url');
  final _findFocus = FocusNode(debugLabel: 'AddSeerr:Find');
  final _changeFocus = FocusNode(debugLabel: 'AddSeerr:Change');
  final _usernameFocus = FocusNode(debugLabel: 'AddSeerr:Username');
  final _passwordFocus = FocusNode(debugLabel: 'AddSeerr:Password');
  final _signInFocus = FocusNode(debugLabel: 'AddSeerr:SignIn');
  final _formKey = GlobalKey<FormState>();

  SeerrProbeInfo? _probeInfo;

  @override
  void dispose() {
    _urlFocus.dispose();
    _findFocus.dispose();
    _changeFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _signInFocus.dispose();
    super.dispose();
  }

  String _normalisedUrl() {
    var url = _urlController.text.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> _probe() async {
    final url = _normalisedUrl();
    if (url.isEmpty) {
      setErrorText(t.addSeerr.urlRequired);
      return;
    }
    await runAsync<void>(
      () async {
        final auth = context.read<SeerrSessionProvider>().authService;
        final info = await auth.probe(url);
        if (!mounted) return;
        if (!info.initialized) {
          setErrorText(t.addSeerr.notInitialized);
          return;
        }
        setState(() => _probeInfo = info);
        _requestFocusAfterFrame(_usernameFocus);
      },
      errorMapper: (e) {
        if (e is SeerrUrlException) return e.message;
        appLogger.e('Seerr probe failed', error: e);
        return t.addSeerr.couldNotReach(error: e.toString());
      },
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final info = _probeInfo;
    if (info == null) {
      await _probe();
      return;
    }
    await runAsync<void>(
      () async {
        final provider = context.read<SeerrSessionProvider>();
        final ok = await provider.connect(
          baseUrl: _normalisedUrl(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (!ok) {
          setErrorText(t.addSeerr.signInFailedGeneric);
          return;
        }
        final connection = provider.connection;
        showSuccessSnackBar(
          context,
          connection != null
              ? t.addSeerr.signInSuccess(label: connection.instanceLabel)
              : t.addSeerr.signInSuccessGeneric,
        );
        Navigator.of(context).pop(true);
      },
      errorMapper: (e) {
        if (e is SeerrAuthException) return e.message;
        if (e is SeerrUrlException) return e.message;
        appLogger.e('Seerr sign in failed', error: e);
        return t.addSeerr.signInFailed(error: e.toString());
      },
    );
  }

  void _requestFocusAfterFrame(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !node.canRequestFocus) return;
      node.requestFocus();
    });
  }

  void _clearProbe() {
    setState(() => _probeInfo = null);
    _urlFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.addSeerr.title),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _body(theme)),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _body(ThemeData theme) {
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        autofocus: true,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy && _probeInfo == null,
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addSeerr.urlLabel,
          hintText: 'https://requests.example.com',
          helperText: _probeInfo == null ? t.addSeerr.urlHelper : null,
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (_) => _normalisedUrl().isEmpty ? t.addSeerr.urlRequired : null,
      ),
      if (_probeInfo == null) ...[
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _findFocus,
          useBackgroundFocus: true,
          onPressed: busy ? null : _probe,
          child: FilledButton.icon(
            onPressed: busy ? null : _probe,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
            label: Text(t.addSeerr.probe),
          ),
        ),
      ] else ...[
        const SizedBox(height: 16),
        _ProbeCard(info: _probeInfo!, onChange: busy ? null : _clearProbe, changeFocus: _changeFocus),
        const SizedBox(height: 16),
        Text(t.addSeerr.signInWithJellyfinHelp, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        const SizedBox(height: 12),
        FocusableTextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: busy ? null : (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: t.addSeerr.jellyfinUsername,
            prefixIcon: const AppIcon(Symbols.person_rounded, fill: 1),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? t.addSeerr.required : null,
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
            labelText: t.addSeerr.jellyfinPassword,
            prefixIcon: const AppIcon(Symbols.lock_rounded, fill: 1),
          ),
          validator: (v) => (v == null || v.isEmpty) ? t.addSeerr.required : null,
        ),
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _signInFocus,
          useBackgroundFocus: true,
          onPressed: busy ? null : _signIn,
          child: FilledButton.icon(
            onPressed: busy ? null : _signIn,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
            label: Text(t.addSeerr.signIn),
          ),
        ),
      ],
      if (errorText != null) ...[
        const SizedBox(height: 12),
        Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
      ],
    ];
  }
}

class _ProbeCard extends StatelessWidget {
  final SeerrProbeInfo info;
  final VoidCallback? onChange;
  final FocusNode changeFocus;

  const _ProbeCard({required this.info, required this.onChange, required this.changeFocus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Text(info.instanceLabel, style: theme.textTheme.titleSmall),
                if (info.version.isNotEmpty)
                  Text(
                    'Seerr ${info.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          FocusableButton(
            focusNode: changeFocus,
            useBackgroundFocus: true,
            onPressed: onChange,
            child: TextButton(onPressed: onChange, child: Text(t.addServer.change)),
          ),
        ],
      ),
    );
  }
}
