import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../discovery/discovery_choice.dart';
import '../../discovery/discovery_vote.dart';
import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../i18n/presentation_formats.dart';
import '../../widgets/app_icon.dart';

/// Private pass-the-device voting. Ballots live only in this route's memory.
class DiscoveryShortlistVoteScreen extends StatefulWidget {
  const DiscoveryShortlistVoteScreen({super.key, required this.profileId, required this.choices});

  final String profileId;
  final List<DiscoveryChoice> choices;

  @override
  State<DiscoveryShortlistVoteScreen> createState() => _DiscoveryShortlistVoteScreenState();
}

enum _VoteStage { setup, voting, handoff, result }

class _DiscoveryShortlistVoteScreenState extends State<DiscoveryShortlistVoteScreen> {
  _VoteStage _stage = _VoteStage.setup;
  int _guestCount = 2;
  int _guest = 0;
  int _choice = 0;
  bool _retired = false;
  final List<Map<String, int>> _ballots = [];
  final Map<String, int> _currentBallot = {};
  DiscoveryChoice? _winner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _retireIfProfileChanged();
  }

  void _retireIfProfileChanged() {
    if (_retired || context.read<ActiveProfileProvider>().active?.id == widget.profileId) return;
    _retired = true;
    _ballots.clear();
    _currentBallot.clear();
    _winner = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _begin() {
    _ballots.clear();
    _currentBallot.clear();
    setState(() {
      _guest = 0;
      _choice = 0;
      _winner = null;
      _stage = _VoteStage.voting;
    });
  }

  void _vote(int value) {
    if (_retired || _stage != _VoteStage.voting) return;
    final choice = widget.choices[_choice];
    _currentBallot[choice.id] = value;
    if (_choice + 1 < widget.choices.length) {
      setState(() => _choice++);
      return;
    }
    _ballots.add(Map.unmodifiable(_currentBallot));
    _currentBallot.clear();
    if (_guest + 1 >= _guestCount) {
      _winner = DiscoveryShortlistConsensus.chooseWinner(choices: widget.choices, ballots: _ballots);
      setState(() => _stage = _VoteStage.result);
    } else {
      setState(() => _stage = _VoteStage.handoff);
    }
  }

  void _nextGuest() {
    setState(() {
      _guest++;
      _choice = 0;
      _currentBallot.clear();
      _stage = _VoteStage.voting;
    });
  }

  @override
  void dispose() {
    _ballots.clear();
    _currentBallot.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _retireIfProfileChanged();
    if (_retired) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.discover.findNext.chooseTogether),
        leading: IconButton(
          tooltip: t.common.close,
          onPressed: () => Navigator.of(context).pop(),
          icon: const AppIcon(Symbols.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: switch (_stage) {
                  _VoteStage.setup => _setup(theme),
                  _VoteStage.voting => _voting(theme),
                  _VoteStage.handoff => _handoff(theme),
                  _VoteStage.result => _result(theme),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setup(ThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(Symbols.groups_rounded, size: 42, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      Text(t.discover.findNext.voteSetup, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(t.discover.findNext.votePrivacy, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text(t.discover.findNext.guestCount, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (var count = 2; count <= 8; count++)
            ChoiceChip(
              label: Text(formatCount(count)),
              selected: count == _guestCount,
              onSelected: (_) => setState(() => _guestCount = count),
            ),
        ],
      ),
      const SizedBox(height: 24),
      FocusableButton(
        onPressed: _begin,
        useBackgroundFocus: true,
        child: FilledButton.icon(
          onPressed: _begin,
          icon: const AppIcon(Symbols.play_arrow_rounded),
          label: Text(t.discover.findNext.beginVoting),
        ),
      ),
    ],
  );

  Widget _voting(ThemeData theme) {
    final candidate = widget.choices[_choice];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.discover.findNext.guestProgress(guest: formatCount(_guest + 1), count: formatCount(_guestCount)),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_choice + 1) / widget.choices.length),
        const SizedBox(height: 24),
        Text(isolateDisplayText(candidate.title), style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          [candidate.typeLabel, isolateDisplayText(candidate.subtitle)].where((value) => value.isNotEmpty).join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 28),
        FocusableButton(
          onPressed: () => _vote(2),
          useBackgroundFocus: true,
          child: FilledButton.icon(
            onPressed: () => _vote(2),
            icon: const AppIcon(Symbols.thumb_up_rounded),
            label: Text(t.common.yes),
          ),
        ),
        const SizedBox(height: 10),
        FocusableButton(
          onPressed: () => _vote(1),
          child: OutlinedButton.icon(
            onPressed: () => _vote(1),
            icon: const AppIcon(Symbols.thumbs_up_down_rounded),
            label: Text(t.discover.findNext.maybe),
          ),
        ),
        const SizedBox(height: 10),
        FocusableButton(
          onPressed: () => _vote(0),
          child: OutlinedButton.icon(
            onPressed: () => _vote(0),
            icon: const AppIcon(Symbols.block_rounded),
            label: Text(t.discover.findNext.notTonight),
          ),
        ),
      ],
    );
  }

  Widget _handoff(ThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(Symbols.phonelink_lock_rounded, size: 42, color: theme.colorScheme.primary),
      const SizedBox(height: 18),
      Text(t.discover.findNext.passDevice, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(t.discover.findNext.passDeviceHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FocusableButton(
        onPressed: _nextGuest,
        useBackgroundFocus: true,
        child: FilledButton(onPressed: _nextGuest, child: Text(t.discover.findNext.readyNextGuest)),
      ),
    ],
  );

  Widget _result(ThemeData theme) {
    final winner = _winner;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          winner == null ? Symbols.groups_rounded : Symbols.celebration_rounded,
          size: 42,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          winner == null ? t.discover.findNext.noSharedPick : t.discover.findNext.sharedPick,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          winner == null
              ? t.discover.findNext.noSharedPickHint
              : t.discover.findNext.sharedPickHint(title: isolateDisplayText(winner.title)),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (winner != null)
          FocusableButton(
            onPressed: () => Navigator.of(context).pop(winner),
            useBackgroundFocus: true,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(winner),
              icon: const AppIcon(Symbols.bookmark_add_rounded),
              label: Text(t.discover.findNext.useSharedPick),
            ),
          )
        else
          FocusableButton(
            onPressed: () => Navigator.of(context).pop(),
            useBackgroundFocus: true,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.discover.findNext.widenShortlist),
            ),
          ),
      ],
    );
  }
}
