import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../focus/card_focus_scope.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../services/plex_gdm_discovery_service.dart';
import '../../services/storage_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../../utils/url_utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import '../profile/profile_switch_screen.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';

class PlexDirectServerInfo {
  final String activeUrl;
  final String serverName;
  final String serverMachineId;
  final String? version;
  final bool requiresAuth;
  final bool isAuthenticated;

  const PlexDirectServerInfo({
    required this.activeUrl,
    required this.serverName,
    required this.serverMachineId,
    this.version,
    required this.requiresAuth,
    required this.isAuthenticated,
  });
}

/// Probes a Plex Media Server at [url] to identify it and test authorization.
Future<PlexDirectServerInfo> probePlexServer({
  required String url,
  required String clientIdentifier,
  String token = '',
  http.Client? client,
}) async {
  final httpClient = client ?? platform.createPlatformClient();
  try {
    final rootUri = Uri.parse(url);
    final headers = {
      'Accept': 'application/json',
      'X-Plex-Client-Identifier': clientIdentifier,
      'X-Plex-Product': 'Plezy',
      'X-Plex-Version': '1.0',
      'X-Plex-Platform': 'Flutter',
    };
    if (token.isNotEmpty) {
      headers['X-Plex-Token'] = token;
    }

    http.Response rootResp;
    try {
      rootResp = await httpClient.get(rootUri.replace(path: '/'), headers: headers).timeout(const Duration(seconds: 5));
    } catch (_) {
      rootResp = await httpClient
          .get(rootUri.replace(path: '/identity'), headers: headers)
          .timeout(const Duration(seconds: 5));
    }

    if (rootResp.statusCode == 200) {
      final json = _tryParseJson(rootResp.body);
      final mc = json?['MediaContainer'] as Map<String, dynamic>?;

      final serverName =
          mc?['friendlyName'] as String? ??
          mc?['myPlexUsername'] as String? ??
          _extractXmlAttr(rootResp.body, 'friendlyName') ??
          'Plex Media Server';
      final machineId =
          mc?['machineIdentifier'] as String? ??
          _extractXmlAttr(rootResp.body, 'machineIdentifier') ??
          '${rootUri.host}:${rootUri.port}';
      final version = mc?['version'] as String? ?? _extractXmlAttr(rootResp.body, 'version');

      return PlexDirectServerInfo(
        activeUrl: url,
        serverName: serverName,
        serverMachineId: machineId,
        version: version,
        requiresAuth: false,
        isAuthenticated: true,
      );
    } else if (rootResp.statusCode == 401) {
      if (token.isNotEmpty) {
        throw const FormatException('Invalid Plex token. Access denied by server.');
      }

      // Query /identity without token to get machine identifier and version
      try {
        final idResp = await httpClient
            .get(rootUri.replace(path: '/identity'), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 5));

        if (idResp.statusCode == 200) {
          final json = _tryParseJson(idResp.body);
          final mc = json?['MediaContainer'] as Map<String, dynamic>?;
          final machineId =
              mc?['machineIdentifier'] as String? ??
              _extractXmlAttr(idResp.body, 'machineIdentifier') ??
              '${rootUri.host}:${rootUri.port}';
          final version = mc?['version'] as String? ?? _extractXmlAttr(idResp.body, 'version');

          return PlexDirectServerInfo(
            activeUrl: url,
            serverName: 'Plex (${rootUri.host})',
            serverMachineId: machineId,
            version: version,
            requiresAuth: true,
            isAuthenticated: false,
          );
        }
      } catch (_) {}

      return PlexDirectServerInfo(
        activeUrl: url,
        serverName: 'Plex (${rootUri.host})',
        serverMachineId: '${rootUri.host}:${rootUri.port}',
        requiresAuth: true,
        isAuthenticated: false,
      );
    } else {
      throw FormatException('Unexpected server response: HTTP ${rootResp.statusCode}');
    }
  } finally {
    if (client == null) httpClient.close();
  }
}

Map<String, dynamic>? _tryParseJson(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
}

String? _extractXmlAttr(String xml, String attr) {
  final match = RegExp('$attr="([^"]+)"').firstMatch(xml);
  return match?.group(1);
}

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
              _syncDiscoveredFocusNodes();
            });
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _isDiscoveringLocalServers = false);
          }),
    );
  }

  void _syncDiscoveredFocusNodes() {
    final validIds = _localServers.map((s) => s.id).toSet();
    _discoveredServerFocusNodes.removeWhere((id, node) {
      if (!validIds.contains(id)) {
        node.dispose();
        return true;
      }
      return false;
    });
    for (final server in _localServers) {
      _discoveredServerFocusNodes.putIfAbsent(server.id, () => FocusNode(debugLabel: 'DiscoveredPlex.${server.name}'));
    }
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

        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        appLogger.e('Direct Plex connect failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
  }

  Future<void> _persistAndExit(PlexDirectConnection connection) async {
    if (!mounted) return;
    final activeProvider = context.read<ActiveProfileProvider>();
    await activeProvider.initialize();
    if (!mounted) return;
    final targetProfile = widget.targetProfile;
    var boundProfile = targetProfile ?? activeProvider.active;

    if (targetProfile == null && boundProfile == null && activeProvider.profiles.isNotEmpty) {
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
    if (targetProfile == null && boundProfile == null && activeProvider.profiles.isEmpty) {
      final now = DateTime.now();
      firstRunProfile = Profile.local(
        id: 'local-${const Uuid().v4()}',
        displayName: connection.serverName,
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
      bindToProfile: ProfileConnection(
        profileId: bindProfile.id,
        connectionId: connection.id,
        userToken: connection.accessToken,
        userIdentifier: connection.serverMachineId,
        tokenAcquiredAt: DateTime.now(),
      ),
      firstRunProfile: firstRunProfile,
    );

    final boundToActive = bindProfile.id == activeProvider.activeId;
    if (!mounted) return;
    if (boundToActive) {
      await context.read<ActiveProfileBinder>().rebindIfActive(bindProfile.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
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
        ..._buildLocalDiscoverySection(theme),
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
        _buildServerCard(theme, info),
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

  Widget _buildServerCard(ThemeData theme, PlexDirectServerInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        children: [
          const BackendBadge(backend: MediaBackend.plex, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.serverName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  info.version != null ? 'Plex Media Server ${info.version}' : info.activeUrl,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                if (info.requiresAuth && !info.isAuthenticated) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppIcon(Symbols.lock_rounded, size: 14, color: theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        t.addServer.plexTokenRequired,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          FocusableButton(
            focusNode: _changeServerFocus,
            useBackgroundFocus: true,
            onPressed: busy
                ? null
                : () => setState(() {
                    _serverInfo = null;
                    _tokenController.clear();
                  }),
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      _serverInfo = null;
                      _tokenController.clear();
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
        Row(
          children: [
            const LoadingIndicatorBox(size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.addServer.searchingLocalPlexServers,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ];
    }

    if (_localServers.isEmpty) return const [];
    final tokensRef = tokens(context);
    return [
      const SizedBox(height: 16),
      Text(t.addServer.localPlexServers, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final (i, server) in _localServers.indexed) ...[
        if (i > 0) SizedBox(height: tokensRef.groupGap),
        _DiscoveredPlexServerTile(
          server: server,
          borderRadius: groupItemRadii(context, i, _localServers.length),
          focusNode: _discoveredServerFocusNodes[server.id],
          onTap: busy ? null : () => _useDiscoveredServer(server),
        ),
      ],
      const SizedBox(height: 8),
    ];
  }
}

class _DiscoveredPlexServerTile extends StatelessWidget {
  final DiscoveredPlexServer server;
  final BorderRadius borderRadius;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const _DiscoveredPlexServerTile({
    required this.server,
    required this.borderRadius,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableWrapper(
      focusNode: focusNode,
      disableScale: true,
      delegateFocusBorder: true,
      descendantsAreFocusable: false,
      onSelect: onTap,
      child: CardFocusBorder(
        borderRadii: borderRadius,
        strokeAlign: BorderSide.strokeAlignInside,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const BackendBadge(backend: MediaBackend.plex, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: .min,
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
      ),
    );
  }
}
