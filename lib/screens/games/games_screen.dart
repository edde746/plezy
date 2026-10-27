import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/input_mode_tracker.dart';
import '../../games/game_discovery.dart';
import '../../games/game_library_controller.dart';
import '../../games/game_models.dart';
import '../../games/game_streaming_client.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_visibility_aware.dart';
import '../../multiview/steam_game_workspace_surface.dart';
import '../../multiview/workspace_controller.dart';
import '../../multiview/workspace_models.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/playback_coordinator.dart';
import '../../services/trackers/oauth_proxy_client.dart';
import '../../services/settings_service.dart';
import '../../sources/source_controller.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/setting_tile.dart';
import '../libraries/state_messages.dart';
import 'game_connection_dialogs.dart';
import '../../widgets/oauth_proxy_dialog.dart';
import 'game_card.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with FocusableTab, TabVisibilityAware {
  GameLibraryController? _controller;
  MultiviewWorkspaceController? _workspaceController;
  final Map<String, SteamGameWorkspaceSession> _workspaceGameSessions = <String, SteamGameWorkspaceSession>{};
  final _firstFocus = FocusNode(debugLabel: 'First Games action');
  final _addFocus = FocusNode(debugLabel: 'Add gaming computer');
  final _scanFocus = FocusNode(debugLabel: 'Find gaming computers');
  final _searchController = TextEditingController();
  String? _profile;
  int? _sourceGeneration;
  int _epoch = 0;
  bool _loading = true;
  bool _loadFailed = false;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<ActiveProfileProvider>().activeId;
    final generation = context.select<SourceController, int>((s) => s.generation);
    if (id == _profile && generation == _sourceGeneration && _controller != null) return;
    if (id != _profile) {
      _searchController.clear();
      _query = '';
    }
    _profile = id;
    _sourceGeneration = generation;
    _retire();
    final epoch = ++_epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(id, epoch));
  }

  Future<void> _load(String? id, int epoch) async {
    if (!mounted || epoch != _epoch || id == null) return;
    if (!PlatformDetector.supportsEmbeddedGameStreaming()) {
      setState(() => _loading = false);
      return;
    }
    final sources = context.read<SourceController>();
    try {
      await sources.ready;
      if (!mounted || epoch != _epoch) return;
      sources.requireSession();
      if (sources.profileId != id) return;
      final generation = sources.generation;
      final controller = GameLibraryController(
        repository: sources.repository,
        profileId: id,
        sessionCurrent: () =>
            mounted &&
            epoch == _epoch &&
            sources.current(generation) &&
            !sources.blocked &&
            context.read<ActiveProfileProvider>().activeId == id &&
            SettingsService.instance.read(SettingsService.showGamesTabForProfile(id)),
        client: NativeGameStreamingClient(),
      );
      _controller = controller;
      controller.addListener(_changed);
      await controller.load();
      if (mounted && controller.current) {
        setState(() {
          _loading = false;
          _loadFailed = false;
        });
        unawaited(_scan());
      }
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _retire() {
    final workspace = _workspaceController;
    for (final entry in _workspaceGameSessions.entries.toList()) {
      workspace?.unregister(entry.key);
      entry.value.dispose();
    }
    _workspaceGameSessions.clear();
    _workspaceController = null;
    _controller?.removeListener(_changed);
    _controller?.dispose();
    _controller = null;
    _loading = true;
    _loadFailed = false;
  }

  void _retryLoad() {
    final id = _profile;
    if (!mounted || id == null) return;
    _retire();
    final epoch = ++_epoch;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    unawaited(_load(id, epoch));
  }

  @override
  void dispose() {
    _epoch++;
    _retire();
    _firstFocus.dispose();
    _addFocus.dispose();
    _scanFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void focusActiveTabIfReady() {
    _firstFocus.requestFocus();
  }

  @override
  void onTabHidden() {
    _controller?.stopScan();
  }

  @override
  void onTabShown() {
    if (mounted) setState(() {});
  }

  Future<bool> _run(Future<void> Function(GameLibraryController) work) async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return false;
    try {
      await c.action(() => work(c));
      return true;
    } catch (error) {
      if (!mounted || !c.current) return false;
      final failure = error is GameClientException ? error.failure : null;
      if (failure == GameClientFailure.cancelled) return false;
      showErrorSnackBar(
        context,
        failure == GameClientFailure.pairingRequired
            ? t.games.pairHelp
            : failure == GameClientFailure.timedOut
            ? t.games.timeout
            : t.games.unavailable,
      );
      return false;
    }
  }

  Future<void> _linkSteamAccount() => _run((c) async {
    final proxy = OAuthProxyClient();
    try {
      final start = await proxy.start('steam');
      c.requireCurrent();
      if (!mounted) return;
      final cancelled = Completer<void>();
      final navigator = Navigator.of(context, rootNavigator: true);
      var dialogClosedByFlow = false;
      var dialogOpen = true;
      final dialog = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OAuthProxyDialog(
          start: start,
          serviceName: 'Steam',
          onCancel: () {
            if (dialogClosedByFlow) return;
            dialogOpen = false;
            if (!cancelled.isCompleted) cancelled.complete();
          },
        ),
      );
      OAuthProxyResult? result;
      try {
        result = await proxy.poll(
          start.session,
          shouldCancel: () => cancelled.isCompleted || !c.current,
          onCancel: cancelled.future,
        );
      } finally {
        if (dialogOpen) {
          dialogClosedByFlow = true;
          dialogOpen = false;
          if (navigator.mounted) navigator.pop();
        }
        await dialog;
      }
      c.requireCurrent();
      final linked = result;
      if (cancelled.isCompleted || linked == null || linked.steamId == null) return;
      final catalog = linked.steamGames.map(SteamCatalogGame.fromJson).toList(growable: false);
      await c.saveSteamCatalog(
        steamId: linked.steamId!,
        games: catalog,
        catalogAvailable: linked.steamLibraryAvailable,
        catalogTruncated: linked.steamCatalogTruncated,
      );
      if (mounted && c.current) {
        showSuccessSnackBar(
          context,
          linked.steamLibraryAvailable
              ? 'Steam account linked (${catalog.length} games imported)'
              : 'Steam account linked; the game library is private or unavailable',
        );
      }
    } finally {
      proxy.dispose();
    }
  });

  Future<void> _unlinkSteamAccount() async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Unlink Steam account',
      message:
          'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
      confirmText: 'Unlink',
      isDestructive: true,
    );
    if (confirmed && mounted && c == _controller) {
      await _run((active) => active.unlinkSteamAccount());
    }
  }

  Future<void> _scan() async {
    final c = _controller;
    if (c == null || !c.current) return;
    try {
      await c.scan();
    } catch (_) {
      /* Manual entry remains available. */
    }
  }

  Future<void> _add() async {
    final c = _controller;
    final host = await showScopedDialog<GameHost>(context: context, builder: (_) => const AddGameComputerDialog());
    if (host == null || !mounted || c != _controller) return;
    if (!await _run((c) => c.saveHost(host))) return;
    if (mounted && c == _controller) await _connect(host);
  }

  Future<void> _connect(GameHost host, {bool forcePair = false}) => _run((c) async {
    final capability = await c.client.capabilities(host);
    c.requireCurrent();
    if (!mounted) return;
    if (!capability.available || !capability.inlinePairing) {
      await _engineUnavailable(host);
      return;
    }
    final selected = host.protocol == GameProtocol.steam
        ? await identifySteamHost(host)
        : await identifyGameStreamHost(host);
    c.requireCurrent();
    if (selected.key != host.key) await c.removeHost(host);
    await c.saveHost(selected);
    // Already authorized computers open their library without another prompt.
    try {
      if (!forcePair) {
        await c.refreshGames(selected);
        return;
      }
    } on GameClientException catch (error) {
      if (error.failure != GameClientFailure.pairingRequired) rethrow;
    }
    c.requireCurrent();
    if (!mounted) return;
    final paired = await showScopedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairGameComputerDialog(host: selected, client: c.client, isCurrent: () => c.current),
    );
    c.requireCurrent();
    if (paired == true) await c.refreshGames(selected);
  }).then<void>((_) {});
  Future<void> _open(GameHost host, StreamGame game) => _run((c) async {
    final capability = await c.client.capabilities(host);
    c.requireCurrent();
    if (!capability.available) {
      await _engineUnavailable(host);
      return;
    }
    await PlaybackCoordinator.instance.claimVideo();
    await PlaybackCoordinator.instance.shutdownVideo();
    c.requireCurrent();
    await c.client.open(
      host,
      game: game,
      touchControls:
          !PlatformDetector.isTV() &&
          SettingsService.instance.read(SettingsService.gameTouchControlsForProfile(c.profileId)),
      pyrowave:
          host.protocol == GameProtocol.steam &&
          SettingsService.instance.read(SettingsService.gamePyrowaveForProfile(c.profileId)),
    );
    c.requireCurrent();
    await c.opened(game);
  }).then<void>((_) {});
  Future<void> _openCatalogGame(SteamCatalogGame catalogGame) async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    final routes = <GameHost, StreamGame>{};
    for (final host in c.library.hosts) {
      if (host.protocol != GameProtocol.steam) continue;
      for (final game in c.library.games) {
        if (game.hostKey == host.key && game.id == catalogGame.key) {
          routes[host] = game;
          break;
        }
      }
    }
    if (routes.isEmpty) {
      showErrorSnackBar(context, 'Connect a Steam computer and add this game as a shortcut before playing.');
      return;
    }
    final GameHost? host;
    if (routes.length == 1) {
      host = routes.keys.first;
    } else {
      host = await showDialog<GameHost>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(t.games.computers),
          children: [
            for (final choice in routes.keys)
              SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, choice), child: Text(choice.name)),
          ],
        ),
      );
    }
    if (host == null || !mounted || !c.current) return;
    await _open(host, routes[host]!);
  }

  Future<void> _openInWorkspace(GameHost host, StreamGame game) => _run((c) async {
    final capability = await c.client.capabilities(host);
    c.requireCurrent();
    if (!capability.embeddedSurface || host.protocol != GameProtocol.steam || !Platform.isAndroid) {
      await _engineUnavailable(host);
      return;
    }

    final workspace = context.read<MultiviewWorkspaceController>();
    _workspaceController = workspace;
    final sessionId = 'game:${game.key}';
    final existing = workspace.session(sessionId);
    if (existing != null) {
      workspace.showSessionInWorkspace(sessionId);
      workspace.focus(sessionId);
      return;
    }

    final session = SteamGameWorkspaceSession(
      pyrowave: SettingsService.instance.read(SettingsService.gamePyrowaveForProfile(c.profileId)),
      host: host,
      game: game,
      touchControls:
          !PlatformDetector.isTV() &&
          SettingsService.instance.read(SettingsService.gameTouchControlsForProfile(c.profileId)),
    );
    final registration = WorkspaceSurfaceRegistration(
      descriptor: WorkspaceSessionDescriptor(
        id: sessionId,
        kind: MultiviewMediaKind.game,
        title: game.name,
        subtitle: host.name,
        mediaKey: game.key,
        hasAudio: true,
        hasVideo: true,
        acceptsInput: true,
        openedAt: DateTime.now(),
      ),
      buildSurface: (_) => session.workspaceSurface(),
      onRestore: () {
        workspace.showSessionInWorkspace(sessionId, fullscreen: true);
      },
      onClose: () {
        _workspaceGameSessions.remove(sessionId)?.dispose();
      },
      onAudioOwnershipChanged: session.setAudioEnabled,
      onInputOwnershipChanged: session.setInputEnabled,
    );

    if (!workspace.register(registration)) {
      session.dispose();
      showErrorSnackBar(context, t.videoControls.pipFailed);
      return;
    }
    _workspaceGameSessions[sessionId] = session;
    await c.opened(game);
  }).then<void>((_) {});
  Future<void> _engineUnavailable(GameHost host) async {
    if (!mounted) return;
    await showScopedDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.games.engineUnavailable),
        scrollable: true,
        content: Text(host.protocol == GameProtocol.steam ? t.games.steamEnginePending : t.games.nativeEnginePending),
        actions: [
          DialogActionButton(
            autofocus: InputModeTracker.isKeyboardMode(dialogContext, listen: false),
            onPressed: () => Navigator.pop(dialogContext),
            label: t.common.ok,
          ),
        ],
      ),
    );
  }

  Future<void> _showHelp() => showScopedDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.games.help),
      scrollable: true,
      content: Text(t.games.helpBody),
      actions: [
        DialogActionButton(
          autofocus: InputModeTracker.isKeyboardMode(dialogContext, listen: false),
          onPressed: () => Navigator.pop(dialogContext),
          label: t.common.ok,
        ),
      ],
    ),
  );

  Future<void> _hostAction(String action, GameHost host) async {
    switch (action) {
      case 'pair':
        await _connect(host, forcePair: true);
      case 'refresh':
        await _run((c) => c.refreshGames(host));
      case 'wake':
        await _run((c) async {
          await wakeGameHost(host);
          if (mounted && c.current) showSuccessSnackBar(context, t.games.wakeSent);
        });
      case 'forget':
        final c = _controller;
        if (await showConfirmDialog(
              context,
              title: t.games.forget,
              message: t.games.forgetDescription,
              confirmText: t.games.forget,
              isDestructive: true,
            ) &&
            mounted &&
            c == _controller) {
          await _run((c) => c.removeHost(host));
        }
      case 'add':
        final c = _controller;
        final game = await showScopedDialog<StreamGame>(
          context: context,
          builder: (_) => AddGameShortcutDialog(host: host),
        );
        if (game != null && mounted && c == _controller) await _run((c) => c.saveGame(game));
    }
  }

  Widget _host(GameHost host) => FocusableListTile(
    leading: AppIcon(
      host.protocol == GameProtocol.steam ? Symbols.sports_esports_rounded : Symbols.desktop_windows_rounded,
    ),
    title: Text(isolateDisplayText(host.name)),
    subtitle: Text(
      '${isolateDisplayText(host.address)} · ${host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}',
    ),
    onTap: _controller!.busy ? null : () => _connect(host),
    trailing: AppMenuButton<String>(
      tooltip: t.games.computers,
      icon: const AppIcon(Symbols.more_vert_rounded),
      adaptiveSheet: true,
      enabled: !_controller!.busy,
      entriesBuilder: (_) => [
        AppMenuItem(value: 'pair', label: t.games.pair, icon: Symbols.link_rounded),
        AppMenuItem(value: 'refresh', label: t.games.refreshGames, icon: Symbols.refresh_rounded),
        AppMenuItem(value: 'add', label: t.games.addGame, icon: Symbols.add_rounded),
        if (host.mac != null) AppMenuItem(value: 'wake', label: t.games.wake, icon: Symbols.power_settings_new_rounded),
        AppMenuItem(value: 'forget', label: t.games.forget, icon: Symbols.delete_rounded, destructive: true),
      ],
      onSelected: (value) => _hostAction(value, host),
    ),
  );
  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget _grid(List<StreamGame> games, {bool first = false}) => GameCardGrid(
    games: games,
    builder: (context, game) {
      final c = _controller!;
      final host = c.library.hosts.firstWhere((v) => v.key == game.hostKey);
      return GameCard(
        key: ValueKey(game.key),
        game: game,
        host: host,
        artwork: c.artwork,
        favorite: c.library.favorites.contains(game.key),
        focusNode: first && game == games.first ? _firstFocus : null,
        onPlay: c.busy ? null : () => _open(host, game),
        onPlayInWorkspace: c.busy || !Platform.isAndroid || host.protocol != GameProtocol.steam
            ? null
            : () => _openInWorkspace(host, game),
        onFavorite: c.busy ? null : () => _run((c) => c.toggleFavorite(game)),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.supportsEmbeddedGameStreaming()) {
      final theme = Theme.of(context);
      return FocusedScrollScaffold(
        title: Text(t.games.title),
        automaticallyImplyLeading: false,
        slivers: _loadFailed
            ? [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateWidget(
                    message: t.errors.unableToLoad(context: t.games.title),
                    onRetry: _retryLoad,
                    actionAutofocus: PlatformDetector.isTV(),
                  ),
                ),
              ]
            : [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(Symbols.sports_esports_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            t.games.engineUnavailable,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
      );
    }
    final c = _controller;
    final state = c?.library ?? const GameLibrary();
    final byKey = {for (final game in state.games) game.key: game};
    final filtered = state.games.where((game) => game.name.toLowerCase().contains(_query.toLowerCase())).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final steamCatalog =
        state.steamCatalog.where((game) => game.name.toLowerCase().contains(_query.toLowerCase())).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final recent = _query.isEmpty
        ? state.recent.map((key) => byKey[key]).whereType<StreamGame>().take(6).toList()
        : <StreamGame>[];
    final favorites = _query.isEmpty
        ? state.favorites.map((key) => byKey[key]).whereType<StreamGame>().toList()
        : <StreamGame>[];
    final nearby =
        c?.nearby
            .where(
              (host) => !state.hosts.any(
                (saved) => saved.protocol == host.protocol && saved.address == host.address && saved.port == host.port,
              ),
            )
            .toList() ??
        <GameHost>[];
    final enabled = c?.current == true && c?.busy == false;
    return FocusedScrollScaffold(
      title: Text(t.games.title),
      automaticallyImplyLeading: false,
      focusableAppBarActions: true,
      actions: [
        FocusableButton(
          autoScroll: false,
          onPressed: _showHelp,
          child: IconButton(
            tooltip: t.games.help,
            icon: const AppIcon(Symbols.help_outline_rounded),
            onPressed: _showHelp,
          ),
        ),
      ],
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.games.subtitle, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FocusableButton(
                        focusNode: filtered.isEmpty ? _firstFocus : _addFocus,
                        onPressed: enabled ? _add : null,
                        useBackgroundFocus: true,
                        onNavigateRight: enabled && c?.scanning == false ? _scanFocus.requestFocus : null,
                        child: FilledButton.icon(
                          onPressed: enabled ? _add : null,
                          icon: const AppIcon(Symbols.add_rounded),
                          label: Text(t.games.addComputer),
                        ),
                      ),
                      FocusableButton(
                        focusNode: _scanFocus,
                        onPressed: enabled && c?.scanning == false ? _scan : null,
                        onNavigateLeft: () => (filtered.isEmpty ? _firstFocus : _addFocus).requestFocus(),
                        child: OutlinedButton.icon(
                          onPressed: enabled && c?.scanning == false ? _scan : null,
                          icon: const AppIcon(Symbols.radar_rounded),
                          label: Text(c?.scanning == true ? t.games.scanning : t.games.findComputers),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: enabled ? _linkSteamAccount : null,
                        icon: const AppIcon(Symbols.link_rounded),
                        label: Text(state.steamAccountId == null ? 'Link Steam account' : 'Refresh Steam account'),
                      ),
                      if (state.steamAccountId != null)
                        TextButton.icon(
                          onPressed: enabled ? _unlinkSteamAccount : null,
                          icon: const AppIcon(Symbols.link_off_rounded),
                          label: const Text('Unlink Steam account'),
                        ),
                    ],
                  ),
                  if (state.games.isEmpty && state.steamAccountId == null) ...[
                    const SizedBox(height: 12),
                    Text(t.games.scanHint),
                  ],
                  if (_loading || c?.busy == true)
                    const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                ],
              ),
            ),
            if (state.games.isNotEmpty || state.steamCatalog.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: FocusableTextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: t.games.search,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) => _firstFocus.requestFocus(),
                  onNavigateDown: _firstFocus.requestFocus,
                ),
              ),
            if (state.games.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: t.games.search,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
          ]),
        ),
        if (!_loadFailed && recent.isNotEmpty) ...[
          SliverToBoxAdapter(child: _heading(t.games.recent)),
          _grid(recent, first: true),
        ],
        if (!_loadFailed && favorites.isNotEmpty) ...[
          SliverToBoxAdapter(child: _heading(t.games.favorites)),
          _grid(favorites, first: recent.isEmpty),
        ],
        if (!_loadFailed && filtered.isNotEmpty) ...[
          SliverToBoxAdapter(child: _heading(t.games.allGames)),
          _grid(filtered, first: recent.isEmpty && favorites.isEmpty),
        ] else if (state.games.isNotEmpty && steamCatalog.isEmpty)
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.all(16), child: Text(t.games.noMatches)),
          ),
        if (state.steamAccountId != null) ...[
          SliverToBoxAdapter(child: _heading('Steam account library')),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Choose an account game to play through a matching shortcut on a paired Steam computer.'),
            ),
          ),
          if (!state.steamCatalogAvailable)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Steam account linked. Its library is private or unavailable, so no games were imported.'),
              ),
            )
          else if (steamCatalog.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  state.steamCatalog.isEmpty
                      ? 'No games are visible in this Steam account library.'
                      : t.games.noMatches,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final game = steamCatalog[index];
                return ListTile(
                  leading: const AppIcon(Symbols.sports_esports_rounded),
                  title: Text(game.name),
                  subtitle: Text('Steam App ID: ${game.appId}'),
                  onTap: enabled ? () => _openCatalogGame(game) : null,
                );
              }, childCount: steamCatalog.length),
            ),
          if (state.steamCatalogStale)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Steam could not refresh the library. Showing the last available catalog.'),
              ),
            ),
          if (state.steamCatalogTruncated)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Showing up to 2,000 games. The Steam catalog was truncated.'),
              ),
            ),
        ],
        SliverList(
          delegate: SliverChildListDelegate([
            if (!_loading && state.hosts.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(t.games.empty)),
            if (state.hosts.isNotEmpty) ...[
              _heading(t.games.computers),
              SettingsGroup(children: state.hosts.map(_host).toList()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(t.games.libraryHint)),
            ],
            if (c != null && nearby.isNotEmpty) ...[
              _heading(t.games.nearby),
              SettingsGroup(
                children: nearby
                    .map(
                      (host) => FocusableListTile(
                        title: Text(isolateDisplayText(host.name)),
                        subtitle: Text(
                          '${isolateDisplayText(host.address)} · ${host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}',
                        ),
                        leading: const AppIcon(Symbols.computer_rounded),
                        onTap: enabled
                            ? () async {
                                final saved = await _run((c) => c.saveHost(host));
                                if (saved && mounted && c.current) await _connect(host);
                              }
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ] else if (!_loading && c?.scanning == false && state.hosts.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(t.games.noNearby)),
          ]),
        ),
        if (!_loadFailed)
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                Padding(padding: const EdgeInsets.all(16), child: Text(t.games.steamLibraryHint)),
                if (_profile != null && defaultTargetPlatform == TargetPlatform.android)
                  SettingSwitchTile(
                    pref: SettingsService.gamePyrowaveForProfile(_profile!),
                    icon: Symbols.speed_rounded,
                    title: t.games.steamBetaTitle,
                    subtitle: t.games.steamBetaDescription,
                  )
                else
                  Padding(padding: const EdgeInsets.all(16), child: Text(t.games.steamBetaDescription)),
              ],
            ),
          ),
        if (!_loadFailed && _profile != null)
          SliverToBoxAdapter(
            child: SettingsGroup(
              title: t.games.touchSetup,
              children: [
                SettingSwitchTile(
                  pref: SettingsService.gameTouchControlsForProfile(_profile!),
                  icon: Symbols.touch_app_rounded,
                  title: t.games.touchControls,
                  subtitle: t.games.touchDescription,
                ),
                Padding(padding: const EdgeInsets.all(16), child: Text(t.games.touchSetupHint)),
              ],
            ),
          ),
        if (!_loadFailed) const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
