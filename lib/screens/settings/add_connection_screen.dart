import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../profiles/profile.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/desktop_app_bar.dart';
import '../profile/borrow_connection_screen.dart';
import 'add_jellyfin_screen.dart';
import 'add_plex_account_screen.dart';

/// Picker shown when the user taps "Add connection".
///
/// When [targetProfile] is provided, also offers a "Borrow from another
/// profile" option that opens [BorrowConnectionScreen] for the target. The
/// global Connections screen invokes this without a target — Plex auto-
/// surfaces its Home users as new profiles, Jellyfin binds to the active
/// profile via [AddJellyfinScreen].
///
/// Pops with `true` after the underlying flow succeeds so the parent list
/// refreshes; pops with `null` (the default) when the user backs out.
class AddConnectionScreen extends StatelessWidget {
  final Profile? targetProfile;

  const AddConnectionScreen({super.key, this.targetProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoped = targetProfile != null;
    final options = <_BackendOption>[
      _BackendOption(
        backend: MediaBackend.plex,
        title: t.addServer.signInWithPlexCard,
        subtitle: scoped ? t.addServer.signInWithPlexCardSubtitleScoped : t.addServer.signInWithPlexCardSubtitle,
        builder: (_) => AddPlexAccountScreen(targetProfile: targetProfile),
      ),
      _BackendOption(
        backend: MediaBackend.jellyfin,
        title: t.addServer.connectToJellyfinCard,
        subtitle: scoped
            ? t.addServer.connectToJellyfinCardSubtitleScoped(name: targetProfile!.displayName)
            : t.addServer.connectToJellyfinCardSubtitle,
        builder: (_) => AddJellyfinScreen(targetProfile: targetProfile),
      ),
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExcludeFocus(
            child: CustomAppBar(
              title: Text(
                scoped
                    ? t.addServer.addConnectionTitleScoped(name: targetProfile!.displayName)
                    : t.addServer.addConnectionTitle,
              ),
              pinned: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  scoped ? t.addServer.addConnectionIntroScoped : t.addServer.addConnectionIntroGlobal,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _BackendCard(
                    leading: BackendBadge(backend: options[i].backend, size: 28),
                    title: options[i].title,
                    subtitle: options[i].subtitle,
                    onTap: () async {
                      final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: options[i].builder));
                      if (added == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ],
                if (scoped) ...[
                  const SizedBox(height: 12),
                  _BackendCard(
                    leading: const AppIcon(Symbols.share_rounded, fill: 1, size: 28),
                    title: t.addServer.borrowFromAnotherProfile,
                    subtitle: t.addServer.borrowFromAnotherProfileSubtitle,
                    onTap: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => BorrowConnectionScreen(targetProfile: targetProfile!)),
                      );
                      if (added == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendOption {
  final MediaBackend backend;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  const _BackendOption({required this.backend, required this.title, required this.subtitle, required this.builder});
}

class _BackendCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackendCard({required this.leading, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            ],
          ),
        ),
      ),
    );
  }
}
