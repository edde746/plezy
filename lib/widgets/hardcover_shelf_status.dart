import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../i18n/presentation_formats.dart';
import '../profiles/active_profile_provider.dart';
import '../services/book_identifiers.dart';
import '../services/hardcover/hardcover_account_store.dart';
import '../services/hardcover/hardcover_client.dart';
import '../sources/source_controller.dart';
import '../sources/source_models.dart';

/// A quiet status line for a local book that was matched in the user's last
/// Hardcover shelf import. It never makes a remote shelf item look playable.
class HardcoverShelfStatus extends StatefulWidget {
  const HardcoverShelfStatus({super.key, required this.identifiers});

  final Map<String, String> identifiers;

  @override
  State<HardcoverShelfStatus> createState() => _HardcoverShelfStatusState();
}

class _HardcoverShelfStatusState extends State<HardcoverShelfStatus> {
  HardcoverBookRecord? _record;
  String? _profileId;
  String? _activeProfileId;
  int _generation = 0;

  @override
  void didUpdateWidget(covariant HardcoverShelfStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identifiers.toString() == widget.identifiers.toString()) return;
    _record = null;
    final sources = Provider.of<SourceController>(context, listen: false);
    final profileId = sources.profileId;
    final activeProfileId = Provider.of<ActiveProfileProvider?>(context, listen: false)?.activeId;
    final generation = ++_generation;
    if (profileId != null && activeProfileId == profileId) {
      unawaited(_load(sources, profileId, generation));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sources = Provider.of<SourceController>(context);
    final activeProfileId = Provider.of<ActiveProfileProvider?>(context)?.activeId;
    final profileId = sources.profileId;
    if (profileId == _profileId && activeProfileId == _activeProfileId) return;
    _profileId = profileId;
    _activeProfileId = activeProfileId;
    final generation = ++_generation;
    if (profileId == null || activeProfileId != profileId) {
      _record = null;
      return;
    }
    unawaited(_load(sources, profileId, generation));
  }

  Future<void> _load(SourceController sources, String profileId, int generation) async {
    try {
      await sources.ready;
      if (!_ownsProfile(sources, profileId, generation)) return;
      final snapshot = await sources.repository.privatePreference(
        profileId,
        HardcoverAccountStore.importedLibraryPreferenceKey,
      );
      final accountId = sourceInt(snapshot['accountId']);
      if (!_ownsProfile(sources, profileId, generation) || accountId == null || accountId <= 0) {
        if (mounted && generation == _generation) setState(() => _record = null);
        return;
      }
      final localIsbns = BookIdentifiers.fromValues(widget.identifiers).values.toSet();
      if (localIsbns.isEmpty) {
        if (mounted && generation == _generation) setState(() => _record = null);
        return;
      }
      final matches = <int, HardcoverBookRecord>{};
      for (final row in sourceList(snapshot['records'])) {
        final record = HardcoverBookRecord.fromJson(sourceMap(row));
        if (record.userBookId <= 0) continue;
        final remoteIsbns = BookIdentifiers.fromValues(record.identifiers).values.toSet();
        if (localIsbns.intersection(remoteIsbns).isNotEmpty) matches[record.userBookId] = record;
      }
      if (!mounted || !_ownsProfile(sources, profileId, generation)) return;
      setState(() => _record = matches.length == 1 ? matches.values.single : null);
    } on Object {
      if (mounted && generation == _generation) setState(() => _record = null);
    }
  }

  bool _ownsProfile(SourceController sources, String profileId, int generation) {
    if (!mounted || generation != _generation || sources.profileId != profileId) return false;
    return Provider.of<ActiveProfileProvider?>(context, listen: false)?.activeId == profileId;
  }

  String? _statusText(HardcoverStatus? status) {
    final value = status?.normalized ?? '';
    if (value.contains('currently reading') || value.contains('reading')) return t.audiobook.statusProgress;
    if (value.contains('want to read') || value.contains('to read') || value.contains('tbr')) {
      return t.audiobook.statusNew;
    }
    if (value.contains('finished') || value.contains('completed') || value == 'read read') {
      return t.audiobook.statusFinished;
    }
    return status?.status;
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final status = _statusText(record?.status);
    if (record == null || status == null || status.trim().isEmpty) return const SizedBox.shrink();
    final pages = record.read?.progressPages;
    final detail = 'Hardcover · $status${pages == null ? '' : ' · p$pages'}';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Tooltip(
        message: 'Imported Hardcover shelf state',
        child: Semantics(
          label: detail,
          child: Row(
            children: [
              Icon(Symbols.menu_book_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isolateDisplayText(detail),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
