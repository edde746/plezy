import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../providers/watch_together_provider.dart';
import 'watch_labels.dart';
import 'watch_room_sections.dart';

/// Opens the room's session sheet: from the player's header indicator, or
/// anywhere below an [OverlaySheetHost].
Future<void> showWatchSessionSheet(BuildContext context) => OverlaySheetController.showAdaptive<void>(
  context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const WatchSessionSheet(),
);

/// The room at a glance, with a page each for the media and matching, the
/// participants and the offset, and the host's settings, leave and end.
///
/// [nested] when pushed as a page of another sheet (the video settings).
class WatchSessionSheet extends StatelessWidget {
  const WatchSessionSheet({super.key, this.nested = false});

  final bool nested;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final code = provider.formattedRoomCode ?? '';
    final media = provider.media;
    final status = provider.isReconnecting
        ? t.watchTogether.reconnecting
        : provider.isConnected
        ? t.watchTogether.connected
        : t.watchTogether.connecting;
    return WatchSheetPage(
      title: t.watchTogether.title,
      nested: nested,
      children: [
        FocusableListTile(
          leading: const AppIcon(Symbols.tag_rounded, fill: 1),
          title: Text(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          subtitle: Text([status, t.watchTogether.participantCount(n: provider.participantCount)].join(' · ')),
          trailing: const AppIcon(Symbols.content_copy_rounded, fill: 1),
          onTap: () => unawaited(copyRoomCode(context, code)),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: WatchReconnectingBanner()),
        FocusableListTile(
          leading: const AppIcon(Symbols.movie_rounded, fill: 1),
          title: Text(media == null ? t.watchTogether.nothingPlaying : watchMediaTitle(media)),
          subtitle: switch (watchMatchSummary(provider)) {
            final summary? => Text(summary),
            null => null,
          },
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () => unawaited(showWatchPage<void>(context, (nested) => WatchMediaPage(nested: nested))),
        ),
        if (provider.canJoinPlayback)
          FocusableListTile(
            leading: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
            title: Text(t.watchTogether.joinCurrentPlayback),
            subtitle: Text(t.watchTogether.joinCurrentPlaybackDescription),
            onTap: () => unawaited(provider.openRoomCopy()),
          ),
        FocusableListTile(
          leading: const AppIcon(Symbols.group_rounded, fill: 1),
          title: Text(t.watchTogether.participants),
          subtitle: Text(t.watchTogether.participantCount(n: provider.participantCount)),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () => unawaited(showWatchPage<void>(context, (nested) => WatchParticipantsPage(nested: nested))),
        ),
        FocusableListTile(
          leading: const AppIcon(Symbols.av_timer_rounded, fill: 1),
          title: Text(t.watchTogether.syncOffset),
          subtitle: Text(watchOffsetText(provider.state.offsetMs)),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () => unawaited(showWatchPage<void>(context, (nested) => WatchOffsetPage(nested: nested))),
        ),
        const WatchHostSettingsSection(),
        FocusableListTile(
          leading: const AppIcon(Symbols.logout_rounded, fill: 1),
          title: Text(t.watchTogether.leaveRoom),
          onTap: () => unawaited(confirmLeaveRoom(context)),
        ),
        if (provider.isHost)
          FocusableListTile(
            leading: const AppIcon(Symbols.cancel_rounded, fill: 1),
            title: Text(t.watchTogether.endRoom),
            onTap: () => unawaited(confirmEndRoom(context)),
          ),
      ],
    );
  }
}

/// The room's media and this user's match.
class WatchMediaPage extends StatelessWidget {
  const WatchMediaPage({super.key, required this.nested});

  final bool nested;

  @override
  Widget build(BuildContext context) => WatchSheetPage(
    title: t.watchTogether.nowPlaying,
    nested: nested,
    children: const [Padding(padding: watchPagePadding, child: WatchMediaSection())],
  );
}

class WatchParticipantsPage extends StatelessWidget {
  const WatchParticipantsPage({super.key, required this.nested});

  final bool nested;

  @override
  Widget build(BuildContext context) =>
      WatchSheetPage(title: t.watchTogether.participants, nested: nested, children: const [WatchParticipantsSection()]);
}

class WatchOffsetPage extends StatelessWidget {
  const WatchOffsetPage({super.key, required this.nested});

  final bool nested;

  @override
  Widget build(BuildContext context) => WatchSheetPage(
    title: t.watchTogether.syncOffset,
    nested: nested,
    children: const [Padding(padding: watchPagePadding, child: WatchOffsetSection())],
  );
}

/// The mismatch prompt the player opens: the offered copy, and play anyway,
/// choose another copy, or don't play. It closes once that mismatch is
/// settled, here or elsewhere.
class WatchMismatchPrompt extends StatefulWidget {
  const WatchMismatchPrompt({super.key, required this.promptKey});

  /// The mismatch it asks about, as [watchMismatchPromptKey] gives it.
  final String promptKey;

  @override
  State<WatchMismatchPrompt> createState() => _WatchMismatchPromptState();
}

class _WatchMismatchPromptState extends State<WatchMismatchPrompt> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final key = context.select<WatchTogetherProvider, String?>(watchMismatchPromptKey);
    if (key != widget.promptKey && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) OverlaySheetController.closeAdaptive(context);
      });
    }
    return WatchSheetPage(
      title: t.watchTogether.mismatchTitle,
      nested: false,
      children: const [Padding(padding: watchPagePadding, child: WatchMismatchBlock(showTitle: false))],
    );
  }
}

/// The mismatch the player asks about, once per media epoch and offered file;
/// null when there is none to ask about (none, or the host's own media).
String? watchMismatchPromptKey(WatchTogetherProvider provider) {
  final mismatch = provider.state.mismatch;
  if (!provider.isConnected || mismatch == null) return null;
  final copy = provider.roomCopy;
  if (provider.isHost && copy != null && copy.id.isEmpty) return null;
  return '${provider.room?.epoch}|${mismatch.candidate.id}';
}
