import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../providers/multi_server_provider.dart';
import '../screens/settings/add_connection_screen.dart';
import 'app_icon.dart';

/// Top-of-app banner shown when one or more servers' tokens have been
/// rejected (HTTP 401/403 on the health probe). Distinct from "server
/// offline" — taps the user toward re-auth instead of leaving them
/// puzzled by empty hubs.
///
/// Tracks [MultiServerProvider.hasAuthErrorServers] and collapses to
/// `SizedBox.shrink()` when no servers are in the auth-error state. The
/// CTA opens [AddConnectionScreen]; the user picks the right backend and
/// the resulting token replaces the stale row in the registry, which
/// clears the auth-error state on the next health sweep.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.select<MultiServerProvider, List<({String serverId, String displayName})>>(
      (p) => p.authErrorServers,
    );
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = entries.length == 1
        ? t.connections.sessionExpiredOne(name: entries.first.displayName)
        : t.connections.sessionExpiredMany(count: entries.length);

    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              AppIcon(Symbols.lock_rounded, fill: 1, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onErrorContainer,
                  foregroundColor: scheme.errorContainer,
                ),
                onPressed: () => _openReauth(context),
                child: Text(t.connections.signInAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReauth(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddConnectionScreen()));
  }
}
