import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/catalog/mdblist_explore_shelf.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/app_icon.dart';
import '../../providers/catalog_sources_provider.dart';
import '../../providers/trackers_provider.dart';
import '../../services/catalog/mdblist_catalog_source.dart';
import '../../services/trackers/mdblist/mdblist_client.dart';
import '../../widgets/settings_page.dart';

/// Account discovery and local shelf preferences. No remote list mutations.
class MdblistExploreShelvesScreen extends StatefulWidget {
  const MdblistExploreShelvesScreen({super.key});

  @override
  State<MdblistExploreShelvesScreen> createState() => _MdblistExploreShelvesScreenState();
}

class _MdblistExploreShelvesScreenState extends State<MdblistExploreShelvesScreen> {
  late CatalogSourcesProvider _sources;
  late String _scope;
  MdblistClient? _client;
  List<MdblistAccountList> _lists = const [];
  late List<MdblistExploreShelf> _shelves;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sources = context.read<CatalogSourcesProvider>();
    _scope = _sources.mdblistShelfScope;
    _shelves = [..._sources.mdblistShelves];
    _client = context.read<TrackersProvider>().mdblistCatalogClient;
    unawaited(_discover());
  }

  Future<void> _discover() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client;
      if (client == null) throw StateError('MDBList is disconnected');
      final lists = await client.getAccountLists();
      if (!mounted || !identical(client, context.read<TrackersProvider>().mdblistCatalogClient)) return;
      setState(() {
        _lists = lists;
        // Refresh source labels without disturbing overrides, selection or order.
        _shelves = [
          for (final shelf in _shelves)
            shelf.copyWith(sourceName: lists.where((list) => list.id == shelf.listId).firstOrNull?.name),
        ];
      });
    } catch (error) {
      if (mounted) setState(() => _error = MdblistCatalogSource.shelfError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_scope != _sources.mdblistShelfScope ||
        !identical(_client, context.read<TrackersProvider>().mdblistCatalogClient)) {
      setState(() => _error = t.explore.mdblistShelves.accountChanged);
      return;
    }
    setState(() => _saving = true);
    try {
      await _sources.setMdblistShelves(_shelves);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = t.explore.mdblistShelves.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rename(int index) async {
    final shelf = _shelves[index];
    var editedName = shelf.displayName ?? '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.explore.mdblistShelves.displayName),
        content: TextFormField(
          initialValue: editedName,
          onChanged: (value) => editedName = value,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: shelf.sourceName, helperText: t.explore.mdblistShelves.nameHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, editedName.trim()), child: Text(t.common.save)),
        ],
      ),
    );
    if (value != null && mounted) setState(() => _shelves[index] = shelf.copyWith(displayName: value));
  }

  void _move(int index, int delta) => setState(() {
    final shelf = _shelves.removeAt(index);
    _shelves.insert(index + delta, shelf);
  });

  @override
  Widget build(BuildContext context) {
    final account = context.watch<TrackersProvider>();
    final selectedIds = _shelves.map((shelf) => shelf.listId).toSet();
    return SettingsPage(
      title: Text(t.explore.mdblistShelves.manage),
      children: [
        FocusableListTile(
          title: Text(
            account.mdblistUsername == null ? 'MDBList' : t.services.connectedAs(username: account.mdblistUsername!),
          ),
          subtitle: Text(t.explore.mdblistShelves.description),
          trailing: IconButton(
            tooltip: t.common.refresh,
            onPressed: _loading || _saving ? null : _discover,
            icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
          ),
        ),
        if (_sources.mdblistShelvesError case final error?)
          Padding(padding: const EdgeInsets.all(16), child: Text(error)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_loading) const LinearProgressIndicator(),
        if (_shelves.isNotEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(t.explore.mdblistShelves.selected)),
        for (var index = 0; index < _shelves.length; index++) _shelfTile(index),
        Padding(padding: const EdgeInsets.all(16), child: Text(t.explore.mdblistShelves.available)),
        if (!_loading && _error == null && _lists.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(t.explore.mdblistShelves.noLists)),
        for (final list in _lists.where((list) => !selectedIds.contains(list.id)))
          FocusableListTile(
            title: Text(list.name),
            subtitle: Text(
              [
                if (list.mediaType != null) list.mediaType!,
                if (list.itemCount != null) t.explore.totalResults(n: list.itemCount!),
              ].join(' · '),
            ),
            trailing: IconButton(
              tooltip: t.explore.mdblistShelves.add,
              icon: const AppIcon(Symbols.add_rounded, fill: 1),
              onPressed: _saving
                  ? null
                  : () => setState(() => _shelves.add(MdblistExploreShelf(listId: list.id, sourceName: list.name))),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving || _loading ? null : _save,
            child: Text(_saving ? t.common.loading : t.explore.mdblistShelves.save),
          ),
        ),
      ],
    );
  }

  Widget _shelfTile(int index) {
    final shelf = _shelves[index];
    final missing = !_loading && _error == null && !_lists.any((list) => list.id == shelf.listId);
    return Column(
      key: ValueKey(shelf.listId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FocusableSwitchListTile(
          title: Text(shelf.title),
          value: shelf.enabled,
          subtitle: Text(missing ? t.explore.mdblistShelves.unavailable : shelf.sourceName),
          onChanged: _saving ? null : (value) => setState(() => _shelves[index] = shelf.copyWith(enabled: value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            children: [
              IconButton(
                tooltip: t.explore.mdblistShelves.moveUp(title: shelf.title),
                icon: const AppIcon(Symbols.arrow_upward_rounded, fill: 1),
                onPressed: _saving || index == 0 ? null : () => _move(index, -1),
              ),
              IconButton(
                tooltip: t.explore.mdblistShelves.moveDown(title: shelf.title),
                icon: const AppIcon(Symbols.arrow_downward_rounded, fill: 1),
                onPressed: _saving || index == _shelves.length - 1 ? null : () => _move(index, 1),
              ),
              TextButton(onPressed: _saving ? null : () => _rename(index), child: Text(t.common.edit)),
              TextButton(
                onPressed: _saving ? null : () => setState(() => _shelves.removeAt(index)),
                child: Text(t.common.delete),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
