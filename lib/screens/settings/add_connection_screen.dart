import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../media/media_browser_dialect.dart';
import '../../theme/mono_tokens.dart';
import '../../profiles/profile.dart';
import '../../widgets/backend_badge.dart';
import '../../services/music_assistant_lan_discovery_service.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../profile/borrow_connection_screen.dart';
import 'add_jellyfin_screen.dart';
import 'add_music_assistant_screen.dart';
import 'add_plex_account_screen.dart';
import 'local_server_discovery.dart';

/// Picker shown when the user taps "Add connection".
///
/// When [targetProfile] is provided, also offers a "Borrow from another
/// profile" option that opens [BorrowConnectionScreen] for the target. The
/// global Connections screen invokes this without a target — Plex auto-
/// surfaces its Home users as new profiles, while MediaBrowser servers bind
/// to the active profile via [AddJellyfinScreen].
///
/// Pops with `true` after the underlying flow succeeds so the parent list
/// refreshes; pops with `null` (the default) when the user backs out.
///
/// ### Why this screen browses the network
///
/// It runs the Music Assistant mDNS browse itself, and says so on the card
/// when something answers. That looks like work belonging to the next screen,
/// and the reason it is here is timing: the browse takes about two and a half
/// seconds, and a user who taps through immediately would otherwise watch a
/// spinner on the other side of the transition. Started here, the answer is
/// usually already waiting by the time the next screen builds.
///
/// It also changes what the card *means*. "Enter your server URL" asks for
/// homework; "Found on your network" is an invitation, and it is the honest
/// label for a one-tap add. Nothing depends on the result — the card behaves
/// identically if the browse finds nothing or never finishes, which is why it
/// is safe to fire and forget.
///
/// Plex and Jellyfin are not browsed for here. Plex has no LAN advert to find
/// and Jellyfin's discovery is a UDP broadcast its own screen already runs at
/// the moment it can act on it.
class AddConnectionScreen extends StatefulWidget {
  final Profile? targetProfile;
  const AddConnectionScreen({super.key, this.targetProfile});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen>
    with LocalServerDiscoveryMixin<DiscoveredMusicAssistantServer, AddConnectionScreen> {
  @override
  String get discoveryDebugLabel => 'AddConnection';

  @override
  String discoveredServerId(DiscoveredMusicAssistantServer server) => server.id;

  @override
  Future<List<DiscoveredMusicAssistantServer>> discoverLocalServers() async {
    return MusicAssistantLanDiscoveryService().discover();
  }

  @override
  void initState() {
    super.initState();
    startLocalDiscovery();
  }

  @override
  void dispose() {
    disposeLocalDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetProfile = widget.targetProfile;
    final scoped = targetProfile != null;
    const jellyfinDialect = MediaBrowserDialect.jellyfin;
    const embyDialect = MediaBrowserDialect.emby;
    final foundMusicAssistant = localServers.isNotEmpty;
    final options = <_BackendOption>[
      _BackendOption(
        backend: MediaBackend.plex,
        title: t.addServer.signInWithPlexCard,
        subtitle: scoped ? t.addServer.signInWithPlexCardSubtitleScoped : t.addServer.signInWithPlexCardSubtitle,
        builder: (_) => AddPlexAccountScreen(targetProfile: targetProfile),
      ),
      _BackendOption(
        backend: MediaBackend.jellyfin,
        title: t.addServer.connectToMediaBrowserCard(product: jellyfinDialect.productName),
        subtitle: scoped
            ? t.addServer.connectToMediaBrowserCardSubtitleScoped(
                product: jellyfinDialect.productName,
                name: targetProfile.displayName,
              )
            : t.addServer.connectToMediaBrowserCardSubtitle,
        builder: (_) => AddJellyfinScreen(targetProfile: targetProfile, dialect: jellyfinDialect),
      ),
      _BackendOption(
        backend: MediaBackend.emby,
        title: t.addServer.connectToMediaBrowserCard(product: embyDialect.productName),
        subtitle: scoped
            ? t.addServer.connectToMediaBrowserCardSubtitleScoped(
                product: embyDialect.productName,
                name: targetProfile.displayName,
              )
            : t.addServer.connectToMediaBrowserCardSubtitle,
        builder: (_) => AddJellyfinScreen(targetProfile: targetProfile, dialect: embyDialect),
      ),
      _BackendOption(
        backend: MediaBackend.musicAssistant,
        title: t.addServer.connectToMusicAssistantCard,
        // The scoped copy wins when both apply: which profile the connection
        // binds to is a consequence the user has to know about, and "found on
        // your network" is only an encouragement.
        subtitle: scoped
            ? t.addServer.connectToMusicAssistantCardSubtitleScoped(name: targetProfile.displayName)
            : foundMusicAssistant
            ? t.addServer.connectToMusicAssistantCardSubtitleFound
            : t.addServer.connectToMusicAssistantCardSubtitle,
        builder: (_) => AddMusicAssistantScreen(targetProfile: targetProfile),
      ),
      if (scoped)
        _BackendOption(
          backend: null,
          title: t.addServer.borrowFromAnotherProfile,
          subtitle: t.addServer.borrowFromAnotherProfileSubtitle,
          builder: (_) => BorrowConnectionScreen(targetProfile: targetProfile),
        ),
    ];
    final tokensRef = tokens(context);
    return FocusedScrollScaffold(
      title: Text(
        scoped ? t.addServer.addConnectionTitleScoped(name: targetProfile.displayName) : t.addServer.addConnectionTitle,
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) SizedBox(height: tokensRef.groupGap),
                _BackendCard(
                  borderRadius: groupItemRadii(context, i, options.length),
                  leading: options[i].backend != null
                      ? BackendBadge(backend: options[i].backend!, size: 28)
                      : const AppIcon(Symbols.share_rounded, fill: 1, size: 28),
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
            ]),
          ),
        ),
      ],
    );
  }
}

class _BackendOption {
  /// Null for the borrow option (renders a share icon instead of a badge).
  final MediaBackend? backend;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  const _BackendOption({required this.backend, required this.title, required this.subtitle, required this.builder});
}

class _BackendCard extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackendCard({
    required this.borderRadius,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The wrapper sits inside the Material so the focus fill paints above the
    // opaque surface color (an outside wrapper's fill would be invisible and
    // fall back to outline chrome).
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: FocusableWrapper(
        disableScale: true,
        useBackgroundFocus: true,
        borderRadii: borderRadius,
        descendantsAreFocusable: false,
        onSelect: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
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
      ),
    );
  }
}
