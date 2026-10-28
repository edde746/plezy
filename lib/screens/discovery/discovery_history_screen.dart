import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../discovery/discovery_choice.dart';
import '../../discovery/discovery_store.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';

/// Profile-local discovery activity. Rows are snapshots only: opening one
/// returns to the active discovery owner, which resolves it again before use.
class DiscoveryHistoryScreen extends StatefulWidget {
  const DiscoveryHistoryScreen({
    super.key,
    required this.profileId,
    required this.store,
    required this.includeCatalog,
    required this.onDetails,
    required this.onRestoreToDeck,
  });

  final String profileId;
  final DiscoveryStore store;
  final bool includeCatalog;
  final ValueChanged<DiscoveryChoice> onDetails;
  final Future<void> Function(DiscoveryChoice) onRestoreToDeck;

  @override
  State<DiscoveryHistoryScreen> createState() => _DiscoveryHistoryScreenState();
}

class _DiscoveryHistoryScreenState extends State<DiscoveryHistoryScreen> {
  DiscoveryState _state = const DiscoveryState();
  bool _loading = true;
  final Set<String> _restoring = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final state = await widget.store.load(widget.profileId);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != widget.profileId) {
        return;
      }
      setState(() {
        _state = state;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, t.discover.findNext.changeFailed);
    }
  }

  String _actionLabel(DiscoveryDecision decision) => switch (decision.action) {
    DiscoveryDecisionAction.save => t.discover.findNext.savedFeedback,
    DiscoveryDecisionAction.notNow => t.discover.findNext.skippedFeedback,
    DiscoveryDecisionAction.removeSaved => t.common.delete,
  };

  String _choiceType(DiscoveryChoice choice) {
    if (choice.mediaKind != null) return choice.mediaKind!.label;
    return switch (choice.type) {
      DiscoveryChoiceType.ebook => t.fileSources.ebooks,
      DiscoveryChoiceType.audiobook => t.fileSources.audiobooks,
      DiscoveryChoiceType.comic => t.fileSources.comics,
      DiscoveryChoiceType.music => t.common.mediaKind.album,
      DiscoveryChoiceType.video ||
      DiscoveryChoiceType.sourceVideo => t.common.mediaKind.movie,
      DiscoveryChoiceType.liveProgram => t.liveTv.title,
    };
  }

  IconData _iconFor(DiscoveryChoice choice) => switch (choice.type) {
    DiscoveryChoiceType.video ||
    DiscoveryChoiceType.sourceVideo => Symbols.movie_rounded,
    DiscoveryChoiceType.music => Symbols.album_rounded,
    DiscoveryChoiceType.audiobook => Symbols.headphones_rounded,
    DiscoveryChoiceType.ebook => Symbols.menu_book_rounded,
    DiscoveryChoiceType.comic => Symbols.auto_stories_rounded,
    DiscoveryChoiceType.liveProgram => Symbols.live_tv_rounded,
  };

  Future<void> _restoreToDeck(DiscoveryChoice choice) async {
    if (_restoring.contains(choice.id) ||
        context.read<ActiveProfileProvider>().active?.id != widget.profileId) {
      return;
    }
    setState(() => _restoring.add(choice.id));
    try {
      await widget.onRestoreToDeck(choice);
    } finally {
      if (mounted) setState(() => _restoring.remove(choice.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileChanged =
        context.watch<ActiveProfileProvider>().active?.id != widget.profileId;
    final recent = _state.history
        .where(
          (decision) =>
              widget.includeCatalog || decision.choice.catalogSourceId == null,
        )
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(t.fileSources.history)),
      body: profileChanged
          ? const SizedBox.shrink()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : recent.isEmpty
          ? Center(child: Text(t.discover.findNext.noPicks))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final decision = recent[index];
                final choice = decision.choice;
                final createdAtMs = decision.createdAtMs;
                final details = [
                  _actionLabel(decision),
                  _choiceType(choice),
                  if (createdAtMs != null && createdAtMs > 0)
                    formatDateTime(
                      DateTime.fromMillisecondsSinceEpoch(createdAtMs),
                    ),
                ].where((value) => value.isNotEmpty).join(' · ');

                return FocusableListTile(
                  autofocus: index == 0,
                  leading: CircleAvatar(
                    child: AppIcon(_iconFor(choice), size: 22),
                  ),
                  title: Text(
                    isolateDisplayText(choice.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: profileChanged ? null : () => widget.onDetails(choice),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: t.discover.findNext.details,
                        onPressed: profileChanged
                            ? null
                            : () => widget.onDetails(choice),
                        icon: const AppIcon(Symbols.info_rounded),
                      ),
                      IconButton(
                        tooltip: t.common.retry,
                        onPressed:
                            profileChanged || _restoring.contains(choice.id)
                            ? null
                            : () => unawaited(_restoreToDeck(choice)),
                        icon: const AppIcon(Symbols.replay_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
