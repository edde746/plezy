import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/cli_debrid/cli_debrid_session.dart';
import '../../providers/cli_debrid_account_provider.dart';
import '../../services/cli_debrid/cli_debrid_client.dart';
import '../../services/cli_debrid/cli_debrid_exceptions.dart';
import '../../services/cli_debrid/cli_debrid_http_client.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'async_form_state_mixin.dart';

/// Single-step cli_debrid connect flow: URL + API token, verified with one
/// request before the session is adopted. Simpler than [SeerrConnectScreen]
/// because cli_debrid auth is a single static token, not a multi-method
/// login negotiated against instance settings.
class CliDebridConnectScreen extends StatefulWidget {
  const CliDebridConnectScreen({super.key});

  @override
  State<CliDebridConnectScreen> createState() => _CliDebridConnectScreenState();
}

class _CliDebridConnectScreenState extends State<CliDebridConnectScreen>
    with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _urlController = createTextEditingController();
  late final _tokenController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'CliDebridConnect:Url');
  final _tokenFocus = FocusNode(debugLabel: 'CliDebridConnect:Token');
  final _connectFocus = FocusNode(debugLabel: 'CliDebridConnect:Connect');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlFocus.dispose();
    _tokenFocus.dispose();
    _connectFocus.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = _urlController.text.trim();
    final url = input.contains('://') ? input : 'https://$input';
    final token = _tokenController.text.trim();

    await runAsync<void>(() async {
      final baseUrl = CliDebridHttpClient.normalizeBaseUrl(url);
      final probeSession = CliDebridSession(baseUrl: baseUrl, apiToken: token, displayName: '', createdAt: 0);
      final probeClient = CliDebridClient(probeSession);
      try {
        await probeClient.verifyConnection();
      } finally {
        probeClient.dispose();
      }

      final account = context.read<CliDebridAccountProvider>();
      await account.adoptSession(
        CliDebridSession(
          baseUrl: baseUrl,
          apiToken: token,
          displayName: baseUrl,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }, errorMapper: _describeError);
  }

  String _describeError(Object e) => switch (e) {
    CliDebridAuthException() => t.cliDebrid.invalidToken,
    CliDebridUrlException() => t.addServer.couldNotReachServer(error: e.toString()),
    _ => t.addServer.couldNotReachServer(error: e.toString()),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.cliDebrid.connectTitle),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FocusableTextFormField(
                    controller: _urlController,
                    focusNode: _urlFocus,
                    autofocus: true,
                    tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !busy,
                    onNavigateDown: () => _tokenFocus.requestFocus(),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: busy ? null : (_) => _tokenFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: t.cliDebrid.serverUrl,
                      hintText: 'https://cli-debrid.example.com',
                      helperText: t.cliDebrid.serverUrlHelper,
                      prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
                  ),
                  const SizedBox(height: 12),
                  FocusableTextFormField(
                    controller: _tokenController,
                    focusNode: _tokenFocus,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !busy,
                    onNavigateUp: () => _urlFocus.requestFocus(),
                    onNavigateDown: () => _connectFocus.requestFocus(),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: busy ? null : (_) => _connect(),
                    decoration: InputDecoration(
                      labelText: t.cliDebrid.apiToken,
                      helperText: t.cliDebrid.apiTokenHelper,
                      prefixIcon: const AppIcon(Symbols.key_rounded, fill: 1),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? t.addServer.required : null,
                  ),
                  const SizedBox(height: 16),
                  FocusableButton(
                    focusNode: _connectFocus,
                    useBackgroundFocus: true,
                    onNavigateUp: () => _tokenFocus.requestFocus(),
                    onPressed: busy ? null : _connect,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _connect,
                      icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.link_rounded, fill: 1),
                      label: Text(t.common.connect),
                    ),
                  ),
                  ...buildInlineError(theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
