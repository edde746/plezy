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
import '../../games/steam_stream_preferences.dart';
import '../../games/steam_inventory_exchange.dart';
import '../../games/steam_host_actions.dart';
import '../../providers/companion_remote_provider.dart';
import '../../services/file_picker_service.dart';
import '../../services/credential_vault.dart';
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
import 'steam_game_activity_panel.dart';
import 'steam_stream_diagnostics.dart';
import '../settings/settings_utils.dart' show DialogOption;

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
  String? _computerFilter;
  bool _installedOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<ActiveProfileProvider>().activeId;
    final generation = context.select<SourceController, int>((s) => s.generation);
    if (id == _profile && generation == _sourceGeneration && _controller != null) return;
    if (id != _profile) {
      _searchController.clear();
      _query = '';
      _computerFilter = null;
      _installedOnly = false;
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
      final protectedCredential = linked.steamCatalogToken == null
          ? null
          : await CredentialVault.protect(linked.steamCatalogToken!);
      c.requireCurrent();
      await c.saveSteamCatalog(
        protectedCredential: protectedCredential,
        steamId: linked.steamId!,
        games: catalog,
        catalogAvailable: linked.steamLibraryAvailable,
        catalogTruncated: linked.steamCatalogTruncated,
      );
      if (mounted && c.current) {
        showSuccessSnackBar(
          context,
          linked.steamLibraryAvailable ? t.games.steamAccountLinked : t.games.steamLibraryPrivate,
        );
      }
    } finally {
      proxy.dispose();
    }
  });

  Future<void> _refreshSteamAccount() async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    final encrypted = c.library.steamCatalogCredential;
    if (encrypted == null) {
      await _linkSteamAccount();
      return;
    }
    var relink = false;
    await _run((c) async {
      final proxy = OAuthProxyClient();
      try {
        final credential = await CredentialVault.reveal(encrypted);
        c.requireCurrent();
        if (credential == null) {
          relink = true;
          return;
        }
        final result = await proxy.refreshSteamCatalog(credential);
        c.requireCurrent();
        if (result.steamId != c.library.steamAccountId) throw const OAuthProxyException('Steam identity mismatch');
        await c.saveSteamCatalog(
          steamId: result.steamId!,
          games: result.steamGames.map(SteamCatalogGame.fromJson).toList(),
          catalogAvailable: result.steamLibraryAvailable,
          catalogTruncated: result.steamCatalogTruncated,
        );
      } on SteamCatalogRelinkRequired {
        relink = true;
      } finally {
        proxy.dispose();
      }
    });
    if (relink && mounted && c.current) await _linkSteamAccount();
  }

  Future<void> _unlinkSteamAccount() async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    final confirmed = await showConfirmDialog(
      context,
      title: t.games.unlinkSteamAccount,
      message: t.games.unlinkSteamAccountConfirm,
      confirmText: t.games.unlinkSteamAccount,
      isDestructive: true,
    );
    if (confirmed && mounted && c == _controller) {
      await _run((active) async {
        final encrypted = active.library.steamCatalogCredential;
        await active.unlinkSteamAccount();
        if (encrypted != null) {
          final proxy = OAuthProxyClient();
          try {
            final credential = await CredentialVault.reveal(encrypted);
            active.requireCurrent();
            if (credential != null) await proxy.revokeSteamCatalog(credential);
          } catch (_) {
            /* Local unlink succeeds offline; server grants expire. */
          } finally {
            proxy.dispose();
          }
        }
      });
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
  Future<void> _open(GameHost host, StreamGame game) async {
    if (Platform.isAndroid && host.protocol == GameProtocol.steam) {
      await _openInWorkspace(host, game, fullscreen: true);
      return;
    }
    await _run((c) async {
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
      // Opening an Activity is not evidence of a connected stream.
    });
  }

  Future<void> _openLibraryGame(LibraryGame game, {bool choose = false, bool mini = false}) async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    if (game.routes.isEmpty) {
      await _details(game);
      return;
    }
    var route = choose ? null : game.preferredRoute(c.library);
    route ??= await showScopedDialog<GameRoute>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.games.chooseComputer),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(t.games.availabilityHint),
          ),
          for (final choice in game.routes)
            FocusableListTile(
              leading: const AppIcon(Symbols.computer_rounded),
              title: Text(isolateDisplayText(choice.host.name)),
              subtitle: Text(
                '${_installationLabel(choice)} · ${choice.host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}',
              ),
              onTap: () => Navigator.pop(dialogContext, choice),
            ),
        ],
      ),
    );
    if (route == null || !mounted || !c.current) return;
    if (mini) {
      await _openInWorkspace(route.host, route.game);
    } else {
      await _open(route.host, route.game);
    }
  }

  Future<void> _details(LibraryGame game) async {
    final c = _controller;
    if (c == null || !c.current) return;
    final activityIdentity = c.library.steamAccountId;
    final activityCredential = c.library.steamCatalogCredential;
    final choice = await showScopedDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isolateDisplayText(game.name)),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (game.steamAppId != null) Text(t.games.steamSource),
            const SizedBox(height: 12),
            Text(game.routes.isEmpty ? t.games.connectToPlay : t.games.availabilityHint),
            if (!PlatformDetector.supportsEmbeddedGameStreaming()) ...[
              const SizedBox(height: 12),
              Text(t.games.nativeEnginePending),
            ],
            for (final route in game.routes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(Symbols.computer_rounded),
                title: Text(isolateDisplayText(route.host.name)),
                subtitle: Text(
                  '${_installationLabel(route)} · ${route.host.protocol == GameProtocol.steam ? t.games.steam : t.games.moonlight}'
                  '${route.observedAt == null ? '' : '\n${t.games.inventoryChecked(date: MaterialLocalizations.of(context).formatCompactDate(route.observedAt!))}'}',
                ),
                trailing: game.steamAppId != null && route.host.protocol == GameProtocol.steam
                    ? AppMenuButton<SteamHostAction>(
                        tooltip: t.games.hostActions,
                        adaptiveSheet: true,
                        icon: const AppIcon(Symbols.more_vert_rounded),
                        entriesBuilder: (_) => [
                          AppMenuItem(
                            value: SteamHostAction.launch,
                            label: t.games.launchOnComputer,
                            icon: Symbols.play_arrow_rounded,
                          ),
                          AppMenuItem(
                            value: SteamHostAction.install,
                            label: t.games.installOnComputer,
                            icon: Symbols.download_rounded,
                          ),
                        ],
                        onSelected: (action) async {
                          Navigator.pop(dialogContext);
                          await _remoteHostAction(route.host, action, appId: game.steamAppId);
                        },
                      )
                    : null,
              ),
            if (game.steamAppId != null)
              SteamGameActivityPanel(
                appId: game.steamAppId!,
                steamId: activityIdentity,
                protectedCredential: activityCredential,
                isCurrent: () =>
                    c.current &&
                    c.library.steamAccountId == activityIdentity &&
                    c.library.steamCatalogCredential == activityCredential,
                onLink: () => Navigator.pop(dialogContext, 'link'),
              ),
            for (final entry in _workspaceGameSessions.entries.where(
              (entry) => game.routes.any((route) => route.game.key == entry.value.game.key),
            ))
              FocusableListTile(
                leading: const AppIcon(Symbols.monitoring_rounded),
                title: Text(t.games.streamDetails),
                subtitle: Text(isolateDisplayText(entry.value.host.name)),
                onTap: () => Navigator.pop(dialogContext, 'metrics:${entry.key}'),
              ),
          ],
        ),
        actions: [
          DialogActionButton(label: t.common.close, onPressed: () => Navigator.pop(dialogContext)),
          DialogActionButton(
            label: c.library.favoriteKeys.contains(game.key) ? t.games.unfavorite : t.games.favorite,
            onPressed: () => Navigator.pop(dialogContext, 'favorite'),
          ),
          DialogActionButton(
            label: game.routes.isEmpty ? t.games.addComputer : t.games.chooseComputer,
            onPressed: () => Navigator.pop(dialogContext, 'route'),
          ),
        ],
      ),
    );
    if (!mounted || !c.current) return;
    if (choice?.startsWith('metrics:') == true) {
      final session = _workspaceGameSessions[choice!.substring(8)];
      await session?.withInputSuspended(() async {
        if (!mounted || !c.current) return;
        await showScopedDialog<void>(
          context: context,
          builder: (_) => SteamStreamDiagnostics(readMetrics: session.readMetrics),
        );
      });
    }
    if (choice == 'favorite') await _run((c) => c.toggleLibraryFavorite(game));
    if (choice == 'link') await _linkSteamAccount();
    if (choice == 'route') {
      if (game.routes.isEmpty) {
        await _add();
      } else {
        await _openLibraryGame(game, choose: true);
      }
    }
  }

  Future<void> _openInWorkspace(GameHost host, StreamGame game, {bool fullscreen = false}) => _run((c) async {
    final capability = await c.client.capabilities(host);
    if (!mounted || !c.current) return;
    if (!capability.embeddedSurface || host.protocol != GameProtocol.steam || !Platform.isAndroid) {
      await _engineUnavailable(host);
      return;
    }

    final workspace = context.read<MultiviewWorkspaceController>();
    _workspaceController = workspace;
    final sessionId = 'game:${game.key}';
    final existing = workspace.session(sessionId);
    if (existing != null) {
      workspace.showSessionInWorkspace(sessionId, fullscreen: fullscreen);
      workspace.focus(sessionId);
      return;
    }

    final session = SteamGameWorkspaceSession(
      onFirstFrame: () {
        if (c.current && game.id != '0') {
          unawaited(c.connected(GameRoute(host: host, game: game)).catchError((Object _) {}));
        }
      },
      pyrowave: SettingsService.instance.read(SettingsService.gamePyrowaveForProfile(c.profileId)),
      quality: SettingsService.instance.read(SettingsService.steamQualityForProfile(c.profileId)),
      codec: SettingsService.instance.read(SettingsService.steamCodecForProfile(c.profileId)),
      controllerCount: SettingsService.instance.read(SettingsService.steamControllerCountForProfile(c.profileId)),
      audio: SettingsService.instance.read(SettingsService.steamAudioForProfile(c.profileId)),
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
    workspace.showSessionInWorkspace(sessionId, fullscreen: fullscreen);
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

  String _installationLabel(GameRoute route) => switch (route.installation) {
    GameInstallation.installed => t.games.installed,
    GameInstallation.incomplete => t.games.installationIncomplete,
    GameInstallation.notInstalled => t.games.notInstalled,
    GameInstallation.unknown => t.games.installationUnknown,
  };

  Future<void> _importInventory(GameHost host) async {
    final c = _controller;
    if (c == null || !c.current) return;
    final remote = context.read<CompanionRemoteProvider>();
    final peerId = remote.gameInventoryPeerId;
    if (peerId == null || !remote.supportsGameInventory) {
      showErrorSnackBar(context, t.games.inventoryConnectHelp);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: t.games.importInstalledGames,
      confirmText: t.games.importInstalledGames,
      message: t.games.inventoryConfirm(peer: remote.connectedDevice?.name ?? t.games.computers, computer: host.name),
    );
    if (!confirmed || !mounted || !c.current || remote.gameInventoryPeerId != peerId) return;
    await _run((c) async {
      try {
        final inventory = await remote.requestGameInventory();
        c.requireCurrent();
        if (remote.gameInventoryPeerId != peerId) throw const SteamInventoryUnavailable();
        await c.saveInventory(
          SteamHostInventory(
            hostKey: host.key,
            peerId: peerId,
            observedAt: DateTime.now(),
            games: inventory.games,
            complete: inventory.complete,
          ),
        );
        if (mounted && c.current) showSuccessSnackBar(context, t.games.inventoryImported);
      } on SteamInventoryUnavailable {
        if (mounted && c.current) showErrorSnackBar(context, t.games.inventoryConnectHelp);
      }
    });
  }

  Future<void> _chooseSteamFolder() async {
    final c = _controller;
    if (c == null || !c.current) return;
    final path = await FilePickerService.instance.getDirectoryPath(dialogTitle: t.games.steamInstallFolder);
    if (path == null || !mounted || !c.current) return;
    await SettingsService.instance.write(
      SettingsService.steamInstallRootForProfile(c.profileId),
      path,
      checkCurrent: c.requireCurrent,
    );
    if (mounted && c.current) setState(() {});
  }

  Future<void> _remoteHostAction(GameHost host, SteamHostAction action, {int? appId}) async {
    final c = _controller;
    if (c == null || !c.current || c.busy) return;
    final remote = context.read<CompanionRemoteProvider>();
    final snapshot = c.library.inventories.where((i) => i.hostKey == host.key).firstOrNull;
    final peer = remote.gameActionPeerId;
    // A discovered name or matching IP cannot authorize a remote command.
    if (snapshot == null || peer == null || snapshot.peerId != peer) {
      showErrorSnackBar(context, t.games.hostActionPairingHelp);
      return;
    }
    final label = switch (action) {
      SteamHostAction.launch => t.games.launchOnComputer,
      SteamHostAction.install => t.games.installOnComputer,
      SteamHostAction.library => t.games.hostLibrary,
      SteamHostAction.downloads => t.games.hostDownloads,
    };
    final confirmed = await showConfirmDialog(
      context,
      title: label,
      message: t.games.hostActionConfirm(computer: isolateDisplayText(host.name)),
      confirmText: label,
    );
    if (!confirmed || !mounted || !c.current || remote.gameActionPeerId != peer) return;
    await _run((c) async {
      final result = await remote.requestGameAction(action, appId: appId);
      if (!mounted || !c.current || remote.gameActionPeerId != peer) return;
      if (result == SteamHostActionResult.submitted) {
        showSuccessSnackBar(context, t.games.hostActionSubmitted);
      } else {
        showErrorSnackBar(
          context,
          result == SteamHostActionResult.denied ? t.games.hostActionDenied : t.games.unavailable,
        );
      }
    });
  }

  Future<void> _hostAction(String action, GameHost host) async {
    switch (action) {
      case 'hostLibrary':
        await _remoteHostAction(host, SteamHostAction.library);
      case 'hostDownloads':
        await _remoteHostAction(host, SteamHostAction.downloads);
      case 'inventory':
        await _importInventory(host);
      case 'library':
        await _open(host, StreamGame(hostKey: host.key, id: '0', name: t.games.steamLibrary));
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
        if (host.protocol == GameProtocol.steam)
          AppMenuItem(value: 'inventory', label: t.games.importInstalledGames, icon: Symbols.download_rounded),
        if (host.protocol == GameProtocol.steam)
          AppMenuItem(value: 'library', label: t.games.steamLibrary, icon: Symbols.apps_rounded),
        if (host.protocol == GameProtocol.steam) ...[
          AppMenuItem(value: 'hostLibrary', label: t.games.hostLibrary, icon: Symbols.desktop_windows_rounded),
          AppMenuItem(value: 'hostDownloads', label: t.games.hostDownloads, icon: Symbols.download_rounded),
        ],
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
  Widget _grid(List<LibraryGame> games, {bool first = false}) => GameCardGrid<LibraryGame>(
    games: games,
    builder: (context, game) {
      final c = _controller!;
      final route = game.preferredRoute(c.library);
      final cardGame = StreamGame(
        hostKey: route?.host.key ?? 'catalog',
        id: route?.game.id ?? game.key,
        name: game.name,
      );
      return GameCard(
        key: ValueKey(game.key),
        game: cardGame,
        host: route?.host,
        steamAppId: game.steamAppId,
        artwork: c.artwork,
        subtitle: route?.host.name ?? (game.routes.isEmpty ? t.games.connectComputer : t.games.chooseComputer),
        favorite: c.library.favoriteKeys.contains(game.key),
        focusNode: first && game == games.first ? _firstFocus : null,
        playLabel: game.routes.isEmpty ? t.games.gameDetails : t.games.play,
        onPlay: c.busy ? null : () => _openLibraryGame(game),
        onDetails: c.busy ? null : () => _details(game),
        onPlayInWorkspace:
            c.busy || !Platform.isAndroid || !game.routes.any((r) => r.host.protocol == GameProtocol.steam)
            ? null
            : () => _openLibraryGame(game, mini: true),
        onFavorite: c.busy ? null : () => _run((c) => c.toggleLibraryFavorite(game)),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return FocusedScrollScaffold(
        title: Text(t.games.title),
        automaticallyImplyLeading: false,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateWidget(
              message: t.errors.unableToLoad(context: t.games.title),
              onRetry: _retryLoad,
              actionAutofocus: PlatformDetector.isTV(),
            ),
          ),
        ],
      );
    }
    final c = _controller;
    final state = c?.library ?? const GameLibrary();
    final entries = state.entries;
    final byKey = {for (final game in entries) game.key: game};
    final filtered =
        entries
            .where(
              (game) =>
                  game.name.toLowerCase().contains(_query.trim().toLowerCase()) &&
                      game.routes
                          .where((route) => _computerFilter == null || route.host.key == _computerFilter)
                          .any((route) => !_installedOnly || route.installation == GameInstallation.installed) ||
                  (_computerFilter == null &&
                      !_installedOnly &&
                      game.routes.isEmpty &&
                      game.name.toLowerCase().contains(_query.trim().toLowerCase())),
            )
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final recent = _query.isEmpty
        ? state.recentKeys.map((key) => byKey[key]).whereType<LibraryGame>().where(filtered.contains).take(6).toList()
        : <LibraryGame>[];
    final favorites = _query.isEmpty
        ? state.favoriteKeys.map((key) => byKey[key]).whereType<LibraryGame>().where(filtered.contains).toList()
        : <LibraryGame>[];
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
                        onPressed: enabled
                            ? (state.steamAccountId == null ? _linkSteamAccount : _refreshSteamAccount)
                            : null,
                        icon: const AppIcon(Symbols.link_rounded),
                        label: Text(
                          state.steamAccountId == null ? t.games.linkSteamAccount : t.games.refreshSteamAccount,
                        ),
                      ),
                      if (state.steamAccountId != null)
                        TextButton.icon(
                          onPressed: enabled ? _unlinkSteamAccount : null,
                          icon: const AppIcon(Symbols.link_off_rounded),
                          label: Text(t.games.unlinkSteamAccount),
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
          ]),
        ),
        if (state.hosts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(t.games.installed),
                    selected: _installedOnly,
                    onSelected: (selected) => setState(() => _installedOnly = selected),
                  ),
                  ChoiceChip(
                    label: Text(t.games.allComputers),
                    selected: _computerFilter == null,
                    onSelected: (_) => setState(() => _computerFilter = null),
                  ),
                  for (final host in state.hosts)
                    ChoiceChip(
                      label: Text(isolateDisplayText(host.name)),
                      selected: _computerFilter == host.key,
                      onSelected: (_) => setState(() => _computerFilter = host.key),
                    ),
                ],
              ),
            ),
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
        ] else if (entries.isNotEmpty && filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.all(16), child: Text(t.games.noMatches)),
          ),
        if (state.steamAccountId != null) ...[
          SliverToBoxAdapter(child: _heading(t.games.steamLibrary)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(t.games.availabilityHint),
            ),
          ),
          if (!state.steamCatalogAvailable)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(t.games.steamLibraryPrivate),
              ),
            ),
          if (state.steamCatalogStale)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(t.games.steamLibraryStale),
              ),
            ),
          if (state.steamCatalogTruncated)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(t.games.steamLibraryTruncated),
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
                Padding(padding: const EdgeInsets.all(16), child: Text(t.games.availabilityHint)),
                if (_profile != null && PlatformDetector.supportsEmbeddedGameStreaming()) ...[
                  SettingSelectionTile<SteamStreamQuality>(
                    pref: SettingsService.steamQualityForProfile(_profile!),
                    icon: Symbols.tune_rounded,
                    title: t.games.streamQuality,
                    subtitleBuilder: _qualityLabel,
                    description: t.games.streamQualityHelp,
                    options: [
                      for (final quality in SteamStreamQuality.values)
                        DialogOption(
                          value: quality,
                          title: _qualityLabel(quality),
                          subtitle: '${quality.height}p · ${quality.fps} fps · ${quality.bitrateKbps ~/ 1000} Mbps',
                        ),
                    ],
                  ),
                  SettingSelectionTile<SteamStreamCodec>(
                    pref: SettingsService.steamCodecForProfile(_profile!),
                    icon: Symbols.movie_rounded,
                    title: t.games.streamCodec,
                    subtitleBuilder: (codec) => codec == SteamStreamCodec.automatic ? t.games.codecAutomatic : 'H.264',
                    description: t.games.streamCodecHelp,
                    options: [
                      DialogOption(value: SteamStreamCodec.automatic, title: t.games.codecAutomatic),
                      const DialogOption(value: SteamStreamCodec.h264, title: 'H.264'),
                    ],
                  ),
                  SettingSelectionTile<SteamStreamAudio>(
                    pref: SettingsService.steamAudioForProfile(_profile!),
                    icon: Symbols.surround_sound_rounded,
                    title: t.games.streamAudio,
                    subtitleBuilder: _audioLabel,
                    description: t.games.streamAudioHelp,
                    options: [
                      for (final audio in SteamStreamAudio.values)
                        DialogOption(value: audio, title: _audioLabel(audio)),
                    ],
                  ),
                  SettingSelectionTile<int>(
                    pref: SettingsService.steamControllerCountForProfile(_profile!),
                    icon: Symbols.sports_esports_rounded,
                    title: t.games.controllerSeats,
                    subtitleBuilder: (count) => '$count',
                    description: t.games.controllerSeatsHelp,
                    options: [for (var count = 1; count <= 4; count++) DialogOption(value: count, title: '$count')],
                  ),
                ],
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
                if (PlatformDetector.supportsEmbeddedGameStreaming())
                  SettingSwitchTile(
                    pref: SettingsService.allowGameSessionControlForProfile(_profile!),
                    icon: Symbols.phonelink_rounded,
                    title: t.games.allowSessionControl,
                    subtitle: t.games.allowSessionControlHelp,
                  ),
              ],
            ),
          ),
        if (_profile != null && PlatformDetector.isDesktopOS())
          SliverToBoxAdapter(
            child: SettingsGroup(
              title: t.games.shareLibrary,
              children: [
                SettingSwitchTile(
                  pref: SettingsService.shareSteamInventoryForProfile(_profile!),
                  icon: Symbols.library_books_rounded,
                  title: t.games.shareLibrary,
                  subtitle: t.games.shareLibraryHelp,
                ),
                SettingSwitchTile(
                  pref: SettingsService.allowSteamActionsForProfile(_profile!),
                  icon: Symbols.security_rounded,
                  title: t.games.allowHostActions,
                  subtitle: t.games.allowHostActionsHelp,
                ),
                SettingSwitchTile(
                  pref: SettingsService.allowSteamInstallForProfile(_profile!),
                  icon: Symbols.download_rounded,
                  title: t.games.allowHostInstall,
                  subtitle: t.games.allowHostInstallHelp,
                ),
                FocusableListTile(
                  leading: const AppIcon(Symbols.folder_rounded),
                  title: Text(t.games.steamInstallFolder),
                  subtitle: Text(
                    SettingsService.instance.read(SettingsService.steamInstallRootForProfile(_profile!)) ??
                        t.games.automaticFolder,
                  ),
                  onTap: _chooseSteamFolder,
                ),
              ],
            ),
          ),
        if (!_loadFailed) const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  String _audioLabel(SteamStreamAudio audio) => switch (audio) {
    SteamStreamAudio.stereo => t.games.audioStereo,
    SteamStreamAudio.quad => t.games.audioQuad,
    SteamStreamAudio.surround51 => t.games.audioSurround51,
  };

  String _qualityLabel(SteamStreamQuality quality) => switch (quality) {
    SteamStreamQuality.balanced => t.games.qualityBalanced,
    SteamStreamQuality.reducedBandwidth => t.games.qualityReducedBandwidth,
    SteamStreamQuality.sharperPicture => t.games.qualitySharperPicture,
    SteamStreamQuality.reducedFrameRate => t.games.qualityReducedFrameRate,
  };
}
