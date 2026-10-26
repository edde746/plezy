import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../games/game_discovery.dart';
import '../../games/game_library_controller.dart';
import '../../games/game_models.dart';
import '../../games/game_streaming_client.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_visibility_aware.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/playback_coordinator.dart';
import '../../services/settings_service.dart';
import '../../sources/source_controller.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/setting_tile.dart';
import 'game_connection_dialogs.dart';
import 'game_card.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with FocusableTab, TabVisibilityAware {
  GameLibraryController? _controller;
  final _firstFocus = FocusNode();
  String? _profile;
  int? _sourceGeneration;
  int _epoch = 0;
  bool _loading = true;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<ActiveProfileProvider>().activeId;
    final generation = context.select<SourceController, int>((s) => s.generation);
    if (id == _profile && generation == _sourceGeneration && _controller != null) return;
    _profile = id;
    _sourceGeneration = generation;
    _retire();
    final epoch = ++_epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(id, epoch));
  }

  Future<void> _load(String? id, int epoch) async {
    if (!mounted || epoch != _epoch || id == null) return;
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
        setState(() => _loading = false);
        unawaited(_scan());
      }
    } catch (_) {
      if (mounted && epoch == _epoch) setState(() => _loading = false);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _retire() {
    _controller?.removeListener(_changed);
    _controller?.dispose();
    _controller = null;
    _loading = true;
  }

  @override
  void dispose() {
    _epoch++;
    _retire();
    _firstFocus.dispose();
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

  Future<void> _run(Future<void> Function(GameLibraryController) work) async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    try {
      await c.action(() => work(c));
    } catch (error) {
      if (!mounted || !c.current) return;
      final failure = error is GameClientException ? error.failure : null;
      if (failure == GameClientFailure.cancelled) return;
      showErrorSnackBar(
        context,
        failure == GameClientFailure.pairingRequired
            ? t.games.pairHelp
            : failure == GameClientFailure.timedOut
            ? t.games.timeout
            : t.games.unavailable,
      );
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
    final host = await showDialog<GameHost>(context: context, builder: (_) => const AddGameComputerDialog());
    if (host == null || !mounted || c != _controller) return;
    await _run((c) => c.saveHost(host));
    if (mounted && c == _controller) await _connect(host);
  }

  Future<void> _connect(GameHost host, {bool forcePair = false}) => _run((c) async {
    final capability = await c.client.capabilities(host);
    c.requireCurrent();
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
    final paired = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairGameComputerDialog(host: selected, client: c.client, isCurrent: () => c.current),
    );
    c.requireCurrent();
    if (paired == true) await c.refreshGames(selected);
  });
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
    );
    c.requireCurrent();
    await c.opened(game);
  });
  Future<void> _engineUnavailable(GameHost host) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.games.engineUnavailable),
        scrollable: true,
        content: Text(host.protocol == GameProtocol.steam ? t.games.steamEnginePending : t.games.nativeEnginePending),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.ok))],
      ),
    );
  }

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
        final game = await showDialog<StreamGame>(
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
    title: Text(host.name),
    subtitle: Text('${host.address} · ${host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}'),
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
        onFavorite: c.busy ? null : () => _run((c) => c.toggleFavorite(game)),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final state = c?.library ?? const GameLibrary();
    final byKey = {for (final game in state.games) game.key: game};
    final filtered = state.games.where((game) => game.name.toLowerCase().contains(_query.toLowerCase())).toList()
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
        IconButton(
          tooltip: t.games.help,
          icon: const AppIcon(Symbols.help_outline_rounded),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(t.games.help),
              scrollable: true,
              content: Text(t.games.helpBody),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.ok))],
            ),
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
                      FilledButton.icon(
                        focusNode: filtered.isEmpty ? _firstFocus : null,
                        onPressed: enabled ? _add : null,
                        icon: const AppIcon(Symbols.add_rounded),
                        label: Text(t.games.addComputer),
                      ),
                      OutlinedButton.icon(
                        onPressed: enabled && c?.scanning == false ? _scan : null,
                        icon: const AppIcon(Symbols.radar_rounded),
                        label: Text(c?.scanning == true ? t.games.scanning : t.games.findComputers),
                      ),
                    ],
                  ),
                  if (state.games.isEmpty) ...[const SizedBox(height: 12), Text(t.games.scanHint)],
                  if (_loading || c?.busy == true)
                    const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                ],
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
        if (recent.isNotEmpty) ...[SliverToBoxAdapter(child: _heading(t.games.recent)), _grid(recent, first: true)],
        if (favorites.isNotEmpty) ...[
          SliverToBoxAdapter(child: _heading(t.games.favorites)),
          _grid(favorites, first: recent.isEmpty),
        ],
        if (filtered.isNotEmpty) ...[
          SliverToBoxAdapter(child: _heading(t.games.allGames)),
          _grid(filtered, first: recent.isEmpty && favorites.isEmpty),
        ] else if (state.games.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.all(16), child: Text(t.games.noMatches)),
          ),
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
                        title: Text(host.name),
                        subtitle: Text(
                          '${host.address} · ${host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}',
                        ),
                        leading: const AppIcon(Symbols.computer_rounded),
                        onTap: enabled
                            ? () async {
                                await _run((c) => c.saveHost(host));
                                if (mounted && c.current) await _connect(host);
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
        SliverToBoxAdapter(
          child: SettingsGroup(
            title: t.games.steamBetaTitle,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(t.games.steamLibraryHint)),
              Padding(padding: const EdgeInsets.all(16), child: Text(t.games.steamBetaDescription)),
            ],
          ),
        ),
        if (_profile != null)
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
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
