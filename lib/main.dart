import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'services/storage_service.dart';
import 'services/macos_titlebar_service.dart';
import 'services/fullscreen_state_manager.dart';
import 'services/update_service.dart';
import 'services/settings_service.dart';
import 'services/tv_detection_service.dart';
import 'providers/user_profile_provider.dart';
import 'providers/plex_client_provider.dart';
import 'providers/multi_server_provider.dart';
import 'providers/server_state_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/hidden_libraries_provider.dart';
import 'providers/playback_state_provider.dart';
import 'services/multi_server_manager.dart';
import 'services/data_aggregation_service.dart';
import 'services/server_registry.dart';
import 'utils/app_logger.dart';
import 'utils/orientation_helper.dart';
import 'utils/language_codes.dart';
import 'i18n/strings.g.dart';
import 'focus/input_mode_tracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings first to get saved locale
  final settings = await SettingsService.getInstance();
  final savedLocale = settings.getAppLocale();

  // Initialize localization with saved locale
  LocaleSettings.setLocale(savedLocale);

  // Configure image cache for large libraries
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200MB

  // Initialize services in parallel where possible
  final futures = <Future<void>>[];

  // Initialize window_manager for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    futures.add(windowManager.ensureInitialized());
  }

  // Initialize TV detection for Android
  if (Platform.isAndroid) {
    futures.add(TvDetectionService.getInstance().then((_) {}));
  }

  // Configure macOS window with custom titlebar (depends on window manager)
  futures.add(MacOSTitlebarService.setupCustomTitlebar());

  // Initialize storage service
  futures.add(StorageService.getInstance().then((_) {}));

  // Initialize language codes for track selection
  futures.add(LanguageCodes.initialize());

  // Wait for all parallel services to complete
  await Future.wait(futures);

  // Initialize logger level based on debug setting
  final debugEnabled = settings.getEnableDebugLogging();
  setLoggerLevel(debugEnabled);

  // Start global fullscreen state monitoring
  FullscreenStateManager().startMonitoring();

  // DTD service is available for MCP tooling connection if needed

  runApp(const MainApp());
}

// Global RouteObserver for tracking navigation
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize multi-server infrastructure
    final serverManager = MultiServerManager();
    final aggregationService = DataAggregationService(serverManager);

    return MultiProvider(
      providers: [
        // Legacy provider for backward compatibility
        ChangeNotifierProvider(create: (context) => PlexClientProvider()),
        // New multi-server providers
        ChangeNotifierProvider(
          create: (context) =>
              MultiServerProvider(serverManager, aggregationService),
        ),
        ChangeNotifierProvider(create: (context) => ServerStateProvider()),
        // Existing providers
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (context) => HiddenLibrariesProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (context) => PlaybackStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return TranslationProvider(
            child: InputModeTracker(
              child: MaterialApp(
                title: t.app.title,
                debugShowCheckedModeBanner: false,
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeProvider.materialThemeMode,
                navigatorObservers: [routeObserver],
                home: const OrientationAwareSetup(),
              ),
            ),
          );
        },
      ),
    );
  }
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
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _checkForUpdatesOnStartup() async {
    // Delay slightly to allow UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final updateInfo = await UpdateService.checkForUpdatesOnStartup();

      if (updateInfo != null && updateInfo['hasUpdate'] == true && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      appLogger.e('Error checking for updates', error: e);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.update.available),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.update.versionAvailable(version: updateInfo['latestVersion']),
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.update.currentVersion(version: updateInfo['currentVersion']),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(t.common.later),
            ),
            TextButton(
              onPressed: () async {
                await UpdateService.skipVersion(updateInfo['latestVersion']);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(t.update.skipVersion),
            ),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(updateInfo['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(t.update.viewRelease),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSavedCredentials() async {
    final storage = await StorageService.getInstance();
    final registry = ServerRegistry(storage);

    // Migrate from single-server to multi-server if needed
    await registry.migrateFromSingleServer();

    // Load enabled servers
    final servers = await registry.getEnabledServers();

    if (servers.isEmpty) {
      // No servers configured - show auth screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
      return;
    }

    // Get multi-server provider
    if (!mounted) return;
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );

    try {
      appLogger.i('Connecting to ${servers.length} enabled servers...');

      // Get or generate client identifier
      final clientId = storage.getClientIdentifier();

      // Connect to all servers in parallel
      final connectedCount = await multiServerProvider.serverManager
          .connectToAllServers(
            servers,
            clientIdentifier: clientId,
            timeout: const Duration(seconds: 10),
            onServerConnected: (serverId, client) {
              // Set first connected client in legacy provider for backward compatibility
              final legacyProvider = Provider.of<PlexClientProvider>(
                context,
                listen: false,
              );
              if (legacyProvider.client == null) {
                legacyProvider.setClient(client);
              }
            },
          );

      if (connectedCount > 0) {
        // At least one server connected successfully
        appLogger.i('Successfully connected to $connectedCount servers');

        if (mounted) {
          // Navigate to main screen immediately
          // Get first connected client for backward compatibility
          final firstClient =
              multiServerProvider.serverManager.onlineClients.values.first;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(client: firstClient),
            ),
          );

          // Check for updates in background after navigation
          _checkForUpdatesOnStartup();
        }
      } else {
        // All connections failed
        appLogger.w('Failed to connect to any servers');

        if (mounted) {
          // Show auth screen to re-authenticate
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Error during multi-server connection',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(t.app.loading),
          ],
        ),
      ),
    );
  }
}
