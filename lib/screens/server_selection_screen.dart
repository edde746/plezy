import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../services/server_connection_service.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/desktop_app_bar.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import 'main_screen.dart';

class ServerSelectionScreen extends StatefulWidget {
  final PlexAuthService authService;
  final String plexToken;

  const ServerSelectionScreen({
    super.key,
    required this.authService,
    required this.plexToken,
  });

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  List<PlexServer>? _servers;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentServerUrl;
  List<Map<String, dynamic>>? _debugServerData;

  @override
  void initState() {
    super.initState();
    _loadCurrentServerUrl();
    _loadServers();
  }

  Future<void> _loadCurrentServerUrl() async {
    try {
      final storage = await StorageService.getInstance();
      setState(() {
        _currentServerUrl = storage.getServerUrl();
      });
    } catch (e) {
      appLogger.w('Failed to load current server URL', error: e);
    }
  }

  Future<void> _loadServers() async {
    try {
      final servers = await widget.authService.fetchServers(widget.plexToken);
      setState(() {
        _servers = servers;
        _isLoading = false;
        _debugServerData = null; // Clear any previous debug data
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
        // Store debug data if it's a parsing exception
        if (e is ServerParsingException) {
          _debugServerData = e.invalidServerData;
        } else {
          _debugServerData = null;
        }
      });
      appLogger.e('Failed to load servers', error: e);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ServerParsingException) {
      return 'Found ${error.invalidServerData.length} server(s) with malformed data. No valid servers available.';
    } else if (error is FormatException) {
      // Handle JSON parsing errors with more user-friendly messages
      if (error.message.contains('Invalid server data')) {
        return 'Some servers have incomplete information and were skipped. Please check your Plex.tv account.';
      } else if (error.message.contains('Invalid connection data')) {
        return 'Server connection information is incomplete. Please try again.';
      }
      return 'Server information is malformed: ${error.message}';
    } else if (error.toString().contains('SocketException') ||
               error.toString().contains('TimeoutException')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    } else if (error.toString().contains('401') ||
               error.toString().contains('Unauthorized')) {
      return 'Authentication failed. Please sign in again.';
    } else if (error.toString().contains('404') ||
               error.toString().contains('Not Found')) {
      return 'Plex service unavailable. Please try again later.';
    }

    return 'Failed to load servers: ${error.toString()}';
  }

  Future<void> _copyDebugDataToClipboard() async {
    if (_debugServerData == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(_debugServerData);
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server debug data copied to clipboard')),
      );
    }
  }

  Future<void> _selectServer(PlexServer server) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to server...'),
            ],
          ),
        ),
      );
    }

    try {
      // Get client identifier and storage
      final storage = await StorageService.getInstance();
      final clientId =
          storage.getClientIdentifier() ?? widget.authService.clientIdentifier;

      // Get current profile context to maintain profile across server switch
      final currentUserUUID = storage.getCurrentUserUUID();

      PlexServer serverWithCorrectToken = server;

      // If we have a current profile, get a profile-specific token for this server
      if (currentUserUUID != null) {
        try {
          // Switch to the current profile on the new server to get the correct token
          final switchResponse = await widget.authService.switchToUser(
            currentUserUUID,
            widget.plexToken,
          );

          // Get servers with the profile's Plex.tv token to get profile-specific server tokens
          final servers = await widget.authService.fetchServers(
            switchResponse.authToken,
          );

          // Find the matching server with the profile-specific token
          final matchingServer = servers.firstWhere(
            (s) =>
                s.name == server.name ||
                s.clientIdentifier == server.clientIdentifier,
            orElse: () => server, // Fallback to original server
          );

          serverWithCorrectToken = matchingServer;
          appLogger.d(
            'Got profile-specific token for server ${server.name} and user UUID $currentUserUUID',
          );
        } catch (e) {
          appLogger.w(
            'Failed to get profile-specific token, using default server token',
            error: e,
          );
          // Continue with original server token as fallback
        }
      }

      // Connect using the server with the correct token
      final result = await ServerConnectionService.connectToServer(
        serverWithCorrectToken,
        clientIdentifier: clientId,
        plexToken: widget.plexToken,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Handle result
      if (result.isSuccess) {
        // Set client in provider before navigation (same pattern as auto-login)
        if (mounted) {
          context.plexClient.setClient(result.client!);

          // Navigate to main app and clear navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(client: result.client!),
            ),
            (route) => false, // Remove all routes
          );
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Connection failed')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to server: $e')),
        );
      }
      appLogger.e('Server selection failed', error: e);
    }
  }

  bool _isCurrentServer(PlexServer server) {
    if (_currentServerUrl == null) return false;

    // Check all server connections to see if any match the current server URL
    for (final connection in server.connections) {
      if (connection.uri == _currentServerUrl) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(title: Text('Select Server')),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _loadServers,
                              child: const Text('Retry'),
                            ),
                            if (_debugServerData != null) ...[
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: _copyDebugDataToClipboard,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Debug Data'),
                              ),
                            ],
                          ],
                        ),
                        if (_debugServerData != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Debug data available for ${_debugServerData!.length} server(s)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  )
                : _servers == null || _servers!.isEmpty
                ? const Center(child: Text('No servers found'))
                : ListView.builder(
                    itemCount: _servers!.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final server = _servers![index];
                      final isCurrentServer = _isCurrentServer(server);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ServerListTile(
                            server: server,
                            isCurrentServer: isCurrentServer,
                            onTap: () => _selectServer(server),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
