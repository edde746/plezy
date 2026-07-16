import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/seerr_account_provider.dart';
import '../../providers/trackers_provider.dart';
import '../../providers/trakt_account_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/catalog_source_logo.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';
import 'seerr_connect_screen.dart';
import 'seerr_settings_screen.dart';
import 'tracker_settings_screen.dart';
import 'trakt_settings_screen.dart';

/// Unified hub for all connected services: the watch-progress trackers
/// (Trakt, MyAnimeList, AniList, Simkl) and the Seerr request server. Each
/// row opens its service-specific settings screen.
class ServicesSettingsScreen extends StatelessWidget {
  const ServicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.services.title),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                t.services.hubSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            SettingsGroup(children: [_trakt(), _mal(), _anilist(), _simkl(), _seerr()]),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _trakt() => Consumer<TraktAccountProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo.asset('assets/trakt_circlemark.svg', size: 24),
      title: t.trakt.title,
      username: account.isConnected ? account.username : null,
      onTap: () {
        if (account.isConnected) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TraktSettingsScreen()));
        } else {
          startTraktConnection(context);
        }
      },
    ),
  );

  Widget _mal() => Consumer<TrackersProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo.asset('assets/mal_mark.svg', size: 24),
      title: t.services.names.mal,
      username: account.isMalConnected ? account.malUsername : null,
      onTap: () {
        if (account.isMalConnected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrackerSettingsScreen(config: TrackerConfig.mal())),
          );
        } else {
          startMalConnection(context);
        }
      },
    ),
  );

  Widget _anilist() => Consumer<TrackersProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo.asset('assets/anilist_mark.svg', size: 24),
      title: t.services.names.anilist,
      username: account.isAnilistConnected ? account.anilistUsername : null,
      onTap: () {
        if (account.isAnilistConnected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrackerSettingsScreen(config: TrackerConfig.anilist())),
          );
        } else {
          startAnilistConnection(context);
        }
      },
    ),
  );

  Widget _simkl() => Consumer<TrackersProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo.asset('assets/simkl_mark.svg', size: 24),
      title: t.services.names.simkl,
      username: account.isSimklConnected ? account.simklUsername : null,
      onTap: () {
        if (account.isSimklConnected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrackerSettingsScreen(config: TrackerConfig.simkl())),
          );
        } else {
          startSimklConnection(context);
        }
      },
    ),
  );

  Widget _seerr() => Consumer<SeerrAccountProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo.asset('assets/seerr_mark.svg', size: 24),
      title: t.services.names.seerr,
      username: account.isConnected ? account.displayName : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => account.isConnected ? const SeerrSettingsScreen() : const SeerrConnectScreen(),
          ),
        );
      },
    ),
  );
}

class _ServiceHubRow extends StatelessWidget {
  final Widget leading;
  final String title;

  /// Non-null when connected. When null, the subtitle shows "Not connected".
  final String? username;

  final VoidCallback onTap;

  const _ServiceHubRow({required this.leading, required this.title, required this.username, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(username != null ? t.services.connectedAs(username: username!) : t.services.notConnected),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: onTap,
    );
  }
}
