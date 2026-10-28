import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/presentation_formats.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'app_icon.dart';
import 'app_menu.dart';
import '../utils/snackbar_helper.dart';

/// Appears only when the current MPV input exposes multiple editions or disc
/// titles, keeping the common playback controls uncluttered.
class SourceEditionMenuButton extends StatefulWidget {
  const SourceEditionMenuButton({super.key, required this.player, required this.sourceIdentity});

  final Player player;
  final String sourceIdentity;

  @override
  State<SourceEditionMenuButton> createState() => _SourceEditionMenuButtonState();
}

class _SourceEditionMenuButtonState extends State<SourceEditionMenuButton> {
  late Future<List<_SourceEdition>> _editions = _readEditions();
  StreamSubscription<void>? _fileLoadedSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToFileLoads();
  }

  void _subscribeToFileLoads() {
    _fileLoadedSubscription?.cancel();
    _fileLoadedSubscription = widget.player.streams.fileLoaded.listen((_) => _refreshEditions());
  }

  void _refreshEditions() {
    if (!mounted) return;
    setState(() {
      _editions = _readEditions();
    });
  }

  @override
  void didUpdateWidget(covariant SourceEditionMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _subscribeToFileLoads();
    }
    if (oldWidget.player != widget.player || oldWidget.sourceIdentity != widget.sourceIdentity) {
      _editions = _readEditions();
    }
  }

  @override
  void dispose() {
    unawaited(_fileLoadedSubscription?.cancel());
    super.dispose();
  }

  Future<List<_SourceEdition>> _readEditions() async {
    try {
      final rawCount = await widget.player.getProperty('edition-list/count');
      final count = int.tryParse(rawCount ?? '') ?? 0;
      if (count < 2) return const [];

      final visibleCount = count.clamp(0, 100);
      final values = await Future.wait(
        List.generate(visibleCount, (index) async {
          final title = await widget.player.getProperty('edition-list/$index/title');
          return _SourceEdition(
            index: index,
            title: isolateDisplayText(
              title?.trim().isNotEmpty == true ? title!.trim() : '${t.universalMedia.editionOrTitle} ${index + 1}',
            ),
          );
        }),
      );
      final currentRaw =
          await widget.player.getProperty('current-edition') ?? await widget.player.getProperty('edition');
      final current = int.tryParse(currentRaw ?? '');
      return [for (final edition in values) edition.copyWith(selected: edition.index == current)];
    } on Object {
      // MPV exposes edition metadata only for formats that support it.
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_SourceEdition>>(
    future: _editions,
    builder: (context, snapshot) {
      final editions = snapshot.data;
      if (editions == null || editions.length < 2) return const SizedBox.shrink();
      return AppMenuButton<int>(
        icon: const AppIcon(Symbols.movie_filter_rounded),
        tooltip: t.universalMedia.editionOrTitle,
        adaptiveSheet: true,
        entriesBuilder: (_) => [
          for (final edition in editions)
            AppMenuItem(value: edition.index, label: edition.title, selected: edition.selected),
        ],
        onSelected: (index) => _selectEdition(index, editions),
      );
    },
  );

  Future<void> _selectEdition(int index, List<_SourceEdition> editions) async {
    if (editions.any((edition) => edition.index == index && edition.selected)) return;
    try {
      await widget.player.setProperty('edition', '$index');
      if (mounted) {
        setState(() {
          _editions = Future.value([
            for (final edition in editions) edition.copyWith(selected: edition.index == index),
          ]);
        });
      }
    } on Object {
      if (mounted) showErrorSnackBar(context, t.fileSources.errorUnavailable);
    }
  }
}

class _SourceEdition {
  const _SourceEdition({required this.index, required this.title, this.selected = false});

  final int index;
  final String title;
  final bool selected;

  _SourceEdition copyWith({bool? selected}) =>
      _SourceEdition(index: index, title: title, selected: selected ?? this.selected);
}
