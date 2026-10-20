import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:provider/provider.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/overlay_sheet.dart';
import '../models/watch_copy.dart';
import '../providers/watch_together_provider.dart';
import 'watch_labels.dart';

/// The building blocks of a room shared by the Watch Together screen, which
/// stacks them as cards, and the player's session sheet, which gives each a
/// page: the room code, the media and this user's match, the sync offset,
/// participants and host tools.

enum WatchButtonStyle { filled, tonal, outlined }

/// A D-pad focusable button of the room UI.
class WatchButton extends StatelessWidget {
  const WatchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = WatchButtonStyle.outlined,
    this.autofocus = false,
    this.focusNode,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WatchButtonStyle style;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Shows a spinner in place of [icon].
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final icon = busy ? const LoadingIndicatorBox() : (this.icon == null ? null : AppIcon(this.icon!, fill: 1));
    final text = Text(label);
    final button = switch ((style, icon)) {
      (WatchButtonStyle.filled, final Widget icon) => FilledButton.icon(onPressed: onPressed, icon: icon, label: text),
      (WatchButtonStyle.filled, null) => FilledButton(onPressed: onPressed, child: text),
      (WatchButtonStyle.tonal, final Widget icon) => FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: icon,
        label: text,
      ),
      (WatchButtonStyle.tonal, null) => FilledButton.tonal(onPressed: onPressed, child: text),
      (WatchButtonStyle.outlined, final Widget icon) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: text,
      ),
      (WatchButtonStyle.outlined, null) => OutlinedButton(onPressed: onPressed, child: text),
    };
    return FocusableButton(
      onPressed: onPressed,
      autofocus: autofocus,
      focusNode: focusNode,
      useBackgroundFocus: style != WatchButtonStyle.outlined,
      child: button,
    );
  }
}

/// Buttons in a row that wraps on narrow screens.
class WatchButtonRow extends StatelessWidget {
  const WatchButtonRow({super.key, required this.children, this.alignment = WrapAlignment.start});

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: alignment,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Whether a page pushed now lands in an open sheet (and so shows a back
/// arrow) rather than opening a sheet of its own.
bool _sheetIsOpen(BuildContext context) => OverlaySheetController.maybeOf(context)?.isOpen ?? false;

/// Opens [builder]'s page: in the open sheet, or as a sheet of its own.
Future<T?> showWatchPage<T>(BuildContext context, Widget Function(bool nested) builder) {
  final nested = _sheetIsOpen(context);
  return OverlaySheetController.pushAdaptive<T>(
    context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => builder(nested),
  );
}

/// A page of a room sheet. [nested] pages show a back arrow; Back pops them
/// (the sheet host's own handling), and Back on the first page closes the
/// sheet. The sheet closes by itself once the user is out of the room.
class WatchSheetPage extends StatelessWidget {
  const WatchSheetPage({super.key, required this.title, required this.nested, required this.children});

  final String title;
  final bool nested;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return WatchSessionGuard(
      child: BottomSheetPageScaffold(
        title: title,
        onBack: nested ? () => OverlaySheetController.popAdaptive(context) : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Closes the enclosing sheet when the user is no longer in a room.
class WatchSessionGuard extends StatefulWidget {
  const WatchSessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<WatchSessionGuard> createState() => _WatchSessionGuardState();
}

class _WatchSessionGuardState extends State<WatchSessionGuard> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final inSession = context.select<WatchTogetherProvider, bool>((provider) => provider.isInSession);
    if (!inSession && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) OverlaySheetController.closeAdaptive(context);
      });
    }
    return widget.child;
  }
}

/// Section padding inside sheet pages.
const watchPagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

TextStyle? _muted(BuildContext context, TextStyle? style) =>
    style?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

// ---------------------------------------------------------------------------
// Room code

Future<void> copyRoomCode(BuildContext context, String formattedCode) async {
  await Clipboard.setData(ClipboardData(text: formattedCode));
  if (context.mounted) showAppSnackBar(context, t.watchTogether.codeCopied);
}

/// Puts an invite naming the room code on the clipboard, for a message.
Future<void> shareRoomInvite(BuildContext context, String formattedCode) async {
  await Clipboard.setData(ClipboardData(text: t.watchTogether.inviteMessage(code: formattedCode)));
  if (context.mounted) showAppSnackBar(context, t.watchTogether.inviteCopied);
}

/// The room code, copy and share, and who runs the room.
class WatchRoomHeader extends StatelessWidget {
  const WatchRoomHeader({super.key, this.autofocus = false});

  /// Focuses the copy button when the header appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final code = provider.formattedRoomCode ?? '';
    final theme = Theme.of(context);
    final hostName = provider.host?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(t.watchTogether.roomCode, style: _muted(context, theme.textTheme.labelLarge)),
        const SizedBox(height: 4),
        Text(
          code,
          style: theme.textTheme.displaySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        WatchButtonRow(
          alignment: WrapAlignment.center,
          children: [
            WatchButton(
              label: t.watchTogether.copyCode,
              icon: Symbols.content_copy_rounded,
              style: WatchButtonStyle.tonal,
              autofocus: autofocus,
              onPressed: () => unawaited(copyRoomCode(context, code)),
            ),
            WatchButton(
              label: t.watchTogether.shareInvite,
              icon: Symbols.share_rounded,
              onPressed: () => unawaited(shareRoomInvite(context, code)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          provider.isHost
              ? t.watchTogether.youAreHost
              : (hostName == null ? '' : t.watchTogether.hostedBy(name: hostName)),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          provider.control == owp.Control.everyone
              ? t.watchTogether.anyoneCanControl
              : t.watchTogether.hostControlsPlayback,
          style: _muted(context, theme.textTheme.bodySmall),
          textAlign: TextAlign.center,
        ),
        if (provider.isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(Symbols.lock_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(t.watchTogether.roomLocked, style: _muted(context, theme.textTheme.bodySmall)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The reconnecting state, while the party resumes on its own.
class WatchReconnectingBanner extends StatelessWidget {
  const WatchReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final reconnecting = context.select<WatchTogetherProvider, bool>((provider) => provider.isReconnecting);
    if (!reconnecting) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AppIcon(Symbols.sync_problem_rounded, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.watchTogether.reconnecting,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                  Text(
                    t.watchTogether.reconnectingDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media and matching

/// The room's media: its title, whether others can find it, this user's
/// match, joining playback, and the host's stop.
class WatchMediaSection extends StatelessWidget {
  const WatchMediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final media = provider.media;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.watchTogether.nowPlaying, style: _muted(context, theme.textTheme.labelLarge)),
        const SizedBox(height: 4),
        if (media == null) ...[
          Text(t.watchTogether.nothingPlaying, style: theme.textTheme.titleMedium),
          Text(
            provider.isHost ? t.watchTogether.nothingPlayingHost : t.watchTogether.nothingPlayingGuest,
            style: _muted(context, theme.textTheme.bodySmall),
          ),
        ] else ...[
          Text(watchMediaTitle(media), style: theme.textTheme.titleMedium),
          if (media.kind == owp.MediaKind.video) ...[
            const SizedBox(height: 8),
            _InfoNote(icon: Symbols.info_rounded, text: t.watchTogether.notShareable),
          ],
          const SizedBox(height: 12),
          const WatchMatchSection(),
          if (provider.canJoinPlayback) ...[
            const SizedBox(height: 16),
            Text(t.watchTogether.joinCurrentPlaybackDescription, style: _muted(context, theme.textTheme.bodySmall)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: WatchButton(
                label: t.watchTogether.joinCurrentPlayback,
                icon: Symbols.play_arrow_rounded,
                style: WatchButtonStyle.filled,
                onPressed: () => unawaited(provider.openRoomCopy()),
              ),
            ),
          ],
          if (provider.isHost) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: WatchButton(
                label: t.watchTogether.stopMedia,
                icon: Symbols.stop_rounded,
                onPressed: provider.stopMedia,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: _muted(context, Theme.of(context).textTheme.bodySmall))),
      ],
    );
  }
}

/// One line describing this user's match, for a summary row; null without
/// media.
String? watchMatchSummary(WatchTogetherProvider provider) {
  if (!provider.hasMedia) return null;
  final state = provider.state;
  final copy = provider.roomCopy;
  if (copy != null && copy.id.isEmpty) return t.watchTogether.sharingYourCopy;
  if (state.mismatch != null) return t.watchTogether.mismatchTitle;
  final match = state.match;
  return switch (match?.state) {
    null || owp.MatchState.searching => t.watchTogether.searching,
    owp.MatchState.matched => copy == null ? t.watchTogether.yourCopy : watchCopyTitle(copy.ref),
    owp.MatchState.mismatched => t.watchTogether.playingOtherLength(difference: watchLengthDifference(match!.deltaMs)),
    owp.MatchState.unavailable => t.watchTogether.unavailableTitle,
  };
}

/// This user's file for the room's media: searching, the matched copy, the
/// mismatch prompt, or nothing found.
class WatchMatchSection extends StatelessWidget {
  const WatchMatchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    if (!provider.hasMedia) return const SizedBox.shrink();
    final state = provider.state;
    final copy = provider.roomCopy;
    if (copy != null && copy.id.isEmpty) {
      return WatchCopySummary(copy: copy.ref, label: t.watchTogether.sharingYourCopy);
    }
    if (state.mismatch != null) return const WatchMismatchBlock();
    final match = state.match;
    final chooseAnother = state.candidates.length > 1
        ? WatchButton(
            label: t.watchTogether.chooseAnotherCopy,
            icon: Symbols.swap_horiz_rounded,
            onPressed: () => unawaited(showWatchCandidates(context)),
          )
        : null;
    switch (match?.state) {
      case null || owp.MatchState.searching:
        return Row(
          children: [
            const LoadingIndicatorBox(),
            const SizedBox(width: 12),
            Expanded(child: Text(t.watchTogether.searching)),
          ],
        );
      case owp.MatchState.matched || owp.MatchState.mismatched:
        final label = match!.state == owp.MatchState.matched
            ? t.watchTogether.yourCopy
            : t.watchTogether.playingOtherLength(difference: watchLengthDifference(match.deltaMs));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (copy != null) WatchCopySummary(copy: copy.ref, label: label) else Text(label),
            if (chooseAnother != null) ...[
              const SizedBox(height: 8),
              WatchButtonRow(children: [chooseAnother]),
            ],
          ],
        );
      case owp.MatchState.unavailable:
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.watchTogether.unavailableTitle, style: theme.textTheme.titleSmall),
            Text(t.watchTogether.unavailableDescription, style: _muted(context, theme.textTheme.bodySmall)),
            const SizedBox(height: 8),
            WatchButtonRow(
              children: [
                WatchButton(
                  label: t.watchTogether.chooseCopy,
                  icon: Symbols.video_library_rounded,
                  onPressed: () => unawaited(showWatchCandidates(context)),
                ),
                WatchButton(
                  label: t.watchTogether.searchAgain,
                  icon: Symbols.refresh_rounded,
                  onPressed: provider.searchAgain,
                ),
              ],
            ),
          ],
        );
    }
  }
}

/// The closest copy differs in length: play it anyway, choose another, or
/// don't play.
class WatchMismatchBlock extends StatelessWidget {
  const WatchMismatchBlock({super.key, this.showTitle = true});

  /// False on the prompt page, whose header already says it.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final mismatch = provider.state.mismatch;
    if (mismatch == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) Text(t.watchTogether.mismatchTitle, style: theme.textTheme.titleSmall),
        Text(
          t.watchTogether.mismatchDescription(difference: watchLengthDifference(mismatch.deltaMs)),
          style: _muted(context, theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 8),
        WatchCopySummary(copy: mismatch.candidate.ref),
        const SizedBox(height: 12),
        WatchButtonRow(
          children: [
            WatchButton(
              label: t.watchTogether.playAnyway,
              icon: Symbols.play_arrow_rounded,
              style: WatchButtonStyle.filled,
              onPressed: provider.acceptMismatch,
            ),
            WatchButton(
              label: t.watchTogether.chooseAnotherCopy,
              icon: Symbols.swap_horiz_rounded,
              onPressed: () => unawaited(showWatchCandidates(context)),
            ),
            WatchButton(
              label: t.watchTogether.dontPlay,
              icon: Symbols.block_rounded,
              onPressed: provider.declineMismatch,
            ),
          ],
        ),
      ],
    );
  }
}

/// A copy's title, then its version, server and length.
class WatchCopySummary extends StatelessWidget {
  const WatchCopySummary({super.key, required this.copy, this.label});

  final WatchCopy copy;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = watchCopyDetails(copy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label case final label?) Text(label, style: _muted(context, theme.textTheme.labelMedium)),
        Text(watchCopyTitle(copy), style: theme.textTheme.bodyLarge),
        if (details.isNotEmpty) Text(details, style: _muted(context, theme.textTheme.bodySmall)),
      ],
    );
  }
}

/// Opens the page of this user's copies of the room's media.
Future<void> showWatchCandidates(BuildContext context) =>
    showWatchPage<void>(context, (nested) => WatchCandidatesPage(nested: nested));

/// This user's copies of the room's media, closest length first, to pick the
/// one to play; and a new search.
class WatchCandidatesPage extends StatelessWidget {
  const WatchCandidatesPage({super.key, required this.nested});

  final bool nested;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final state = provider.state;
    final current = provider.roomCopy?.ref;
    final searching = state.match?.state == owp.MatchState.searching;
    return WatchSheetPage(
      title: t.watchTogether.chooseCopy,
      nested: nested,
      children: [
        for (final ranked in state.candidates)
          FocusableListTile(
            leading: AppIcon(
              ranked.candidate.ref == current ? Symbols.check_circle_rounded : Symbols.movie_rounded,
              fill: 1,
            ),
            title: Text(watchCopyTitle(ranked.candidate.ref)),
            subtitle: Text(
              [
                watchCopyDetails(ranked.candidate.ref),
                watchLengthDifference(ranked.deltaMs),
              ].where((part) => part.isNotEmpty).join(' · '),
            ),
            onTap: () => unawaited(_choose(context, provider, ranked.candidate)),
          ),
        if (state.candidates.isEmpty && !searching)
          Padding(padding: watchPagePadding, child: Text(t.watchTogether.noCandidates)),
        if (searching)
          Padding(
            padding: watchPagePadding,
            child: Row(
              children: [
                const LoadingIndicatorBox(),
                const SizedBox(width: 12),
                Expanded(child: Text(t.watchTogether.searching)),
              ],
            ),
          ),
        FocusableListTile(
          leading: const AppIcon(Symbols.refresh_rounded, fill: 1),
          title: Text(t.watchTogether.searchAgain),
          onTap: searching ? null : provider.searchAgain,
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, WatchTogetherProvider provider, owp.Candidate<WatchCopy> candidate) async {
    final chosen = await provider.choose(candidate);
    if (!context.mounted) return;
    if (chosen) {
      OverlaySheetController.popAdaptive(context);
    } else {
      showErrorSnackBar(context, t.watchTogether.choiceFailed);
    }
  }
}

// ---------------------------------------------------------------------------
// Offset

/// This user's offset against the room: steps, reset, and the length
/// difference of their copy as a hint.
class WatchOffsetSection extends StatelessWidget {
  const WatchOffsetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final state = provider.state;
    final offset = state.offsetMs;
    final match = state.match;
    final hint = state.mismatch?.deltaMs ?? (match?.state == owp.MatchState.mismatched ? match!.deltaMs : null);
    final theme = Theme.of(context);
    Widget step(String label, int by) => WatchButton(label: label, onPressed: () => provider.setOffset(offset + by));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(t.watchTogether.syncOffset, style: theme.textTheme.titleSmall)),
            Text(watchOffsetText(offset), style: theme.textTheme.titleMedium),
          ],
        ),
        Text(t.watchTogether.syncOffsetDescription, style: _muted(context, theme.textTheme.bodySmall)),
        const SizedBox(height: 8),
        WatchButtonRow(
          children: [
            step(t.watchTogether.offsetMinusSecond, -1000),
            step(t.watchTogether.offsetMinusTenth, -100),
            step(t.watchTogether.offsetPlusTenth, 100),
            step(t.watchTogether.offsetPlusSecond, 1000),
            WatchButton(
              label: t.common.reset,
              icon: Symbols.restart_alt_rounded,
              onPressed: offset == 0 ? null : () => provider.setOffset(0),
            ),
          ],
        ),
        if (hint != null && hint.abs() >= 1000) ...[
          const SizedBox(height: 12),
          Text(
            t.watchTogether.offsetHint(difference: watchLengthDifference(hint)),
            style: _muted(context, theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: WatchButton(
              label: t.watchTogether.applyDifference(offset: watchOffsetText(hint)),
              icon: Symbols.tune_rounded,
              onPressed: offset == hint ? null : () => provider.setOffset(hint),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Participants

/// Every participant of the room.
class WatchParticipantsSection extends StatelessWidget {
  const WatchParticipantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final participants = context.watch<WatchTogetherProvider>().participants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final participant in participants) WatchParticipantTile(participant: participant)],
    );
  }
}

/// A participant: name, host badge, app, connection, player, match and
/// offset. The host opens their actions from it.
class WatchParticipantTile extends StatelessWidget {
  const WatchParticipantTile({super.key, required this.participant});

  final owp.Participant participant;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final me = participant.peerId == provider.myPeerId;
    final canManage = provider.isHost && !me;
    final match = participant.match;
    final details = [
      watchClientApp(participant.client),
      participant.connected ? t.watchTogether.connected : t.watchTogether.disconnected,
      if (participant.connected) watchPlayerStateText(participant.player),
      if (match != null) watchMatchStateText(match.state),
      if (participant.offsetMs != 0) t.watchTogether.participantOffset(offset: watchOffsetText(participant.offsetMs)),
    ].join(' · ');
    return FocusableListTile(
      leading: AppIcon(participant.connected ? Symbols.person_rounded : Symbols.person_off_rounded, fill: 1),
      title: Row(
        children: [
          Flexible(
            child: Text(
              me ? t.watchTogether.nameYou(name: participant.name) : participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (participant.host) ...[const SizedBox(width: 8), const WatchHostBadge()],
        ],
      ),
      subtitle: Text(details),
      trailing: canManage ? const AppIcon(Symbols.chevron_right_rounded, fill: 1) : null,
      onTap: canManage ? () => unawaited(showWatchParticipantActions(context, participant.peerId)) : null,
    );
  }
}

class WatchHostBadge extends StatelessWidget {
  const WatchHostBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: const BorderRadius.all(Radius.circular(4))),
      child: Text(
        t.watchTogether.hostBadge,
        style: TextStyle(color: scheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

Future<void> showWatchParticipantActions(BuildContext context, String peerId) =>
    showWatchPage<void>(context, (nested) => WatchParticipantActionsPage(peerId: peerId, nested: nested));

/// The host's actions on one participant: make host, remove. Each asks first.
class WatchParticipantActionsPage extends StatelessWidget {
  const WatchParticipantActionsPage({super.key, required this.peerId, required this.nested});

  final String peerId;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    final participant = provider.participants.where((p) => p.peerId == peerId).firstOrNull;
    final canManage = participant != null && provider.isHost && peerId != provider.myPeerId;
    return WatchSheetPage(
      title: participant?.name ?? t.watchTogether.participants,
      nested: nested,
      children: [
        if (canManage) ...[
          FocusableListTile(
            leading: const AppIcon(Symbols.star_rounded, fill: 1),
            title: Text(t.watchTogether.makeHost),
            onTap: () => unawaited(_makeHost(context, provider, participant)),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.person_remove_rounded, fill: 1),
            title: Text(t.watchTogether.removeParticipant),
            onTap: () => unawaited(_remove(context, provider, participant)),
          ),
        ],
      ],
    );
  }

  Future<void> _makeHost(BuildContext context, WatchTogetherProvider provider, owp.Participant participant) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.watchTogether.makeHostQuestion,
      message: t.watchTogether.makeHostConfirm(name: participant.name),
      confirmText: t.watchTogether.transfer,
    );
    if (!confirmed || !context.mounted) return;
    provider.transferHost(participant.peerId);
    OverlaySheetController.popAdaptive(context);
  }

  Future<void> _remove(BuildContext context, WatchTogetherProvider provider, owp.Participant participant) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.watchTogether.removeParticipantQuestion(name: participant.name),
      message: t.watchTogether.removeParticipantConfirm(name: participant.name),
      confirmText: t.watchTogether.remove,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    provider.kick(participant.peerId);
    OverlaySheetController.popAdaptive(context);
  }
}

// ---------------------------------------------------------------------------
// Host tools, leaving

/// The host's room settings: who controls playback, and the lock.
class WatchHostSettingsSection extends StatelessWidget {
  const WatchHostSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchTogetherProvider>();
    if (!provider.isHost) return const SizedBox.shrink();
    final everyone = provider.control == owp.Control.everyone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableSwitchListTile(
          secondary: const AppIcon(Symbols.sports_esports_rounded, fill: 1),
          title: Text(t.watchTogether.letEveryoneControl),
          subtitle: Text(everyone ? t.watchTogether.anyoneCanControl : t.watchTogether.hostControlsPlayback),
          value: everyone,
          onChanged: (value) => provider.setControl(value ? owp.Control.everyone : owp.Control.host),
        ),
        FocusableSwitchListTile(
          secondary: const AppIcon(Symbols.lock_rounded, fill: 1),
          title: Text(t.watchTogether.lockRoom),
          subtitle: Text(t.watchTogether.lockRoomDescription),
          value: provider.isLocked,
          onChanged: provider.setLocked,
        ),
      ],
    );
  }
}

/// Asks, then leaves the room.
Future<void> confirmLeaveRoom(BuildContext context) async {
  final provider = context.read<WatchTogetherProvider>();
  final confirmed = await showConfirmDialog(
    context,
    title: t.watchTogether.leaveRoomQuestion,
    message: t.watchTogether.leaveRoomConfirm,
    confirmText: t.watchTogether.leave,
  );
  if (confirmed) provider.leave();
}

/// Asks, then ends the room for everyone (host).
Future<void> confirmEndRoom(BuildContext context) async {
  final provider = context.read<WatchTogetherProvider>();
  final confirmed = await showConfirmDialog(
    context,
    title: t.watchTogether.endRoomQuestion,
    message: t.watchTogether.endRoomConfirm,
    confirmText: t.watchTogether.end,
    isDestructive: true,
  );
  if (confirmed) provider.endRoom();
}
