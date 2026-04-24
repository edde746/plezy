import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/trackers_provider.dart';
import '../../providers/trakt_account_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'tracker_settings_screen.dart';
import 'trakt_settings_screen.dart';

/// Unified hub for all watch-progress trackers: Trakt, MyAnimeList, AniList,
/// Simkl. Each row opens its service-specific settings screen.
class TrackersSettingsScreen extends StatelessWidget {
  const TrackersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.trackers.title),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                t.trackers.hubSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            _trakt(),
            _mal(),
            _anilist(),
            _simkl(),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _trakt() => Consumer<TraktAccountProvider>(
    builder: (context, account, _) => _TrackerHubRow(
      leading: const _TrackerLogo('assets/trakt_circlemark.svg'),
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
    builder: (context, account, _) => _TrackerHubRow(
      leading: const _TrackerLogo('assets/mal_mark.svg'),
      title: t.trackers.services.mal,
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
    builder: (context, account, _) => _TrackerHubRow(
      leading: const _TrackerLogo('assets/anilist_mark.svg'),
      title: t.trackers.services.anilist,
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
    builder: (context, account, _) => _TrackerHubRow(
      leading: const _TrackerLogo('assets/simkl_mark.svg'),
      title: t.trackers.services.simkl,
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
}

class _TrackerHubRow extends StatelessWidget {
  final Widget leading;
  final String title;

  /// Non-null when connected. When null, the subtitle shows "Not connected".
  final String? username;

  final VoidCallback onTap;

  const _TrackerHubRow({required this.leading, required this.title, required this.username, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(username != null ? t.trackers.connectedAs(username: username!) : t.trackers.notConnected),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: onTap,
    );
  }
}

/// 24x24 SVG logo driven by [IconTheme]. Uses [SvgTheme.currentColor] so SVGs
/// with multiple explicit fills (AniList keeps its brand-blue L while the A
/// follows the theme) render correctly alongside single-color wordmarks.
class _TrackerLogo extends StatelessWidget {
  final String asset;
  const _TrackerLogo(this.asset);

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(asset, width: 24, height: 24, theme: SvgTheme(currentColor: color));
  }
}
