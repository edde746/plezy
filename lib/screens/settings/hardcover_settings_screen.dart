import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/book_identifiers.dart';
import '../../services/hardcover/hardcover_account_store.dart';
import '../../services/hardcover/hardcover_client.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';
import '../sources/source_detail_screen.dart';

class HardcoverSettingsScreen extends StatefulWidget {
  const HardcoverSettingsScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<HardcoverSettingsScreen> createState() => _HardcoverSettingsScreenState();
}

class _HardcoverSettingsScreenState extends State<HardcoverSettingsScreen> {
  final _token = TextEditingController();
  SourceController? _sources;
  HardcoverAccountStore? _store;
  HardcoverClient? _client;
  HardcoverAccount? _account;
  List<HardcoverStatus> _statuses = const [];
  List<HardcoverBookRecord> _importedRecords = const [];
  Map<String, SourceEntry> _localEntriesByUserBookId = const {};
  List<_ExportChange> _exportPreview = const [];
  bool _hasImportedSnapshot = false;
  bool _hasImportUndo = false;
  bool _hasExportUndo = false;
  bool _initializing = true;
  bool _busy = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sources != null) return;
    _sources = context.read<SourceController>();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _token.dispose();
    _client?.dispose();
    super.dispose();
  }

  bool get _isCurrentOwner {
    if (!mounted || _sources == null || _sources!.profileId != widget.profileId) return false;
    return context.read<ActiveProfileProvider?>()?.activeId == widget.profileId;
  }

  void _requireCurrentOwner() {
    if (!_isCurrentOwner) throw const SourceException(SourceFailure.cancelled);
  }

  Future<void> _initialize() async {
    try {
      final sources = _sources!;
      await sources.ready;
      if (!_isCurrentOwner) return;
      _store = HardcoverAccountStore(sources.repository);
      final session = await _store!.load(widget.profileId);
      if (!_isCurrentOwner) return;
      if (session != null) {
        final client = HardcoverClient(token: session.token);
        try {
          final account = await client.account();
          _requireCurrentOwner();
          if (account.id != session.account.id) {
            await _store!.clear(widget.profileId);
            _requireCurrentOwner();
            await _store!.save(widget.profileId, session.token, account);
          }
          _client = client;
          _account = account;
          await _refreshWith(client);
        } on Object {
          if (!identical(_client, client)) client.dispose();
          rethrow;
        }
      }
      await _loadImportedSnapshot();
    } on Object catch (error) {
      if (mounted && _isCurrentOwner) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _loadImportedSnapshot() async {
    final store = _store;
    if (store == null) return;
    final value = await _sources!.repository.privatePreference(widget.profileId, HardcoverAccountStore.importedLibraryPreferenceKey);
    _requireCurrentOwner();
    final accountId = _account?.id;
    final hasSnapshot = accountId != null && sourceInt(value['accountId']) == accountId && value['records'] is List;
    final rows = hasSnapshot ? sourceList(value['records']).map((row) => HardcoverBookRecord.fromJson(sourceMap(row))).toList() : const <HardcoverBookRecord>[];
    final localMatches = sourceMap(value['localMatches']);
    final localEntries = hasSnapshot ? await _sources!.repository.entries(widget.profileId) : const <SourceEntry>[];
    _requireCurrentOwner();
    final entriesByKey = {for (final entry in localEntries) entry.key: entry};
    final matchedEntries = <String, SourceEntry>{};
    for (final record in rows) {
      final userBookId = record.userBookId.toString();
      final entryKey = localMatches[userBookId];
      if (entryKey is! String) continue;
      final entry = entriesByKey[entryKey];
      if (entry != null) matchedEntries[userBookId] = entry;
    }
    final importUndo = await _sources!.repository.privatePreference(widget.profileId, HardcoverAccountStore.importUndoPreferenceKey);
    _requireCurrentOwner();
    final exportUndo = await _sources!.repository.privatePreference(widget.profileId, HardcoverAccountStore.exportUndoPreferenceKey);
    _requireCurrentOwner();
    if (mounted) {
      setState(() {
        _importedRecords = rows;
        _localEntriesByUserBookId = Map.unmodifiable(matchedEntries);
        _hasImportedSnapshot = hasSnapshot;
        _hasImportUndo = accountId != null &&
            sourceInt(importUndo['accountId']) == accountId &&
            importUndo['previous'] is Map;
        _hasExportUndo = accountId != null &&
            sourceInt(exportUndo['accountId']) == accountId &&
            sourceList(exportUndo['changes']).isNotEmpty;
      });
    }
  }

  Future<void> _refreshWith(HardcoverClient client) async {
    final statuses = await client.statuses();
    _requireCurrentOwner();
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _exportPreview = const [];
      });
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy || !_isCurrentOwner) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
      _requireCurrentOwner();
    } on Object catch (error) {
      if (mounted && _isCurrentOwner) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async {
    final token = _token.text.trim();
    final client = HardcoverClient(token: token);
    try {
      final account = await client.account();
      _requireCurrentOwner();
      final saved = await _store!.load(widget.profileId);
      _requireCurrentOwner();
      if (saved != null && saved.account.id != account.id) {
        await _store!.clear(widget.profileId);
        _requireCurrentOwner();
      }
      await _store!.save(widget.profileId, token, account);
      _requireCurrentOwner();
      final previous = _client;
      _client = client;
      _account = account;
      previous?.dispose();
      await _refreshWith(client);
      await _loadImportedSnapshot();
      _token.clear();
    } on Object {
      if (!identical(_client, client)) client.dispose();
      rethrow;
    }
  });

  Future<void> _disconnect() async {
    final confirmed = await showScopedDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hardcover'),
        content: Text(t.libraries.confirmActionMessage),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext, false), label: t.common.cancel),
          DialogActionButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            label: t.common.disconnect,
            isPrimary: true,
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !_isCurrentOwner) return;
    await _run(() async {
      await _store!.clear(widget.profileId);
      _client?.dispose();
      if (mounted) {
        setState(() {
          _client = null;
          _account = null;
          _statuses = const [];
          _importedRecords = const [];
          _localEntriesByUserBookId = const {};
          _hasImportedSnapshot = false;
          _hasImportUndo = false;
          _hasExportUndo = false;
          _exportPreview = const [];
        });
      }
    });
  }

  Future<void> _refresh() => _run(() async {
    final client = _client, account = _account;
    if (client == null || account == null) throw const SourceException(SourceFailure.authentication);
    await _refreshWith(client);
  });

  Set<String> _isbnIdentifiers(Map<String, String> identifiers) => BookIdentifiers.fromValues(identifiers).values.toSet();

  Future<void> _importLibrary() => _run(() async {
    final client = _client, account = _account, store = _store;
    if (client == null || account == null || store == null) {
      throw const SourceException(SourceFailure.authentication);
    }
    final library = await client.library(account.id);
    _requireCurrentOwner();
    final localEntries = await _sources!.repository.entries(widget.profileId);
    _requireCurrentOwner();
    final localByIsbn = <String, List<SourceEntry>>{};
    for (final entry in localEntries.where((entry) => entry.kind == SourceItemKind.ebook || entry.kind == SourceItemKind.comic)) {
      for (final isbn in _isbnIdentifiers(entry.identifiers)) {
        localByIsbn.putIfAbsent(isbn, () => []).add(entry);
      }
    }
    final localMatches = <String, String>{};
    for (final remote in library) {
      final candidates = <String, SourceEntry>{};
      for (final isbn in _isbnIdentifiers(remote.identifiers)) {
        for (final entry in localByIsbn[isbn] ?? const <SourceEntry>[]) {
          candidates[entry.key] = entry;
        }
      }
      if (candidates.length == 1) localMatches['${remote.userBookId}'] = candidates.values.single.key;
    }
    final previous = await _sources!.repository.privatePreference(
      widget.profileId,
      HardcoverAccountStore.importedLibraryPreferenceKey,
    );
    _requireCurrentOwner();
    await _sources!.repository.savePrivatePreference(widget.profileId, HardcoverAccountStore.importUndoPreferenceKey, {
      'accountId': account.id,
      'previous': previous,
    });
    _requireCurrentOwner();
    await _sources!.repository.savePrivatePreference(widget.profileId, HardcoverAccountStore.importedLibraryPreferenceKey, {
      'accountId': account.id,
      'importedAt': DateTime.now().millisecondsSinceEpoch,
      'records': library.map((record) => record.toJson()).toList(),
      'localMatches': localMatches,
    });
    _requireCurrentOwner();
    await _loadImportedSnapshot();
  });

  Future<void> _undoImport() => _run(() async {
    final account = _account;
    if (account == null) throw const SourceException(SourceFailure.authentication);
    final repo = _sources!.repository;
    final undo = await repo.privatePreference(widget.profileId, HardcoverAccountStore.importUndoPreferenceKey);
    _requireCurrentOwner();
    if (sourceInt(undo['accountId']) != account.id || undo['previous'] is! Map) {
      throw const SourceException(SourceFailure.conflict);
    }
    final previous = sourceMap(undo['previous']);
    if (previous.isEmpty) {
      await repo.forgetPreference(widget.profileId, HardcoverAccountStore.importedLibraryPreferenceKey);
    } else {
      await repo.savePrivatePreference(widget.profileId, HardcoverAccountStore.importedLibraryPreferenceKey, previous);
    }
    await repo.forgetPreference(widget.profileId, HardcoverAccountStore.importUndoPreferenceKey);
    await _loadImportedSnapshot();
  });

  Future<void> _prepareExport() => _run(() async {
    final client = _client, account = _account;
    if (client == null || account == null) throw const SourceException(SourceFailure.authentication);
    final library = await client.library(account.id);
    _requireCurrentOwner();
    final statuses = await client.statuses();
    _requireCurrentOwner();
    final entries = await _sources!.repository.entries(widget.profileId);
    final progress = (await _sources!.repository.allProgress(widget.profileId))
        .where((record) => record.mode == PublicationMode.reading)
        .toList();
    _requireCurrentOwner();
    final entriesByKey = {for (final entry in entries) entry.key: entry};
    final progressByEntry = <String, PublicationProgress>{};
    for (final record in progress) {
      if ((progressByEntry[record.entryKey]?.updatedAt ?? -1) < record.updatedAt) {
        progressByEntry[record.entryKey] = record;
      }
    }
    final localItems = <String, ({SourceEntry entry, PublicationProgress progress, Set<String> isbns})>{};
    for (final record in progressByEntry.values) {
      final entry = entriesByKey[record.entryKey];
      if (entry == null || (entry.kind != SourceItemKind.ebook && entry.kind != SourceItemKind.comic)) continue;
      final isbns = _isbnIdentifiers(entry.identifiers);
      if (isbns.isEmpty) continue;
      localItems[entry.key] = (entry: entry, progress: record, isbns: isbns);
    }
    final localOwnersByIsbn = <String, Set<String>>{};
    for (final item in localItems.values) {
      for (final isbn in item.isbns) {
        localOwnersByIsbn.putIfAbsent(isbn, () => {}).add(item.entry.key);
      }
    }
    final remoteByIsbn = <String, List<HardcoverBookRecord>>{};
    for (final record in library) {
      for (final isbn in _isbnIdentifiers(record.identifiers)) {
        remoteByIsbn.putIfAbsent(isbn, () => []).add(record);
      }
    }
    final changes = <_ExportChange>[];
    for (final item in localItems.values) {
      if (item.isbns.any((isbn) => localOwnersByIsbn[isbn]?.length != 1)) continue;
      final remoteCandidates = <int, HardcoverBookRecord>{};
      for (final isbn in item.isbns) {
        for (final record in remoteByIsbn[isbn] ?? const <HardcoverBookRecord>[]) {
          remoteCandidates[record.userBookId] = record;
        }
      }
      if (remoteCandidates.length != 1) continue;
      final remote = remoteCandidates.values.single;
      final status = _targetStatus(statuses, item.progress);
      if (status == null || remote.statusId <= 0 || remote.statusId == status.id) continue;
      final matchingIsbn = item.isbns.firstWhere(
        (isbn) => (remoteByIsbn[isbn] ?? const <HardcoverBookRecord>[]).any((record) => record.userBookId == remote.userBookId),
      );
      changes.add(
        _ExportChange(
          userBookId: remote.userBookId,
          oldStatusId: remote.statusId,
          targetStatusId: status.id,
          title: item.entry.title,
          isbn: matchingIsbn,
          localProgressKey: item.progress.key,
          localRevision: item.progress.revision,
          localUpdatedAt: item.progress.updatedAt,
          oldStatus: _statusLabel(remote.status),
          targetStatus: _statusLabel(status),
        ),
      );
      if (changes.length >= 25) break;
    }
    if (mounted) setState(() => _exportPreview = List.unmodifiable(changes));
  });

  HardcoverStatus? _targetStatus(List<HardcoverStatus> statuses, PublicationProgress progress) {
    final normalized = progress.finished
        ? 'read'
        : (progress.fraction > 0 || progress.locator?.page != null)
        ? 'currently reading'
        : 'want to read';
    String normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    for (final status in statuses) {
      final candidates = [normalize(status.slug), normalize(status.status)];
      if (normalized == 'currently reading' &&
          candidates.any((candidate) => candidate == 'currently reading' || candidate == 'reading' || candidate == 'in progress')) {
        return status;
      }
      if (normalized == 'want to read' &&
          candidates.any((candidate) => candidate == 'want to read' || candidate == 'to read' || candidate == 'tbr')) {
        return status;
      }
      if (normalized == 'read' &&
          candidates.any((candidate) => candidate == 'read' || candidate == 'finished' || candidate == 'completed')) {
        return status;
      }
    }
    return null;
  }

  String _statusLabel(HardcoverStatus? status) {
    final name = status?.normalized ?? '';
    if (name.contains('currently reading') || name.contains('reading')) return t.audiobook.statusProgress;
    if (name.contains('want to read') || name.contains('to read') || name.contains('tbr')) return t.audiobook.statusNew;
    if (name.contains('finished') || name.contains('completed') || name == 'read read') return t.audiobook.statusFinished;
    return status?.status ?? '';
  }

  Future<void> _applyExport() async {
    if (_exportPreview.isEmpty || _client == null || _account == null) return;
    final confirmed = await showScopedDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.fileSources.useLocal),
        content: Text(t.libraries.confirmActionMessage),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext, false), label: t.common.cancel),
          DialogActionButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            label: t.discover.findNext.apply,
            isPrimary: true,
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !_isCurrentOwner) return;
    await _run(() async {
      final client = _client!, account = _account!, repo = _sources!.repository;
      final snapshot = List<_ExportChange>.of(_exportPreview);
      final fresh = await client.library(account.id);
      _requireCurrentOwner();
      final statuses = await client.statuses();
      _requireCurrentOwner();
      final progressRecords = await repo.allProgress(widget.profileId);
      _requireCurrentOwner();
      final localProgress = {
        for (final record in progressRecords)
          if (record.mode == PublicationMode.reading) record.key: record,
      };
      final sourceEntries = await repo.entries(widget.profileId);
      _requireCurrentOwner();
      final localEntries = {for (final entry in sourceEntries) entry.key: entry};
      final byId = {for (final record in fresh) record.userBookId: record};
      final applied = <_ExportChange>[];
      var skipped = 0;
      for (final change in snapshot) {
        final remote = byId[change.userBookId];
        if (remote == null || remote.statusId != change.oldStatusId) {
          skipped++;
          continue;
        }
        final currentProgress = localProgress[change.localProgressKey];
        if (currentProgress == null ||
            currentProgress.revision != change.localRevision ||
            currentProgress.updatedAt != change.localUpdatedAt) {
          skipped++;
          continue;
        }
        final localEntry = localEntries[currentProgress.entryKey];
        if (localEntry == null || !_isbnIdentifiers(localEntry.identifiers).contains(change.isbn)) {
          skipped++;
          continue;
        }
        if (_targetStatus(statuses, currentProgress)?.id != change.targetStatusId) {
          skipped++;
          continue;
        }
        await repo.savePrivatePreference(widget.profileId, HardcoverAccountStore.exportUndoPreferenceKey, {
          'accountId': account.id,
          'changes': [...applied, change].map((item) => item.toJson()).toList(),
        });
        _requireCurrentOwner();
        _hasExportUndo = true;
        await client.updateStatus(userBookId: change.userBookId, statusId: change.targetStatusId);
        _requireCurrentOwner();
        applied.add(change);
      }
      await _refreshWith(client);
      if (skipped > 0) throw const SourceException(SourceFailure.conflict);
    });
  }

  Future<void> _undoExport() => _run(() async {
    final client = _client, account = _account;
    if (client == null || account == null) throw const SourceException(SourceFailure.authentication);
    final repo = _sources!.repository;
    final undo = await repo.privatePreference(widget.profileId, HardcoverAccountStore.exportUndoPreferenceKey);
    _requireCurrentOwner();
    if (sourceInt(undo['accountId']) != account.id) throw const SourceException(SourceFailure.conflict);
    final changes = sourceList(undo['changes']).map((row) => _ExportChange.fromJson(sourceMap(row))).toList();
    if (changes.isEmpty) throw const SourceException(SourceFailure.conflict);
    final fresh = await client.library(account.id);
    _requireCurrentOwner();
    final byId = {for (final record in fresh) record.userBookId: record};
    var skipped = 0;
    for (final change in changes) {
      final remote = byId[change.userBookId];
      if (remote == null || remote.statusId != change.targetStatusId) {
        skipped++;
        continue;
      }
      await client.updateStatus(userBookId: change.userBookId, statusId: change.oldStatusId);
      _requireCurrentOwner();
    }
    await repo.forgetPreference(widget.profileId, HardcoverAccountStore.exportUndoPreferenceKey);
    _hasExportUndo = false;
    await _refreshWith(client);
    if (skipped > 0) throw const SourceException(SourceFailure.conflict);
  });

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return FocusedScrollScaffold(
      title: const Text('Hardcover'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              if (_initializing)
                const LinearProgressIndicator()
              else if (account == null)
                _connectForm()
              else ...[
                SettingsGroup(
                  children: [
                    ListTile(
                      leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
                      title: Text(t.services.connectedAs(username: account.displayName)),
                      subtitle: Text(t.services.connected),
                    ),
                    FocusableListTile(
                      leading: AppIcon(Symbols.refresh_rounded, fill: 1),
                      title: Text(t.fileSources.refresh),
                      onTap: _busy ? null : () => unawaited(_refresh()),
                    ),
                    FocusableListTile(
                      leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                      title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: _busy ? null : () => unawaited(_disconnect()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: t.audiobook.statusFilter,
                  children: [
                    FocusableListTile(
                      leading: const AppIcon(Symbols.download_rounded),
                      title: Text(t.fileSources.useRemote),
                      onTap: _busy ? null : () => unawaited(_importLibrary()),
                    ),
                    if (_hasImportUndo)
                      FocusableListTile(
                        leading: const AppIcon(Symbols.undo_rounded),
                        title: Text(t.discover.findNext.undo),
                        onTap: _busy ? null : () => unawaited(_undoImport()),
                      ),
                    if (_hasImportedSnapshot)
                      for (final record in _importedRecords.take(100)) _bookTile(context, record),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: t.audiobook.statusFilter,
                  children: [
                    FocusableListTile(
                      leading: const AppIcon(Symbols.upload_rounded),
                      title: Text(t.fileSources.useLocal),
                      onTap: _busy ? null : () => unawaited(_prepareExport()),
                    ),
                    for (final change in _exportPreview)
                      FocusableListTile(
                        leading: const AppIcon(Symbols.sync_alt_rounded),
                        title: Text(change.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${change.oldStatus} → ${change.targetStatus}'),
                      ),
                    if (_exportPreview.isNotEmpty)
                      FocusableListTile(
                        leading: const AppIcon(Symbols.check_circle_rounded),
                        title: Text(t.discover.findNext.apply),
                        onTap: _busy ? null : () => unawaited(_applyExport()),
                      ),
                    if (_hasExportUndo)
                      FocusableListTile(
                        leading: const AppIcon(Symbols.undo_rounded),
                        title: Text(t.discover.findNext.undo),
                        onTap: _busy ? null : () => unawaited(_undoExport()),
                      ),
                  ],
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(t.common.error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectForm() => SettingsGroup(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: FocusableTextField(
          controller: _token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: t.fileSources.token),
        ),
      ),
      FocusableListTile(
        leading: const AppIcon(Symbols.link_rounded),
        title: Text(t.common.connect),
        onTap: _busy || _token.text.trim().isEmpty ? null : () => unawaited(_connect()),
      ),
    ],
  );

  Widget _bookTile(BuildContext context, HardcoverBookRecord record) {
    final entry = _localEntriesByUserBookId['${record.userBookId}'];
    return FocusableListTile(
      leading: const AppIcon(Symbols.menu_book_rounded),
      title: Text(record.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(_statusLabel(record.status)),
      trailing: entry == null ? null : const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: entry == null || !_isCurrentOwner
          ? null
          : () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => SourceDetailScreen(entry: entry)),
            ),
    );
  }
}

class _ExportChange {
  const _ExportChange({
    required this.userBookId,
    required this.oldStatusId,
    required this.targetStatusId,
    required this.title,
    required this.isbn,
    required this.localProgressKey,
    required this.localRevision,
    required this.localUpdatedAt,
    required this.oldStatus,
    required this.targetStatus,
  });

  final int userBookId;
  final int oldStatusId;
  final int targetStatusId;
  final String title;
  final String isbn;
  final String localProgressKey;
  final int localRevision;
  final int localUpdatedAt;
  final String oldStatus;
  final String targetStatus;

  Map<String, dynamic> toJson() => {
    'userBookId': userBookId,
    'oldStatusId': oldStatusId,
    'targetStatusId': targetStatusId,
    'title': title,
    'isbn': isbn,
    'localProgressKey': localProgressKey,
    'localRevision': localRevision,
    'localUpdatedAt': localUpdatedAt,
    'oldStatus': oldStatus,
    'targetStatus': targetStatus,
  };

  factory _ExportChange.fromJson(Map<String, dynamic> json) => _ExportChange(
    userBookId: sourceInt(json['userBookId']) ?? 0,
    oldStatusId: sourceInt(json['oldStatusId']) ?? 0,
    targetStatusId: sourceInt(json['targetStatusId']) ?? 0,
    title: json['title'] as String? ?? '',
    isbn: json['isbn'] as String? ?? '',
    localProgressKey: json['localProgressKey'] as String? ?? '',
    localRevision: sourceInt(json['localRevision']) ?? 0,
    localUpdatedAt: sourceInt(json['localUpdatedAt']) ?? 0,
    oldStatus: json['oldStatus'] as String? ?? '',
    targetStatus: json['targetStatus'] as String? ?? '',
  );
}
