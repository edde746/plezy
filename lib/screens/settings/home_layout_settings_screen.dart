import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/home_section_config.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_backend.dart';
import '../../media/ids.dart';
import '../../media/media_library.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../models/plex/plex_managed_hub.dart';
import '../../utils/home_section_builder.dart'
    show continueWatchingHeroOverrideKey, continueWatchingRowToken, libraryContinueWatchingHeroOverrideKey;
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

class HomeLayoutSettingsScreen extends StatefulWidget {
  const HomeLayoutSettingsScreen({super.key});

  @override
  State<HomeLayoutSettingsScreen> createState() => _HomeLayoutSettingsScreenState();
}

class _HomeLayoutSettingsScreenState extends State<HomeLayoutSettingsScreen> {
  List<HomeSectionConfig> _sections = [];
  bool _loaded = false;
  List<MediaItem> _collections = const [];
  Map<String, List<PlexManagedHub>> _managedRows = {};
  Map<String, ManagedHubHeroOverride> _heroOverrides = {};
  List<String> _rowOrder = [];
  bool _continueWatchingOnHome = true;

  /// Reordering starts unlocked every time this screen opens, per user
  /// request 2026-09-10 (revised same day — the first cut of this defaulted
  /// locked, inverted from what was actually wanted). A lock icon toggles
  /// this per list: open padlock = unlocked (can drag), closed padlock =
  /// locked (a whole-row click does nothing, so Hero/Trailer/Library
  /// checkboxes can be tapped without risking an accidental drag). `true`
  /// here is the Organizer list; per-library lists get their own entry in
  /// [_libraryReorderUnlocked] instead, since each library's own row list
  /// is independent — both default to unlocked (`?? true` at each read
  /// site) the same way this field's own literal default does.
  bool _organizerReorderUnlocked = true;
  final Map<String, bool> _libraryReorderUnlocked = {};

  Future<void> _setContinueWatchingOnHome(bool value) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.continueWatchingOnHome, value);
    final libraries = context
        .read<LibrariesProvider>()
        .libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(_rowOrder, libraries, _sections, _managedRows, continueWatchingOnHome: value);
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) {
      setState(() {
        _continueWatchingOnHome = value;
        _rowOrder = order;
      });
    }
  }

  /// Per-library counterpart to [_setContinueWatchingOnHome] — Plex's own
  /// Continue Watching hub for a library isn't a [PlexManagedHub] the way
  /// every other row on that library's Recommended tab is (nothing to
  /// promote/demote via `updateManagedHubVisibility`), so this is a
  /// Plezy-local toggle instead, read directly by [LibraryRecommendedTab]
  /// when it decides what to show.
  Future<void> _setLibraryContinueWatchingVisible(MediaLibrary library, bool visible) async {
    final settings = await SettingsService.getInstance();
    final hidden = Set<String>.of(settings.read(SettingsService.libraryContinueWatchingHidden));
    if (visible) {
      hidden.remove(library.globalKey);
    } else {
      hidden.add(library.globalKey);
    }
    await settings.write(SettingsService.libraryContinueWatchingHidden, hidden);
    if (mounted) setState(() {});
  }

  String _heroOverrideKey(MediaLibrary library, PlexManagedHub hub) => '${library.globalKey}::${hub.identifier}';

  ManagedHubHeroOverride _heroOverrideFor(MediaLibrary library, PlexManagedHub hub) =>
      _heroOverrideForKey(_heroOverrideKey(library, hub));

  Future<void> _setHeroOverride(MediaLibrary library, PlexManagedHub hub, ManagedHubHeroOverride override) =>
      _setHeroOverrideForKey(_heroOverrideKey(library, hub), override);

  ManagedHubHeroOverride _heroOverrideForKey(String key) => _heroOverrides[key] ?? const ManagedHubHeroOverride();

  Future<void> _setHeroOverrideForKey(String key, ManagedHubHeroOverride override) async {
    final settings = await SettingsService.getInstance();
    final updated = Map<String, ManagedHubHeroOverride>.of(_heroOverrides);
    // Trailer preview can never survive hero style being off — enforced
    // here too, not just by the UI graying the checkbox out, so a stale
    // true left over from before hero was disabled can't linger unseen.
    if (!override.heroStyle && override.heroTrailerPreview) {
      override = override.copyWith(heroTrailerPreview: false);
    }
    if (!override.heroStyle && !override.heroTrailerPreview) {
      updated.remove(key);
    } else {
      updated[key] = override;
    }
    await settings.write(SettingsService.managedHubHeroOverrides, updated);
    setState(() => _heroOverrides = updated);
  }

  String? _highlightedRowToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsService.getInstance();
    final sections = List.of(settings.read(SettingsService.homeSections));
    final rowOrder = List.of(settings.read(SettingsService.homeRowOrder));
    List<MediaItem> collections = const [];
    try {
      collections =
          (await context.read<MultiServerProvider>().aggregationService.getCollectionsFromAllServers()).collections;
    } catch (_) {
      // The editor remains usable when a server is temporarily offline.
    }
    final managedRows = <String, List<PlexManagedHub>>{};

    final libraryProvider = context.read<LibrariesProvider>();
    if (!libraryProvider.hasLibraries) await libraryProvider.loadLibraries();
    final plexLibraries = context
        .read<LibrariesProvider>()
        .libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    await Future.wait(
      plexLibraries.map((library) async {
        try {
          final client = context.read<MultiServerProvider>().getPlexClientForServer(ServerId(library.serverId!));
          if (client != null) managedRows[library.globalKey] = await client.fetchManagedHubs(library.id);
        } catch (_) {}
      }),
    );
    final normalizedOrder = _normalizeRowOrder(
      rowOrder,
      plexLibraries,
      sections,
      managedRows,
      continueWatchingOnHome: settings.read(SettingsService.continueWatchingOnHome),
    );
    // home_row_order is the only thing that decides what shows on Home
    // (see buildConfiguredHomeSections), so a newly-promoted Plex hub or a
    // row created outside the normal Add-row flow has to actually land in
    // the saved order the moment it's discovered here -- otherwise it stays
    // invisible on Home until some unrelated reorder happens to write it.
    if (!listEquals(normalizedOrder, rowOrder)) {
      await settings.write(SettingsService.homeRowOrder, normalizedOrder);
    }
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _collections = collections;
      _managedRows = managedRows;
      _heroOverrides = settings.read(SettingsService.managedHubHeroOverrides);
      _rowOrder = normalizedOrder;
      _continueWatchingOnHome = settings.read(SettingsService.continueWatchingOnHome);
      _loaded = true;
    });
  }

  Future<void> _save(List<HomeSectionConfig> sections) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeSections, sections);
    final libraries = context
        .read<LibrariesProvider>()
        .libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(
      settings.read(SettingsService.homeRowOrder),
      libraries,
      sections,
      _managedRows,
      continueWatchingOnHome: _continueWatchingOnHome,
    );
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted)
      setState(() {
        _sections = sections;
        _rowOrder = order;
      });
  }

  Future<void> _editSection(HomeSectionConfig current) async {
    final libraries = context.read<LibrariesProvider>().libraries.where((l) => !l.hidden).toList();
    final result = await showDialog<HomeSectionConfig>(
      context: context,
      builder: (_) => _HomeSectionDialog(libraries: libraries, collections: _collections, initial: current),
    );
    if (result != null) {
      final updated = _sections.map((s) => s.id == current.id ? result : s).toList();
      await _save(updated);
    }
  }

  Future<void> _addSection() async {
    final libraries = context.read<LibrariesProvider>().libraries.where((l) => !l.hidden).toList();
    final result = await showDialog<HomeSectionConfig>(
      context: context,
      builder: (_) => _HomeSectionDialog(libraries: libraries, collections: _collections),
    );
    if (result == null) return;
    await _save([..._sections, result]);
    if (result.showOnHome) await _moveTokenToTop('custom:${result.id}');
  }

  Future<void> _moveTokenToTop(String token) async {
    if (!_rowOrder.contains(token)) return;
    final order = List<String>.of(_rowOrder)..remove(token);
    order.insert(0, token);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) setState(() => _rowOrder = order);
  }

  Future<void> _deleteSection(HomeSectionConfig section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Home row?'),
        content: Text('"${section.title}" will be deleted. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(_sections.where((s) => s.id != section.id).toList());
  }

  String _hubToken(MediaLibrary library, PlexManagedHub hub) =>
      'plex:${library.serverId}:${library.id}:${hub.identifier}';

  List<String> _normalizeRowOrder(
    List<String> saved,
    List<MediaLibrary> libraries,
    List<HomeSectionConfig> sections,
    Map<String, List<PlexManagedHub>> managedRows, {
    required bool continueWatchingOnHome,
  }) {
    final available = <String>[
      // Continue Watching defaults to the front of the list (matching its
      // old fixed-first position) so an untouched install's saved order
      // stays effectively unchanged the first time this runs after upgrade.
      if (continueWatchingOnHome) continueWatchingRowToken,
      for (final library in libraries)
        for (final hub in managedRows[library.globalKey] ?? const <PlexManagedHub>[])
          if (hub.promotedToOwnHome) _hubToken(library, hub),
      for (final section in sections)
        if (section.enabled && section.showOnHome) 'custom:${section.id}',
    ];
    return [...saved.where(available.contains), ...available.where((entry) => !saved.contains(entry))];
  }

  /// Wraps [child] so the entire tile — not just a small handle icon — is a
  /// drag target, but only once reordering is unlocked; locked, [child]
  /// renders plain with no drag capability at all, so nothing in it can
  /// start a reorder no matter where it's clicked.
  Widget _maybeDraggable({required bool unlocked, required int index, required Widget child}) =>
      unlocked ? ReorderableDragStartListener(index: index, child: child) : child;

  /// A tappable padlock — open means unlocked (rows can be dragged by
  /// clicking anywhere on them), closed means locked (a whole-row click
  /// does nothing, so the Hero/Trailer/Library checkboxes underneath can be
  /// tapped without risking an accidental drag). Starts open every time
  /// this screen loads — not persisted.
  Widget _reorderLockTile({required bool unlocked, required ValueChanged<bool> onChanged}) {
    return ListTile(
      dense: true,
      leading: Icon(unlocked ? Symbols.lock_open_rounded : Symbols.lock_rounded),
      title: Text(unlocked ? 'Reordering unlocked' : 'Reordering locked'),
      subtitle: Text(unlocked ? 'Rows can be dragged — tap the lock to prevent that' : 'Tap the lock to drag rows'),
      onTap: () => onChanged(!unlocked),
    );
  }

  /// [oldIndex]/[newIndex] are positions within the currently-*visible*
  /// organizer list (`_organizerRows()`), not [_rowOrder] itself — that list
  /// can also hold tokens for rows that aren't currently shown (a disabled
  /// custom row, Continue Watching while off), which [_organizerRows]
  /// silently skips. Moving the dragged token to sit directly before
  /// whichever visible token now follows it (rather than just splicing by
  /// raw index into [_rowOrder]) keeps those hidden tokens at their existing
  /// relative position instead of bunching them at the end.
  Future<void> _reorderOrganizerRow(int oldIndex, int newIndex) async {
    final rows = _organizerRows();
    if (newIndex > oldIndex) newIndex -= 1; // ReorderableListView's own convention
    final movedToken = rows[oldIndex].token;
    final order = List<String>.of(_rowOrder)..remove(movedToken);
    final visibleAfterRemoval = [
      for (final row in rows)
        if (row.token != movedToken) row.token,
    ];
    final insertBeforeToken = newIndex < visibleAfterRemoval.length ? visibleAfterRemoval[newIndex] : null;
    final insertAt = insertBeforeToken == null ? order.length : order.indexOf(insertBeforeToken);
    order.insert(insertAt < 0 ? order.length : insertAt, movedToken);
    // Update and highlight immediately rather than after the settings write
    // completes: waiting made the row jump with no visible cue of which one
    // moved, since the highlight and the reorder landed in the same frame
    // only once the (imperceptibly fast, but still async) write returned.
    setState(() {
      _rowOrder = order;
      _highlightedRowToken = movedToken;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _highlightedRowToken == movedToken) setState(() => _highlightedRowToken = null);
    });
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeRowOrder, order);
  }

  /// Parses a `plex:<serverId>:<libraryId>:<hubIdentifier>` token back into
  /// the real (library, hub) pair it names, or null if either no longer
  /// exists (a library was removed, a Plex row was deleted upstream, etc).
  (MediaLibrary, PlexManagedHub)? _resolvePlexRowRef(String token) {
    if (!token.startsWith('plex:')) return null;
    final parts = token.split(':');
    if (parts.length < 4) return null;
    final serverId = parts[1];
    final libraryId = parts[2];
    final hubIdentifier = parts.sublist(3).join(':');
    final library = context
        .read<LibrariesProvider>()
        .libraries
        .where((l) => l.serverId == serverId && l.id == libraryId)
        .firstOrNull;
    if (library == null) return null;
    final hub = (_managedRows[library.globalKey] ?? const <PlexManagedHub>[])
        .where((h) => h.identifier == hubIdentifier)
        .firstOrNull;
    if (hub == null) return null;
    return (library, hub);
  }

  Future<void> _removeRowFromHome(String token) async {
    if (token.startsWith('custom:')) {
      final id = token.substring('custom:'.length);
      await _save(_sections.map((s) => s.id == id ? s.copyWith(showOnHome: false) : s).toList());
      return;
    }
    if (token == continueWatchingRowToken) {
      await _setContinueWatchingOnHome(false);
      return;
    }
    final ref = _resolvePlexRowRef(token);
    if (ref == null) return;
    await _setManagedVisibility(ref.$1, ref.$2, home: false);
  }

  /// Row data for the actual Organizer list (drag handle + up/down/X) — the
  /// single place that reflects what's really on Home and in what order, so
  /// Hero/Trailer belong here rather than only inside each library's own
  /// raw hub list below (which includes hubs that aren't even on Home).
  List<_OrganizerRow> _organizerRows() {
    final rows = <_OrganizerRow>[];
    for (final token in _rowOrder) {
      if (token.startsWith('custom:')) {
        final id = token.substring('custom:'.length);
        final section = _sections.where((s) => s.id == id).firstOrNull;
        if (section == null || !section.enabled || !section.showOnHome) continue;
        rows.add(
          _OrganizerRow(
            token: token,
            label: 'Custom: ${section.title}',
            supportsHero: section.supportsHeroStyle,
            heroStyle: section.heroStyle,
            heroTrailerPreview: section.heroTrailerPreview,
          ),
        );
        continue;
      }
      if (token == continueWatchingRowToken) {
        if (!_continueWatchingOnHome) continue;
        final override = _heroOverrideForKey(continueWatchingHeroOverrideKey);
        rows.add(
          _OrganizerRow(
            token: token,
            label: 'Continue Watching',
            supportsHero: true,
            heroStyle: override.heroStyle,
            heroTrailerPreview: override.heroTrailerPreview,
          ),
        );
        continue;
      }
      final ref = _resolvePlexRowRef(token);
      if (ref == null) continue;
      final (library, hub) = ref;
      final override = _heroOverrideFor(library, hub);
      rows.add(
        _OrganizerRow(
          token: token,
          label: '${library.title}: ${hub.title}',
          supportsHero: true,
          heroStyle: override.heroStyle,
          heroTrailerPreview: override.heroTrailerPreview,
        ),
      );
    }
    return rows;
  }

  Future<void> _setOrganizerRowHero(String token, {bool? heroStyle, bool? heroTrailerPreview}) async {
    if (token.startsWith('custom:')) {
      final id = token.substring('custom:'.length);
      final section = _sections.where((s) => s.id == id).firstOrNull;
      if (section == null) return;
      var updated = section.copyWith(
        heroStyle: heroStyle ?? section.heroStyle,
        heroTrailerPreview: heroTrailerPreview ?? section.heroTrailerPreview,
      );
      // Trailer can never survive hero being turned off — same rule the
      // managed-hub override and the Add/Edit dialog both enforce.
      if (!updated.heroStyle && updated.heroTrailerPreview) updated = updated.copyWith(heroTrailerPreview: false);
      await _save(_sections.map((s) => s.id == id ? updated : s).toList());
      return;
    }
    if (token == continueWatchingRowToken) {
      final override = _heroOverrideForKey(continueWatchingHeroOverrideKey);
      await _setHeroOverrideForKey(
        continueWatchingHeroOverrideKey,
        override.copyWith(
          heroStyle: heroStyle ?? override.heroStyle,
          heroTrailerPreview: heroTrailerPreview ?? override.heroTrailerPreview,
        ),
      );
      return;
    }
    final ref = _resolvePlexRowRef(token);
    if (ref == null) return;
    final override = _heroOverrideFor(ref.$1, ref.$2);
    await _setHeroOverride(
      ref.$1,
      ref.$2,
      override.copyWith(
        heroStyle: heroStyle ?? override.heroStyle,
        heroTrailerPreview: heroTrailerPreview ?? override.heroTrailerPreview,
      ),
    );
  }

  List<Widget> _plexManagerGroups() {
    final libraries = context.read<LibrariesProvider>().libraries.where(
      (library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null,
    );
    return [
      SettingsGroup(
        title: 'Plex Home manager',
        children: [
          ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Symbols.sync_rounded),
            title: const Text('Manage Plex rows in Plezy'),
            subtitle: const Text('Open to organize the Home-selected rows'),
            children: [
              if (!_continueWatchingOnHome) _continueWatchingTile(),
              if (_organizerRows().isNotEmpty) ...[
                _reorderLockTile(
                  unlocked: _organizerReorderUnlocked,
                  onChanged: (v) => setState(() => _organizerReorderUnlocked = v),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: _reorderOrganizerRow,
                  children: [
                    for (final indexed in _organizerRows().indexed)
                      AnimatedContainer(
                        key: ValueKey(indexed.$2.token),
                        duration: const Duration(milliseconds: 200),
                        color: indexed.$2.token == _highlightedRowToken
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                            : Colors.transparent,
                        child: _maybeDraggable(
                          unlocked: _organizerReorderUnlocked,
                          index: indexed.$1,
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Symbols.drag_indicator_rounded),
                            title: Text(indexed.$2.label),
                            trailing: Wrap(
                              spacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Tooltip(
                                  message: indexed.$2.supportsHero
                                      ? 'Render as a hero card'
                                      : 'Only available when this row resolves to a single collection\'s actual titles',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: indexed.$2.supportsHero && indexed.$2.heroStyle,
                                        onChanged: !indexed.$2.supportsHero
                                            ? null
                                            : (v) => _setOrganizerRowHero(indexed.$2.token, heroStyle: v ?? false),
                                      ),
                                      const Text('Hero'),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: indexed.$2.heroStyle
                                      ? 'Play a trailer/scene clip in the hero card'
                                      : 'Enable Hero first — trailer preview needs a hero card to play in',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: indexed.$2.heroStyle && indexed.$2.heroTrailerPreview,
                                        onChanged: !indexed.$2.heroStyle
                                            ? null
                                            : (v) => _setOrganizerRowHero(
                                                indexed.$2.token,
                                                heroTrailerPreview: v ?? false,
                                              ),
                                      ),
                                      const Text('Trailer'),
                                    ],
                                  ),
                                ),
                                // Continue Watching has no library/custom-row
                                // list to re-add it from once removed — every
                                // other row type here does (its own library's
                                // expansion tile, or Custom rows), which is
                                // what makes an X safe for them. A checkbox
                                // keeps this one genuinely reversible in place
                                // instead.
                                if (indexed.$2.token == continueWatchingRowToken)
                                  Tooltip(
                                    message: 'Show on Home screen',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(value: true, onChanged: (v) => _setContinueWatchingOnHome(v ?? false)),
                                        const Text('Home'),
                                      ],
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Symbols.close_rounded),
                                    tooltip: 'Remove from Home',
                                    onPressed: () => _removeRowFromHome(indexed.$2.token),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (_organizerRows().isEmpty) const ListTile(title: Text('Select Home rows below first.')),
            ],
          ),
          for (final library in libraries) _managedLibraryTile(library),
        ],
      ),
    ];
  }

  Future<void> _setManagedVisibility(
    MediaLibrary library,
    PlexManagedHub hub, {
    bool? recommended,
    bool? home,
    bool? friendsHome,
  }) async {
    final client = context.read<MultiServerProvider>().getPlexClientForServer(ServerId(library.serverId!));
    if (client == null) return;
    await client.updateManagedHubVisibility(
      library.id,
      hub.identifier,
      promotedToRecommended: recommended ?? hub.promotedToRecommended,
      promotedToOwnHome: home ?? hub.promotedToOwnHome,
      promotedToSharedHome: friendsHome ?? hub.promotedToSharedHome,
    );
    await _load();
  }

  /// Applies this library's saved drag-to-reorder order (if any) to its
  /// fetched managed rows. A saved identifier not present among the
  /// currently-fetched rows is simply dropped (that hub no longer exists or
  /// was removed); any fetched row not yet in the saved order is appended
  /// at the end (a newly-discovered hub) — same "saved order wins, unknowns
  /// go last" shape [_normalizeRowOrder] already uses for Home's own order.
  List<PlexManagedHub> _orderedManagedRows(MediaLibrary library) {
    final rows = _managedRows[library.globalKey] ?? const <PlexManagedHub>[];
    final savedOrder = SettingsService.instance.read(SettingsService.libraryManagedRowOrder)[library.globalKey];
    if (savedOrder == null || savedOrder.isEmpty) return rows;
    final remaining = List<PlexManagedHub>.of(rows);
    final ordered = <PlexManagedHub>[];
    for (final identifier in savedOrder) {
      final match = remaining.where((row) => row.identifier == identifier).firstOrNull;
      if (match != null) {
        ordered.add(match);
        remaining.remove(match);
      }
    }
    return [...ordered, ...remaining];
  }

  Future<void> _reorderLibraryRow(
    MediaLibrary library,
    List<PlexManagedHub> orderedRows,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = List<PlexManagedHub>.of(orderedRows);
    if (newIndex > oldIndex) newIndex -= 1; // ReorderableListView's own convention
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final settings = await SettingsService.getInstance();
    final allOrders = Map<String, List<String>>.of(settings.read(SettingsService.libraryManagedRowOrder));
    allOrders[library.globalKey] = [for (final row in reordered) row.identifier];
    await settings.write(SettingsService.libraryManagedRowOrder, allOrders);
    if (mounted) setState(() {});
  }

  Widget _managedLibraryTile(MediaLibrary library) {
    final rows = _orderedManagedRows(library);
    final continueWatchingVisible = !SettingsService.instance
        .read(SettingsService.libraryContinueWatchingHidden)
        .contains(library.globalKey);
    final continueWatchingOverride = _heroOverrideForKey(libraryContinueWatchingHeroOverrideKey(library.globalKey));
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Icon(library.kind == MediaKind.show ? Symbols.tv_rounded : Symbols.movie_rounded),
      title: Text(library.title),
      subtitle: Text('${rows.length} Plex-managed rows'),
      children: [
        // Continue Watching isn't a PlexManagedHub — Plex itself has no
        // promote/demote concept for it — so it can't come from `rows`
        // like every other tile here. Shown first, matching how Home's own
        // Organizer always pins Continue Watching to the front too.
        ListTile(
          dense: true,
          title: const Text('Continue Watching'),
          subtitle: const Text("This library's own resume-progress row"),
          trailing: Wrap(
            spacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: 'Show in Library Recommended',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: continueWatchingVisible,
                      onChanged: (v) => _setLibraryContinueWatchingVisible(library, v ?? false),
                    ),
                    const Text('Library'),
                  ],
                ),
              ),
              Tooltip(
                message: continueWatchingVisible
                    ? 'Render as a hero card'
                    : 'Check Library first — Hero needs somewhere to show',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: continueWatchingVisible && continueWatchingOverride.heroStyle,
                      onChanged: !continueWatchingVisible
                          ? null
                          : (v) => _setHeroOverrideForKey(
                              libraryContinueWatchingHeroOverrideKey(library.globalKey),
                              continueWatchingOverride.copyWith(heroStyle: v ?? false),
                            ),
                    ),
                    const Text('Hero'),
                  ],
                ),
              ),
              Tooltip(
                message: continueWatchingVisible && continueWatchingOverride.heroStyle
                    ? 'Play a trailer/scene clip in the hero card'
                    : 'Enable Hero first — trailer preview needs a hero card to play in',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value:
                          continueWatchingVisible &&
                          continueWatchingOverride.heroStyle &&
                          continueWatchingOverride.heroTrailerPreview,
                      onChanged: !continueWatchingVisible || !continueWatchingOverride.heroStyle
                          ? null
                          : (v) => _setHeroOverrideForKey(
                              libraryContinueWatchingHeroOverrideKey(library.globalKey),
                              continueWatchingOverride.copyWith(heroTrailerPreview: v ?? false),
                            ),
                    ),
                    const Text('Trailer'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (rows.isNotEmpty) ...[
          _reorderLockTile(
            unlocked: _libraryReorderUnlocked[library.globalKey] ?? true,
            onChanged: (v) => setState(() => _libraryReorderUnlocked[library.globalKey] = v),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) => _reorderLibraryRow(library, rows, oldIndex, newIndex),
            children: [
              for (var index = 0; index < rows.length; index++)
                KeyedSubtree(
                  key: ValueKey(rows[index].identifier),
                  child: _maybeDraggable(
                    unlocked: _libraryReorderUnlocked[library.globalKey] ?? true,
                    index: index,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Symbols.drag_indicator_rounded),
                      title: Text(rows[index].title),
                      subtitle: rows[index].deletable ? const Text('Custom Plex row') : null,
                      trailing: Wrap(
                        spacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Show in Library Recommended',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: rows[index].promotedToRecommended,
                                  onChanged: (v) => _setManagedVisibility(library, rows[index], recommended: v),
                                ),
                                const Text('Library'),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Show on Home screen',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: rows[index].promotedToOwnHome,
                                  onChanged: (v) => _setManagedVisibility(library, rows[index], home: v),
                                ),
                                const Text('Home'),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final override = _heroOverrideFor(library, rows[index]);
                              // Hero only actually renders anywhere this hub is
                              // visible — with neither Library nor Home checked,
                              // there's no surface left for it to apply to, so it
                              // can't be turned on until at least one is.
                              final canHero = rows[index].promotedToRecommended || rows[index].promotedToOwnHome;
                              return Tooltip(
                                message: canHero
                                    ? 'Render as a hero card'
                                    : 'Check Library or Home first — Hero needs somewhere to show',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: canHero && override.heroStyle,
                                      onChanged: !canHero
                                          ? null
                                          : (v) => _setHeroOverride(
                                              library,
                                              rows[index],
                                              override.copyWith(heroStyle: v ?? false),
                                            ),
                                    ),
                                    const Text('Hero'),
                                  ],
                                ),
                              );
                            },
                          ),
                          Builder(
                            builder: (context) {
                              final override = _heroOverrideFor(library, rows[index]);
                              final canHero = rows[index].promotedToRecommended || rows[index].promotedToOwnHome;
                              final canTrailer = canHero && override.heroStyle;
                              return Tooltip(
                                message: canTrailer
                                    ? 'Play a trailer/scene clip in the hero card'
                                    : 'Enable Hero first — trailer preview needs a hero card to play in',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: canTrailer && override.heroTrailerPreview,
                                      onChanged: !canTrailer
                                          ? null
                                          : (v) => _setHeroOverride(
                                              library,
                                              rows[index],
                                              override.copyWith(heroTrailerPreview: v ?? false),
                                            ),
                                    ),
                                    const Text('Trailer'),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (rows[index].deletable)
                            IconButton(
                              icon: const Icon(Symbols.delete_outline_rounded),
                              tooltip: 'Remove Hub',
                              onPressed: () async {
                                final client = context.read<MultiServerProvider>().getPlexClientForServer(
                                  ServerId(library.serverId!),
                                );
                                if (client != null) {
                                  await client.removeManagedHub(library.id, rows[index].identifier);
                                  await _load();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (rows.isEmpty) const ListTile(title: Text('No Plex-managed rows returned for this library.')),
      ],
    );
  }

  /// Continue Watching used to be a fixed fixture always pinned ahead of
  /// every other Home row, with no way to remove or reorder it. This is now
  /// ONLY the add-back switch for when it's off (mirroring the "Add Home
  /// row" / per-library "Home" checkbox mechanisms every other row type
  /// already has) — once it's on, `_organizerRows()` already includes it as
  /// a normal token with its own Hero/Trailer checkboxes and reordering, so
  /// this tile is hidden entirely rather than showing a second, lesser copy
  /// of the same row (the actual bug reported 2026-09-09: this tile used to
  /// render unconditionally, creating a Hero/Trailer-less duplicate above
  /// the real entry, which could be scrolled to way down at wherever
  /// `home_row_order` had placed it).
  Widget _continueWatchingTile() {
    return ListTile(
      dense: true,
      title: const Text('Continue Watching'),
      subtitle: const Text('The resume-progress row shown on Home'),
      trailing: Tooltip(
        message: 'Show on Home screen',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: _continueWatchingOnHome, onChanged: (v) => _setContinueWatchingOnHome(v ?? false)),
            const Text('Home'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: const Text('Home layout'),
      children: [
        if (_loaded) ..._plexManagerGroups(),
        SettingsGroup(
          title: 'Hero cards',
          children: [
            SettingSegmentedTile<HeroCardTapAction>(
              pref: SettingsService.heroCardTapAction,
              icon: Symbols.touch_app_rounded,
              title: 'Tapping a hero card',
              segments: const [
                ButtonSegment(value: HeroCardTapAction.play, label: Text('Play')),
                ButtonSegment(value: HeroCardTapAction.details, label: Text('Open details')),
              ],
            ),
            SettingSegmentedTile<HeroCardTapAction>(
              pref: SettingsService.heroCardTrailerTapAction,
              icon: Symbols.smart_display_rounded,
              title: 'Tapping trailer',
              segments: const [
                ButtonSegment(value: HeroCardTapAction.play, label: Text('Play')),
                ButtonSegment(value: HeroCardTapAction.details, label: Text('Open details')),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: 'Custom rows',
          children: [
            if (!_loaded) const ListTile(title: Text('Loading home layout…')),
            if (_loaded && _sections.isEmpty)
              const ListTile(title: Text('No custom rows yet'), subtitle: Text('Use Add Home row to create one.')),
            for (final section in _sections)
              ListTile(
                leading: const Icon(Symbols.tune_rounded),
                title: Text(section.title),
                subtitle: Text(_label(section.kind)),
                onTap: () => _editSection(section),
                trailing: IconButton(
                  icon: const Icon(Symbols.delete_outline_rounded),
                  tooltip: 'Remove row',
                  onPressed: () => _deleteSection(section),
                ),
              ),
            ListTile(
              leading: const Icon(Symbols.add_rounded),
              title: const Text('Add Home row'),
              subtitle: const Text('Choose a category; the new row is added to Organizer automatically'),
              onTap: _addSection,
            ),
          ],
        ),
      ],
    );
  }
}

/// One row's display data for the real Organizer list (drag handle +
/// up/down/X) — see [_HomeLayoutSettingsScreenState._organizerRows].
class _OrganizerRow {
  const _OrganizerRow({
    required this.token,
    required this.label,
    required this.supportsHero,
    required this.heroStyle,
    required this.heroTrailerPreview,
  });
  final String token;
  final String label;
  final bool supportsHero;
  final bool heroStyle;
  final bool heroTrailerPreview;
}

String _label(HomeSectionKind kind) => switch (kind) {
  HomeSectionKind.recentlyAdded => 'Recently Added',
  HomeSectionKind.recentlyReleased => 'Recently Released',
  HomeSectionKind.movieCollections => 'Movie Collections',
  HomeSectionKind.showCollections => 'Show Collections',
};

class _HomeSectionDialog extends StatefulWidget {
  const _HomeSectionDialog({required this.libraries, required this.collections, this.initial});
  final List<MediaLibrary> libraries;
  final List<MediaItem> collections;
  final HomeSectionConfig? initial;
  @override
  State<_HomeSectionDialog> createState() => _HomeSectionDialogState();
}

class _HomeSectionDialogState extends State<_HomeSectionDialog> {
  final _title = TextEditingController();
  HomeSectionKind _kind = HomeSectionKind.recentlyAdded;
  final _selected = <String>{};
  final _selectedCollections = <String>{};
  bool _allCollections = true;
  bool _showInLibraryRecommended = true;
  bool _showOnHome = true;
  bool _heroStyle = false;
  bool _heroTrailerPreview = false;

  /// Mirrors [HomeSectionConfig.supportsHeroStyle] against the dialog's
  /// live, not-yet-saved selection — a collection row only qualifies once
  /// it resolves to exactly one collection's actual contents.
  bool get _supportsHeroStyle =>
      (_kind != HomeSectionKind.movieCollections && _kind != HomeSectionKind.showCollections) ||
      (!_allCollections && _selectedCollections.length == 1);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _kind = initial.kind;
      _selected.addAll(initial.libraryKeys);
      _selectedCollections.addAll(initial.collectionKeys);
      _allCollections = initial.collectionKeys.isEmpty;
      _showInLibraryRecommended = initial.showInLibraryRecommended;
      _showOnHome = initial.showOnHome;
      _heroStyle = initial.heroStyle;
      _heroTrailerPreview = initial.heroTrailerPreview;
    }
  }

  List<MediaItem> _filteredCollections() => widget.collections.where((item) {
    final isMovie = widget.libraries.any(
      (library) => library.globalKey == item.libraryGlobalKey && library.kind == MediaKind.movie,
    );
    final isShow = widget.libraries.any(
      (library) => library.globalKey == item.libraryGlobalKey && library.kind == MediaKind.show,
    );
    final matchesKind = _kind == HomeSectionKind.movieCollections ? isMovie : isShow;
    return matchesKind && (_selected.isEmpty || _selected.contains(item.libraryGlobalKey));
  }).toList();

  @override
  Widget build(BuildContext context) => AlertDialog(
    // Nudged above dead-center: on a shorter window the dialog's natural
    // content height (title + dropdown + both checklists) can exceed the
    // available height even after the cap below, and centering split the
    // overflow evenly above/below — the bottom half (Save/Cancel) was the
    // one actually getting clipped against the window edge.
    alignment: const Alignment(0, -0.3),
    title: Text(widget.initial == null ? 'Add Home row' : 'Edit Home row'),
    content: SizedBox(
      width: 560,
      // A shrink-wrapped ListView sizes to its content with no ceiling, so a
      // dialog with many libraries/collections checked could grow taller
      // than the window and get clipped at the bottom instead of scrolling.
      // Capping the height here and dropping shrinkWrap makes the list
      // scroll internally once it would otherwise overflow.
      height: (MediaQuery.sizeOf(context).height - 160).clamp(200, 640),
      child: ListView(
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Row title'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HomeSectionKind>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'Content'),
            items: [
              for (final kind in HomeSectionKind.values) DropdownMenuItem(value: kind, child: Text(_label(kind))),
            ],
            onChanged: (value) => setState(() {
              _kind = value ?? _kind;
              _selectedCollections.clear();
              _allCollections = true;
            }),
          ),
          const SizedBox(height: 12),
          const Text('Show this row in:'),
          CheckboxListTile(
            dense: true,
            title: const Text('Library Recommended'),
            value: _showInLibraryRecommended,
            onChanged: (value) => setState(() => _showInLibraryRecommended = value ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: const Text('Home'),
            value: _showOnHome,
            onChanged: (value) => setState(() => _showOnHome = value ?? false),
          ),
          const SizedBox(height: 12),
          const Text('Hero card'),
          CheckboxListTile(
            dense: true,
            title: const Text('Render as a hero card'),
            subtitle: Text(
              _supportsHeroStyle
                  ? 'Shows as one full-width rotating card instead of a poster shelf.'
                  : 'Only available when this row resolves to a single collection\'s '
                        'actual titles — with more than one collection selected there is '
                        'no single title to rotate through.',
            ),
            value: _supportsHeroStyle && _heroStyle,
            onChanged: !_supportsHeroStyle
                ? null
                : (value) => setState(() {
                    _heroStyle = value ?? false;
                    if (!_heroStyle) _heroTrailerPreview = false;
                  }),
          ),
          CheckboxListTile(
            dense: true,
            title: const Text('Play trailer preview'),
            subtitle: const Text('Plays a trailer or scene clip in the hero card instead of static art.'),
            value: _supportsHeroStyle && _heroStyle && _heroTrailerPreview,
            onChanged: (!_supportsHeroStyle || !_heroStyle)
                ? null
                : (value) => setState(() => _heroTrailerPreview = value ?? false),
          ),
          const SizedBox(height: 12),
          const Text('Libraries (leave all unchecked to include every library)'),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'Every library checked here is merged into this one row.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          for (final library in widget.libraries)
            CheckboxListTile(
              dense: true,
              value: _selected.contains(library.globalKey),
              title: Text(library.title),
              subtitle: Text(library.serverName ?? ''),
              onChanged: (value) => setState(
                () => value == true ? _selected.add(library.globalKey) : _selected.remove(library.globalKey),
              ),
            ),
          if (_kind == HomeSectionKind.movieCollections || _kind == HomeSectionKind.showCollections) ...[
            const SizedBox(height: 12),
            Text(
              _kind == HomeSectionKind.movieCollections
                  ? 'Movie collections (leave all unchecked for every selected library)'
                  : 'Show collections (leave all unchecked for every selected library)',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'If exactly one collection matches, its titles show directly in the '
                "row. If more than one matches, each collection shows as a single "
                'poster — tap it to open that collection.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('All collections'),
              value: _allCollections,
              onChanged: (value) => setState(() {
                _allCollections = value ?? true;
                if (_allCollections) _selectedCollections.clear();
              }),
            ),
            for (final collection in _filteredCollections())
              CheckboxListTile(
                dense: true,
                value: !_allCollections && _selectedCollections.contains(collection.globalKey),
                title: Text(collection.title ?? 'Untitled collection'),
                subtitle: Text(collection.libraryTitle ?? ''),
                onChanged: _allCollections
                    ? null
                    : (value) => setState(
                        () => value == true
                            ? _selectedCollections.add(collection.globalKey)
                            : _selectedCollections.remove(collection.globalKey),
                      ),
              ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          final title = _title.text.trim().isEmpty ? _label(_kind) : _title.text.trim();
          Navigator.pop(
            context,
            HomeSectionConfig(
              // Reuse the original id on an edit: it's also the row's identity
              // in home_row_order (as 'custom:<id>'), so minting a fresh one
              // here would orphan the saved position and the row would land
              // at the back of the Organizer instead of staying put.
              id: widget.initial?.id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              kind: _kind,
              libraryKeys: _selected.toList(),
              collectionKeys: _selectedCollections.toList(),
              showInLibraryRecommended: _showInLibraryRecommended,
              showOnHome: _showOnHome,
              // Re-checked here, not just at the checkbox: the collection
              // selection can change after hero/trailer were toggled on,
              // and a stale true must never survive into the saved config.
              heroStyle: _supportsHeroStyle && _heroStyle,
              heroTrailerPreview: _supportsHeroStyle && _heroStyle && _heroTrailerPreview,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
