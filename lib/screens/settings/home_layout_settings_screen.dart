import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
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
    show
        continueWatchingHeroOverrideKey,
        continueWatchingRowToken,
        libraryContinueWatchingHeroOverrideKey,
        nextUpHeroOverrideKey,
        nextUpRowToken;
import '../../services/home_layout_sync_service.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'tv_row_organizer_screen.dart';

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
  bool _nextUpOnHome = true;

  /// Reordering starts unlocked every time this screen opens, per user
  /// request 2026-09-10 (revised same day — the first cut of this defaulted
  /// locked, inverted from what was actually wanted). A lock icon toggles
  /// this per list: open padlock = unlocked (can drag), closed padlock =
  /// locked (a whole-row click does nothing, so Hero/Library
  /// checkboxes can be tapped without risking an accidental drag). `true`
  /// here is the Organizer list; per-library lists get their own entry in
  /// [_libraryReorderUnlocked] instead, since each library's own row list
  /// is independent — both default to unlocked (`?? true` at each read
  /// site) the same way this field's own literal default does.
  bool _organizerReorderUnlocked = true;
  final Map<String, bool> _libraryReorderUnlocked = {};

  Future<void> _setContinueWatchingOnHome(bool value) async {
    final libraryProvider = context.read<LibrariesProvider>();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.continueWatchingOnHome, value);
    final libraries = libraryProvider.libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(
      _rowOrder,
      libraries,
      _sections,
      _managedRows,
      continueWatchingOnHome: value,
      nextUpOnHome: _nextUpOnHome,
    );
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) {
      setState(() {
        _continueWatchingOnHome = value;
        _rowOrder = order;
      });
    }
  }

  Future<void> _setNextUpOnHome(bool value) async {
    final libraryProvider = context.read<LibrariesProvider>();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.nextUpOnHome, value);
    final libraries = libraryProvider.libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(
      _rowOrder,
      libraries,
      _sections,
      _managedRows,
      continueWatchingOnHome: _continueWatchingOnHome,
      nextUpOnHome: value,
    );
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) {
      setState(() {
        _nextUpOnHome = value;
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
    if (!override.heroStyle && override.heroAutoSlide) {
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
    HomeLayoutSyncService.instance.appliedRevision.addListener(_onLayoutSynced);
  }

  @override
  void dispose() {
    HomeLayoutSyncService.instance.appliedRevision.removeListener(_onLayoutSynced);
    super.dispose();
  }

  /// Another device's change arrived while this screen is open.
  void _onLayoutSynced() {
    if (mounted) unawaited(_load());
  }

  Future<void> _load() async {
    final multiServer = context.read<MultiServerProvider>();
    final libraryProvider = context.read<LibrariesProvider>();
    final settings = await SettingsService.getInstance();
    final sections = List.of(settings.read(SettingsService.homeSections));
    final rowOrder = List.of(settings.read(SettingsService.homeRowOrder));
    List<MediaItem> collections = const [];
    try {
      collections = (await multiServer.aggregationService.getCollectionsFromAllServers()).collections;
    } catch (_) {
      // The editor remains usable when a server is temporarily offline.
    }
    final managedRows = <String, List<PlexManagedHub>>{};

    if (!libraryProvider.hasLibraries) await libraryProvider.loadLibraries();
    final plexLibraries = libraryProvider.libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    await Future.wait(
      plexLibraries.map((library) async {
        try {
          final client = multiServer.getPlexClientForServer(ServerId(library.serverId!));
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
      nextUpOnHome: settings.read(SettingsService.nextUpOnHome),
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
      _nextUpOnHome = settings.read(SettingsService.nextUpOnHome);
      _loaded = true;
    });
  }

  /// Restores Home's hero rendering to stock Plezy — the single rotating
  /// carousel at the top of the page this add-on's per-row hero rendering
  /// replaced — without touching row order or which rows exist (2026-09-12
  /// user request: "reset it to original plezy like if my pr wasnt there
  /// except the order part"). Turns every row's own heroStyle off (custom
  /// rows here, Continue Watching and other managed hubs via
  /// managedHubHeroOverrides) and flips SettingsService.showHeroSection
  /// back on, which is what discover_screen.dart's showLegacyHero actually
  /// gates on.
  Future<void> _resetHeroToStock() async {
    final settings = await SettingsService.getInstance();
    // Order matters: each of these settings has its own DiscoverProvider
    // listener that fires an unawaited reload on write (_onHomeLayoutChanged).
    // Writing managedHubHeroOverrides/showHeroSection *before* the final
    // _save() means _save()'s own reload is the last one triggered and so
    // the one whose result actually sticks — reflecting every change here,
    // not a reload that raced in using the not-yet-cleared override (which
    // showed as a still-hero row alongside the newly-restored legacy
    // carousel — "2 hero cards", reported 2026-09-12).
    await settings.write(SettingsService.managedHubHeroOverrides, const {});
    await settings.write(SettingsService.showHeroSection, true);
    await _save(_sections.map((s) => s.copyWith(heroStyle: false)).toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.homeLayout.resetToast)));
    }
  }

  Future<void> _confirmResetHeroToStock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.homeLayout.resetHeroTitle),
        content: Text(t.homeLayout.resetHeroBody),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(context, false), label: t.common.cancel),
          DialogActionButton(onPressed: () => Navigator.pop(context, true), label: t.common.reset),
        ],
      ),
    );
    if (confirmed == true) await _resetHeroToStock();
  }

  Future<void> _save(List<HomeSectionConfig> sections) async {
    final libraryProvider = context.read<LibrariesProvider>();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeSections, sections);
    final libraries = libraryProvider.libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(
      settings.read(SettingsService.homeRowOrder),
      libraries,
      sections,
      _managedRows,
      continueWatchingOnHome: _continueWatchingOnHome,
      nextUpOnHome: _nextUpOnHome,
    );
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) {
      setState(() {
        _sections = sections;
        _rowOrder = order;
      });
    }
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
        title: Text(t.homeLayout.removeRowTitle),
        content: Text(t.homeLayout.removeRowBody(title: '"${section.title}"')),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext, false), label: t.common.cancel),
          DialogActionButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            label: t.common.delete,
            isPrimary: true,
          ),
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
    required bool nextUpOnHome,
  }) {
    final available = <String>[
      // Continue Watching defaults to the front of the list (matching its
      // old fixed-first position) so an untouched install's saved order
      // stays effectively unchanged the first time this runs after upgrade.
      if (continueWatchingOnHome) continueWatchingRowToken,
      if (nextUpOnHome) nextUpRowToken,
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

  /// Keeps the row controls beside their title when there's room, then gives
  /// them a full-width line on narrow screens or when text is enlarged. The
  /// multi-checkbox controls otherwise squeeze the title and subtitle into a
  /// very narrow column on phones.
  Widget _responsiveControlTile({Widget? leading, required Widget title, Widget? subtitle, required Widget controls}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final enlargedText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final stackControls = constraints.maxWidth < 520 || enlargedText;
        if (!stackControls) {
          return ListTile(dense: true, leading: leading, title: title, subtitle: subtitle, trailing: controls);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(dense: true, leading: leading, title: title, subtitle: subtitle),
            Padding(
              padding: EdgeInsetsDirectional.only(start: leading == null ? 16 : 56, end: 16, bottom: 8),
              child: controls,
            ),
          ],
        );
      },
    );
  }

  /// A tappable padlock — open means unlocked (rows can be dragged by
  /// clicking anywhere on them), closed means locked (a whole-row click
  /// does nothing, so the Hero/Library checkboxes underneath can be
  /// tapped without risking an accidental drag). Starts open every time
  /// this screen loads — not persisted.
  Widget _reorderLockTile({required bool unlocked, required ValueChanged<bool> onChanged}) {
    return ListTile(
      dense: true,
      leading: AppIcon(unlocked ? Symbols.lock_open_rounded : Symbols.lock_rounded),
      title: Text(unlocked ? t.homeLayout.reorderingUnlocked : t.homeLayout.reorderingLocked),
      subtitle: Text(unlocked ? t.homeLayout.rowsCanBeDragged : t.homeLayout.tapLockToDrag),
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
    if (token == nextUpRowToken) {
      await _setNextUpOnHome(false);
      return;
    }
    final ref = _resolvePlexRowRef(token);
    if (ref == null) return;
    await _setManagedVisibility(ref.$1, ref.$2, home: false);
  }

  /// Row data for the actual Organizer list (drag handle + up/down/X) — the
  /// single place that reflects what's really on Home and in what order, so
  /// Hero belongs here rather than only inside each library's own
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
            label: t.homeLayout.customRowLabel(title: section.title),
            supportsHero: section.supportsHeroStyle,
            heroStyle: section.heroStyle,
            heroAutoSlide: section.heroAutoSlide,
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
            label: t.homeLayout.continueWatching,
            supportsHero: true,
            heroStyle: override.heroStyle,
            heroAutoSlide: override.heroAutoSlide,
          ),
        );
        continue;
      }
      if (token == nextUpRowToken) {
        if (!_nextUpOnHome) continue;
        final override = _heroOverrideForKey(nextUpHeroOverrideKey);
        rows.add(
          _OrganizerRow(
            token: token,
            label: t.discover.nextUp,
            supportsHero: true,
            heroStyle: override.heroStyle,
            heroAutoSlide: override.heroAutoSlide,
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
          label: t.homeLayout.libraryHubLabel(library: library.title, hub: hub.title),
          supportsHero: true,
          heroStyle: override.heroStyle,
          heroAutoSlide: override.heroAutoSlide,
        ),
      );
    }
    return rows;
  }

  Future<void> _setOrganizerRowHero(String token, {bool? heroStyle, bool? heroAutoSlide}) async {
    if (token.startsWith('custom:')) {
      final id = token.substring('custom:'.length);
      final section = _sections.where((s) => s.id == id).firstOrNull;
      if (section == null) return;
      final updated = section.copyWith(heroStyle: heroStyle, heroAutoSlide: heroAutoSlide);
      await _save(_sections.map((s) => s.id == id ? updated : s).toList());
      return;
    }
    if (token == continueWatchingRowToken) {
      final override = _heroOverrideForKey(continueWatchingHeroOverrideKey);
      await _setHeroOverrideForKey(
        continueWatchingHeroOverrideKey,
        override.copyWith(heroStyle: heroStyle, heroAutoSlide: heroAutoSlide),
      );
      return;
    }
    final ref = _resolvePlexRowRef(token);
    if (ref == null) return;
    final override = _heroOverrideFor(ref.$1, ref.$2);
    await _setHeroOverride(ref.$1, ref.$2, override.copyWith(heroStyle: heroStyle, heroAutoSlide: heroAutoSlide));
  }

  /// TV only: one tile that opens [TvRowOrganizerScreen], where every row's
  /// options sit inline and d-pad Select picks a row up to move it. Replaces
  /// the old per-row popup menus.
  Widget _tvOrganizerTile({
    required String title,
    required String subtitle,
    required List<TvOrganizerEntry> Function() entries,
    Future<void> Function(List<String> keys)? onReorder,
  }) {
    return FocusableListTile(
      leading: const AppIcon(Symbols.reorder_rounded),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TvRowOrganizerScreen(title: title, entries: entries, onReorder: onReorder),
          ),
        );
        if (mounted) setState(() {});
      },
    );
  }

  List<TvOrganizerEntry> _tvHomeEntries() => [
    for (final row in _organizerRows())
      TvOrganizerEntry(
        key: row.token,
        title: row.label,
        actions: [
          TvOrganizerAction(
            label: t.homeLayout.hero,
            icon: Symbols.view_carousel_rounded,
            value: row.supportsHero && row.heroStyle,
            enabled: row.supportsHero,
            onPressed: () => _setOrganizerRowHero(row.token, heroStyle: !row.heroStyle),
          ),
          TvOrganizerAction(
            label: t.homeLayout.autoSlide,
            icon: Symbols.slideshow_rounded,
            value: row.heroStyle && row.heroAutoSlide,
            enabled: row.heroStyle,
            onPressed: () => _setOrganizerRowHero(row.token, heroAutoSlide: !row.heroAutoSlide),
          ),
          TvOrganizerAction(
            label: row.token == continueWatchingRowToken ? t.homeLayout.hide : t.homeLayout.remove,
            icon: row.token == continueWatchingRowToken ? Symbols.visibility_off_rounded : Symbols.close_rounded,
            destructive: true,
            onPressed: () => _removeRowFromHome(row.token),
          ),
        ],
      ),
  ];

  /// Rewrites the visible tokens of [_rowOrder] in [visibleTokens] order,
  /// leaving hidden tokens (disabled custom rows, Continue Watching while
  /// off) in their existing slots, same rule as [_reorderOrganizerRow].
  Future<void> _applyOrganizerOrder(List<String> visibleTokens) async {
    final visible = visibleTokens.toSet();
    var next = 0;
    final order = [
      for (final token in _rowOrder)
        if (visible.contains(token) && next < visibleTokens.length) visibleTokens[next++] else token,
      ...visibleTokens.where((token) => !_rowOrder.contains(token)),
    ];
    setState(() => _rowOrder = order);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeRowOrder, order);
  }

  static const _tvLibraryContinueWatchingKey = '__continue_watching__';

  List<TvOrganizerEntry> _tvLibraryEntries(MediaLibrary library) {
    final cwVisible = !SettingsService.instance
        .read(SettingsService.libraryContinueWatchingHidden)
        .contains(library.globalKey);
    final cwKey = libraryContinueWatchingHeroOverrideKey(library.globalKey);
    final cwOverride = _heroOverrideForKey(cwKey);
    final cwHero = cwVisible && cwOverride.heroStyle;
    return [
      // Pinned first (not movable), matching the PC list. Its disabled Home
      // button keeps the columns lined up with the rows below.
      TvOrganizerEntry(
        key: _tvLibraryContinueWatchingKey,
        title: t.homeLayout.continueWatching,
        subtitle: t.homeLayout.libraryResumeRow,
        movable: false,
        actions: [
          TvOrganizerAction(
            label: t.homeLayout.library,
            icon: Symbols.video_library_rounded,
            value: cwVisible,
            onPressed: () => _setLibraryContinueWatchingVisible(library, !cwVisible),
          ),
          TvOrganizerAction(
            label: t.homeLayout.home,
            icon: Symbols.home_rounded,
            enabled: false,
            onPressed: () async {},
          ),
          TvOrganizerAction(
            label: t.homeLayout.hero,
            icon: Symbols.view_carousel_rounded,
            value: cwHero,
            enabled: cwVisible,
            onPressed: () => _setHeroOverrideForKey(cwKey, cwOverride.copyWith(heroStyle: !cwHero)),
          ),
          TvOrganizerAction(
            label: t.homeLayout.autoSlide,
            icon: Symbols.slideshow_rounded,
            value: cwHero && cwOverride.heroAutoSlide,
            enabled: cwHero,
            onPressed: () =>
                _setHeroOverrideForKey(cwKey, cwOverride.copyWith(heroAutoSlide: !cwOverride.heroAutoSlide)),
          ),
        ],
      ),
      for (final row in _orderedManagedRows(library)) _tvLibraryEntry(library, row),
    ];
  }

  TvOrganizerEntry _tvLibraryEntry(MediaLibrary library, PlexManagedHub row) {
    final override = _heroOverrideFor(library, row);
    final canHero = row.promotedToRecommended || row.promotedToOwnHome;
    final hero = canHero && override.heroStyle;
    return TvOrganizerEntry(
      key: row.identifier,
      title: row.title,
      actions: [
        TvOrganizerAction(
          label: t.homeLayout.library,
          icon: Symbols.video_library_rounded,
          value: row.promotedToRecommended,
          onPressed: () => _setManagedVisibility(library, row, recommended: !row.promotedToRecommended),
        ),
        TvOrganizerAction(
          label: t.homeLayout.home,
          icon: Symbols.home_rounded,
          value: row.promotedToOwnHome,
          onPressed: () => _setManagedVisibility(library, row, home: !row.promotedToOwnHome),
        ),
        TvOrganizerAction(
          label: t.homeLayout.hero,
          icon: Symbols.view_carousel_rounded,
          value: hero,
          enabled: canHero,
          onPressed: () => _setHeroOverride(library, row, override.copyWith(heroStyle: !hero)),
        ),
        TvOrganizerAction(
          label: t.homeLayout.autoSlide,
          icon: Symbols.slideshow_rounded,
          value: hero && override.heroAutoSlide,
          enabled: hero,
          onPressed: () => _setHeroOverride(library, row, override.copyWith(heroAutoSlide: !override.heroAutoSlide)),
        ),
        if (row.deletable)
          TvOrganizerAction(
            label: t.common.delete,
            icon: Symbols.delete_outline_rounded,
            destructive: true,
            confirmLabel: t.homeLayout.pressAgainToDelete,
            onPressed: () async {
              final client = context.read<MultiServerProvider>().getPlexClientForServer(ServerId(library.serverId!));
              if (client == null) return;
              await client.removeManagedHub(library.id, row.identifier);
              await _load();
            },
          ),
      ],
    );
  }

  Future<void> _applyLibraryOrder(MediaLibrary library, List<String> identifiers) async {
    final settings = await SettingsService.getInstance();
    final allOrders = Map<String, List<String>>.of(settings.read(SettingsService.libraryManagedRowOrder));
    allOrders[library.globalKey] = identifiers;
    await settings.write(SettingsService.libraryManagedRowOrder, allOrders);
    if (mounted) setState(() {});
  }

  /// Per-device switch for sharing the layout through the Plex account,
  /// plus the last sync result and a manual Sync now while it is on.
  Widget _syncGroup() {
    final sync = HomeLayoutSyncService.instance;
    final tv = PlatformDetector.usesTvHomeLayout();
    return SettingsGroup(
      title: t.homeLayout.sync,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: SettingsService.instance.listenable(SettingsService.homeLayoutSyncEnabled),
          builder: (context, enabled, _) {
            Future<void> toggle() async {
              await sync.setEnabled(!enabled);
              if (mounted) await _load();
            }

            final title = Text(t.homeLayout.syncAccountTitle);
            final subtitle = Text(enabled ? t.homeLayout.syncAccountOn : t.homeLayout.syncAccountOff);
            const leading = AppIcon(Symbols.devices_rounded);
            final tile = tv
                ? FocusableListTile(
                    leading: leading,
                    title: title,
                    subtitle: subtitle,
                    trailing: Switch(value: enabled, onChanged: (_) => toggle()),
                    onTap: toggle,
                  )
                : SwitchListTile(
                    secondary: leading,
                    title: title,
                    subtitle: subtitle,
                    value: enabled,
                    onChanged: (_) => toggle(),
                  );
            if (!enabled) return tile;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile,
                ValueListenableBuilder<String>(
                  valueListenable: sync.status,
                  builder: (context, status, _) {
                    Future<void> syncNow() async {
                      await sync.pull(force: true);
                      if (mounted) await _load();
                    }

                    final syncTitle = Text(t.homeLayout.syncNow);
                    final syncSubtitle = Text(status);
                    const syncLeading = AppIcon(Symbols.sync_rounded);
                    return tv
                        ? FocusableListTile(
                            leading: syncLeading,
                            title: syncTitle,
                            subtitle: syncSubtitle,
                            onTap: syncNow,
                          )
                        : ListTile(leading: syncLeading, title: syncTitle, subtitle: syncSubtitle, onTap: syncNow);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _plexManagerGroups() {
    final libraries = context.read<LibrariesProvider>().libraries.where(
      (library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null,
    );
    return [
      SettingsGroup(
        title: t.homeLayout.plexHomeManager,
        children: [
          ExpansionTile(
            initiallyExpanded: false,
            leading: const AppIcon(Symbols.sync_rounded),
            title: Text(t.homeLayout.managePlexRows),
            subtitle: Text(t.homeLayout.managePlexRowsDescription),
            children: [
              if (!_continueWatchingOnHome) _continueWatchingTile(),
              if (!_nextUpOnHome) _nextUpTile(),
              // TV: a single tile opening the d-pad organizer (see
              // _tvOrganizerTile). The drag list's inline checkboxes can't
              // take d-pad focus and dragging is impossible with a remote.
              if (_organizerRows().isNotEmpty && PlatformDetector.usesTvHomeLayout())
                _tvOrganizerTile(
                  title: t.homeLayout.organizeHomeRows,
                  subtitle: t.homeLayout.organizeHomeRowsDescription(n: _organizerRows().length),
                  entries: _tvHomeEntries,
                  onReorder: _applyOrganizerOrder,
                ),
              if (_organizerRows().isNotEmpty && !PlatformDetector.usesTvHomeLayout()) ...[
                _reorderLockTile(
                  unlocked: _organizerReorderUnlocked,
                  onChanged: (v) => setState(() => _organizerReorderUnlocked = v),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: _reorderOrganizerRow,
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
                          child: _responsiveControlTile(
                            leading: const AppIcon(Symbols.drag_indicator_rounded),
                            title: Text(indexed.$2.label),
                            controls: Wrap(
                              spacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Tooltip(
                                  message: indexed.$2.supportsHero
                                      ? t.homeLayout.renderAsHero
                                      : t.homeLayout.heroOnlySingleCollection,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: indexed.$2.supportsHero && indexed.$2.heroStyle,
                                        onChanged: !indexed.$2.supportsHero
                                            ? null
                                            : (v) => _setOrganizerRowHero(indexed.$2.token, heroStyle: v ?? false),
                                      ),
                                      Text(t.homeLayout.hero),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: indexed.$2.heroStyle
                                      ? t.homeLayout.autoSlideDescription
                                      : t.homeLayout.enableHeroFirst,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: indexed.$2.heroStyle && indexed.$2.heroAutoSlide,
                                        onChanged: !indexed.$2.heroStyle
                                            ? null
                                            : (v) => _setOrganizerRowHero(indexed.$2.token, heroAutoSlide: v ?? false),
                                      ),
                                      Text(t.homeLayout.autoSlide),
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
                                    message: t.homeLayout.showOnHome,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(value: true, onChanged: (v) => _setContinueWatchingOnHome(v ?? false)),
                                        Text(t.homeLayout.home),
                                      ],
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const AppIcon(Symbols.close_rounded),
                                    tooltip: t.homeLayout.removeFromHome,
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
              if (_organizerRows().isEmpty) ListTile(title: Text(t.homeLayout.selectRowsFirst)),
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
      leading: AppIcon(library.kind == MediaKind.show ? Symbols.tv_rounded : Symbols.movie_rounded),
      title: Text(library.title),
      subtitle: Text(t.homeLayout.plexManagedRows(n: rows.length)),
      children: [
        // Continue Watching isn't a PlexManagedHub — Plex itself has no
        // promote/demote concept for it — so it can't come from `rows`
        // like every other tile here. Shown first, matching how Home's own
        // Organizer always pins Continue Watching to the front too.
        if (PlatformDetector.usesTvHomeLayout())
          _tvOrganizerTile(
            title: t.homeLayout.organizeLibraryRows(library: library.title),
            subtitle: t.homeLayout.organizeLibraryRowsDescription(n: rows.length),
            entries: () => _tvLibraryEntries(library),
            onReorder: (keys) => _applyLibraryOrder(library, keys),
          )
        else
          _responsiveControlTile(
            title: Text(t.homeLayout.continueWatching),
            subtitle: Text(t.homeLayout.continueWatchingLibraryDescription),
            controls: Wrap(
              spacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: t.homeLayout.showInRecommended,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: continueWatchingVisible,
                        onChanged: (v) => _setLibraryContinueWatchingVisible(library, v ?? false),
                      ),
                      Text(t.homeLayout.library),
                    ],
                  ),
                ),
                Tooltip(
                  message: continueWatchingVisible ? t.homeLayout.renderAsHero : t.homeLayout.heroNeedsLibrary,
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
                      Text(t.homeLayout.hero),
                    ],
                  ),
                ),
                Tooltip(
                  message: continueWatchingVisible && continueWatchingOverride.heroStyle
                      ? t.homeLayout.autoSlideDescription
                      : t.homeLayout.enableHeroFirst,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value:
                            continueWatchingVisible &&
                            continueWatchingOverride.heroStyle &&
                            continueWatchingOverride.heroAutoSlide,
                        onChanged: !continueWatchingVisible || !continueWatchingOverride.heroStyle
                            ? null
                            : (v) => _setHeroOverrideForKey(
                                libraryContinueWatchingHeroOverrideKey(library.globalKey),
                                continueWatchingOverride.copyWith(heroAutoSlide: v ?? false),
                              ),
                      ),
                      Text(t.homeLayout.autoSlide),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (rows.isNotEmpty && !PlatformDetector.usesTvHomeLayout()) ...[
          _reorderLockTile(
            unlocked: _libraryReorderUnlocked[library.globalKey] ?? true,
            onChanged: (v) => setState(() => _libraryReorderUnlocked[library.globalKey] = v),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) => _reorderLibraryRow(library, rows, oldIndex, newIndex),
            children: [
              for (var index = 0; index < rows.length; index++)
                KeyedSubtree(
                  key: ValueKey(rows[index].identifier),
                  child: _maybeDraggable(
                    unlocked: _libraryReorderUnlocked[library.globalKey] ?? true,
                    index: index,
                    child: _responsiveControlTile(
                      leading: const AppIcon(Symbols.drag_indicator_rounded),
                      title: Text(rows[index].title),
                      subtitle: rows[index].deletable ? Text(t.homeLayout.customPlexRow) : null,
                      controls: Wrap(
                        spacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tooltip(
                            message: t.homeLayout.showInRecommended,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: rows[index].promotedToRecommended,
                                  onChanged: (v) => _setManagedVisibility(library, rows[index], recommended: v),
                                ),
                                Text(t.homeLayout.library),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: t.homeLayout.showOnHome,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: rows[index].promotedToOwnHome,
                                  onChanged: (v) => _setManagedVisibility(library, rows[index], home: v),
                                ),
                                Text(t.homeLayout.home),
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
                                message: canHero ? t.homeLayout.renderAsHero : t.homeLayout.heroNeedsSurface,
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
                                    Text(t.homeLayout.hero),
                                  ],
                                ),
                              );
                            },
                          ),
                          Builder(
                            builder: (context) {
                              final override = _heroOverrideFor(library, rows[index]);
                              final canHero = rows[index].promotedToRecommended || rows[index].promotedToOwnHome;
                              final canAutoSlide = canHero && override.heroStyle;
                              return Tooltip(
                                message: canAutoSlide
                                    ? t.homeLayout.autoSlideDescription
                                    : t.homeLayout.enableHeroFirst,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: canAutoSlide && override.heroAutoSlide,
                                      onChanged: !canAutoSlide
                                          ? null
                                          : (v) => _setHeroOverride(
                                              library,
                                              rows[index],
                                              override.copyWith(heroAutoSlide: v ?? false),
                                            ),
                                    ),
                                    Text(t.homeLayout.autoSlide),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (rows[index].deletable)
                            IconButton(
                              icon: const AppIcon(Symbols.delete_outline_rounded),
                              tooltip: t.homeLayout.removeHub,
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
        if (rows.isEmpty) ListTile(title: Text(t.homeLayout.noPlexRows)),
      ],
    );
  }

  /// Continue Watching used to be a fixed fixture always pinned ahead of
  /// every other Home row, with no way to remove or reorder it. This is now
  /// ONLY the add-back switch for when it's off (mirroring the "Add Home
  /// row" / per-library "Home" checkbox mechanisms every other row type
  /// already has) — once it's on, `_organizerRows()` already includes it as
  /// a normal token with its own Hero checkboxes and reordering, so
  /// this tile is hidden entirely rather than showing a second, lesser copy
  /// of the same row (the actual bug reported 2026-09-09: this tile used to
  /// render unconditionally, creating a Hero-less duplicate above
  /// the real entry, which could be scrolled to way down at wherever
  /// `home_row_order` had placed it).
  Widget _continueWatchingTile() {
    if (PlatformDetector.usesTvHomeLayout()) {
      return FocusableListTile(
        title: Text(t.homeLayout.continueWatching),
        subtitle: Text(t.homeLayout.continueWatchingHomeDescription),
        trailing: Switch(value: _continueWatchingOnHome, onChanged: _setContinueWatchingOnHome),
        onTap: () => _setContinueWatchingOnHome(!_continueWatchingOnHome),
      );
    }
    return ListTile(
      dense: true,
      title: Text(t.homeLayout.continueWatching),
      subtitle: Text(t.homeLayout.continueWatchingHomeDescription),
      trailing: Tooltip(
        message: t.homeLayout.showOnHome,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: _continueWatchingOnHome, onChanged: (v) => _setContinueWatchingOnHome(v ?? false)),
            Text(t.homeLayout.home),
          ],
        ),
      ),
    );
  }

  Widget _nextUpTile() {
    if (PlatformDetector.usesTvHomeLayout()) {
      return FocusableListTile(
        title: Text(t.discover.nextUp),
        subtitle: Text(t.homeLayout.nextUpHomeDescription),
        trailing: Switch(value: _nextUpOnHome, onChanged: _setNextUpOnHome),
        onTap: () => _setNextUpOnHome(!_nextUpOnHome),
      );
    }
    return ListTile(
      dense: true,
      title: Text(t.discover.nextUp),
      subtitle: Text(t.homeLayout.nextUpHomeDescription),
      trailing: Tooltip(
        message: t.homeLayout.showOnHome,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: _nextUpOnHome, onChanged: (v) => _setNextUpOnHome(v ?? false)),
            Text(t.homeLayout.home),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: Text(t.homeLayout.title),
      children: [
        _syncGroup(),
        if (_loaded) ..._plexManagerGroups(),
        SettingsGroup(
          title: t.homeLayout.heroCards,
          children: [
            SettingSegmentedTile<HeroCardTapAction>(
              pref: SettingsService.heroCardTapAction,
              icon: Symbols.touch_app_rounded,
              title: t.homeLayout.tapHeroCard,
              segments: [
                ButtonSegment(value: HeroCardTapAction.play, label: Text(t.common.play)),
                ButtonSegment(value: HeroCardTapAction.details, label: Text(t.homeLayout.openDetails)),
              ],
            ),
            SettingSwitchTile(
              pref: SettingsService.tvHeroPlayButtonFocus,
              icon: Symbols.settings_remote_rounded,
              title: t.homeLayout.tvPlayFocus,
              subtitle: t.homeLayout.tvPlayFocusDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.tvHeroWrapAround,
              icon: Symbols.repeat_rounded,
              title: t.homeLayout.tvWrap,
              subtitle: t.homeLayout.tvWrapDescription,
            ),
            if (PlatformDetector.usesTvHomeLayout())
              SettingSwitchTile(
                pref: SettingsService.tvHeroCastBubbles,
                icon: Symbols.groups_rounded,
                title: t.homeLayout.castOnHero,
                subtitle: t.homeLayout.castOnHeroDescription,
              ),
            ListTile(
              leading: const AppIcon(Symbols.settings_backup_restore_rounded),
              title: Text(t.homeLayout.resetHeroButton),
              subtitle: Text(t.homeLayout.resetHeroButtonDescription),
              onTap: _confirmResetHeroToStock,
            ),
          ],
        ),
        SettingsGroup(
          title: t.homeLayout.customRows,
          children: [
            if (!_loaded) ListTile(title: Text(t.homeLayout.loading)),
            if (_loaded && _sections.isEmpty)
              ListTile(title: Text(t.homeLayout.noCustomRows), subtitle: Text(t.homeLayout.addRowHint)),
            for (final section in _sections)
              ListTile(
                leading: const AppIcon(Symbols.tune_rounded),
                title: Text(section.title),
                subtitle: Text(_label(section.kind)),
                onTap: () => _editSection(section),
                trailing: IconButton(
                  icon: const AppIcon(Symbols.delete_outline_rounded),
                  tooltip: t.homeLayout.removeRow,
                  onPressed: () => _deleteSection(section),
                ),
              ),
            ListTile(
              leading: const AppIcon(Symbols.add_rounded),
              title: Text(t.homeLayout.addHomeRow),
              subtitle: Text(t.homeLayout.addHomeRowDescription),
              onTap: _addSection,
            ),
          ],
        ),
      ],
    );
  }
}

/// One entry in a TV row-actions menu (see `_tvActionRow`).
/// One row's display data for the real Organizer list (drag handle +
/// up/down/X) — see [_HomeLayoutSettingsScreenState._organizerRows].
class _OrganizerRow {
  const _OrganizerRow({
    required this.token,
    required this.label,
    required this.supportsHero,
    required this.heroStyle,
    required this.heroAutoSlide,
  });
  final String token;
  final String label;
  final bool supportsHero;
  final bool heroStyle;
  final bool heroAutoSlide;
}

String _label(HomeSectionKind kind) => switch (kind) {
  HomeSectionKind.recentlyAdded => t.homeLayout.recentlyAdded,
  HomeSectionKind.recentlyReleased => t.homeLayout.recentlyReleased,
  HomeSectionKind.movieCollections => t.homeLayout.movieCollections,
  HomeSectionKind.showCollections => t.homeLayout.showCollections,
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
  bool _heroAutoSlide = true;

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
      _heroAutoSlide = initial.heroAutoSlide;
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
    scrollable: true,
    // Nudged above dead-center: on a shorter window the dialog's natural
    // content height (title + dropdown + both checklists) can exceed the
    // available height even after the cap below, and centering split the
    // overflow evenly above/below — the bottom half (Save/Cancel) was the
    // one actually getting clipped against the window edge.
    alignment: const Alignment(0, -0.3),
    title: Text(widget.initial == null ? t.homeLayout.addHomeRow : t.homeLayout.editHomeRow),
    content: SizedBox(
      width: double.maxFinite,
      // A shrink-wrapped ListView sizes to its content with no ceiling, so a
      // dialog with many libraries/collections checked could grow taller
      // than the window and get clipped at the bottom instead of scrolling.
      // Capping the height here and dropping shrinkWrap makes the list
      // scroll internally once it would otherwise overflow.
      height:
          (MediaQuery.sizeOf(context).height -
                  MediaQuery.viewPaddingOf(context).vertical -
                  MediaQuery.viewInsetsOf(context).bottom -
                  160)
              .clamp(0.0, 640.0)
              .toDouble(),
      child: ListView(
        children: [
          FocusableTextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: t.homeLayout.rowTitle),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HomeSectionKind>(
            initialValue: _kind,
            decoration: InputDecoration(labelText: t.homeLayout.content),
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
          Text(t.homeLayout.showThisRowIn),
          CheckboxListTile(
            dense: true,
            title: Text(t.homeLayout.libraryRecommended),
            value: _showInLibraryRecommended,
            onChanged: (value) => setState(() => _showInLibraryRecommended = value ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: Text(t.homeLayout.home),
            value: _showOnHome,
            onChanged: (value) => setState(() => _showOnHome = value ?? false),
          ),
          const SizedBox(height: 12),
          Text(t.homeLayout.heroCard),
          CheckboxListTile(
            dense: true,
            title: Text(t.homeLayout.renderAsHero),
            subtitle: Text(
              _supportsHeroStyle ? t.homeLayout.heroCardDescription : t.homeLayout.heroUnavailableDescription,
            ),
            value: _supportsHeroStyle && _heroStyle,
            onChanged: !_supportsHeroStyle ? null : (value) => setState(() => _heroStyle = value ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: Text(t.homeLayout.autoSlide),
            subtitle: Text(t.homeLayout.autoSlideEditDescription),
            value: _supportsHeroStyle && _heroStyle && _heroAutoSlide,
            onChanged: (!_supportsHeroStyle || !_heroStyle)
                ? null
                : (value) => setState(() => _heroAutoSlide = value ?? false),
          ),
          const SizedBox(height: 12),
          Text(t.homeLayout.librariesSelection),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              t.homeLayout.librariesMergedDescription,
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
                  ? t.homeLayout.movieCollectionsSelection
                  : t.homeLayout.showCollectionsSelection,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                t.homeLayout.collectionRowsDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            CheckboxListTile(
              dense: true,
              title: Text(t.homeLayout.allCollections),
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
                title: Text(collection.title ?? t.homeLayout.untitledCollection),
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
      DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel),
      DialogActionButton(
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
              // selection can change after hero was toggled on,
              // and a stale true must never survive into the saved config.
              heroStyle: _supportsHeroStyle && _heroStyle,
              heroAutoSlide: _heroAutoSlide,
            ),
          );
        },
        label: t.common.save,
        isPrimary: true,
      ),
    ],
  );
}
