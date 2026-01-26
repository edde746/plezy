import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../services/server_registry.dart';
import '../providers/multi_server_provider.dart';
import '../providers/plex_client_provider.dart';
import '../providers/libraries_provider.dart';
import '../services/offline_watch_sync_service.dart';
import '../i18n/strings.g.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  late PlexAuthService _authService;
  bool _shouldCancelPolling = false;
  bool _useQrFlow = false; // whether current auth attempt is QR based
  String? _qrAuthUrl; // auth URL rendered as QR

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    _authService = await PlexAuthService.create();

    // On Android TV, auto-start QR code flow
    if (PlatformDetector.isTV()) {
      setState(() {
        _useQrFlow = true;
      });
      _startAuthentication();
    }
  }

  /// Connect to all available servers and navigate to main screen
  Future<void> _connectToAllServersAndNavigate(String plexToken) async {
    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Fetch user info and servers for this user
      final userInfo = await _authService.getUserInfo(plexToken);
      final username = userInfo['username'] as String? ?? '';
      final email = userInfo['email'] as String? ?? '';

      final servers = await _authService.fetchServers(plexToken);
      final storage = await StorageService.getInstance();

      if (servers.isEmpty) {
        await storage.clearCredentials();
        setState(() {
          _isAuthenticating = false;
          _errorMessage = t.serverSelection.noServersFoundForAccount(username: username, email: email);
        });
        return;
      }

      // Save all servers to registry (all servers are considered enabled)
      final registry = ServerRegistry(storage);
      await registry.saveServers(servers);

      // Connect to all servers
      if (!mounted) return;
      final multiServerProvider = context.read<MultiServerProvider>();
      final connectedCount = await multiServerProvider.serverManager.connectToAllServers(servers);

      if (connectedCount == 0) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = t.serverSelection.allServerConnectionsFailed;
        });
        return;
      }

      // Get the first connected client for backward compatibility
      if (!mounted) return;
      final firstClient = multiServerProvider.serverManager.onlineClients.values.first;

      // Set it as the legacy client
      final plexClientProvider = context.read<PlexClientProvider>();
      plexClientProvider.setClient(firstClient);

      // Initialize and load libraries (mirroring SetupScreen behavior)
      final librariesProvider = context.read<LibrariesProvider>();
      librariesProvider.initialize(multiServerProvider.aggregationService);
      try {
        await librariesProvider.loadLibraries();
      } catch (e) {
        appLogger.w('Failed to load libraries during sign-in', error: e);
        // Continue anyway - MainScreen will retry
      }

      // Trigger initial watch sync now that Plex clients are available
      if (mounted) {
        context.read<OfflineWatchSyncService>().onServersConnected();
      }

      // Navigate to main screen
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(client: firstClient)));
    } catch (e) {
      appLogger.e('Failed to connect to servers', error: e);
      setState(() {
        _isAuthenticating = false;
        _errorMessage = t.serverSelection.failedToLoadServers(error: e);
      });
    }
  }

  Future<void> _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
      _shouldCancelPolling = false;
      // preserve _useQrFlow as chosen prior to calling
      if (!_useQrFlow) {
        _qrAuthUrl = null; // ensure stale QR cleared for browser flow
      }
    });

    try {
      // Create a PIN
      final pinData = await _authService.createPin();
      final pinId = pinData['id'] as int;
      final pinCode = pinData['code'] as String;

      // Construct auth URL
      final authUrl = _authService.getAuthUrl(pinCode);

      if (_useQrFlow) {
        // Display QR instead of launching browser
        setState(() {
          _qrAuthUrl = authUrl;
        });
      } else {
        // Open browser (in-app for mobile, external for desktop)
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          // On TV, use inAppWebView (simpler WebView) instead of Chrome Custom Tabs
          final mode = PlatformDetector.isTV()
              ? LaunchMode.inAppWebView
              : LaunchMode.inAppBrowserView;
          await launchUrl(uri, mode: mode);
        } else {
          throw Exception(t.errors.couldNotLaunchUrl);
        }
      }

      // Poll for authentication with cancellation support
      final token = await _authService.pollPinUntilClaimed(pinId, shouldCancel: () => _shouldCancelPolling);

      // If polling was cancelled, don't show error
      if (_shouldCancelPolling) {
        return;
      }

      if (token == null) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = t.auth.authenticationTimeout;
        });
        return;
      }

      // Auto-close the in-app browser on mobile (no-op on desktop)
      if (!_useQrFlow) {
        try {
          await closeInAppWebView();
        } catch (e) {
          // Ignore errors - browser might already be closed or on desktop
        }
      }

      // Store the token
      final storage = await StorageService.getInstance();
      await storage.savePlexToken(token);

      // Clear QR URL after successful auth
      setState(() {
        _qrAuthUrl = null;
        _useQrFlow = false;
      });

      // Connect to all servers and navigate to main screen
      if (mounted) {
        await _connectToAllServersAndNavigate(token);
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = t.errors.authenticationFailed(error: e);
      });
    }
  }

  void _retryAuthentication() {
    setState(() {
      _shouldCancelPolling = true;
      _isAuthenticating = false;
      _qrAuthUrl = null;
    });
    // Start new authentication after a brief delay to ensure cleanup
    Future.delayed(const Duration(milliseconds: 100), _startAuthentication);
  }

  void _handleDebugTap() {
    if (!kDebugMode) return;
    _showDebugTokenDialog();
  }

  void _showDebugTokenDialog() {
    final tokenController = TextEditingController();
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.auth.debugEnterToken),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tokenController,
                    decoration: InputDecoration(
                      labelText: t.auth.plexTokenLabel,
                      hintText: t.auth.plexTokenHint,
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    maxLines: 1,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.auth.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    final token = tokenController.text.trim();
                    if (token.isEmpty) {
                      setDialogState(() {
                        errorMessage = t.errors.pleaseEnterToken;
                      });
                      return;
                    }

                    final navigator = Navigator.of(context);

                    try {
                      final isValid = await _authService.verifyToken(token);
                      if (!isValid) {
                        setDialogState(() {
                          errorMessage = t.errors.invalidToken;
                        });
                        return;
                      }

                      // Store the token
                      final storage = await StorageService.getInstance();
                      await storage.savePlexToken(token);

                      // Close dialog and connect to all servers
                      if (mounted) {
                        navigator.pop();
                        await _connectToAllServersAndNavigate(token);
                      }
                    } catch (e) {
                      setDialogState(() {
                        errorMessage = t.errors.failedToVerifyToken(error: e);
                      });
                    }
                  },
                  child: Text(t.auth.authenticate),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use two-column layout on desktop, single column on mobile
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : 400),
          padding: const EdgeInsets.all(24),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // First column - Logo and title (always visible)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/plezy.png', width: 120, height: 120),
                          const SizedBox(height: 24),
                          Text(
                            t.app.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Second column - All authentication content
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isAuthenticating) ...[
                                if (_useQrFlow && _qrAuthUrl != null)
                                  _buildQrAuthWidget(qrSize: 300)
                                else
                                  _buildBrowserAuthWidget(),
                              ] else
                                _buildInitialButtons(),
                            ],
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
                      Image.asset('assets/plezy.png', width: 120, height: 120),
                      const SizedBox(height: 24),
                      Text(
                        t.app.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      if (_isAuthenticating) ...[
                        if (_useQrFlow && _qrAuthUrl != null)
                          _buildQrAuthWidget(qrSize: 200)
                        else
                          _buildBrowserAuthWidget(),
                      ] else
                        _buildInitialButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Builds the initial authentication buttons (before auth starts)
  Widget _buildInitialButtons() {
    final isTV = PlatformDetector.isTV();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTV) ...[
          // On TV: QR is primary, browser is secondary
          ElevatedButton(
            autofocus: true,
            onPressed: () {
              setState(() {
                _useQrFlow = true;
              });
              _startAuthentication();
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(t.auth.showQRCode),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _startAuthentication,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(t.auth.useBrowser),
          ),
        ] else ...[
          // On other platforms: Browser is primary, QR is secondary
          ElevatedButton(
            onPressed: _startAuthentication,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(t.auth.signInWithPlex),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _useQrFlow = true;
              });
              _startAuthentication();
            },
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(t.auth.showQRCode),
          ),
        ],
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _handleDebugTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Text(t.auth.debugEnterToken, style: TextStyle(fontSize: 12)),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _retryAuthentication,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
          child: Text(t.auth.retry),
        ),
      ],
    );
  }

  /// Builds the QR code authentication widget
  Widget _buildQrAuthWidget({required double qrSize}) {
    final isTV = PlatformDetector.isTV();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.auth.scanQRToSignIn,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens(context).radiusMd),
            child: QrImageView(
              data: _qrAuthUrl!,
              size: qrSize,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        // On TV, show retry and browser buttons in a row
        if (isTV) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                autofocus: true,
                onPressed: _retryAuthentication,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
                child: Text(t.auth.retry),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _useQrFlow = false;
                  });
                  _startAuthentication();
                },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
                child: Text(t.auth.useBrowser),
              ),
            ],
          ),
        ] else
          _buildRetryButton(),
      ],
    );
  }

  /// Builds the browser authentication waiting widget
  Widget _buildBrowserAuthWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Text(
          t.auth.waitingForAuth,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        _buildRetryButton(),
      ],
    );
  }
}
