import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../providers/multi_server_provider.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../services/music_assistant/music_assistant_api.dart';
import '../../services/music_assistant/music_assistant_models.dart';
import '../../services/music_assistant_lan_discovery_service.dart';
import '../../services/music_assistant_mappers.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/device_identity.dart';
import '../../utils/log_redaction_manager.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import '../profile/profile_switch_screen.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';
import 'local_server_discovery.dart';

/// Port Music Assistant listens on out of the box.
const int _defaultMusicAssistantPort = 8095;

/// Row id for a Music Assistant connection.
///
/// Derived from the server's own `server_id` rather than minted fresh, so
/// re-adding a server the user already has upserts the existing row instead of
/// creating a duplicate that would register a second client for one server.
///
/// The cost of that convenience is that the id is chosen by the *server*: a
/// greeting is unauthenticated, so anything on the network can claim any
/// `server_id` it likes and the upsert will then repoint the matching row's
/// `baseUrl`. See [confirmMusicAssistantRepoint] — the id keeps its
/// deduplicating job, and the address change it can cause is never silent.
@visibleForTesting
String musicAssistantConnectionId(String serverId) => 'ma-$serverId';

/// Whether saving [incoming] would silently move an existing connection to a
/// different address.
///
/// True only when a row with the same id already exists *and* its URL differs.
/// A re-add of the same server at the same address — the ordinary case, and
/// the one the shared id exists for — is not a repoint and must not prompt.
@visibleForTesting
bool isMusicAssistantRepoint({required Connection? existing, required MusicAssistantConnection incoming}) {
  if (existing is! MusicAssistantConnection) return false;
  return existing.baseUrl != incoming.baseUrl;
}

/// Fill in what the user left out. Music Assistant's default port is not 80 and
/// its URL is invariably typed as a bare LAN address, so `10.0.2.107` alone must
/// resolve to `http://10.0.2.107:8095` or the obvious input fails to connect.
@visibleForTesting
String? normalizeMusicAssistantUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';

  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  // `ws`/`wss` are what a user copies out of Music Assistant's own settings;
  // the connection stores the HTTP form because the image proxy and the flow
  // stream are derived from it. MusicAssistantApi re-derives the socket URL.
  final scheme = switch (uri.scheme) {
    'ws' => 'http',
    'wss' => 'https',
    'http' || 'https' => uri.scheme,
    _ => null,
  };
  if (scheme == null) return null;

  // A trailing `/ws` is the endpoint, not the server root.
  var path = uri.path.replaceAll(RegExp(r'/+$'), '');
  if (path.endsWith('/ws')) path = path.substring(0, path.length - 3);

  return Uri(
    scheme: scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : (scheme == 'https' ? null : _defaultMusicAssistantPort),
    path: path,
  ).toString();
}

/// Add a Music Assistant server, by finding it rather than by describing it.
///
/// ### Discovery is the path, not the shortcut
///
/// This screen used to open on an empty URL field, with the servers found on
/// the network listed underneath it as a convenience. That has the shape
/// backwards. Music Assistant advertises itself over mDNS as `_mass._tcp`, the
/// browse takes about two and a half seconds, and on the network of anyone who
/// has a server the answer is already there before the user could have typed
/// the first octet. Asking for an address first makes every user do by hand
/// the thing the network already answered.
///
/// So the found servers are the body of the screen and a single tap on one
/// adds it outright — probe, name, persist, bind, pop — with no form to fill
/// in between. Typing an address is still available, one tap away, for the
/// cases discovery genuinely cannot reach: a server on another subnet, a
/// reverse proxy, mDNS blocked by the access point.
///
/// ### One tap is still not a silent tap
///
/// The row id is derived from the advertised `server_id`, and an advert is
/// unauthenticated — anything on the link can claim any id. That is what makes
/// one-tap add safe to offer *and* what makes [_confirmRepointIfNeeded]
/// non-negotiable: the tap is allowed to add a server, and is never allowed to
/// quietly move an existing one to a new address. Reducing the number of taps
/// must not reduce the number of decisions the user is shown.
///
/// The advertised instance name being the `server_id` also means an
/// already-added server can be recognised *before* any connection is opened,
/// so the list marks it rather than offering a second add that would resolve
/// to the same row.
///
/// ### The steps behind either path
///   1. Probe a URL by opening the WebSocket and reading the greeting frame,
///      which is the only thing that proves both that the address is reachable
///      *and* that what is listening is Music Assistant. There is no cheaper
///      HTTP identity endpoint to use instead.
///   2. Persist via [persistAndBindConnection] and bind it to the target (or
///      active) profile, exactly as [AddJellyfinScreen] does.
///
/// The probe also asks whether the server wants a sign-in, because the greeting
/// cannot say. A server from before accounts existed adds in one tap, as it
/// always did. Anything newer lands on the form, and what gets stored is a
/// long-lived token; the password goes no further than the sign-in itself.
class AddMusicAssistantScreen extends StatefulWidget {
  /// When set, the new connection is bound to this profile. When null, falls
  /// back to the currently active profile.
  final Profile? targetProfile;
  final FutureOr<List<DiscoveredMusicAssistantServer>> Function()? _localDiscoveryFactory;
  final MusicAssistantApi Function()? _apiFactory;

  const AddMusicAssistantScreen({
    super.key,
    this.targetProfile,
    @visibleForTesting this._localDiscoveryFactory,
    @visibleForTesting this._apiFactory,
  });

  @override
  State<AddMusicAssistantScreen> createState() => _AddMusicAssistantScreenState();
}

class _AddMusicAssistantScreenState extends State<AddMusicAssistantScreen>
    with
        AsyncFormStateMixin,
        ControllerDisposerMixin,
        LocalServerDiscoveryMixin<DiscoveredMusicAssistantServer, AddMusicAssistantScreen> {
  late final _urlController = createTextEditingController();
  late final _tokenController = createTextEditingController();
  late final _usernameController = createTextEditingController();
  late final _passwordController = createTextEditingController();
  late final _nameController = createTextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'AddMusicAssistant:Url');
  final _findServerFocus = FocusNode(debugLabel: 'AddMusicAssistant:FindServer');
  final _changeServerFocus = FocusNode(debugLabel: 'AddMusicAssistant:ChangeServer');
  final _searchAgainFocus = FocusNode(debugLabel: 'AddMusicAssistant:SearchAgain');
  final _manualToggleFocus = FocusNode(debugLabel: 'AddMusicAssistant:EnterManually');
  final _nameFocus = FocusNode(debugLabel: 'AddMusicAssistant:Name');
  final _tokenFocus = FocusNode(debugLabel: 'AddMusicAssistant:Token');
  final _usernameFocus = FocusNode(debugLabel: 'AddMusicAssistant:Username');
  final _passwordFocus = FocusNode(debugLabel: 'AddMusicAssistant:Password');
  final _addFocus = FocusNode(debugLabel: 'AddMusicAssistant:Add');
  final _formKey = GlobalKey<FormState>();

  MaServerInfo? _serverInfo;

  /// The URL the greeting actually arrived on — preferred over the greeting's
  /// own `base_url`, which on a containerised or multi-homed host is routinely
  /// an address this device cannot reach.
  String? _resolvedBaseUrl;

  /// Whether the resolved server refused an unauthenticated socket.
  bool _requiresSignIn = false;

  /// Whether the type-an-address fallback is on screen.
  ///
  /// Starts closed. It opens by itself only when discovery has finished and
  /// found nothing, because at that point it is no longer a fallback — it is
  /// the only way forward, and making the user press one more button to reach
  /// it would be a wall in front of the door.
  bool _manualEntry = false;

  /// The discovered server currently being added, so its own row can show the
  /// progress instead of the whole screen going busy.
  String? _addingServerId;

  /// `server_id`s already saved as connections.
  ///
  /// Knowable without opening a socket: the advertised instance name *is* the
  /// `server_id`, and the connection row id is derived from it. So a server
  /// the user already has can be marked as such straight from the advert,
  /// rather than by connecting to it to find out.
  Set<String> _savedServerIds = const {};

  /// The saved servers that still need a sign-in, and so stay tappable: rows
  /// saved before the server wanted one, and tokens it has since refused. This
  /// screen is where "Sign in again" leads, so it must not be a dead end.
  Set<String> _needsSignInServerIds = const {};

  /// What each saved server is called, so signing in again keeps the name.
  Map<String, String> _savedNames = const {};

  @override
  String get discoveryDebugLabel => 'AddMusicAssistant';

  @override
  String discoveredServerId(DiscoveredMusicAssistantServer server) => server.id;

  @override
  Future<List<DiscoveredMusicAssistantServer>> discoverLocalServers() async {
    final factory = widget._localDiscoveryFactory;
    return factory != null ? await factory() : await MusicAssistantLanDiscoveryService().discover();
  }

  @override
  void initState() {
    super.initState();
    startLocalDiscovery();
    unawaited(_loadSavedServerIds());
  }

  /// Read which Music Assistant servers are already saved.
  ///
  /// Best-effort: a failure here only costs the "Already added" marker, and
  /// re-adding a saved server at the same address is a harmless upsert, so a
  /// registry that cannot be read must not stop the screen working.
  Future<void> _loadSavedServerIds() async {
    try {
      final rejected = context.read<MultiServerProvider?>()?.authErrorServerIds ?? const <String>[];
      final connections = await context.read<ConnectionRegistry>().list();
      if (!mounted) return;
      // Both, because they are not always the same thing. The row id is what an
      // add would upsert, and is derived from `server_id` for anything added
      // since; the stored `serverId` column covers rows written before that and
      // is null on none of them that matter. Matching either avoids offering to
      // "add" a server the user is already looking at in their connection list.
      Iterable<String> idsOf(MusicAssistantConnection connection) => [
        if (connection.serverId case final String id) id,
        if (connection.id.startsWith('ma-')) connection.id.substring(3),
      ];
      final saved = connections.whereType<MusicAssistantConnection>();
      setState(() {
        _savedServerIds = {for (final connection in saved) ...idsOf(connection)};
        _needsSignInServerIds = {
          for (final connection in saved)
            if (connection.accessToken == null || idsOf(connection).any(rejected.contains)) ...idsOf(connection),
        };
        _savedNames = {
          for (final connection in saved)
            for (final id in idsOf(connection)) id: connection.displayName,
        };
      });
    } catch (e) {
      // Type only: the miss this most often hits is a missing provider, whose
      // `toString` is thirty lines of framework advice that would drown a test
      // run for something the screen already handles.
      appLogger.d('Could not read saved Music Assistant connections: ${e.runtimeType}');
    }
  }

  @override
  void dispose() {
    disposeLocalDiscovery();
    _urlFocus.dispose();
    _findServerFocus.dispose();
    _changeServerFocus.dispose();
    _searchAgainFocus.dispose();
    _manualToggleFocus.dispose();
    _nameFocus.dispose();
    _tokenFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  void _clearResolvedServer() {
    _serverInfo = null;
    _resolvedBaseUrl = null;
    _requiresSignIn = false;
  }

  /// One tap: probe the advertised address and, if it answers, add it.
  ///
  /// No intermediate form. Everything the manual path asks for is either
  /// already known (the address, from the advert) or has a right answer for a
  /// server found this way (the display name, which
  /// [MusicAssistantClient.serverName] is going to replace with something
  /// better than an address anyway). A server that wants a sign-in is the one
  /// exception, and stops on the form instead of being added.
  ///
  /// The probe still happens. The advert proves something is announcing itself
  /// as Music Assistant, not that it is reachable from here or that it is
  /// really Music Assistant, and the greeting is the only thing that proves
  /// both.
  Future<void> _useDiscoveredServer(DiscoveredMusicAssistantServer server) async {
    if (busy || _addingServerId != null) return;
    setState(() {
      _addingServerId = server.id;
      _urlController.text = server.address;
      _nameController.text = _savedNames[server.id] ?? _nameController.text;
      _clearResolvedServer();
    });
    try {
      await _probe();
      if (!mounted || _serverInfo == null || _requiresSignIn) return;
      if (_nameController.text.trim().isEmpty) _nameController.text = musicAssistantDefaultName;
      await _persistResolvedServer();
    } finally {
      // `mounted` is false on the success path — `_persistAndExit` pops.
      if (mounted) setState(() => _addingServerId = null);
    }
  }

  /// Open the socket, read the greeting, find out whether it wants a sign-in,
  /// close it again.
  ///
  /// Deliberately a throwaway [MusicAssistantApi] with `autoReconnect: false`:
  /// a mistyped address must fail here and stay failed, not leave a retry loop
  /// running behind a form the user has already backed out of.
  Future<void> _probe() async {
    final url = normalizeMusicAssistantUrl(_urlController.text);
    if (url == null) {
      setErrorText(t.addServer.enterMusicAssistantUrlError);
      return;
    }
    // Registered before the probe, not after it succeeds: the failure path is
    // the one that logs the URL, and every failed probe writes it to a log
    // buffer the user can upload. An IP is covered by the generic pattern, a
    // hostname is not covered by anything until it is registered.
    LogRedactionManager.registerServerUrl(url);
    await runAsync<void>(
      () async {
        final api = _oneShotApi();
        final MaServerInfo info;
        final bool requiresSignIn;
        try {
          info = await api.connect(Uri.parse(url));
          requiresSignIn = await api.requiresSignIn();
        } finally {
          unawaited(api.dispose());
        }
        if (!mounted) return;
        setState(() {
          _serverInfo = info;
          _resolvedBaseUrl = url;
          _requiresSignIn = requiresSignIn;
          _urlController.text = url;
          if (_nameController.text.trim().isEmpty) _nameController.text = musicAssistantDefaultName;
        });
        // Only when the form is what the user is looking at. On the one-tap
        // path the Add button never renders, and moving focus to a node that
        // is not in the tree strands a D-pad between two screens.
        if (requiresSignIn) {
          _requestFocusAfterFrame(_usernameFocus);
        } else if (_addingServerId == null) {
          _requestFocusAfterFrame(_addFocus);
        }
      },
      errorMapper: (e) {
        appLogger.w('Music Assistant probe failed for $url', error: e);
        // "Nothing answered" gets its own message because it has its own fix.
        // The generic one invites the user to re-check an address that is
        // usually correct — the address a browser on the same phone can reach
        // — while the thing actually blocking it is a permission they have no
        // reason to connect to this screen.
        if (e is MaUnreachableException) return t.addServer.musicAssistantUnreachable(address: e.address);
        return t.addServer.couldNotReachServer(error: e is MaException ? e.message : e.toString());
      },
    );
  }

  /// A socket that lives for one step of this form.
  MusicAssistantApi _oneShotApi() =>
      widget._apiFactory?.call() ??
      // Deliberately more generous than the background client's ten
      // seconds. This is a one-shot the user is watching, with
      // `autoReconnect: false` and nothing behind it — a premature
      // failure costs them the whole form, while a slow success costs
      // only the spinner. The first connection to a LAN address is also
      // the one iOS may hold while it asks the user for local-network
      // access, and a budget under that prompt's lifetime fails a server
      // that was about to work.
      MusicAssistantApi(autoReconnect: false, handshakeTimeout: const Duration(seconds: 20));

  /// The manual path's Add button: validate the form first, then persist.
  Future<void> _add() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_serverInfo == null || _resolvedBaseUrl == null) {
      await _probe();
      return;
    }
    if (!_requiresSignIn) {
      await _persistResolvedServer();
      return;
    }
    final token = await _signIn();
    if (token != null) await _persistResolvedServer(token: token);
  }

  /// Turn what the form holds into a token the server has accepted, or null
  /// with the reason on screen.
  ///
  /// A pasted token is checked here too. Stored unchecked, a typo would only
  /// surface later as a banner saying the session expired.
  Future<String?> _signIn() {
    final url = _resolvedBaseUrl!;
    final pasted = _tokenController.text.trim();
    return runAsync<String>(
      () async {
        final api = _oneShotApi();
        try {
          await api.connect(Uri.parse(url), accessToken: pasted.isEmpty ? null : pasted);
          if (pasted.isEmpty) {
            return await api.signIn(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              tokenName: await _tokenName(),
            );
          }
          if (await api.requiresSignIn()) {
            throw const MaRequestException('auth', 23, 'The access token is invalid or has expired.');
          }
          return pasted;
        } finally {
          unawaited(api.dispose());
        }
      },
      errorMapper: (e) {
        appLogger.w('Music Assistant sign-in failed', error: e);
        if (e is MaRequestException && e.isAuthFailure) return t.addServer.musicAssistantSignInRejected;
        return t.addServer.signInFailed(error: e is MaException ? e.message : e.toString());
      },
    );
  }

  /// What the token is called in Music Assistant's own list of them, which is
  /// where someone goes to revoke it, so it has to name the device.
  static Future<String> _tokenName() async {
    try {
      final name = (await DeviceIdentityService.resolve()).deviceName?.trim();
      if (name != null && name.isNotEmpty) return 'Plezy ($name)';
    } catch (e) {
      appLogger.d('Could not resolve a device name for the Music Assistant token: $e');
    }
    return 'Plezy';
  }

  /// Persist whatever the last successful probe resolved.
  ///
  /// Split out of [_add] because the one-tap path has no form to validate —
  /// its fields are not on screen — and running `validate()` against a form
  /// whose only field is absent is at best a no-op and at worst, once the
  /// manual section has been opened and left empty, a refusal to add a server
  /// the user just tapped.
  Future<void> _persistResolvedServer({String? token}) async {
    final info = _serverInfo;
    final baseUrl = _resolvedBaseUrl;
    if (info == null || baseUrl == null) return;
    final name = _nameController.text.trim();
    final accessToken = token ?? _tokenController.text.trim();
    // It is about to travel through the persistence layer's own logging.
    // Registering it costs a set insertion and removes a whole class of future
    // leak.
    LogRedactionManager.registerToken(accessToken.isEmpty ? null : accessToken);
    await runAsync<void>(
      () async {
        final connection = MusicAssistantConnection(
          id: musicAssistantConnectionId(info.serverId),
          displayName: name.isEmpty ? musicAssistantDefaultName : name,
          baseUrl: baseUrl,
          serverId: info.serverId,
          serverVersion: info.serverVersion,
          accessToken: accessToken.isEmpty ? null : accessToken,
          createdAt: DateTime.now(),
          lastAuthenticatedAt: DateTime.now(),
        );
        if (!await _confirmRepointIfNeeded(connection)) return;
        await _persistAndExit(connection);
      },
      errorMapper: (e) {
        appLogger.e('Add Music Assistant failed', error: e);
        return t.addServer.signInFailed(error: e.toString());
      },
    );
  }

  /// Ask before letting an add move an existing connection's address.
  ///
  /// The row id is `ma-<server_id>`, and `server_id` comes from an
  /// unauthenticated greeting. A server on the network that claims the same
  /// `server_id` as the user's real one therefore upserts the user's row and
  /// takes over its `baseUrl` — silently, from a list the user was invited to
  /// tap. Discovery makes that a one-tap operation, so the change is confirmed
  /// with both addresses on screen. It is not blocked: moving a server to a
  /// new address is a thing people legitimately do.
  Future<bool> _confirmRepointIfNeeded(MusicAssistantConnection incoming) async {
    final existing = await context.read<ConnectionRegistry>().get(incoming.id);
    if (!mounted) return false;
    if (!isMusicAssistantRepoint(existing: existing, incoming: incoming)) return true;
    final current = existing! as MusicAssistantConnection;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.addServer.musicAssistantRepointTitle),
        content: Text(
          t.addServer.musicAssistantRepointBody(
            name: current.displayName,
            current: current.baseUrl,
            replacement: incoming.baseUrl,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.addServer.musicAssistantRepointConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Same shape as the Jellyfin flow: atomically provision the optional
  /// first-run profile, the connection and the ownership row, then rebind and
  /// pop only after durable success.
  Future<void> _persistAndExit(MusicAssistantConnection connection) async {
    if (!mounted) return;
    final activeProvider = context.read<ActiveProfileProvider>();
    await activeProvider.initialize();
    if (!mounted) return;
    final targetProfile = widget.targetProfile;
    var boundProfile = targetProfile ?? activeProvider.active;
    if (shouldPromptForProfileSelection(
      targetProfile: targetProfile,
      activeProfile: activeProvider.active,
      hasProfiles: activeProvider.profiles.isNotEmpty,
    )) {
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
    if (shouldCreateFirstRunProfile(
      targetProfile: targetProfile,
      activeProfile: boundProfile,
      hasProfiles: activeProvider.profiles.isNotEmpty,
    )) {
      final now = DateTime.now();
      firstRunProfile = Profile.local(
        // Music Assistant has no user to name the profile after, so the server
        // label is the only meaningful thing to call it.
        id: 'local-${const Uuid().v4()}',
        displayName: connection.displayName,
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
        // No per-user token and no user identity to record here: the token
        // belongs to the connection, so one Music Assistant connection is one
        // server account, shared by every profile bound to it.
        userToken: '',
        userIdentifier: '',
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

  void _requestFocusAfterFrame(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !node.canRequestFocus) return;
      node.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusedScrollScaffold(
      title: Text(t.addServer.addMusicAssistantTitle),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: .stretch, children: _buildBodyChildren(theme)),
            ),
          ),
        ),
      ],
    );
  }

  /// The screen has three shapes, in the order a user meets them:
  ///
  ///  * **Nothing resolved yet** — the discovery list, and a way to type an
  ///    address if it is not enough. This is the shape almost everyone sees,
  ///    and almost everyone leaves it by tapping a row.
  ///  * **Manual entry open** — the URL field and its Find button, unchanged
  ///    from before except that it is now something the user asked for.
  ///  * **A server resolved by hand, or one that wants a sign-in** — the
  ///    confirmation card, display name, and token or credentials. The
  ///    one-tap path only reaches this shape when it has something to ask.
  List<Widget> _buildBodyChildren(ThemeData theme) {
    if (_serverInfo != null) return _buildResolvedServerChildren(theme);
    return [
      ..._buildLocalDiscoverySection(theme),
      if (!isDiscoveringLocalServers && localServers.isEmpty) ..._buildNothingFound(theme),
      if (!isDiscoveringLocalServers) ..._buildManualEntry(theme),
      ...buildInlineError(theme),
    ];
  }

  /// Shown when the browse came back empty.
  ///
  /// Deliberately says what to check before offering the retry: the two
  /// reasons a browse finds nothing on a network that has a server are the
  /// phone being on a different SSID (guest network, or 5GHz/2.4GHz split with
  /// isolation) and the server being off. Neither is fixed by pressing search
  /// again, so the button comes after the sentence rather than instead of it.
  List<Widget> _buildNothingFound(ThemeData theme) => [
    const SizedBox(height: 8),
    Text(t.addServer.musicAssistantNoneFound, style: theme.textTheme.titleSmall),
    const SizedBox(height: 4),
    Text(
      t.addServer.musicAssistantNoneFoundDetail,
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
    ),
    const SizedBox(height: 12),
    FocusableButton(
      focusNode: _searchAgainFocus,
      useBackgroundFocus: true,
      onNavigateDown: () => (_manualEntry ? _urlFocus : _manualToggleFocus).requestFocus(),
      onPressed: busy ? null : restartLocalDiscovery,
      child: OutlinedButton.icon(
        onPressed: busy ? null : restartLocalDiscovery,
        icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
        label: Text(t.addServer.musicAssistantSearchAgain),
      ),
    ),
  ];

  /// The type-an-address fallback.
  ///
  /// Collapsed to a single text button until it is wanted, so the primary
  /// screen is the list of real servers rather than an empty field. Opens
  /// itself when discovery found nothing, because then it is not a fallback.
  List<Widget> _buildManualEntry(ThemeData theme) {
    final expanded = _manualEntry || localServers.isEmpty;
    if (!expanded) {
      return [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FocusableButton(
            focusNode: _manualToggleFocus,
            useBackgroundFocus: true,
            onNavigateUp: () => focusLastDiscoveredServerOr(_manualToggleFocus),
            onPressed: busy ? null : () => setState(() => _manualEntry = true),
            child: TextButton.icon(
              onPressed: busy ? null : () => setState(() => _manualEntry = true),
              icon: const AppIcon(Symbols.keyboard_rounded, fill: 1),
              label: Text(t.addServer.musicAssistantEnterManually),
            ),
          ),
        ),
      ];
    }

    return [
      const SizedBox(height: 16),
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        tvTextInputPresentation: PlatformDetector.isAppleTV()
            ? TvTextInputPresentation.platform
            : TvTextInputPresentation.automatic,
        // Only steals the keyboard when there is nothing else to do. With
        // servers on screen the first thing that happens must be the list
        // appearing, not a keyboard covering it.
        autofocus: localServers.isEmpty,
        tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
        keyboardType: TextInputType.url,
        maxLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        onNavigateUp: () => focusLastDiscoveredServerOr(_searchAgainFocus),
        onNavigateDown: () => _findServerFocus.requestFocus(),
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addServer.musicAssistantUrl,
          // URL example — intentionally not localized.
          hintText: 'http://192.168.1.10:8095',
          helperText: t.addServer.musicAssistantUrlHelper,
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (_) => normalizeMusicAssistantUrl(_urlController.text) == null ? t.addServer.required : null,
      ),
      const SizedBox(height: 16),
      FocusableButton(
        focusNode: _findServerFocus,
        useBackgroundFocus: true,
        onNavigateUp: () => _urlFocus.requestFocus(),
        onPressed: busy ? null : _probe,
        child: FilledButton.icon(
          onPressed: busy ? null : _probe,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.travel_explore_rounded, fill: 1),
          label: Text(t.addServer.findServer),
        ),
      ),
    ];
  }

  List<Widget> _buildResolvedServerChildren(ThemeData theme) {
    return [
      FocusableTextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        tvTextInputPresentation: PlatformDetector.isAppleTV()
            ? TvTextInputPresentation.platform
            : TvTextInputPresentation.automatic,
        tvTextInputAutoOpenBehavior: deferredUrlFieldAutoOpen,
        keyboardType: TextInputType.url,
        maxLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        onChanged: (_) {
          if (_serverInfo == null) return;
          setState(_clearResolvedServer);
        },
        onNavigateDown: () => _changeServerFocus.requestFocus(),
        textInputAction: TextInputAction.go,
        onFieldSubmitted: busy ? null : (_) => _probe(),
        decoration: InputDecoration(
          labelText: t.addServer.musicAssistantUrl,
          hintText: 'http://192.168.1.10:8095',
          prefixIcon: const AppIcon(Symbols.link_rounded, fill: 1),
        ),
        validator: (_) => normalizeMusicAssistantUrl(_urlController.text) == null ? t.addServer.required : null,
      ),
      const SizedBox(height: 16),
      _buildServerCard(theme),
      const SizedBox(height: 16),
      FocusableTextFormField(
        controller: _nameController,
        focusNode: _nameFocus,
        enabled: !busy,
        onNavigateUp: () => _changeServerFocus.requestFocus(),
        textInputAction: TextInputAction.next,
        onFieldSubmitted: busy ? null : (_) => (_requiresSignIn ? _usernameFocus : _tokenFocus).requestFocus(),
        decoration: InputDecoration(
          labelText: t.addServer.musicAssistantDisplayName,
          prefixIcon: const AppIcon(Symbols.label_rounded, fill: 1),
        ),
      ),
      const SizedBox(height: 12),
      if (_requiresSignIn) ...[
        FocusableTextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: busy ? null : (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: t.addServer.username,
            prefixIcon: const AppIcon(Symbols.person_rounded, fill: 1),
          ),
          validator: _requiredUnlessTokenPasted,
        ),
        const SizedBox(height: 12),
        FocusableTextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: busy ? null : (_) => _add(),
          decoration: InputDecoration(
            labelText: t.addServer.password,
            prefixIcon: const AppIcon(Symbols.password_rounded, fill: 1),
          ),
          validator: _requiredUnlessTokenPasted,
        ),
        const SizedBox(height: 12),
      ],
      FocusableTextFormField(
        controller: _tokenController,
        focusNode: _tokenFocus,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        enabled: !busy,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: busy ? null : (_) => _add(),
        decoration: InputDecoration(
          labelText: t.addServer.musicAssistantToken,
          helperText: _requiresSignIn
              ? t.addServer.musicAssistantTokenInsteadHelper
              : t.addServer.musicAssistantTokenHelper,
          prefixIcon: const AppIcon(Symbols.key_rounded, fill: 1),
        ),
        // No validator: a blank token is the normal case.
      ),
      const SizedBox(height: 16),
      FocusableButton(
        focusNode: _addFocus,
        useBackgroundFocus: true,
        onPressed: busy ? null : _add,
        child: FilledButton.icon(
          onPressed: busy ? null : _add,
          icon: busy ? const LoadingIndicatorBox() : const AppIcon(Symbols.add_rounded, fill: 1),
          label: Text(_requiresSignIn ? t.addServer.signIn : t.addServer.addMusicAssistantServer),
        ),
      ),
      ...buildInlineError(theme),
    ];
  }

  String? _requiredUnlessTokenPasted(String? value) =>
      (value ?? '').isEmpty && _tokenController.text.trim().isEmpty ? t.addServer.required : null;

  Widget _buildServerCard(ThemeData theme) {
    final info = _serverInfo!;
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
              crossAxisAlignment: .start,
              children: [
                // Product name + version, matching the Jellyfin card; not
                // localized because neither half of it translates.
                Text('Music Assistant ${info.serverVersion}', style: theme.textTheme.titleSmall),
                Text(
                  info.serverId,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          FocusableButton(
            focusNode: _changeServerFocus,
            useBackgroundFocus: true,
            onNavigateUp: () => _urlFocus.requestFocus(),
            onNavigateDown: () => _nameFocus.requestFocus(),
            onPressed: busy ? null : () => setState(_clearResolvedServer),
            child: TextButton(
              onPressed: busy ? null : () => setState(_clearResolvedServer),
              child: Text(t.addServer.change),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLocalDiscoverySection(ThemeData theme) => buildLocalDiscoverySection(
    theme,
    searchingLabel: t.addServer.searchingLocalMusicAssistantServers,
    sectionLabel: t.addServer.musicAssistantFoundOnNetwork,
    // Nothing above the list any more — it is the top of the screen. Up from
    // the first row goes to the manual-entry control below it rather than
    // nowhere, so a D-pad can always leave.
    focusAbove: _manualEntry ? _urlFocus : _manualToggleFocus,
    focusBelow: _manualEntry ? _urlFocus : _manualToggleFocus,
    // The advert carries no server name, only an id and a version, so the
    // product name plus the version is the most recognisable label there is.
    titleOf: (server) => server.version == null ? 'Music Assistant' : 'Music Assistant ${server.version}',
    addressOf: (server) => server.address,
    // Recognised from the advert alone — the instance name is the server_id
    // and the row id is derived from it — so this costs no round trip.
    statusOf: (server) => _needsSignInServerIds.contains(server.id)
        ? t.addServer.musicAssistantTapToSignIn
        : _savedServerIds.contains(server.id)
        ? t.addServer.musicAssistantAlreadyAdded
        : (_addingServerId == null ? t.addServer.musicAssistantTapToAdd : null),
    busyOf: (server) => _addingServerId == server.id,
    // An already-saved server is shown and not offered. Adding it again would
    // upsert the same row, which is harmless but tells the user nothing —
    // and if its address had changed it would raise a repoint dialog for
    // something they only meant to look at. One that needs a sign-in has
    // something to do, so it stays tappable.
    enabledOf: (server) => !_savedServerIds.contains(server.id) || _needsSignInServerIds.contains(server.id),
    onSelected: busy || _addingServerId != null ? null : (server) => unawaited(_useDiscoveredServer(server)),
  );
}
