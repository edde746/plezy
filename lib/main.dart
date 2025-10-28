import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'services/storage_service.dart';
import 'services/plex_auth_service.dart';
import 'services/server_connection_service.dart';
import 'services/macos_titlebar_service.dart';
import 'services/fullscreen_state_manager.dart';
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

        // Connect using the optimized service
        final result = await ServerConnectionService.connectToServer(
          server,
          clientIdentifier: clientId,
          verifyServer: true,
          fetchUserProfile: plexToken != null,
          plexToken: plexToken,
        );

        // Handle result
        if (result.isSuccess) {
          // Success! Navigate to main screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  client: result.client!,
                  userProfile: result.userProfile,
                ),
              ),
            );
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
