import 'package:flutter/material.dart';
import '../services/plex_auth_service.dart';

class ServerListTile extends StatelessWidget {
  final PlexServer server;
  final VoidCallback onTap;
  final bool showTrailingIcon;

  const ServerListTile({
    super.key,
    required this.server,
    required this.onTap,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = server.isOnline;

    return ListTile(
      leading: Icon(
        Icons.dns,
        color: isOnline
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      title: Text(server.name),
      subtitle: Row(
        children: [
          Icon(
            isOnline ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            server.owned ? 'Owned' : 'Shared',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: showTrailingIcon ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
