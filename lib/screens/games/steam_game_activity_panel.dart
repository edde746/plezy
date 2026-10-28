import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focusable_button.dart';
import '../../games/steam_game_activity.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../services/credential_vault.dart';
import '../../services/trackers/oauth_proxy_client.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';

/// Metadata is fetched on demand and lives only for this profile's detail view.
/// No webview, upstream HTML, arbitrary image URL or unsolicited social lookup.
class SteamGameActivityPanel extends StatefulWidget {
  const SteamGameActivityPanel({
    super.key,
    required this.appId,
    required this.isCurrent,
    required this.onLink,
    this.steamId,
    this.protectedCredential,
  });
  final int appId;
  final String? steamId, protectedCredential;
  final bool Function() isCurrent;
  final VoidCallback onLink;
  @override
  State<SteamGameActivityPanel> createState() => _SteamGameActivityPanelState();
}

class _SteamGameActivityPanelState extends State<SteamGameActivityPanel> {
  final _proxy = OAuthProxyClient();
  SteamGameActivity? _activity;
  bool _loading = false, _failed = false, _relink = false, _friends = false;
  int _visible = 20;
  bool get current => mounted && widget.isCurrent();
  @override
  void dispose() {
    _proxy.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!current || _loading) return;
    final encrypted = widget.protectedCredential, id = widget.steamId;
    if (encrypted == null || id == null) {
      widget.onLink();
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
      _relink = false;
    });
    try {
      final credential = await CredentialVault.reveal(encrypted);
      if (!current) return;
      if (credential == null) throw const SteamCatalogRelinkRequired();
      final activity = await _proxy.steamGameActivity(
        credential,
        appId: widget.appId,
        steamId: id,
        includeFriends: _friends,
      );
      if (current) setState(() => _activity = activity);
    } on SteamCatalogRelinkRequired {
      if (current) setState(() => _relink = true);
    } catch (_) {
      if (current) setState(() => _failed = true);
    } finally {
      if (current) setState(() => _loading = false);
    }
  }

  Future<void> _open(SteamDestination destination) async {
    final uri = steamDestination(widget.appId, destination);
    final confirmed = await showConfirmDialog(
      context,
      title: t.games.openSteamPage,
      message: t.games.openSteamPageHelp,
      confirmText: t.games.openSteamPage,
    );
    if (!confirmed || !current) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted && widget.isCurrent()) {
        showErrorSnackBar(context, t.games.unavailable);
      }
    } catch (_) {
      if (mounted && widget.isCurrent()) showErrorSnackBar(context, t.games.unavailable);
    }
  }

  Widget _button(String label, VoidCallback? action) => FocusableButton(
    onPressed: action,
    child: TextButton(onPressed: action, child: Text(label)),
  );

  @override
  Widget build(BuildContext context) {
    final data = _activity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(t.games.steamActivity, style: Theme.of(context).textTheme.titleMedium),
        Text(t.games.steamActivityHelp),
        FocusableSwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.games.includeFriends),
          subtitle: Text(t.games.includeFriendsHelp),
          value: _friends,
          onChanged: _loading
              ? null
              : (value) => setState(() {
                  _friends = value;
                  // Turning social context off immediately hides its current snapshot.
                }),
        ),
        if (_loading) Semantics(liveRegion: true, child: Text(t.games.activityLoading)),
        if (_failed) Text(t.games.activityUnavailable),
        _button(
          _relink || widget.protectedCredential == null ? t.games.linkSteamAccount : t.games.loadSteamActivity,
          _loading ? null : (_relink ? widget.onLink : _load),
        ),
        if (data != null) ...[
          Text(t.games.achievements, style: Theme.of(context).textTheme.titleSmall),
          if (!data.achievementsAvailable)
            Text(t.games.activityPrivate)
          else ...[
            Text(
              t.games.achievementProgress(
                unlocked: data.achievements.where((a) => a.unlocked).length,
                total: data.achievements.length,
              ),
            ),
            for (final achievement in data.achievements.take(_visible))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(achievement.unlocked ? Symbols.emoji_events_rounded : Symbols.lock_rounded),
                title: Text(achievement.hidden ? t.games.hiddenAchievement : isolateDisplayText(achievement.name)),
                subtitle: Text(
                  '${achievement.unlocked ? t.games.achievementUnlocked : t.games.achievementLocked}\n'
                  '${achievement.hidden ? t.games.hiddenAchievementHelp : isolateDisplayText(achievement.description)}',
                ),
              ),
            if (_visible < data.achievements.length)
              _button(t.games.moreAchievements, () => setState(() => _visible += 20)),
          ],
          Text(t.games.gameNews, style: Theme.of(context).textTheme.titleSmall),
          if (!data.newsAvailable)
            Text(t.games.activityUnavailable)
          else if (data.news.isEmpty)
            Text(t.games.noGameNews)
          else
            for (final news in data.news)
              FocusableListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isolateDisplayText(news.title)),
                subtitle: Text(
                  '${isolateDisplayText(news.feed)} · ${MaterialLocalizations.of(context).formatCompactDate(news.date.toLocal())}',
                ),
                trailing: const AppIcon(Symbols.open_in_new_rounded),
                onTap: () => _open(SteamDestination.news),
              ),
          if (_friends && data.friendsRequested) ...[
            Text(t.games.friendsPlaying, style: Theme.of(context).textTheme.titleSmall),
            if (!data.friendsAvailable)
              Text(t.games.activityPrivate)
            else if (data.friends.isEmpty)
              Text(t.games.noFriendsPlaying)
            else
              for (final friend in data.friends)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Symbols.person_rounded),
                  title: Text(isolateDisplayText(friend.name)),
                ),
          ],
          if (data.truncated) Text(t.games.activityTruncated),
        ],
        Wrap(
          spacing: 8,
          children: [
            _button(t.games.steamStore, () => _open(SteamDestination.store)),
            _button(t.games.steamCommunity, () => _open(SteamDestination.community)),
            _button(t.games.steamWorkshop, () => _open(SteamDestination.workshop)),
            _button(t.games.gameNews, () => _open(SteamDestination.news)),
          ],
        ),
      ],
    );
  }
}
