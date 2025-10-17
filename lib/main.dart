import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'client/plex_client.dart';
import 'config/plex_config.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'services/storage_service.dart';
import 'services/plex_auth_service.dart';
import 'services/macos_titlebar_service.dart';
import 'services/fullscreen_state_manager.dart';
import 'models/plex_user_profile.dart';
import 'utils/language_codes.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window_manager for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }

  // Configure macOS window with custom titlebar
  await MacOSTitlebarService.setupCustomTitlebar();

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Lock orientation to portrait for all screens except video player
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await StorageService.getInstance();

  // Initialize language codes for track selection
  await LanguageCodes.initialize();

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
    return MaterialApp(
      title: 'Plezy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      navigatorObservers: [routeObserver],
      home: const SetupScreen(),
    );
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

  Future<void> _loadSavedCredentials() async {
    final storage = await StorageService.getInstance();

    // Check if we have server data
    final serverData = storage.getServerData();
    final clientId = storage.getClientIdentifier();
    final plexToken = storage.getPlexToken();

    if (serverData != null && clientId != null) {
      try {
        // Recreate PlexServer from stored data
        final server = PlexServer.fromJson(serverData);

        // Test connections to find best working one
        final connection = await server.findBestWorkingConnection();

        if (connection != null) {
          // Update stored server URL with working connection
          await storage.saveServerUrl(connection.uri);

          // Create client with working connection
          final config = PlexConfig(
            baseUrl: connection.uri,
            token: server.accessToken,
            clientIdentifier: clientId,
          );
          final client = PlexClient(config);

          // Verify server is accessible
          try {
            await client.getServerIdentity();

            // Fetch and cache user profile if we have a plex token
            PlexUserProfile? userProfile;
            if (plexToken != null) {
              userProfile = await _fetchAndCacheUserProfile(plexToken);
            }

            // Success! Navigate to main screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MainScreen(client: client, userProfile: userProfile),
                ),
              );
              return;
            }
          } catch (e) {
            // Server identity check failed
            await storage.clearCredentials();
          }
        } else {
          // No working connections found
          await storage.clearCredentials();
        }
      } catch (e) {
        // Error loading or testing server
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

  Future<PlexUserProfile?> _fetchAndCacheUserProfile(String plexToken) async {
    appLogger.d('Fetching user profile from Plex API');
    try {
      final authService = await PlexAuthService.create();
      final profile = await authService.getUserProfile(plexToken);

      appLogger.i(
        'Successfully fetched user profile',
        error: {
          'autoSelectAudio': profile.autoSelectAudio,
          'defaultAudioLanguage': profile.defaultAudioLanguage ?? 'not set',
          'autoSelectSubtitle': profile.autoSelectSubtitle,
          'defaultSubtitleLanguage':
              profile.defaultSubtitleLanguage ?? 'not set',
          'defaultSubtitleForced': profile.defaultSubtitleForced,
        },
      );

      // Cache the profile
      final storage = await StorageService.getInstance();
      await storage.saveUserProfile(profile.toJson());
      appLogger.d('User profile cached locally');

      return profile;
    } catch (e) {
      appLogger.w(
        'Failed to fetch user profile from API, attempting to load from cache',
        error: e,
      );

      // Failed to fetch profile, try to load from cache
      final storage = await StorageService.getInstance();
      final cachedProfile = storage.getUserProfile();
      if (cachedProfile != null) {
        final profile = PlexUserProfile.fromJson(cachedProfile);
        appLogger.i(
          'Loaded user profile from cache',
          error: {
            'autoSelectAudio': profile.autoSelectAudio,
            'defaultAudioLanguage': profile.defaultAudioLanguage ?? 'not set',
            'autoSelectSubtitle': profile.autoSelectSubtitle,
            'defaultSubtitleLanguage':
                profile.defaultSubtitleLanguage ?? 'not set',
            'defaultSubtitleForced': profile.defaultSubtitleForced,
          },
        );
        return profile;
      }

      appLogger.w(
        'No cached user profile available, track selection will use defaults',
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
