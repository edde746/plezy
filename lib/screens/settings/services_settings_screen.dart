import '../../profiles/active_profile_provider.dart';
import '../../focus/focusable_wrapper.dart';
import '../../media/media_backend.dart';
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
import '../../widgets/backend_badge.dart';
import '../../widgets/connector_brand_mark.dart';
import '../../widgets/provider_mark.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';
import 'add_connection_screen.dart';
import 'hardcover_settings_screen.dart';
import '../sources/add_source_screen.dart';
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
              children: [
                FocusableListTile(
                  leading: const _MediaServerMarks(),
                  title: Text(t.addServer.addConnectionTitle),
                  subtitle: Text(t.addServer.addConnectionSubtitleNoProfile),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(builder: (_) => const AddConnectionScreen()),
                  ),
                ),
                FocusableListTile(
                  leading: const _FileSourceMarks(),
                  title: Text(t.fileSources.title),
                  subtitle: Text(t.fileSources.subtitle),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(builder: (_) => const AddSourceScreen()),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(t.explore.detail.links, style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ConnectorCategoryGrid(
                onCategorySelected: (category) => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ExternalAccessScreen(title: '', categories: [category]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsGroup(
              title: t.services.integrations,
              children: [
                for (final info in TrackerServiceInfo.all) _TrackerHubRow(info),
                _seerr(),
                _remoteStreaming(),
                FocusableListTile(
                  leading: ConnectorBrandMark(providerId: 'hardcover', name: t.services.hardcover),
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
                    secondary: ConnectorBrandMark(providerId: 'discord', name: 'Discord'),
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

class _MediaServerMarks extends StatelessWidget {
  const _MediaServerMarks();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BackendBadge(backend: MediaBackend.plex, size: 22),
      SizedBox(width: 4),
      BackendBadge(backend: MediaBackend.jellyfin, size: 22),
      SizedBox(width: 4),
      BackendBadge(backend: MediaBackend.emby, size: 22),
    ],
  );
}

class _FileSourceMarks extends StatelessWidget {
  const _FileSourceMarks();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ProviderMark('google_drive.png', size: 22),
      SizedBox(width: 3),
      ProviderMark('onedrive.svg', size: 22),
      SizedBox(width: 3),
      ProviderMark('dropbox.png', size: 22),
    ],
  );
}

class _ConnectorCategoryGrid extends StatelessWidget {
  const _ConnectorCategoryGrid({required this.onCategorySelected});

  final ValueChanged<ExternalAccessCategory> onCategorySelected;

  String _label(ExternalAccessCategory category) => switch (category) {
    ExternalAccessCategory.video => t.explore.detail.watchOn,
    ExternalAccessCategory.rentals => t.explore.detail.links,
    ExternalAccessCategory.books => t.fileSources.ebooks,
    ExternalAccessCategory.audiobooks => t.fileSources.audiobooks,
    ExternalAccessCategory.comics => t.fileSources.comics,
    ExternalAccessCategory.music => t.explore.format.music,
    ExternalAccessCategory.games => t.games.title,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 480.0;
        final columns = width >= 900 ? 3 : width >= 620 ? 2 : 1;
        const gap = 12.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in ExternalAccessCategory.values)
              SizedBox(
                width: cardWidth,
                child: _ConnectorCategoryCard(
                  category: category,
                  label: _label(category),
                  onTap: () => onCategorySelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConnectorCategoryCard extends StatelessWidget {
  const _ConnectorCategoryCard({
    required this.category,
    required this.label,
    required this.onTap,
  });

  final ExternalAccessCategory category;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = ExternalAccessDirectory.forCategory(category).toList(growable: false);
    final preview = destinations.take(4).toList(growable: false);
    final radius = BorderRadius.circular(20);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: .65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FocusableWrapper(
        borderRadii: radius,
        semanticLabel: label,
        onSelect: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 106,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          destinations.length.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      for (final destination in preview) ...[
                        ConnectorBrandMark(
                          providerId: destination.id,
                          name: destination.name,
                          size: 24,
                          logoDomain: destination.host,
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Spacer(),
                      Icon(
                        Symbols.chevron_right_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
