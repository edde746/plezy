import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import 'server_selection_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    _authService = await PlexAuthService.create();
  }

  Future<void> _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
      _shouldCancelPolling = false;
    });

    try {
      // Create a PIN
      final pinData = await _authService.createPin();
      final pinId = pinData['id'] as int;
      final pinCode = pinData['code'] as String;

      // Construct auth URL
      final authUrl = _authService.getAuthUrl(pinCode);

      // Open browser (in-app for mobile, external for desktop)
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else {
        throw Exception('Could not launch auth URL');
      }

      // Poll for authentication with cancellation support
      final token = await _authService.pollPinUntilClaimed(
        pinId,
        shouldCancel: () => _shouldCancelPolling,
      );

      // If polling was cancelled, don't show error
      if (_shouldCancelPolling) {
        return;
      }

      if (token == null) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Authentication timed out. Please try again.';
        });
        return;
      }

      // Auto-close the in-app browser on mobile (no-op on desktop)
      try {
        await closeInAppWebView();
      } catch (e) {
        // Ignore errors - browser might already be closed or on desktop
      }

      // Store the token
      final storage = await StorageService.getInstance();
      await storage.savePlexToken(token);

      // Navigate to server selection
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServerSelectionScreen(
              authService: _authService,
              plexToken: token,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Authentication failed: $e';
      });
    }
  }

  void _retryAuthentication() {
    setState(() {
      _shouldCancelPolling = true;
      _isAuthenticating = false;
    });
    // Start new authentication after a brief delay to ensure cleanup
    Future.delayed(const Duration(milliseconds: 100), _startAuthentication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/plezy.png', width: 120, height: 120),
              const SizedBox(height: 24),
              Text(
                'Plezy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Text(
                  'Waiting for authentication...\nPlease complete sign-in in your browser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _retryAuthentication,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _startAuthentication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Sign in with Plex'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
