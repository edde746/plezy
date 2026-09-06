import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../connection/connection.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/profile.dart';
import '../../services/plex_direct_service.dart';
import '../../services/plex_gdm_discovery_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/url_utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';
import 'discovered_server_section.dart';
import 'probed_server_card.dart';

export '../../services/plex_direct_service.dart';

/// Screen to add a direct Plex connection without plex.tv.
class AddDirectPlexScreen extends StatefulWidget {
  final Profile? targetProfile;
  final DiscoveredPlexServer? initialServer;
  final bool autoConnect;

  const AddDirectPlexScreen({super.key, this.targetProfile, this.initialServer, this.autoConnect = false});

  @override
  State<AddDirectPlexScreen> createState() => _AddDirectPlexScreenState();
}

class _AddDirectPlexScreenState extends State<AddDirectPlexScreen>
    with ControllerDisposerMixin, AsyncFormStateMixin<AddDirectPlexScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  late final FocusNode _urlFocus;
  late final FocusNode _tokenFocus;
  late final FocusNode _findServerFocus;
  late final FocusNode _connectFocus;
  late final FocusNode _changeServerFocus;
  final Map<String, FocusNode> _discoveredServerFocusNodes = {};

  PlexDirectServerInfo? _serverInfo;
  List<DiscoveredPlexServer> _localServers = const [];
  bool _isDiscoveringLocalServers = false;

  @override
  void initState() {
    super.initState();
    final initialUrl = widget.initialServer?.address ?? '';
    _urlController = createTextEditingController(text: initialUrl);
    _tokenController = createTextEditingController();

    _urlFocus = FocusNode(debugLabel: 'DirectPlex.url');
    _tokenFocus = FocusNode(debugLabel: 'DirectPlex.token');
    _findServerFocus = FocusNode(debugLabel: 'DirectPlex.findServer');
    _connectFocus = FocusNode(debugLabel: 'DirectPlex.connect');
    _changeServerFocus = FocusNode(debugLabel: 'DirectPlex.changeServer');

    _startGdmDiscovery();

    if (initialUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _probe(autoConnectIfAllowed: widget.autoConnect);
      });
    }
  }

  @override
  void dispose() {
    _urlFocus.dispose();
    _tokenFocus.dispose();
    _findServerFocus.dispose();
    _connectFocus.dispose();
    _changeServerFocus.dispose();
    for (final node in _discoveredServerFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _startGdmDiscovery() {
    setState(() => _isDiscoveringLocalServers = true);
    unawaited(
      PlexGdmDiscoveryService()
          .discover()
          .then((servers) {
            if (!mounted) return;
            setState(() {
              _localServers = servers;
              _isDiscoveringLocalServers = false;
              syncDiscoveredFocusNodes(
                _discoveredServerFocusNodes,
                servers.map((s) => s.id),
                debugPrefix: 'DiscoveredPlex',
              );
            });
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _isDiscoveringLocalServers = false);
          }),
    );
  }

  String _cleanUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return canonicalizeBaseUrl(url);
  }

  Future<void> _probe({bool autoConnectIfAllowed = false}) async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setErrorText(t.addServer.enterAtLeastOneUrl(product: 'Plex'));
      return;
    }
    final url = _cleanUrl(rawUrl);

    await runAsync<void>(
      () async {
        final storage = await StorageService.getInstance();
        final clientIdentifier = await storage.getOrCreateClientIdentifier();
        final token = _tokenController.text.trim();

        final info = await probePlexServer(url: url, clientIdentifier: clientIdentifier, token: token);

        if (!mounted) return;
        setState(() {
          _serverInfo = info;
          _urlController.text = url;
        });

        if (info.requiresAuth && !info.isAuthenticated) {
          requestFocusAfterFrame(_tokenFocus);
        } else if (autoConnectIfAllowed) {
          await _connect();
        } else {
          requestFocusAfterFrame(_connectFocus);
        }
      },
      errorMapper: (e) {
        appLogger.w('Direct Plex probe failed', error: e);
        return t.addServer.couldNotReachServer(error: e.toString());
      },
    );
  }

  Future<void> _connect() async {
    final info = _serverInfo;
    if (info == null) {
      await _probe();
      return;
    }
    if (info.requiresAuth && !info.isAuthenticated) {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        setErrorText(t.addServer.plexTokenRequired);
        _tokenFocus.requestFocus();
        return;
      }
      // Re-probe with the entered token to confirm validity
      await _probe();
      if (_serverInfo?.isAuthenticated != true) return;
    }

    await runAsync<void>(
      () async {
        final storage = await StorageService.getInstance();
        final clientIdentifier = await storage.getOrCreateClientIdentifier();
        final token = _tokenController.text.trim();

        final connection = PlexDirectConnection(
          id: 'plex-direct-${info.serverMachineId}',
          baseUrl: info.activeUrl,
          baseUrls: [info.activeUrl],
          serverName: info.serverName,
          serverMachineId: info.serverMachineId,
          clientIdentifier: clientIdentifier,
          accessToken: token,
          createdAt: DateTime.now(),
        );

        if (!mounted) return;
        await persistDirectServerConnectionAndExit(
          context: context,
          connection: connection,
          userIdentifier: info.serverMachineId,
          userToken: token,
          defaultProfileName: connection.serverName,
          targetProfile: widget.targetProfile,
          onError: setErrorText,
        );
      },
      errorMapper: (e) {
        appLogger.e('Direct Plex connect failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
  }

  void _useDiscoveredServer(DiscoveredPlexServer server) {
    setState(() {
      _serverInfo = null;
      _urlController.text = server.address;
    });
    _probe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.targetProfile != null
        ? t.addServer.addConnectionTitleScoped(name: widget.targetProfile!.displayName)
        : t.addServer.addDirectPlexTitle;

    return FocusedScrollScaffold(
      title: Text(title),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
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
    final info = _serverInfo;
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        autofocus: widget.initialServer == null,
        keyboardType: TextInputType.url,
        enabled: !busy,
        decoration: InputDecoration(
          labelText: t.addServer.directPlexServerUrl,
          hintText: t.addServer.directPlexServerUrlHint,
          helperText: info == null ? t.addServer.directPlexServerUrlHelper : null,
          prefixIcon: const BackendBadge(backend: MediaBackend.plex, size: 20),
        ),
        onChanged: (_) {
          if (_serverInfo != null) {
            setState(() => _serverInfo = null);
          }
        },
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
      ),
      if (info == null) ...[
        DiscoveredServerSection<DiscoveredPlexServer>(
          isDiscovering: _isDiscoveringLocalServers,
          discoveringText: t.addServer.searchingLocalPlexServers,
          sectionTitle: t.addServer.localPlexServers,
          servers: _localServers,
          idOf: (s) => s.id,
          nameOf: (s) => s.name,
          addressOf: (s) => s.address,
          leadingBuilder: (_) => const BackendBadge(backend: MediaBackend.plex, size: 24),
          focusNodes: _discoveredServerFocusNodes,
          onSelect: _useDiscoveredServer,
          enabled: !busy,
        ),
        const SizedBox(height: 16),
        FocusableButton(
          focusNode: _findServerFocus,
          useBackgroundFocus: true,
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
          leading: const BackendBadge(backend: MediaBackend.plex, size: 28),
          title: info.serverName,
          subtitle: info.version != null ? 'Plex Media Server ${info.version}' : info.activeUrl,
          statusNotice: info.requiresAuth && !info.isAuthenticated
              ? Row(
                  children: [
                    AppIcon(Symbols.lock_rounded, size: 14, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      t.addServer.plexTokenRequired,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                )
              : null,
          changeFocusNode: _changeServerFocus,
          onChange: () => setState(() {
            _serverInfo = null;
            _tokenController.clear();
          }),
          enabled: !busy,
        ),
        const SizedBox(height: 16),
        if (info.requiresAuth || _tokenController.text.isNotEmpty) ...[
          FocusableTextFormField(
            controller: _tokenController,
            focusNode: _tokenFocus,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: t.addServer.plexToken,
              helperText: info.requiresAuth ? t.addServer.plexTokenRequired : t.addServer.plexTokenHelper,
              prefixIcon: const AppIcon(Symbols.key_rounded, fill: 1),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: busy ? null : (_) => _connect(),
          ),
          const SizedBox(height: 16),
        ],
        FocusableButton(
          focusNode: _connectFocus,
          useBackgroundFocus: true,
          onPressed: busy ? null : _connect,
          child: FilledButton.icon(
            onPressed: busy ? null : _connect,
            icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.login_rounded, fill: 1),
            label: Text(t.addServer.connectDirect),
          ),
        ),
      ],
      ...buildInlineError(theme),
    ];
  }
}
