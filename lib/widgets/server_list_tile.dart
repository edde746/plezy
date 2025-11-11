import 'package:flutter/material.dart';
import '../services/plex_auth_service.dart';
import '../i18n/strings.g.dart';

class ServerListTile extends StatelessWidget {
  final PlexServer server;
  final VoidCallback onTap;
  final bool showTrailingIcon;
  final bool isCurrentServer;

  const ServerListTile({
    super.key,
    required this.server,
    required this.onTap,
    this.showTrailingIcon = true,
    this.isCurrentServer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = server.isOnline;

    return Semantics(
      selected: isCurrentServer,
      identifier: server.name,
      label: server.name,
      child: ListTile(
        key: ValueKey(server.name),
        leading: Icon(
          Icons.dns,
          color: isOnline
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          semanticLabel: t.common.server,
        ),
        title: Text(server.name),
        subtitle: Semantics(
          label:
              '${isOnline ? t.common.online : t.common.offline}, ${server.owned ? t.common.owned : t.common.shared}',
          excludeSemantics: true,
          child: Row(
            children: [
              Semantics(
                excludeSemantics: true,
                child: Icon(
                  isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? t.common.online : t.common.offline,
                style: TextStyle(
                  fontSize: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                excludeSemantics: true,
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                server.owned ? t.common.owned : t.common.shared,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: isCurrentServer
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.common.current,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : (showTrailingIcon ? const Icon(Icons.chevron_right) : null),
        onTap: isCurrentServer ? null : onTap,
        enabled: !isCurrentServer,
      ),
    );
  }
}
