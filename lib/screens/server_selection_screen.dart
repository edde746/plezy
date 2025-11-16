import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/strings.g.dart';
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
      return t.serverSelection.malformedServerData(
        count: error.invalidServerData.length,
      );
    } else if (error is FormatException) {
      // Handle JSON parsing errors with more user-friendly messages
      if (error.message.contains('Invalid server data')) {
        return t.serverSelection.incompleteServerInfo;
      } else if (error.message.contains('Invalid connection data')) {
        return t.serverSelection.incompleteConnectionInfo;
      }
      return t.serverSelection.malformedServerInfo(message: error.message);
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return t.serverSelection.networkConnectionFailed;
    } else if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized')) {
      return t.serverSelection.authenticationFailed;
    } else if (error.toString().contains('404') ||
        error.toString().contains('Not Found')) {
      return t.serverSelection.plexServiceUnavailable;
    }

    return t.serverSelection.failedToLoadServers(error: error.toString());
  }

  Future<void> _copyDebugDataToClipboard() async {
    if (_debugServerData == null) return;

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(_debugServerData);
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.serverSelection.serverDebugCopied)),
      );
    }
  }

  Future<void> _selectServer(PlexServer server) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(t.serverSelection.connectingToServer),
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
            SnackBar(
              content: Text(result.error ?? t.errors.connectionFailedGeneric),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
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
          CustomAppBar(title: Text(t.screens.selectServer)),
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
                              child: Text(t.common.retry),
                            ),
                            if (_debugServerData != null) ...[
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: _copyDebugDataToClipboard,
                                icon: const Icon(Icons.copy),
                                label: Text(t.serverSelection.copyDebugData),
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
                ? Center(child: Text(t.serverSelection.noServersFound))
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
