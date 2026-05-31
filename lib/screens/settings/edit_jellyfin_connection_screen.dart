import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../services/jellyfin_endpoint_discovery.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'async_form_state_mixin.dart';

class EditJellyfinConnectionScreen extends StatefulWidget {
  final JellyfinConnection connection;

  const EditJellyfinConnectionScreen({super.key, required this.connection});

  @override
  State<EditJellyfinConnectionScreen> createState() => _EditJellyfinConnectionScreenState();
}

class _EditJellyfinConnectionScreenState extends State<EditJellyfinConnectionScreen>
    with AsyncFormStateMixin, ControllerDisposerMixin {
  late final _urlsController = createTextEditingController(text: widget.connection.baseUrls.join('\n'));
  final _urlsFocus = FocusNode(debugLabel: 'EditJellyfin:Urls');
  final _saveFocus = FocusNode(debugLabel: 'EditJellyfin:Save');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlsFocus.dispose();
    _saveFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await runAsync<void>(
      () async {
        final input = JellyfinEndpointDiscovery.buildUserInputCandidates(_enteredUrls());
        final endpoint = await JellyfinEndpointDiscovery().raceEndpoints(
          input.probeBaseUrls,
          preferredUrl: widget.connection.baseUrl,
          expectedMachineId: widget.connection.serverMachineId,
          baseUrlsToPersist: input.explicitBaseUrls,
          baseUrlValidationGroups: input.validationBaseUrlGroups,
        );
        final updated = widget.connection.copyWith(
          baseUrl: endpoint.activeBaseUrl,
          baseUrls: endpoint.baseUrls,
          serverName: endpoint.serverInfo.serverName,
        );
        if (!mounted) return;
        await context.read<ConnectionRegistry>().upsert(updated);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      },
      errorMapper: (e) {
        if (e is MediaServerUrlException) return e.message;
        appLogger.e('Edit Jellyfin connection failed', error: e);
        return t.addServer.couldNotReachServer(error: e.toString());
      },
    );
  }

  List<String> _enteredUrls() {
    return _urlsController.text
        .split(RegExp(r'[\n,]+'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.connections.editJellyfinTitle),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.connections.editJellyfinIntro(serverName: widget.connection.serverName),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FocusableTextFormField(
                    controller: _urlsController,
                    focusNode: _urlsFocus,
                    autofocus: true,
                    keyboardType: TextInputType.url,
                    minLines: 1,
                    maxLines: 5,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !busy,
                    onNavigateDown: () => _saveFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: t.addServer.serverUrls,
                      prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
                    ),
                    validator: (_) => _enteredUrls().isEmpty ? t.addServer.required : null,
                  ),
                  const SizedBox(height: 16),
                  FocusableButton(
                    focusNode: _saveFocus,
                    useBackgroundFocus: true,
                    onPressed: busy ? null : _save,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _save,
                      icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.save_rounded, fill: 1),
                      label: Text(t.common.save),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
