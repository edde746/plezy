import 'dart:async';
import 'dart:io' show Platform, ProcessInfo;
import 'dart:ui' show AppExitResponse;
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'connection/connection.dart';
import 'connection/connection_bootstrap.dart';
import 'connection/connection_registry.dart';
import 'profiles/active_profile_binder.dart';
import 'profiles/active_profile_provider.dart';
import 'profiles/profile.dart';
import 'profiles/profile_connection_registry.dart';
import 'profiles/profile_registry.dart';
import 'profiles/plex_home_service.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile/pin_entry_dialog.dart';
import 'screens/profile/profile_switch_screen.dart';
import 'services/storage_service.dart';
import 'services/macos_window_service.dart';
import 'services/native_window_service.dart';
import 'services/fullscreen_state_manager.dart';
import 'services/settings_service.dart';
import 'utils/platform_detector.dart';
import 'services/discord_rpc_service.dart';
import 'services/gamepad_service.dart';
import 'services/trakt/trakt_scrobble_service.dart';
import 'services/trakt/trakt_sync_service.dart';
import 'services/trackers/tracker_coordinator.dart';
import 'providers/trakt_account_provider.dart';
import 'providers/trackers_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/multi_server_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/hidden_libraries_provider.dart';
import 'providers/libraries_provider.dart';
import 'providers/playback_state_provider.dart';
import 'providers/download_provider.dart';
import 'providers/offline_mode_provider.dart';
import 'providers/offline_watch_provider.dart';
import 'providers/companion_remote_provider.dart';
import 'providers/shader_provider.dart';
import 'utils/snackbar_helper.dart';
import 'watch_together/providers/watch_together_provider.dart';
import 'services/multi_server_manager.dart';
import 'services/offline_watch_sync_service.dart';
import 'services/data_aggregation_service.dart';
import 'services/in_app_review_service.dart';
import 'services/server_registry.dart';
import 'services/download_manager_service.dart';
import 'services/pip_service.dart';
import 'services/download_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/jellyfin_api_cache.dart';
import 'services/plex_api_cache.dart';
import 'database/app_database.dart';
import 'screens/video_player_screen.dart';
import 'utils/app_logger.dart';
import 'utils/media_server_http_client.dart' show httpClient;
import 'utils/orientation_helper.dart';
import 'utils/watch_state_notifier.dart';
import 'i18n/strings.g.dart';
import 'focus/input_mode_tracker.dart';
import 'focus/key_event_utils.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/navigation_transitions.dart';
import 'utils/log_redaction_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

const bool _enableSentry = bool.fromEnvironment('ENABLE_SENTRY', defaultValue: false);
const String gitCommit = String.fromEnvironment('GIT_COMMIT');
const String _sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT');

// Workaround for Flutter bug #177992: iPadOS 26.1+ misinterprets fake touch events
// at (0,0) as barrier taps, causing modals to dismiss immediately.
// Remove when Flutter PR #179643 is merged.
bool _zeroOffsetPointerGuardInstalled = false;

void _installZeroOffsetPointerGuard() {
  if (_zeroOffsetPointerGuardInstalled) return;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_absorbZeroOffsetPointerEvent);
  _zeroOffsetPointerGuardInstalled = true;
}

void _absorbZeroOffsetPointerEvent(PointerEvent event) {
  if (event.position == Offset.zero) {
    GestureBinding.instance.cancelPointer(event.pointer);
  }
}

/// Register platform plugin stores manually for tvOS. Flutter's tool
/// doesn't support tvOS so it never generates a plugin registrant for it.
/// Each plugin whose iOS Swift implementation is tvOS-compatible must be
/// wired here; the Swift side (GeneratedPluginRegistrant.m / AppDelegate)
/// also needs to call the plugin's Swift register(with:) to attach its
/// message channels.
void _registerTvosPlatformPlugins() {
  if (!Platform.isIOS) return; // tvOS reports as iOS via dart:io.
  SharedPreferencesFoundation.registerWith();
}

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Build the semantics tree in debug so Maestro/UI automation can locate
  // widgets by text. Zero cost in release builds.
  if (kDebugMode) binding.ensureSemantics();
  _installZeroOffsetPointerGuard(); // Workaround for iPadOS 26.1+ modal dismissal bug

  // On tvOS, Flutter's generated plugin registrant doesn't run (no tvOS
  // target in Flutter's tool), so register platform stores manually for
  // the plugins we use.
  _registerTvosPlatformPlugins();

  if (_enableSentry) {
    final packageInfo = await PackageInfo.fromPlatform();

    await SentryFlutter.init((options) {
      options.dsn = 'https://6a1a6ef8c72140099b2798973c1bfb2f@bugs.plezy.app/1';
      options.release = gitCommit.isNotEmpty
          ? 'plezy@${gitCommit.substring(0, 7)}'
          : 'plezy@${packageInfo.version}+${packageInfo.buildNumber}';
      if (_sentryEnvironment.isNotEmpty) options.environment = _sentryEnvironment;
      options.tracesSampleRate = 0;
      options.attachStacktrace = true;
      options.enableAutoSessionTracking = false;
      options.recordHttpBreadcrumbs = false;
      options.captureNativeFailedRequests = false;
      options.enableAppHangTracking = !kDebugMode;
      options.appHangTimeoutInterval = const Duration(seconds: 3);
      options.beforeSend = _beforeSend;
      options.beforeBreadcrumb = _beforeBreadcrumb;
    }, appRunner: _bootstrapApp);
    return;
  }

  await _bootstrapApp();
}

Future<void> _bootstrapApp() async {
  final settings = await SettingsService.getInstance();
  final savedLocale = settings.read(SettingsService.appLocale);

  unawaited(LocaleSettings.setLocale(savedLocale));

  await initializeDateFormatting(savedLocale.languageCode, null);

  // Configure image cache — keep budget modest to leave headroom for Skia decode buffers
  if (PlatformDetector.isDesktopOS()) {
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150MB
  } else {
    PaintingBinding.instance.imageCache.maximumSize = 800;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
  }

  final futures = <Future<void>>[];

  if (PlatformDetector.isDesktopOS()) {
    futures.add(windowManager.ensureInitialized());
  }

  // Initialize TV detection (Android leanback or Apple TV) and PiP on Android.
  if (Platform.isAndroid || Platform.isIOS) {
    futures.add(TvDetectionService.getInstance(forceTv: settings.read(SettingsService.forceTvMode)));
  }
  if (Platform.isAndroid) {
    PipService();
  }

  futures.add(MacOSWindowService.setupCustomTitlebar());

  // Hook Windows native fullscreen callback (no-op elsewhere).
  NativeWindowService.initialize();

  futures.add(StorageService.getInstance());

  await Future.wait(futures);

  // The PLEX_TOKEN dart-define (screenshot automation) is consumed by
  // [ConnectionBootstrap.seedFromDevTokenDefine] later, when the registry
  // is available — keeps the deprecated legacy slots out of runtime paths.

  final debugEnabled = settings.read(SettingsService.enableDebugLogging);
  setLoggerLevel(debugEnabled);

  final packageInfo = await PackageInfo.fromPlatform();
  final commitSuffix = gitCommit.isNotEmpty ? ' (${gitCommit.substring(0, 7)})' : '';
  String renderer = '';
  if (Platform.isAndroid) {
    renderer = ' [${await const MethodChannel('com.plezy/theme').invokeMethod<String>('getRenderer')}]';
  }
  appLogger.i('Plezy v${packageInfo.version}+${packageInfo.buildNumber}$commitSuffix$renderer');

  await DownloadStorageService.instance.initialize(settings);

  FullscreenStateManager().startMonitoring();

  // Apply "start in fullscreen" preference on Windows/Linux. macOS is
  // excluded — its native fullscreen animation is awkward at launch and
  // the OS already restores window state.
  if ((Platform.isWindows || Platform.isLinux) && settings.read(SettingsService.startInFullscreen)) {
    unawaited(FullscreenStateManager().enterFullscreen());
  }

  // Initialize gamepad service (all platforms — universal_gamepad auto-registers
  // and intercepts input events, so we must listen to re-dispatch them)
  GamepadService.instance.start();

  if (PlatformDetector.isDesktopOS()) {
    unawaited(DiscordRPCService.instance.initialize());
  }

  await TraktScrobbleService.instance.initialize();

  _registerShaderLicenses();

  // In release mode, show a colored placeholder instead of a blank/white screen
  // when a widget build() throws an unhandled exception.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const ColoredBox(color: Color(0xFF000000));
  };

  runApp(const MainApp());
}

Breadcrumb? _beforeBreadcrumb(Breadcrumb? breadcrumb, Hint _) {
  if (breadcrumb == null) return null;

  final message = breadcrumb.message;
  final data = breadcrumb.data;
  if (message == null && (data == null || data.isEmpty)) return breadcrumb;

  if (message != null) breadcrumb.message = LogRedactionManager.redact(message);
  if (data != null) breadcrumb.data = data.map((k, v) => MapEntry(k, v is String ? LogRedactionManager.redact(v) : v));
  return breadcrumb;
}

FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint _) {
  // Drop event if user opted out of crash reporting
  final instance = SettingsService.instanceOrNull;
  if (instance != null && !instance.read(SettingsService.crashReporting)) return null;

  // Drop unactionable errors
  final exceptions = event.exceptions;
  if (exceptions != null) {
    bool shouldDrop(SentryException e) {
      final v = e.value;
      // Windows file-lock errors from cache manager cleanup
      if (e.type == 'FileSystemException' && v != null && v.contains('plexImageCache') && v.contains('errno = 32')) {
        return true;
      }
      // Linux without DBus/NetworkManager
      if (e.type == 'DBusServiceUnknownException' || (v != null && v.contains('system_bus_socket'))) {
        return true;
      }
      // Device out of disk space
      if (v != null &&
          (v.contains('SQLITE_FULL') ||
              v.contains('No space left on device') ||
              v.contains('errno = 112') ||
              v.contains('database or disk is full'))) {
        return true;
      }
      // Native HTTP errors from CFNetwork (server errors, not actionable)
      if (e.type == 'HTTPClientError') return true;
      // Discord RPC errors when Discord is not running
      if (e.type == 'DiscordStateException') return true;
      return false;
    }

    if (exceptions.any(shouldDrop)) return null;

    // Scrub Plex tokens and server URLs from exception messages
    for (final e in exceptions) {
      final value = e.value;
      if (value != null) {
        e.value = LogRedactionManager.redact(value);
      }
    }
  }

  // Enrich TimeoutException with operation name + duration as tags/fingerprint.
  // value format: "TimeoutException after 0:00:05.000000: <operation> timed out"
  if (exceptions != null) {
    final timeoutException = exceptions.where((e) => e.type == 'TimeoutException').firstOrNull;
    if (timeoutException != null) {
      final value = timeoutException.value ?? '';
      final colonIdx = value.indexOf(': ');
      final message = colonIdx >= 0 ? value.substring(colonIdx + 2) : value;
      final operation = message.endsWith(' timed out')
          ? message.substring(0, message.length - ' timed out'.length)
          : null;
      final durationMatch = RegExp(r'after (\d+:\d{2}:\d{2}\.\d+)').firstMatch(value);

      final tags = event.tags ??= {};
      if (operation != null) tags['timeout.operation'] = operation;
      if (durationMatch != null) tags['timeout.duration'] = durationMatch.group(1)!;
      event.fingerprint = ['TimeoutException', ?operation];
    }
  }

  // Scrub breadcrumb messages and data
  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    for (final b in breadcrumbs) {
      final message = b.message;
      final data = b.data;
      if (message != null) b.message = LogRedactionManager.redact(message);
      if (data != null) b.data = data.map((k, v) => MapEntry(k, v is String ? LogRedactionManager.redact(v) : v));
    }
  }

  return event;
}

void _registerShaderLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Anime4K'],
      'MIT License\n'
      '\n'
      'Copyright (c) 2019-2021 bloc97\n'
      'All rights reserved.\n'
      '\n'
      'Permission is hereby granted, free of charge, to any person obtaining a copy '
      'of this software and associated documentation files (the "Software"), to deal '
      'in the Software without restriction, including without limitation the rights '
      'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
      'copies of the Software, and to permit persons to whom the Software is '
      'furnished to do so, subject to the following conditions:\n'
      '\n'
      'The above copyright notice and this permission notice shall be included in all '
      'copies or substantial portions of the Software.\n'
      '\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
      'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
      'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
      'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
      'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
      'SOFTWARE.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['NVIDIA Image Scaling (NVScaler)'],
      'The MIT License (MIT)\n'
      '\n'
      'Copyright (c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.\n'
      '\n'
      'Permission is hereby granted, free of charge, to any person obtaining a copy of '
      'this software and associated documentation files (the "Software"), to deal in '
      'the Software without restriction, including without limitation the rights to '
      'use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of '
      'the Software, and to permit persons to whom the Software is furnished to do so, '
      'subject to the following conditions:\n'
      '\n'
      'The above copyright notice and this permission notice shall be included in all '
      'copies or substantial portions of the Software.\n'
      '\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS '
      'FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR '
      'COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER '
      'IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN '
      'CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
    );
  });
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Top-level PIN prompt used by [ActiveProfileBinder] when it runs above the
/// per-screen widget tree. Routes through [rootNavigatorKey] so the dialog
/// renders correctly whether the binder fires from the splash, MainScreen,
/// or any future host. Returns `null` when no Navigator is available yet
/// (early boot, post-dispose) so the binder treats it as "PIN cancelled".
Future<String?> _rootPinPrompt(Profile profile, {String? errorMessage}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return Future.value(null);
  return showPinEntryDialog(ctx, profile.displayName, errorMessage: errorMessage);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final MultiServerManager _serverManager;
  late final DataAggregationService _aggregationService;
  late final AppDatabase _appDatabase;
  late final DownloadManagerService _downloadManager;
  late final OfflineWatchSyncService _offlineWatchSyncService;
  late final AppLifecycleListener _appLifecycleListener;
  StreamSubscription<WatchStateEvent>? _watchStateSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncDebounce;
  final Set<String> _pendingSyncKeys = <String>{};
  bool _isAutoDeleteRunning = false;
  bool _lastConnectivityWasWifi = false;

  /// Last time server health probes ran from a resume event (cooldown for desktop)
  DateTime _lastResumeProbe = DateTime(0);

  /// Periodic memory check timer for desktop platforms
  Timer? _memoryCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (PlatformDetector.isDesktopOS()) {
      _memoryCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        final rss = ProcessInfo.currentRss;
        if (rss > 1536 * 1024 * 1024) {
          // 1.5GB
          appLogger.w('RSS high ($rss bytes), evicting image caches');
          _evictImageCaches();
        }
      });
    }

    _serverManager = MultiServerManager();
    _aggregationService = DataAggregationService(_serverManager);
    _appDatabase = AppDatabase();

    PlexApiCache.initialize(_appDatabase);
    JellyfinApiCache.initialize(_appDatabase);

    _downloadManager = DownloadManagerService(database: _appDatabase, storageService: DownloadStorageService.instance);
    _downloadManager.setClientResolver((serverId, {clientScopeId}) {
      if (clientScopeId != null && clientScopeId.isNotEmpty) {
        return _serverManager.getJellyfinClientByCompoundId(clientScopeId) ?? _serverManager.getClient(serverId);
      }
      return _serverManager.getClient(serverId);
    });
    _downloadManager.recoveryFuture = _downloadManager.recoverInterruptedDownloads();

    _offlineWatchSyncService = OfflineWatchSyncService(database: _appDatabase, serverManager: _serverManager);

    // Trakt sync service (subscribes to WatchStateNotifier, requires serverManager
    // to resolve PlexClients for GUID lookups).
    TraktSyncService.instance.initialize(serverManager: _serverManager);

    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        httpClient.close();
        await _appDatabase.close();
        return AppExitResponse.exit;
      },
    );

    // Start in-app review session tracking
    InAppReviewService.instance.startSession();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _watchStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _memoryCheckTimer?.cancel();
    _appLifecycleListener.dispose();
    _downloadManager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    appLogger.w('System memory pressure, evicting image caches');
    _evictImageCaches();
  }

  void _evictImageCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Fires [_autoDeleteAndSync] on each WiFi/Ethernet reconnect so rules run
  /// as soon as the device is back online. Rapid flapping is bounded by the
  /// executor's cooldown.
  void _startConnectivitySyncTrigger(DownloadProvider downloadProvider) {
    Future<void> setup() async {
      try {
        final initial = await Connectivity().checkConnectivity();
        _lastConnectivityWasWifi = _hasWifiOrEthernet(initial);
      } catch (e) {
        appLogger.w('Initial connectivity read failed, defaulting to false: $e');
        _lastConnectivityWasWifi = false;
      }

      try {
        _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
          final hasWifi = _hasWifiOrEthernet(results);
          final transitioned = hasWifi && !_lastConnectivityWasWifi;
          _lastConnectivityWasWifi = hasWifi;
          if (transitioned) {
            appLogger.d('Connectivity moved onto WiFi/Ethernet — triggering sync pass');
            _autoDeleteAndSync(downloadProvider);
          }
        });
      } catch (e) {
        appLogger.w('Could not subscribe to connectivity changes: $e');
      }
    }

    setup();
  }

  static bool _hasWifiOrEthernet(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);

  /// Run auto-delete (if enabled) and then a sync-rule pass.
  ///
  /// When [targetKeys] is non-null, only those rules are re-evaluated
  /// (cooldown doesn't apply — targeted runs are always "we know this
  /// changed"). When null, every rule runs via the executor, with [force]
  /// gating the cooldown: `true` for user-initiated drains, `false` for
  /// background probes like a connectivity reconnect.
  Future<void> _autoDeleteAndSync(
    DownloadProvider downloadProvider, {
    List<String>? targetKeys,
    bool force = false,
  }) async {
    if (_isAutoDeleteRunning) return;
    _isAutoDeleteRunning = true;
    try {
      await downloadProvider.refreshMetadataFromCache();
      final activeKey = VideoPlayerScreenState.activeId;
      final settings = SettingsService.instanceOrNull;
      if (settings != null && settings.read(SettingsService.autoRemoveWatchedDownloads)) {
        final deleted = await downloadProvider.autoDeleteWatchedDownloads(activeId: activeKey);
        if (deleted.isNotEmpty) {
          final msg = deleted.length == 1
              ? t.messages.autoRemovedWatchedDownload(title: deleted.first)
              : t.messages.autoRemovedWatchedDownload(title: '${deleted.length} items');
          showMainSnackBar(msg);
        }
      }

      if (targetKeys != null) {
        for (final key in targetKeys) {
          if (!downloadProvider.hasSyncRule(key)) continue;
          final result = await downloadProvider.executeSyncRuleFor(key, _serverManager);
          if (result != null && result.queuedCount > 0) {
            final title = result.title ?? 'Unknown';
            showMainSnackBar(t.downloads.syncedNewEpisodes(count: '1', title: '$title (${result.queuedCount})'));
          }
        }
      } else {
        final synced = await downloadProvider.executeSyncRules(_serverManager, force: force);
        if (synced.isNotEmpty) {
          showMainSnackBar(t.downloads.syncedNewEpisodes(count: synced.length.toString(), title: synced.first));
        }
      }
    } finally {
      _isAutoDeleteRunning = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - trigger sync check and start new session
        _offlineWatchSyncService.onAppResumed();
        TraktSyncService.instance.flushQueue();
        InAppReviewService.instance.startSession();
        // Re-probe servers — mobile OS may have dropped TCP connections during doze/sleep.
        // On desktop, resumed fires on every window focus (alt-tab), so apply a cooldown
        // to avoid piling up network probes from rapid alt-tabbing.
        final now = DateTime.now();
        final cooldown = (Platform.isIOS || Platform.isAndroid)
            ? const Duration(seconds: 10)
            : const Duration(minutes: 2);
        if (now.difference(_lastResumeProbe) >= cooldown) {
          _lastResumeProbe = now;
          // Await health check before reconnecting so stale "online" servers
          // get marked offline and included in the reconnection sweep.
          unawaited(() async {
            await _serverManager.checkServerHealth();
            await _serverManager.reconnectOfflineServers();
          }());
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Database is session-scoped and must survive suspend/resume.
        // Closing here would kill the Drift isolate channel while services
        // (sync, downloads, cache) still hold references to the executor.
        // SQLite WAL mode handles process death; desktop uses onExitRequested.
        InAppReviewService.instance.endSession();
        if (PlatformDetector.isDesktopOS()) {
          if (ProcessInfo.currentRss > 1024 * 1024 * 1024) {
            // 1GB
            _evictImageCaches();
          }
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transitional states - don't trigger session events
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose AppDatabase + ConnectionRegistry so screens (Settings, Setup)
        // can manage stored Jellyfin/Plex connections without re-creating
        // the registry per-call site.
        Provider<AppDatabase>.value(value: _appDatabase),
        Provider<ConnectionRegistry>(create: (_) => ConnectionRegistry(_appDatabase)),
        Provider<ProfileRegistry>(create: (_) => ProfileRegistry(_appDatabase)),
        Provider<ProfileConnectionRegistry>(create: (_) => ProfileConnectionRegistry(_appDatabase)),
        Provider<PlexHomeService>(
          create: (context) {
            // start() resolves StorageService internally — the singleton was
            // already initialised eagerly during boot, so the await is a
            // microtask hop in practice.
            final service = PlexHomeService(
              connections: context.read<ConnectionRegistry>(),
              profileConnections: context.read<ProfileConnectionRegistry>(),
            );
            unawaited(service.start());
            return service;
          },
          dispose: (_, s) => s.dispose(),
        ),
        ChangeNotifierProvider<ActiveProfileProvider>(
          create: (context) {
            final provider = ActiveProfileProvider(
              registry: context.read<ProfileRegistry>(),
              plexHome: context.read<PlexHomeService>(),
              connections: context.read<ConnectionRegistry>(),
            );
            unawaited(provider.initialize());
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            _serverManager.onJellyfinConnectionUpdated = context.read<ConnectionRegistry>().upsert;
            return MultiServerProvider(_serverManager, _aggregationService);
          },
        ),
        // Profile binder owns the cold-start client connect: Plex token
        // refresh + Jellyfin client creation. Hoisted out of MainScreen so
        // the splash can await its first settle — without this, MainScreen
        // mounts (and discover/libraries query) before any client exists.
        Provider<ActiveProfileBinder>(
          lazy: false,
          create: (context) {
            final activeProfile = context.read<ActiveProfileProvider>();
            return ActiveProfileBinder(
              activeProfile: activeProfile,
              connections: context.read<ConnectionRegistry>(),
              profileConnections: context.read<ProfileConnectionRegistry>(),
              serverManager: _serverManager,
              multiServerProvider: context.read<MultiServerProvider>(),
              pinPrompt: _rootPinPrompt,
              shouldDeferInitialBind: (_) async {
                final settings = await SettingsService.getInstance();
                return settings.read(SettingsService.requireProfileSelectionOnOpen) &&
                    activeProfile.hasMultipleProfiles;
              },
            )..start();
          },
          dispose: (_, binder) => binder.dispose(),
        ),
        ChangeNotifierProxyProvider<MultiServerProvider, OfflineModeProvider>(
          create: (_) {
            final provider = OfflineModeProvider(_serverManager);
            provider.initialize(); // Initialize immediately so statusStream listener is ready
            return provider;
          },
          update: (_, multiServerProvider, previous) {
            final provider = previous ?? OfflineModeProvider(_serverManager);
            provider.initialize(); // Idempotent - safe to call again
            return provider;
          },
        ),
        // Download provider. Downloads are shared, but sync rules are scoped to
        // the active profile and reload when the profile changes.
        ChangeNotifierProxyProvider<ActiveProfileProvider, DownloadProvider>(
          create: (context) => DownloadProvider(downloadManager: _downloadManager, database: _appDatabase),
          update: (context, activeProfile, previous) {
            final provider = previous ?? DownloadProvider(downloadManager: _downloadManager, database: _appDatabase);
            provider.setActiveProfileId(activeProfile.activeId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ActiveProfileProvider, OfflineWatchSyncService>(
          create: (context) {
            final offlineModeProvider = context.read<OfflineModeProvider>();
            final downloadProvider = context.read<DownloadProvider>();
            final activeProfile = context.read<ActiveProfileProvider>();
            _offlineWatchSyncService.setActiveProfileId(
              activeProfile.activeId,
              availableProfileCount: activeProfile.profiles.length,
            );

            // Offline-sync drain replays a batch of queued watch actions without
            // per-item data, so we can't target rules — force a full pass.
            _offlineWatchSyncService.onWatchStatesRefreshed = () async {
              await _autoDeleteAndSync(downloadProvider, force: true);
            };

            // In-session watch events carry the episode's parent chain, so we
            // only re-evaluate rules that actually cover the watched item —
            // leaves unrelated collection/playlist rules alone. Debounced so
            // binge-watching coalesces into one pass.
            _watchStateSubscription = WatchStateNotifier().stream.listen((event) {
              if (event.changeType != WatchStateChangeType.watched) return;
              if (VideoPlayerScreenState.activeId == event.itemId) return;

              _pendingSyncKeys.addAll(downloadProvider.syncRuleKeysForWatchEvent(event));

              _syncDebounce?.cancel();
              _syncDebounce = Timer(const Duration(seconds: 5), () {
                final keys = _pendingSyncKeys.toList();
                _pendingSyncKeys.clear();
                _autoDeleteAndSync(downloadProvider, targetKeys: keys);
              });
            });

            _startConnectivitySyncTrigger(downloadProvider);

            // Thread the offline flag into services so queue/resume paths can
            // short-circuit instead of hitting the network and failing.
            downloadProvider.setOfflineSource(offlineModeProvider);

            _offlineWatchSyncService.startConnectivityMonitoring(offlineModeProvider);
            return _offlineWatchSyncService;
          },
          update: (_, activeProfile, previous) {
            final provider = previous ?? _offlineWatchSyncService;
            provider.setActiveProfileId(activeProfile.activeId, availableProfileCount: activeProfile.profiles.length);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<OfflineWatchSyncService, DownloadProvider, OfflineWatchProvider>(
          create: (context) => OfflineWatchProvider(
            syncService: _offlineWatchSyncService,
            downloadProvider: context.read<DownloadProvider>(),
          ),
          update: (_, syncService, downloadProvider, previous) {
            return previous ?? OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
          },
        ),
        ChangeNotifierProxyProvider2<ActiveProfileProvider, ConnectionRegistry, UserProfileProvider>(
          create: (_) => UserProfileProvider(),
          update: (context, activeProfile, connections, previous) {
            final provider = previous ?? UserProfileProvider();
            provider.attach(
              connections: connections,
              activeProfile: activeProfile,
              profileConnections: context.read<ProfileConnectionRegistry>(),
              serverManager: context.read<MultiServerProvider>().serverManager,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Tracker accounts — depend on UserProfileProvider for per-profile
        // session scoping. Hydrated and rebound by `_TrackerProfileBootstrap`.
        ChangeNotifierProvider(create: (context) => TraktAccountProvider()),
        ChangeNotifierProvider(create: (context) => TrackersProvider()),
        ChangeNotifierProvider(create: (context) => HiddenLibrariesProvider(), lazy: true),
        ChangeNotifierProvider(create: (context) => LibrariesProvider()),
        ChangeNotifierProvider(create: (context) => PlaybackStateProvider()),
        ChangeNotifierProvider(create: (context) => WatchTogetherProvider()),
        ChangeNotifierProvider(create: (context) => CompanionRemoteProvider()),
        ChangeNotifierProvider(create: (context) => ShaderProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return TranslationProvider(
            child: Builder(
              builder: (context) {
                final trakt = context.read<TraktAccountProvider>();
                final trackers = context.read<TrackersProvider>();
                return _TrackerProfileBootstrap(
                  onProfileChanged: [trakt.onActiveProfileChanged, trackers.onActiveProfileChanged],
                  onFirstMount: TrackerCoordinator.instance.initialize,
                  child: Listener(
                    onPointerDown: (event) {
                      if ((event.buttons & kBackMouseButton) != 0) {
                        rootNavigatorKey.currentState?.maybePop();
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: InputModeTracker(
                      child: MaterialApp(
                        title: t.app.title,
                        debugShowCheckedModeBanner: false,
                        theme: themeProvider.lightTheme,
                        darkTheme: themeProvider.darkTheme,
                        themeMode: themeProvider.materialThemeMode,
                        navigatorKey: rootNavigatorKey,
                        navigatorObservers: [routeObserver, BackKeySuppressorObserver()],
                        home: const OrientationAwareSetup(),
                        // Siri Remote select + gamepad A report as
                        // LogicalKeyboardKey.{select,gameButtonA} which aren't
                        // in Flutter's default shortcut set — Material-level
                        // widgets (PopupMenuItem, showModalBottomSheet actions)
                        // ignore them. Map both to ActivateIntent so tapping
                        // select on tvOS activates the focused widget.
                        shortcuts: <ShortcutActivator, Intent>{
                          ...WidgetsApp.defaultShortcuts,
                          const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
                          const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
                          const SingleActivator(LogicalKeyboardKey.goBack): const DismissIntent(),
                          const SingleActivator(LogicalKeyboardKey.browserBack): const DismissIntent(),
                          const SingleActivator(LogicalKeyboardKey.gameButtonB): const DismissIntent(),
                        },
                        builder: (context, child) => ScaffoldMessenger(
                          key: rootScaffoldMessengerKey,
                          child: Scaffold(
                            backgroundColor: Colors.transparent,
                            body: _AppleTvScale(child: child),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// On Apple TV the system hands Flutter a 1920×1080 surface at
/// devicePixelRatio 1.0, the same logical pixel count as a phablet. That's
/// too dense for a 10ft viewing distance, so everything ends up tiny. We
/// shrink the effective logical size to half and scale the rendered output
/// back up so fonts, icons, and paddings end up visually ~2× larger — roughly
/// matching the UI feel of Android TV (which renders at lower logical DPI).
class _AppleTvScale extends StatelessWidget {
  final Widget? child;
  const _AppleTvScale({required this.child});

  static const double _scale = 2.0;

  @override
  Widget build(BuildContext context) {
    if (child == null || !PlatformDetector.isAppleTV()) {
      return child ?? const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalSize = Size(constraints.maxWidth / _scale, constraints.maxHeight / _scale);
        final outerQ = MediaQuery.of(context);
        // tvOS reports conservative overscan insets (~60pt top/bottom,
        // ~90pt left/right). Modern TVs don't overscan, so treat them as
        // dead margin and zero them out — the UI can use the full surface.
        return Transform.scale(
          scale: _scale,
          alignment: Alignment.topLeft,
          transformHitTests: true,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: MediaQuery(
              data: outerQ.copyWith(
                size: logicalSize,
                devicePixelRatio: outerQ.devicePixelRatio * _scale,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                systemGestureInsets: EdgeInsets.zero,
              ),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}

/// Hydrates Trakt and MAL/AniList/Simkl providers with the active profile's
/// sessions and rebinds their services whenever the user switches profiles.
///
/// Lives high in the widget tree (above MaterialApp) so the listener survives
/// route changes. [onFirstMount] runs exactly once after the first
/// `didChangeDependencies`.
class _TrackerProfileBootstrap extends StatefulWidget {
  final Widget child;
  final List<Future<void> Function(String? profileId)> onProfileChanged;
  final VoidCallback? onFirstMount;

  const _TrackerProfileBootstrap({required this.child, required this.onProfileChanged, this.onFirstMount});

  @override
  State<_TrackerProfileBootstrap> createState() => _TrackerProfileBootstrapState();
}

class _TrackerProfileBootstrapState extends State<_TrackerProfileBootstrap> {
  ActiveProfileProvider? _provider;
  String? _lastId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ActiveProfileProvider>();

    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProfileChanged);
      _provider = provider;
      _provider!.addListener(_onProfileChanged);
    }

    if (!_initialized) {
      _initialized = true;
      widget.onFirstMount?.call();
      _onProfileChanged();
    }
  }

  void _onProfileChanged() {
    final id = _provider?.activeId;
    if (id == _lastId) return;
    _lastId = id;
    for (final fn in widget.onProfileChanged) {
      unawaited(
        fn(id).catchError((Object e, StackTrace s) {
          appLogger.w('Tracker profile bootstrap failed', error: e, stackTrace: s);
        }),
      );
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class OrientationAwareSetup extends StatefulWidget {
  const OrientationAwareSetup({super.key});

  @override
  State<OrientationAwareSetup> createState() => _OrientationAwareSetupState();
}

class _OrientationAwareSetupState extends State<OrientationAwareSetup> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setOrientationPreferences();
  }

  void _setOrientationPreferences() {
    OrientationHelper.restoreDefaultOrientations(context);
  }

  @override
  Widget build(BuildContext context) {
    return const SetupScreen();
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _statusMessage = '';

  // Per-server connection status: serverId -> (name, connected?)
  final Map<String, (String name, bool? connected)> _serverStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _setStatus(String message) {
    if (mounted) setState(() => _statusMessage = message);
  }

  Future<void> _loadSavedCredentials() async {
    _setStatus(t.common.checkingNetwork);

    final storage = await StorageService.getInstance();
    final registry = ServerRegistry(storage);

    // Idempotent: brings legacy SharedPreferences state (plexToken,
    // currentUserUUID, homeUsersCache) into the new ConnectionRegistry +
    // ProfileRegistry tables. No-op on subsequent launches.
    if (mounted) {
      try {
        final connRegistry = context.read<ConnectionRegistry>();
        final profileRegistry = context.read<ProfileRegistry>();
        final activeProfiles = context.read<ActiveProfileProvider>();
        final bootstrap = ConnectionBootstrap(
          storage: storage,
          connectionRegistry: connRegistry,
          serverRegistry: registry,
          profileRegistry: profileRegistry,
        );
        await bootstrap.run();
        // Provider initialization starts before this screen runs the legacy
        // migration. Reload after bootstrap so copied Plex Home users and the
        // selected active profile are visible before setup decides binding is
        // already settled and navigates to MainScreen.
        await activeProfiles.reloadFromStorage();
      } catch (e, st) {
        appLogger.w('Boot-time migration failed', error: e, stackTrace: st);
      }
    }

    // Check network connectivity early to fast-path airplane mode.
    // Timeout guards against connectivity_plus hanging on some Android TV devices after force-close.
    bool hasNetwork;
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Checking network connectivity', category: 'setup')));
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.other],
      );
      hasNetwork = !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // connectivity_plus throws DBusServiceUnknownException on Linux without NetworkManager
      hasNetwork = true;
    }

    unawaited(
      Sentry.addBreadcrumb(Breadcrumb(message: 'Network check done: hasNetwork=$hasNetwork', category: 'setup')),
    );

    _setStatus(t.common.loadingServers);

    if (!mounted) return;

    // Snapshot ConnectionRegistry before we cross any awaits — Provider lookups
    // through `context` after async gaps trip the use_build_context_synchronously
    // lint, and reading early is safe because the registry is a singleton.
    final connectionRegistry = context.read<ConnectionRegistry>();
    final allConnections = await connectionRegistry.list();

    if (allConnections.isEmpty) {
      if (mounted) {
        unawaited(Navigator.pushReplacement(context, fadeRoute(const AuthScreen())));
      }
      return;
    }

    if (!mounted) return;

    // No network — skip connection attempts and go straight to offline mode
    if (!hasNetwork) {
      _setStatus(t.common.startingOfflineMode);
      await context.read<DownloadProvider>().ensureInitialized();
      if (!mounted) return;
      unawaited(Navigator.pushReplacement(context, fadeRoute(const MainScreen(isOfflineMode: true))));
      return;
    }

    if (mounted) {
      setState(() {
        for (final conn in allConnections) {
          if (conn is PlexAccountConnection) {
            for (final s in conn.servers) {
              _serverStatus[s.clientIdentifier] = (s.name, null);
            }
          } else if (conn is JellyfinConnection) {
            _serverStatus[conn.serverMachineId] = (conn.serverName, null);
          }
        }
      });
    }

    final plexCount = allConnections.whereType<PlexAccountConnection>().fold<int>(0, (n, c) => n + c.servers.length);
    final jellyfinCount = allConnections.whereType<JellyfinConnection>().length;
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Handing off to MainScreen with $plexCount Plex server(s) + $jellyfinCount Jellyfin',
          category: 'setup',
        ),
      ),
    );
    _setStatus(t.common.connectingToServers);

    // Snapshot Provider refs before further awaits.
    final activeProfile = context.read<ActiveProfileProvider>();
    // Reading the binder here is enough — the Provider is `lazy: false` so
    // it has already constructed the binder and called `start()` during
    // MultiProvider build. We just need to wait for it.
    context.read<ActiveProfileBinder>();
    final downloadProvider = context.read<DownloadProvider>();

    // Wait for the active profile to load from disk so the binder has a
    // profile to bind. `initialize` is fire-and-forget at provider creation,
    // so awaiting here pulls control through the same future and triggers
    // the listener-driven rebind synchronously.
    await activeProfile.reloadFromStorage();
    if (!mounted) return;

    if (activeProfile.active == null && activeProfile.profiles.isEmpty) {
      appLogger.w('Setup: stored connections exist but no profiles resolved after bootstrap; returning to auth');
      unawaited(Navigator.pushReplacement(context, fadeRoute(const AuthScreen())));
      return;
    }

    // Wire the per-server status listener before either branch so the splash
    // checkmarks fill in even while the user is choosing a profile.
    _bindServerStatusListener(activeProfile, _serverManagerFromContext);

    // If "prompt for profile on launch" is on (or no profile is selected
    // yet), surface the picker BEFORE waiting for the previously-active
    // profile's bind to settle — otherwise the user sees the splash fully
    // connect before the prompt arrives. The picker's own `_switchTo` calls
    // `awaitBindingSettle` after activation, so by the time it pops, the
    // chosen profile's bind is settled.
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    final hasNoActive = activeProfile.active == null && activeProfile.profiles.isNotEmpty;
    final requireOnOpen =
        settings.read(SettingsService.requireProfileSelectionOnOpen) && activeProfile.hasMultipleProfiles;
    final shouldPrompt = hasNoActive || requireOnOpen;

    if (shouldPrompt) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
      if (!mounted) return;
    } else {
      // Now wait for the binder to settle. This is the Plex/Jellyfin server
      // race: per-server status flips on the splash list as each client comes
      // online, and we don't push MainScreen until they're all done (success
      // or fail). Eliminates the "Failed to load discover content: No servers
      // available" race the old eager-navigate flow caused.
      await activeProfile.awaitBindingSettle();
      if (!mounted) return;
    }

    // Repopulate metadata for downloaded items now that per-backend caches
    // are resolvable (the Connections row + live JellyfinClient are in
    // place). Without this the downloads list and sync-rule titles render
    // empty until something forces a later refresh.
    await downloadProvider.refreshMetadataFromCache();
    if (!mounted) return;

    unawaited(Navigator.pushReplacement(context, fadeRoute(MainScreen(initialPromptHandled: shouldPrompt))));
  }

  /// Wire per-server status updates from [MultiServerManager] into the
  /// splash list so the user sees check/cross marks land as the binder
  /// brings each client online. Best-effort: stops listening when the
  /// state goes away.
  StreamSubscription<Map<String, bool>>? _statusSub;

  void _bindServerStatusListener(ActiveProfileProvider _, MultiServerManager Function() resolveManager) {
    _statusSub?.cancel();
    final manager = resolveManager();
    _statusSub = manager.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        for (final entry in status.entries) {
          final existing = _serverStatus[entry.key];
          if (existing != null) {
            _serverStatus[entry.key] = (existing.$1, entry.value);
          }
        }
      });
    });
  }

  MultiServerManager _serverManagerFromContext() => context.read<MultiServerProvider>().serverManager;

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  Widget _buildStatusText(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        _statusMessage,
        key: ValueKey(_statusMessage),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildServerStatusList(BuildContext context) {
    if (_serverStatus.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final dimColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    const coralColor = Color(0xFFE5A00D);
    const successColor = Color(0xFF4CAF50);
    const failColor = Color(0xFFEF5350);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _serverStatus.entries.map((entry) {
        final (name, connected) = entry.value;
        final Widget statusIcon;
        if (connected == null) {
          statusIcon = const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: coralColor),
          );
        } else if (connected) {
          statusIcon = const Icon(Icons.check_circle, size: 14, color: successColor);
        } else {
          statusIcon = const Icon(Icons.cancel, size: 14, color: failColor);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              statusIcon,
              const SizedBox(width: 8),
              Text(name, style: textTheme.bodySmall?.copyWith(color: dimColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const coralColor = Color(0xFFE5A00D);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Center(child: SvgPicture.asset('assets/plezy_adaptive_foreground.svg', width: 288, height: 288)),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.sizeOf(context).height * 0.5 - 170,
            child: _buildStatusText(context),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.sizeOf(context).height * 0.5 + 180,
            child: Center(
              child: _serverStatus.isEmpty
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: coralColor),
                    )
                  : _buildServerStatusList(context),
            ),
          ),
        ],
      ),
    );
  }
}
