import 'package:flutter/material.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../client/plex_client.dart';
import '../config/plex_config.dart';
import '../widgets/server_list_tile.dart';
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

  @override
  void initState() {
    super.initState();
    _loadServers();
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
              Text('Testing connections...'),
            ],
          ),
        ),
      );
    }

    // Test connections to find best working one
    final connection = await server.findBestWorkingConnection();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (connection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No working connections found for this server'),
          ),
        );
      }
      return;
    }

    // Store server information
    final storage = await StorageService.getInstance();
    await storage.saveServerData(server.toJson());
    await storage.saveServerUrl(connection.uri);
    await storage.saveServerAccessToken(server.accessToken);
    await storage.savePlexToken(widget.plexToken);

    // Get client identifier
    final clientId =
        storage.getClientIdentifier() ?? widget.authService.clientIdentifier;

    // Create client and navigate to main app
    final config = PlexConfig(
      baseUrl: connection.uri,
      token: server.accessToken,
      clientIdentifier: clientId,
    );
    final client = PlexClient(config);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(client: client)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Server')),
      body: _isLoading
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
                return Card(
                  child: ServerListTile(
                    server: server,
                    onTap: () => _selectServer(server),
                  ),
                );
              },
            ),
    );
  }
}
