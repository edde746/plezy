import 'package:flutter/material.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../services/server_connection_service.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/desktop_app_bar.dart';
import '../utils/app_logger.dart';
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load servers: $e';
        _isLoading = false;
      });
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
        // Navigate to main app and clear navigation stack
        if (mounted) {
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
          const DesktopSliverAppBar(title: Text('Select Server')),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadServers,
                          child: const Text('Retry'),
                        ),
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
