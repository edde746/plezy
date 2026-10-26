import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../connection/plex_account_setup.dart';
import '../database/app_database.dart';
import '../mixins/controller_disposer_mixin.dart';
import '../profiles/active_profile_binder.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile_selection_policy.dart';
import '../services/plex_auth_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../providers/account_preferences_controller.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/error_message_utils.dart';
import '../utils/platform_detector.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_text_field.dart';
import '../media/media_backend.dart';
import '../media/media_browser_dialect.dart';
import '../navigation/profile_session_screen.dart';
import '../utils/navigation_transitions.dart';
import '../widgets/backend_badge.dart';
import '../widgets/dialog_action_button.dart';
import '../services/plex_gdm_discovery_service.dart';
import 'auth/plex_pin_auth_flow.dart';
import 'sources/file_sources_setup.dart';
import 'sources/source_widgets.dart';
import 'profile/profile_switch_screen.dart';
import 'settings/add_direct_plex_screen.dart';
import 'settings/add_jellyfin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialErrorMessage,
    this.initializeServices = true,
    this.databaseRecoveryRequired = false,
  });

  final String? initialErrorMessage;
  final bool initializeServices;
  final bool databaseRecoveryRequired;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  // Reuse a one-shot service for the debug-token verify path; the Plex
  // PIN/QR flow inside [PlexPinAuthFlow] owns its own service instance.
  PlexAuthService? _verifyOnlyService;
  Future<void>? _recoveryAcknowledgement;
  bool _recoveryAcknowledged = false;
  List<DiscoveredPlexServer> _discoveredPlexServers = const [];

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
    // Debug-token verification only — release builds must not hold an idle
    // auth service (and its HTTP client) for a dialog that can't open.
    if (kDebugMode && widget.initializeServices) unawaited(_initVerifyService());
    if (widget.initializeServices) _startGdmDiscovery();
  }

  void _startGdmDiscovery() {
    unawaited(
      PlexGdmDiscoveryService()
          .discover()
          .then((servers) {
            if (!mounted) return;
            setState(() => _discoveredPlexServers = servers);
          })
          .catchError((_) {}),
    );
  }

  Future<void> _initVerifyService() async {
    final svc = await PlexAuthService.create();
    if (!mounted) {
      svc.dispose();
      return;
    }
    setState(() => _verifyOnlyService = svc);
  }

  @override
  void dispose() {
    _verifyOnlyService?.dispose();
    super.dispose();
  }

  /// Auto-select the active profile after sign-in *only* when there's a
  /// single, unprotected Plex Home user — there's no choice for the user to
  /// make. With multiple Home users (the "real" Home case) we leave the active
  /// id unset so [MainScreen] forces the picker before the binder runs,
  /// avoiding a surprise PIN prompt on whichever user we'd otherwise
  /// pre-select. A PIN-protected single user also goes through the picker —
  /// see [initialPlexHomeProfileFromCache].
  Future<void> _selectInitialProfile(
    PlexHomeService plexHome,
    ActiveProfileProvider activeProfiles,
    PlexAccountConnection accountConn,
  ) async {
    await activeProfiles.initialize();
    final profile = initialPlexHomeProfileFromCache(plexHome, accountConn);
    if (profile == null) {
      await activeProfiles.clearActiveProfile();
      return;
    }
    await activeProfiles.activate(profile);
  }

  Future<bool> _prepareDatabaseRecoveryForSignIn() async {
    if (!widget.databaseRecoveryRequired || _recoveryAcknowledged) return true;
    final acknowledgement = _recoveryAcknowledgement ??= context
        .read<AppDatabase>()
        .acknowledgeTvosDatabaseRecoveryRequired();
    try {
      await acknowledgement;
      _recoveryAcknowledged = true;
      if (mounted) setState(() => _errorMessage = null);
      return mounted;
    } catch (_) {
      _recoveryAcknowledgement = null;
      if (mounted) setState(() => _errorMessage = t.auth.localDataRecoveryRequired);
      return false;
    }
  }

  Future<void> _startPlexAfterRecovery(VoidCallback start) async {
    if (await _prepareDatabaseRecoveryForSignIn()) start();
  }

  /// Persist the new Plex account into the connection pipeline, resolve the
  /// initial active profile when possible, and navigate to the main screen.
  /// The top-level [ActiveProfileBinder] picks up the active profile id and
  /// connects servers via [MultiServerManager.refreshTokensForProfile].
  Future<void> _connectToAllServersAndNavigate(String plexToken) async {
    if (!await _prepareDatabaseRecoveryForSignIn()) return;
    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final connectionRegistry = context.read<ConnectionRegistry>();
    final profileConnections = context.read<ProfileConnectionRegistry>();
    final plexHome = context.read<PlexHomeService>();

    try {
      final storage = await StorageService.getInstance();
      final registration = await registerPlexAccountFromToken(
        token: plexToken,
        connections: connectionRegistry,
        profileConnections: profileConnections,
        storage: storage,
        plexHome: plexHome,
      );
      final accountConnection = registration.connection;

      if (accountConnection.servers.isEmpty) {
        // Nothing to roll back — the registered account row is exactly what
        // a retry will upsert over; wiping global credentials here would
        // also nuke the device identity and every server-endpoint cache.
        if (!mounted) return;
        setState(() {
          _isAuthenticating = false;
          _errorMessage = t.serverSelection.noServersFoundForAccount(
            username: registration.username,
            email: registration.email,
          );
        });
        return;
      }

      if (!registration.homeUsersFetched && plexHome.current[accountConnection.id] == null) {
        // A failed home-user fetch is NOT "multiple users, let them pick":
        // with no home users and no locals there is no profile to select,
        // and navigating lands in a dead session. Surface a retry instead.
        if (!mounted) return;
        setState(() {
          _isAuthenticating = false;
          _errorMessage = t.profiles.failedToLoadHomeUsers;
        });
        return;
      }

      if (!mounted) return;
      final activeProfiles = context.read<ActiveProfileProvider>();
      await _selectInitialProfile(plexHome, activeProfiles, accountConnection);

      if (!mounted) return;

      // Start the binder before the picker/MainScreen, mirroring the
      // cold-start SetupScreen ordering. On a fresh install SetupScreen
      // routes here without ever starting it, so without this the profile
      // activated above is bound only by MainScreen's post-frame start() —
      // Discover renders a "No servers available" flash in the gap, and the
      // picker's awaitBindingSettle resolves before anything is bound.
      context.read<ActiveProfileBinder>().start();

      final settings = await SettingsService.getInstance();
      if (!mounted) return;

      final promptHandled = shouldPromptForInitialProfileSelection(
        activeProfile: activeProfiles.active,
        hasProfiles: activeProfiles.profiles.isNotEmpty,
        accountHasHomeUsers: plexHome.current[accountConnection.id]?.isNotEmpty == true,
        requireProfileSelectionOnOpen: activeProfiles.requiresSelectionOnOpen(settings),
      );
      if (promptHandled) {
        final selected = await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
        if (!mounted) return;
        if (selected != true || activeProfiles.active == null) {
          setState(() => _isAuthenticating = false);
          return;
        }
      }

      await context.read<AccountPreferencesController>().ensureActiveLoaded();

      if (!mounted) return;
      unawaited(
        Navigator.pushReplacement(context, fadeRoute(ProfileSessionScreen(initialPromptHandled: promptHandled))),
      );
    } catch (e) {
      appLogger.e('Failed to connect to servers', error: e);
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = e is ServerParsingException
            ? e.display
            : t.serverSelection.failedToLoadServers(error: localizedErrorReason(e));
      });
    }
  }

  void _handleDebugTap() {
    if (!kDebugMode) return;
    _showDebugTokenDialog();
  }

  Future<void> _connectToFiles() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      if (!await _prepareDatabaseRecoveryForSignIn() || !mounted) return;
      await openFileSourcesSession(context, createIfEmpty: true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _connectToMediaBrowser(MediaBrowserDialect dialect) async {
    if (!await _prepareDatabaseRecoveryForSignIn()) return;
    if (!mounted) return;
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddJellyfinScreen(dialect: dialect)),
    );
    if (!mounted || added != true) return;
    // The connection persisted and the manager registered the client; move
    // straight to the main screen. [MainScreen] reads the active client
    // from the server provider, so no client argument is needed here.
    unawaited(Navigator.pushReplacement(context, fadeRoute(const ProfileSessionScreen())));
  }

  Future<void> _connectToDiscoveredPlexServer(DiscoveredPlexServer server) async {
    if (!await _prepareDatabaseRecoveryForSignIn()) return;
    if (!mounted) return;
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddDirectPlexScreen(initialServer: server, autoConnect: true)),
    );
    if (!mounted || added != true) return;
    unawaited(Navigator.pushReplacement(context, fadeRoute(const ProfileSessionScreen())));
  }

  Future<void> _connectToDirectPlex() async {
    if (!await _prepareDatabaseRecoveryForSignIn()) return;
    if (!mounted) return;
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddDirectPlexScreen()));
    if (!mounted || added != true) return;
    unawaited(Navigator.pushReplacement(context, fadeRoute(const ProfileSessionScreen())));
  }

  void _showDebugTokenDialog() {
    unawaited(
      showScopedDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return _DebugTokenDialog(verifyService: _verifyOnlyService, onTokenAccepted: _connectToAllServersAndNavigate);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isTV()) return _buildTvLayout(context);

    final size = MediaQuery.sizeOf(context);
    final scale = _authUiScale(size);
    final isWide = size.width >= 1000;
    final wideQrMaxSize = _wideAuthColumnWidth(size, scale);
    final logoSize = isWide ? 120 * scale : 104.0;
    final headline = Theme.of(context).textTheme.headlineMedium;
    final titleStyle = headline?.copyWith(fontWeight: FontWeight.bold, fontSize: (headline.fontSize ?? 28) * scale);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthScreenBackground(),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isWide ? 1040 * scale : 480),
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                24 * scale,
                24 * scale,
                24 * scale + MediaQuery.paddingOf(context).bottom,
              ),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset('assets/plezy.png', width: logoSize, height: logoSize),
                              SizedBox(height: 24 * scale),
                              Text(t.app.title, style: titleStyle, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        SizedBox(width: 48 * scale),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [_buildAuthBody(qrMaxSize: wideQrMaxSize)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset('assets/plezy.png', width: logoSize, height: logoSize),
                          SizedBox(height: 20 * scale),
                          Text(t.app.title, style: titleStyle, textAlign: TextAlign.center),
                          SizedBox(height: 36 * scale),
                          _buildAuthBody(qrMaxSize: 420),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvLayout(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = _authUiScale(size);
    final qrMaxSize = _tvAuthQrMaxSize(size, scale);
    final headline = theme.textTheme.displaySmall;
    final titleStyle = headline?.copyWith(fontWeight: FontWeight.bold, fontSize: (headline.fontSize ?? 36) * scale);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthScreenBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1280 * scale),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 64 * scale, vertical: 36 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/plezy.png', width: 176 * scale, height: 176 * scale),
                            SizedBox(height: 28 * scale),
                            Text(t.app.title, style: titleStyle, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      SizedBox(width: 56 * scale),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 720 * scale),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(32 * scale),
                                child: SingleChildScrollView(child: _buildAuthBody(qrMaxSize: qrMaxSize)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthBody({required double qrMaxSize}) {
    if (_isAuthenticating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            t.auth.waitingForAuth,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      );
    }
    return PlexPinAuthFlow(
      onTokenReceived: _connectToAllServersAndNavigate,
      autoStartQrOnTV: false,
      initializeService: widget.initializeServices,
      qrMaxSize: qrMaxSize,
      initialButtonsBuilder: _buildInitialButtons,
    );
  }

  Widget _buildInitialButtons(BuildContext context, VoidCallback startBrowser, VoidCallback startQr, bool busy) {
    final isTV = PlatformDetector.isTV();
    final isAppleTV = PlatformDetector.isAppleTV();
    final scale = _authUiScale(MediaQuery.sizeOf(context));
    final theme = Theme.of(context);
    final buttonHeight = (56 * scale).clamp(56.0, 88.0).toDouble();
    final buttonFontSize = (16 * scale).clamp(16.0, 24.0).toDouble();
    final badgeSize = (18 * scale).clamp(18.0, 28.0).toDouble();
    final supportingFontSize = (14 * scale).clamp(14.0, 21.0).toDouble();
    final gap = 12 * scale;
    final sectionGap = 24 * scale;
    final actionStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(buttonHeight)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale)),
      textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge?.copyWith(fontSize: buttonFontSize)),
    );
    void startBrowserAfterRecovery() => unawaited(_startPlexAfterRecovery(startBrowser));
    void startQrAfterRecovery() => unawaited(_startPlexAfterRecovery(startQr));
    const jellyfinDialect = MediaBrowserDialect.jellyfin;
    const embyDialect = MediaBrowserDialect.emby;
    void connectToJellyfin() => unawaited(_connectToMediaBrowser(jellyfinDialect));
    void connectToEmby() => unawaited(_connectToMediaBrowser(embyDialect));
    void connectToDirectPlex() => unawaited(_connectToDirectPlex());
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (_discoveredPlexServers.isNotEmpty) ...[
          for (final server in _discoveredPlexServers) ...[
            FocusableButton(
              useBackgroundFocus: true,
              onPressed: busy ? null : () => unawaited(_connectToDiscoveredPlexServer(server)),
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => unawaited(_connectToDiscoveredPlexServer(server)),
                style: actionStyle.copyWith(
                  backgroundColor: WidgetStatePropertyAll(theme.colorScheme.primaryContainer),
                  foregroundColor: WidgetStatePropertyAll(theme.colorScheme.onPrimaryContainer),
                ),
                icon: BackendBadge(backend: MediaBackend.plex, size: badgeSize),
                label: Text(
                  t.auth.connectToMediaBrowser(product: server.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: gap),
          ],
        ],
        if (isTV) ...[
          FocusableButton(
            autofocus: true,
            onPressed: busy ? null : startQrAfterRecovery,
            useBackgroundFocus: true,
            child: ElevatedButton(
              onPressed: busy ? null : startQrAfterRecovery,
              style: actionStyle,
              child: Row(
                mainAxisAlignment: .center,
                mainAxisSize: .min,
                children: [
                  BackendBadge(backend: MediaBackend.plex, size: badgeSize),
                  SizedBox(width: 8 * scale),
                  Text(t.auth.signInWithPlex),
                ],
              ),
            ),
          ),
          if (!isAppleTV) ...[
            SizedBox(height: gap),
            FocusableButton(
              onPressed: busy ? null : startBrowserAfterRecovery,
              child: OutlinedButton(
                onPressed: busy ? null : startBrowserAfterRecovery,
                style: actionStyle,
                child: Text(t.auth.useBrowser),
              ),
            ),
          ],
        ] else ...[
          FocusableButton(
            onPressed: busy ? null : startBrowserAfterRecovery,
            useBackgroundFocus: true,
            child: ElevatedButton.icon(
              onPressed: busy ? null : startBrowserAfterRecovery,
              style: actionStyle,
              icon: BackendBadge(backend: MediaBackend.plex, size: badgeSize),
              label: Text(t.auth.signInWithPlex),
            ),
          ),
          SizedBox(height: gap),
          FocusableButton(
            onPressed: busy ? null : startQrAfterRecovery,
            child: OutlinedButton(
              onPressed: busy ? null : startQrAfterRecovery,
              style: actionStyle,
              child: Text(t.auth.showQRCode),
            ),
          ),
        ],
        SizedBox(height: sectionGap),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
              child: Text(
                t.auth.or,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: supportingFontSize,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
        SizedBox(height: gap),
        FocusableButton(
          onPressed: connectToJellyfin,
          child: OutlinedButton.icon(
            onPressed: connectToJellyfin,
            style: actionStyle,
            icon: BackendBadge(backend: MediaBackend.jellyfin, size: badgeSize),
            label: Text(t.auth.connectToMediaBrowser(product: jellyfinDialect.productName)),
          ),
        ),
        SizedBox(height: gap),
        FocusableButton(
          onPressed: connectToEmby,
          child: OutlinedButton.icon(
            onPressed: connectToEmby,
            style: actionStyle,
            icon: BackendBadge(backend: MediaBackend.emby, size: badgeSize),
            label: Text(t.auth.connectToMediaBrowser(product: embyDialect.productName)),
          ),
        ),
        SizedBox(height: gap),
        FocusableButton(
          onPressed: connectToDirectPlex,
          child: OutlinedButton.icon(
            onPressed: connectToDirectPlex,
            style: actionStyle,
            icon: BackendBadge(backend: MediaBackend.plex, size: badgeSize),
            label: Text(t.auth.connectToDirectPlex),
          ),
        ),
        SizedBox(height: gap),
        FocusableButton(
          onPressed: busy ? null : () => unawaited(sourceAction(context, _connectToFiles)),
          child: OutlinedButton(
            onPressed: busy ? null : () => unawaited(sourceAction(context, _connectToFiles)),
            style: actionStyle,
            child: Text(t.fileSources.useFiles),
          ),
        ),
        if (kDebugMode) ...[
          SizedBox(height: gap),
          FocusableButton(
            onPressed: _handleDebugTap,
            child: OutlinedButton(
              onPressed: _handleDebugTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: const Text('Debug: Enter Plex Token', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          SizedBox(height: gap),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: supportingFontSize, color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

double _authUiScale(Size size) {
  if (size.width < 700) return 1;
  final widthScale = size.width / 1280;
  final heightScale = size.height / 800;
  return math.min(widthScale, heightScale).clamp(1.0, 1.55).toDouble();
}

double _wideAuthColumnWidth(Size size, double scale) {
  final layoutWidth = math.min(1040 * scale, size.width);
  return math.max(140, (layoutWidth - 96 * scale) / 2).toDouble();
}

double _tvAuthQrMaxSize(Size size, double scale) {
  final layoutWidth = math.min(1280 * scale, size.width);
  final columnWidth = (layoutWidth - 184 * scale) / 2;
  final cardWidth = math.min(720 * scale, columnWidth);
  return math.max(140, cardWidth - 64 * scale).toDouble();
}

class _AuthScreenBackground extends StatelessWidget {
  const _AuthScreenBackground();

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final compact = size.width < 760;
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final physicalSize = size * devicePixelRatio;
        // Use the 4K-sized site-art upscale only when the physical
        // display can show it; phone and standard-density layouts keep the
        // smaller source to avoid decoding a 4K bitmap unnecessarily.
        final useHighResolutionArtwork = physicalSize.width >= 2560 && physicalSize.height >= 1440;
        final illustrationAsset = useHighResolutionArtwork
            ? 'assets/branding/plezyng-product-illustration-4k.png'
            : 'assets/branding/plezyng-product-illustration.webp';
        final illustrationWidth = math.min(size.width * 0.82, 1800.0).toDouble();
        final illustrationHeight = math.min(size.height * 0.44, size.width * 0.72).toDouble();
        final illustrationPixelWidth = useHighResolutionArtwork
            ? math.min((compact ? size.width : illustrationWidth) * devicePixelRatio, 3840).round()
            : null;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: surface),
            if (compact)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: illustrationHeight,
                child: ExcludeSemantics(
                  child: Image.asset(
                    illustrationAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                    cacheWidth: illustrationPixelWidth,
                  ),
                ),
              )
            else
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: illustrationWidth,
                child: ExcludeSemantics(
                  child: Image.asset(
                    illustrationAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                    cacheWidth: illustrationPixelWidth,
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: compact
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.42, 0.72, 1],
                            colors: [
                              surface.withValues(alpha: 0.06),
                              surface.withValues(alpha: 0.42),
                              surface.withValues(alpha: 0.92),
                              surface,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: const [0, 0.34, 0.66, 1],
                            colors: [
                              surface,
                              surface.withValues(alpha: 0.96),
                              surface.withValues(alpha: 0.56),
                              surface.withValues(alpha: 0.02),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

@visibleForTesting
/// The profile to auto-select after sign-in: the account's only Plex Home
/// user, unless it is PIN-protected. A bare activation skips the PIN check
/// the picker performs, and the first bind of the session may reuse a cached
/// user token — after an in-app logout, the one the previous session minted —
/// so a protected user must be picked (and its PIN entered) explicitly.
Profile? initialPlexHomeProfileFromCache(PlexHomeService plexHome, PlexAccountConnection accountConn) {
  final users = plexHome.current[accountConn.id];
  if (users == null || users.length != 1 || users.single.protected) return null;
  return Profile.virtualPlexHome(connectionId: accountConn.id, homeUser: users.single);
}

@visibleForTesting
bool shouldPromptForInitialProfileSelection({
  required Profile? activeProfile,
  required bool hasProfiles,
  required bool accountHasHomeUsers,
  required bool requireProfileSelectionOnOpen,
}) {
  return requireProfileSelectionOnOpen || (activeProfile == null && (hasProfiles || accountHasHomeUsers));
}

/// Stateful so the [TextEditingController] is disposed when the dialog
/// closes — the previous inline `showDialog` builder created the
/// controller in a closure and leaked it on every dismissal.
class _DebugTokenDialog extends StatefulWidget {
  final PlexAuthService? verifyService;
  final Future<void> Function(String token) onTokenAccepted;

  const _DebugTokenDialog({required this.verifyService, required this.onTokenAccepted});

  @override
  State<_DebugTokenDialog> createState() => _DebugTokenDialogState();
}

class _DebugTokenDialogState extends State<_DebugTokenDialog> with ControllerDisposerMixin {
  late final TextEditingController _tokenController = createTextEditingController();
  String? _errorMessage;
  bool _busy = false;

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = t.errors.pleaseEnterToken);
      return;
    }
    final svc = widget.verifyService;
    if (svc == null) {
      setState(() => _errorMessage = 'Auth service not ready');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _errorMessage = null;
      _busy = true;
    });
    try {
      final isValid = await svc.verifyToken(token);
      if (!mounted) return;
      if (!isValid) {
        setState(() {
          _errorMessage = t.errors.invalidToken;
          _busy = false;
        });
        return;
      }
      navigator.pop();
      await widget.onTokenAccepted(token);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = t.errors.failedToVerifyToken(error: e);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Debug: Enter Plex Token'),
      content: Column(
        mainAxisSize: .min,
        children: [
          FocusableTextFormField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: 'Plex Auth Token',
              hintText: 'Enter your Plex.tv token',
              errorText: _errorMessage,
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _busy ? null : _submit(),
          ),
        ],
      ),
      actions: [
        DialogActionButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), label: t.common.cancel),
        DialogActionButton(onPressed: _busy ? null : _submit, label: t.auth.authenticate, isPrimary: true),
      ],
    );
  }
}
