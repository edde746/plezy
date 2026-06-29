import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../providers/seerr_session_provider.dart';
import '../../services/seerr/seerr_exceptions.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import '../settings/async_form_state_mixin.dart';

/// In-tab login form shown when:
///   - the profile has a SeerrConnection bound but the cookie was invalidated, OR
///   - we want a re-auth UI without leaving the Seerr tab.
///
/// When [connection] is provided, the URL is fixed (we know which instance
/// to re-authenticate against) and we only ask for the password.
class SeerrLoginScreen extends StatefulWidget {
  /// Existing connection to reauthenticate against; when null this is a
  /// "no Seerr configured" empty state that nudges the user to Settings.
  final SeerrConnection? connection;

  const SeerrLoginScreen({super.key, this.connection});

  @override
  State<SeerrLoginScreen> createState() => _SeerrLoginScreenState();
}

class _SeerrLoginScreenState extends State<SeerrLoginScreen> with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _passwordController = createTextEditingController();
  final _passwordFocus = FocusNode(debugLabel: 'SeerrLogin:Password');
  final _signInFocus = FocusNode(debugLabel: 'SeerrLogin:SignIn');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordFocus.dispose();
    _signInFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final connection = widget.connection;
    if (connection == null) return;
    await runAsync<void>(
      () async {
        final provider = context.read<SeerrSessionProvider>();
        final ok = await provider.connect(
          baseUrl: connection.baseUrl,
          username: connection.jellyfinUsername,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (!ok) setErrorText(t.addSeerr.signInFailedGeneric);
      },
      errorMapper: (e) {
        if (e is SeerrAuthException) return e.message;
        appLogger.e('Seerr login failed', error: e);
        return t.addSeerr.signInFailed(error: e.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final connection = widget.connection;
    if (connection == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.playlist_add_check_rounded, fill: 1, size: 56, color: muted),
              const SizedBox(height: 12),
              Text(t.seerr.login.emptyTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                t.seerr.login.emptySubtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.seerr.login.sessionExpired, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              t.seerr.login.signInAs(username: connection.jellyfinUsername, instance: connection.instanceLabel),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            FocusableTextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              autofocus: true,
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
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
