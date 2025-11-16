import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'services/storage_service.dart';
import 'services/plex_auth_service.dart';
import 'services/server_connection_service.dart';
import 'services/macos_titlebar_service.dart';
import 'services/fullscreen_state_manager.dart';
import 'services/update_service.dart';
import 'services/settings_service.dart';
import 'providers/user_profile_provider.dart';
import 'providers/plex_client_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/hidden_libraries_provider.dart';
import 'providers/playback_state_provider.dart';
import 'utils/language_codes.dart';
import 'utils/app_logger.dart';
import 'utils/provider_extensions.dart';
import 'utils/orientation_helper.dart';
import 'utils/platform_detector.dart';
import 'i18n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings first to get saved locale
  final settings = await SettingsService.getInstance();
  final savedLocale = settings.getAppLocale();

  // Initialize localization with saved locale
  LocaleSettings.setLocale(savedLocale);

  // Configure image cache for large libraries
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 << 20; // 500MB
  PaintingBinding.instance.imageCache.maximumSize = 500; // 500 images

  // Initialize window_manager for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }

  // Configure macOS window with custom titlebar
  await MacOSTitlebarService.setupCustomTitlebar();

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Initialize TV detection early for Android devices
  await PlatformDetector.initializeTVDetection();

  // Note: Orientation will be set dynamically based on device type in MainApp

  await StorageService.getInstance();

  // Initialize language codes for track selection
  await LanguageCodes.initialize();

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PlexClientProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProfileProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => HiddenLibrariesProvider()),
        ChangeNotifierProvider(create: (context) => PlaybackStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return TranslationProvider(
            child: MaterialApp(
              title: t.app.title,
              debugShowCheckedModeBanner: false,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.materialThemeMode,
              navigatorObservers: [routeObserver],
              home: const OrientationAwareSetup(),
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

  void _checkForUpdatesOnStartup() async {
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

    // Check if we have server data
    final serverData = storage.getServerData();
    final clientId = storage.getClientIdentifier();
    final plexToken = storage.getPlexToken();

    // Get current user's server token (prioritize over original server token)
    final currentUserToken = storage.getToken();

    if (serverData != null && clientId != null) {
      try {
        // Recreate PlexServer from stored data
        final server = PlexServer.fromJson(serverData);

        // Use current user's token if available, fallback to server's original token
        final tokenToUse = currentUserToken ?? server.accessToken;

        appLogger.d(
          'App startup token selection: currentUserToken=${currentUserToken != null ? 'present' : 'null'}, using=${currentUserToken != null ? 'current user' : 'original server'} token',
        );

        // Create updated server with correct token for current user
        final serverWithCurrentToken = PlexServer(
          name: server.name,
          clientIdentifier: server.clientIdentifier,
          accessToken: tokenToUse,
          connections: server.connections,
          owned: server.owned,
          product: server.product,
          platform: server.platform,
          lastSeenAt: server.lastSeenAt,
          presence: server.presence,
        );

        // Connect using the optimized service with current user's token
        final result = await ServerConnectionService.connectToServer(
          serverWithCurrentToken,
          clientIdentifier: clientId,
          verifyServer: true,
          fetchUserProfile: plexToken != null,
          plexToken: plexToken,
        );

        // Handle result
        if (result.isSuccess) {
          // Success! Set client in provider
          if (mounted) {
            context.plexClient.setClient(result.client!);

            // Check for updates BEFORE navigation to keep context valid
            _checkForUpdatesOnStartup();

            // Navigate to main screen after update check is initiated
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(client: result.client!),
                ),
              );
            }
          }
          return;
        } else {
          // Connection failed, clear credentials
          await storage.clearCredentials();
        }
      } catch (e) {
        // Error loading or testing server
        appLogger.e('Error during auto-login', error: e);
        await storage.clearCredentials();
      }
    }

    // No saved credentials or auto-login failed - show auth screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
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
