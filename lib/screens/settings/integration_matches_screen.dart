import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../integrations/integration_identity_store.dart';
import '../../profiles/active_profile_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';

/// Reversible, profile-scoped catalog-to-library title matches created from
/// Global Search. Removing a match does not touch provider or library state.
class IntegrationMatchesScreen extends StatefulWidget {
  const IntegrationMatchesScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<IntegrationMatchesScreen> createState() => _IntegrationMatchesScreenState();
}

class _IntegrationMatchesScreenState extends State<IntegrationMatchesScreen> {
  final IntegrationIdentityStore _store = IntegrationIdentityStore();
  List<IdentityCrosswalk> _matches = const [];
  final Set<String> _removing = {};
  bool _loading = true;

  bool get _isCurrentProfile => context.read<ActiveProfileProvider?>()?.activeId == widget.profileId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final matches = await _store.load(widget.profileId);
      if (!mounted || !_isCurrentProfile) return;
      setState(() => _matches = matches);
    } on Object {
      if (mounted && _isCurrentProfile) showErrorSnackBar(context, t.common.error);
    } finally {
      if (mounted && _isCurrentProfile) setState(() => _loading = false);
    }
  }

  Future<void> _remove(IdentityCrosswalk match) async {
    if (!_isCurrentProfile || !_removing.add(match.id)) return;
    setState(() {});
    try {
      await _store.remove(widget.profileId, match.id);
      if (!mounted || !_isCurrentProfile) return;
      setState(() => _matches = [for (final row in _matches) if (row.id != match.id) row]);
    } on Object {
      if (mounted && _isCurrentProfile) showErrorSnackBar(context, t.common.error);
    } finally {
      if (mounted) setState(() => _removing.remove(match.id));
    }
  }

  String _providerLabel(String providerId) => switch (providerId) {
    'plex' => 'Plex Discover',
    'trakt' => 'Trakt',
    'mal' => 'MyAnimeList',
    'anilist' => 'AniList',
    'simkl' => 'Simkl',
    'mdblist' => 'MDBList',
    'server.plex' => 'Plex library',
    'server.jellyfin' => 'Jellyfin library',
    'server.emby' => 'Emby library',
    _ => providerId,
  };

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.matchScreen.match),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList.list(
          children: [
            if (_loading)
              const LinearProgressIndicator()
            else if (_matches.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(t.matchScreen.noMatchesFound)),
              )
            else
              SettingsGroup(
                title: 'Linked catalog titles',
                children: [
                  for (final match in _matches)
                    FocusableListTile(
                      leading: const AppIcon(Symbols.link_rounded),
                      title: Text('${_providerLabel(match.from.providerId)} ↔ ${_providerLabel(match.to.providerId)}'),
                      subtitle: Text(
                        '${match.from.kind.name} · ${match.from.nativeId} → ${match.to.nativeId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                      trailing: IconButton(
                        tooltip: t.common.delete,
                        onPressed: _removing.contains(match.id) ? null : () => unawaited(_remove(match)),
                        icon: _removing.contains(match.id)
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const AppIcon(Symbols.link_off_rounded),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}
