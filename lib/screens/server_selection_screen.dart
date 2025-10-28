import 'package:flutter/material.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../services/server_connection_service.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/desktop_app_bar.dart';
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

    // Get client identifier
    final storage = await StorageService.getInstance();
    final clientId =
        storage.getClientIdentifier() ?? widget.authService.clientIdentifier;

    // Connect using the optimized service
    final result = await ServerConnectionService.connectToServer(
      server,
      clientIdentifier: clientId,
      plexToken: widget.plexToken,
    );

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    // Handle result
    if (result.isSuccess) {
      // Navigate to main app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(client: result.client!),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DesktopAppBar(title: Text('Select Server')),
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
