import '../../profiles/active_profile_provider.dart';
import '../../utils/platform_detector.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/seerr_account_provider.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/external_access_directory.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/catalog_source_logo.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';
import 'hardcover_settings_screen.dart';
import 'integration_matches_screen.dart';
import 'seerr_connect_screen.dart';
import 'seerr_settings_screen.dart';
import 'remote_streaming_settings_screen.dart';
import 'tracker_service_info.dart';
import '../external_access_screen.dart';

/// Unified hub for connected trackers, reading history, requests, and
/// external-access integrations.
class ServicesSettingsScreen extends StatelessWidget {
  const ServicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileId = context.watch<ActiveProfileProvider?>()?.activeId;
    return FocusedScrollScaffold(
      title: Text(t.services.title),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SettingsHelpHint(text: t.services.hubSubtitle),
            ),
            SettingsGroup(
              children: [for (final info in TrackerServiceInfo.all) _TrackerHubRow(info), _seerr(), _remoteStreaming()],
            ),
            SettingsGroup(
              title: t.services.integrations,
              children: [
                FocusableListTile(
                  leading: const AppIcon(Symbols.menu_book_rounded, fill: 1),
                  title: Text(t.services.hardcover),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: profileId == null
                      ? null
                      : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(builder: (_) => HardcoverSettingsScreen(profileId: profileId)),
                        ),
                ),
                if (profileId != null)
                  FocusableListTile(
                    leading: const AppIcon(Symbols.link_rounded),
                    title: Text(t.services.linkedCatalogTitles),
                    trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (_) => IntegrationMatchesScreen(profileId: profileId)),
                    ),
                  ),
                FocusableListTile(
                  leading: const AppIcon(Symbols.open_in_new_rounded),
                  title: Text(t.explore.detail.links),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ExternalAccessScreen(title: '', categories: ExternalAccessCategory.values),
                    ),
                  ),
                ),
              ],
            ),
            if (profileId != null && PlatformDetector.supportsEmbeddedGameStreaming())
              SettingsGroup(
                title: t.games.title,
                children: [
                  SettingSwitchTile(
                    pref: SettingsService.showGamesTabForProfile(profileId),
                    icon: Symbols.sports_esports_rounded,
                    title: t.games.enable,
                    subtitle: t.games.enableDescription,
                  ),
                ],
              ),
            if (DiscordRPCService.isAvailable)
              SettingsGroup(
                title: t.services.integrations,
                children: [
                  SettingSwitchTile(
                    pref: SettingsService.enableDiscordRPC,
                    icon: Symbols.chat_rounded,
                    title: t.settings.discordRichPresence,
                    subtitle: t.settings.discordRichPresenceDescription,
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _seerr() => Consumer<SeerrAccountProvider>(
    builder: (context, account, _) => _ServiceHubRow(
      leading: const CatalogSourceLogo(CatalogSourceId.seerr, size: 24),
      title: t.services.names.seerr,
      description: t.services.seerrDescription,
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

  Widget _remoteStreaming() => Consumer<RemoteStreamingProvider>(
    builder: (context, streaming, _) {
      final configured = streaming.accounts.length + streaming.addons.length;
      return FocusableListTile(
        leading: const AppIcon(Symbols.play_circle_rounded, fill: 1),
        title: Text(t.streaming.title),
        subtitle: Text(
          streaming.loading
              ? t.streaming.subtitle
              : configured == 0
              ? t.streaming.addonsDescription
              : t.streaming.connectionsConfigured(count: configured),
        ),
        trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemoteStreamingSettingsScreen())),
      );
    },
  );
}

/// Hub row for a watch tracker. Owns the `watch` on that service's account
/// provider so only this row rebuilds when the connection state changes.
class _TrackerHubRow extends StatelessWidget {
  final TrackerServiceInfo info;

  const _TrackerHubRow(this.info);

  @override
  Widget build(BuildContext context) {
    final connected = info.isConnected(context);
    return _ServiceHubRow(
      leading: CatalogSourceLogo(info.logoSource, size: 24),
      title: info.displayName,
      description: info.description,
      username: connected ? info.username(context) : null,
      onTap: () {
        if (connected) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => info.buildSettingsScreen()));
        } else {
          info.startConnection(context);
        }
      },
    );
  }
}

class _ServiceHubRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String description;

  /// Non-null when connected. When null, the subtitle shows "Not connected".
  final String? username;

  final VoidCallback onTap;

  const _ServiceHubRow({
    required this.leading,
    required this.title,
    required this.description,
    required this.username,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(
        '${username != null ? t.services.connectedAs(username: username!) : t.services.notConnected} · $description',
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: onTap,
    );
  }
}
