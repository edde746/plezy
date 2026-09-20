import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/dpad_navigator.dart';
import '../../i18n/strings.g.dart';
import '../../media/downloads_filter.dart';
import '../../media/downloads_sort_options.dart';
import '../../media/ids.dart';
import '../../media/library_query.dart';
import '../../media/media_filter.dart';
import '../../media/media_item.dart';
import '../../media/media_item_sort.dart';
import '../../media/media_sort.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/anchored_option_menus.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/options_chips_bar.dart';
import '../../widgets/overlay_sheet.dart';
import '../libraries/filters_bottom_sheet.dart';
import '../libraries/library_browse_grouping.dart';
import '../libraries/sort_bottom_sheet.dart';

/// The surface a downloads content tab exposes to the screen's app bar: the
/// mobile options sheet and the D-pad entry point into the tab's top chrome
/// (chips bar on desktop/TV, first content item on mobile).
abstract interface class DownloadsOptionsTab {
  /// Open the mobile options sheet (Grouping / Filters / Sort rows).
  void showOptionsSheet();

  /// Focus the tab's top chrome: the first options chip where the chips bar
  /// exists, otherwise the first content item.
  void focusTopContent();
}

/// Shared grouping/sort/filter state and options surfaces for the downloads
/// screen's content tabs (TV Shows, Movies, Music).
///
/// Mirrors the library browse UX split (`library_browse_tab.dart`): mobile
/// gets a single options sheet whose rows push nested pages; desktop and TV
/// get an [OptionsChipsBar] whose chips open anchored menus on desktop and
/// the same sheet pages on TV. Selections persist per tab through
/// [StorageService] under [optionsSectionId].
mixin DownloadsTabOptionsMixin<T extends StatefulWidget> on State<T> implements DownloadsOptionsTab {
  /// StorageService section id — `downloads:tv`, `downloads:movies`, or
  /// `downloads:music`.
  String get optionsSectionId;

  /// Grouping values this tab offers, in sheet order. The first entry is the
  /// default when nothing is persisted.
  List<String> get groupingOptions;

  /// Focus node handed to the first focusable content item.
  late final FocusNode firstItemFocusNode = FocusNode(debugLabel: 'downloads_${optionsSectionId}_firstItem');

  // Chip focus nodes — created here so D-pad handoffs can target them; the
  // anchor keys locate each chip's render box for desktop popup menus.
  late final FocusNode _groupingChipFocusNode = FocusNode(debugLabel: 'downloads_${optionsSectionId}_groupingChip');
  late final FocusNode _filtersChipFocusNode = FocusNode(debugLabel: 'downloads_${optionsSectionId}_filtersChip');
  late final FocusNode _sortChipFocusNode = FocusNode(debugLabel: 'downloads_${optionsSectionId}_sortChip');
  final GlobalKey _groupingChipKey = GlobalKey();
  final GlobalKey _filtersChipKey = GlobalKey();
  final GlobalKey _sortChipKey = GlobalKey();

  String _grouping = browseGroupingShows;
  MediaSort? _sort;
  bool _sortDescending = false;
  List<LibraryFilter> _filters = const [];

  String get selectedGrouping => _grouping;

  /// Whether any filter is currently active — drives the filtered-empty
  /// state (reset affordance instead of the bare "no downloads" message).
  bool get hasActiveFilters => _filters.isNotEmpty;

  /// Clear every active filter (the filtered-empty state's reset action).
  void resetDownloadsFilters() => unawaited(_applyFilters(const []));

  /// Call from [State.initState]: seeds the default grouping and kicks off the
  /// persisted-selection restore.
  void initDownloadsOptions() {
    _grouping = groupingOptions.first;
    unawaited(_restoreOptions());
  }

  /// Call from [State.dispose].
  void disposeDownloadsOptions() {
    firstItemFocusNode.dispose();
    _groupingChipFocusNode.dispose();
    _filtersChipFocusNode.dispose();
    _sortChipFocusNode.dispose();
  }

  /// Restore grouping/sort/filters persisted under [optionsSectionId].
  /// Filter keys are whitelisted to the ones the downloads UI offers. Stored
  /// values are kept unconditionally: validating a `library` value against
  /// [DownloadProvider.downloadedLibraries] at init time races the provider's
  /// own load and would silently drop a valid filter on cold start — a stale
  /// value instead just matches nothing until the user clears it.
  Future<void> _restoreOptions() async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;

    final savedGrouping = storage.getLibraryGrouping(optionsSectionId);
    final savedSort = storage.getLibrarySort(optionsSectionId);
    // Strict sectioned read: the legacy-global fallback would leak a stale
    // library browse filter (e.g. `unwatched`) into every downloads tab.
    final savedFilters = storage.getLibraryFilters(sectionId: optionsSectionId, legacyGlobalFallback: false);

    final restoredFilters = savedFilters
        .where((clause) => clause.field == downloadFilterUnwatched || clause.field == downloadFilterLibrary)
        .toList();

    final sortOptions = downloadSortOptions(includeDownloadFields: true);
    MediaSort? restoredSort;
    var restoredDescending = false;
    final savedSortKey = savedSort?['key'];
    if (savedSortKey is String) {
      for (final option in sortOptions) {
        if (option.key == savedSortKey) {
          restoredSort = option;
          restoredDescending = savedSort?['descending'] as bool? ?? false;
          break;
        }
      }
    }

    setState(() {
      if (savedGrouping != null && groupingOptions.contains(savedGrouping)) {
        _grouping = savedGrouping;
      }
      _sort = restoredSort;
      _sortDescending = restoredDescending;
      _filters = restoredFilters;
    });
  }

  /// Filter then sort [items] with the tab's current selection. Sort extras
  /// resolve download bookkeeping (timestamp, byte size) once per call —
  /// containers aggregate over their downloaded leaves.
  List<MediaItem> applyDownloadsOptions(DownloadProvider provider, List<MediaItem> items) {
    // Remembered so the editor's "Show N" footer can count a pending edit
    // without the tab having to hand its item list to the sheet.
    _countableItems = items;
    final filtered = _filters.isEmpty
        ? List.of(items)
        : items.where((item) => downloadItemMatchesFilters(item, _filters)).toList();
    final sort = _sort;
    if (sort == null) return filtered;
    final extras = provider.downloadSortExtras(filtered);
    filtered.sort(
      mediaItemSortComparator(
        sort.key,
        descending: _sortDescending,
        extras: (item) => extras[item.globalKey] ?? (downloadedAt: null, totalBytes: null),
      ),
    );
    return filtered;
  }

  String _groupingLabel(String grouping) {
    return switch (grouping) {
      browseGroupingMovies => t.libraries.groupings.movies,
      browseGroupingShows => t.libraries.groupings.shows,
      browseGroupingSeasons => t.libraries.groupings.seasons,
      browseGroupingEpisodes => t.libraries.groupings.episodes,
      browseGroupingAlbums => t.libraries.groupings.albums,
      browseGroupingTracks => t.libraries.groupings.tracks,
      browseGroupingLibrary => t.downloads.groupings.library,
      _ => t.libraries.groupings.all,
    };
  }

  /// Items the tab last rendered, used only for the pending-selection count.
  List<MediaItem> _countableItems = const [];

  List<MediaFilter> get _filterDefinitions => [
    MediaFilter(
      filter: downloadFilterUnwatched,
      filterType: MediaFilterType.boolean,
      key: downloadFilterUnwatched,
      title: t.libraries.filterCategories.unwatched,
      type: 'filter',
    ),
    MediaFilter(
      filter: downloadFilterLibrary,
      filterType: MediaFilterType.tag,
      key: downloadFilterLibrary,
      title: t.downloads.groupings.library,
      type: 'filter',
    ),
  ];

  /// Downloads filtering runs in memory, so the count is exact and free.
  Future<int?> _countFilteredDownloads(List<LibraryFilter> clauses) async {
    if (clauses.isEmpty) return _countableItems.length;
    return _countableItems.where((item) => downloadItemMatchesFilters(item, clauses)).length;
  }

  /// Local filter-value loader: the `library` category lists the libraries
  /// that actually hold downloads, suffixed with the server name when more
  /// than one server contributes.
  Future<List<MediaFilterValue>> _loadFilterValues(MediaFilter filter) async {
    if (!mounted || filter.filter != downloadFilterLibrary) return const [];
    final provider = context.read<DownloadProvider>();
    final serverManager = context.read<MultiServerProvider>().serverManager;
    final libraries = provider.downloadedLibraries;
    final multiServer = libraries.map((library) => library.serverId).toSet().length > 1;
    return [
      for (final library in libraries)
        () {
          // Unstamped buckets carry the server name as their title; resolve a
          // live display name when the metadata lacks one (serverDisplayName
          // falls back to the raw id — detect that), and skip the suffix so
          // they don't render as "Server (Server)".
          final serverName = serverManager.serverDisplayName(ServerId(library.serverId));
          final title = library.libraryId == null && serverName != library.serverId ? serverName : library.title;
          return MediaFilterValue(
            key: downloadLibraryFilterValue(library.serverId, library.libraryId),
            title: multiServer && title != serverName ? '$title ($serverName)' : title,
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------------
  // Options sheet (mobile rows, TV chip targets)
  // ---------------------------------------------------------------------

  /// No drag handle here either: the header's close button is this session's
  /// single dismissal affordance, on the options list and on the grouping,
  /// filter and sort pages pushed onto it.
  @override
  void showOptionsSheet() {
    if (!mounted) return;
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    OverlaySheetController.of(context).show(builder: (sheetContext) => _buildOptionsSheet(sheetContext));
  }

  Widget _buildOptionsSheet(BuildContext sheetContext) {
    final controller = OverlaySheetController.of(sheetContext);
    return BottomSheetPageScaffold(
      title: t.downloads.options,
      icon: Symbols.tune_rounded,
      child: ListView(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          FocusableListTile(
            leading: const AppIcon(Symbols.category_rounded, fill: 1),
            title: Text(t.libraries.groupings.title),
            subtitle: Text(_groupingLabel(_grouping)),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showGroupingOptionsPage(controller),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.filter_alt_rounded, fill: 1),
            title: Text(_filters.isEmpty ? t.libraries.filters : t.libraries.filtersWithCount(count: _filters.length)),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showFiltersOptionsPage(controller),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.sort_rounded, fill: 1),
            title: Text(t.libraries.sort),
            subtitle: _sort == null ? null : Text(_sort!.title),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSortOptionsPage(controller),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Grouping
  // ---------------------------------------------------------------------

  void _showGroupingOptions() {
    final anchorRect = useAnchoredChipMenus(context) ? chipAnchorRect(_groupingChipKey) : null;
    if (anchorRect != null) {
      showAnchoredSelectionMenu<String>(
        context,
        anchorRect: anchorRect,
        options: groupingOptions,
        labelOf: _groupingLabel,
        selected: _grouping,
      ).then(_handleGroupingSelection);
      return;
    }
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    final controller = OverlaySheetController.of(context);
    controller
        .show<String>(builder: (_) => _buildGroupingSheet(onSelected: (value) => controller.close(value)))
        .then(_handleGroupingSelection);
  }

  void _showGroupingOptionsPage(OverlaySheetController controller) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    controller
        .push<String>(
          builder: (_) =>
              _buildGroupingSheet(onBack: () => controller.pop(), onSelected: (value) => controller.close(value)),
        )
        .then(_handleGroupingSelection);
  }

  Widget _buildGroupingSheet({required ValueChanged<String> onSelected, VoidCallback? onBack}) {
    return BottomSheetPageScaffold(
      title: t.libraries.groupings.title,
      icon: Symbols.category_rounded,
      onBack: onBack,
      child: ListView(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final grouping in groupingOptions)
            FocusableListTile(
              key: ValueKey(grouping),
              dense: true,
              leading: AppIcon(
                _grouping == grouping ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                fill: 1,
              ),
              title: Text(_groupingLabel(grouping)),
              onTap: () => onSelected(grouping),
            ),
        ],
      ),
    );
  }

  void _handleGroupingSelection(String? value) {
    if (!mounted || value == null || value == _grouping || !groupingOptions.contains(value)) return;
    setState(() {
      _grouping = value;
    });
    StorageService.getInstance().then((storage) {
      storage.saveLibraryGrouping(optionsSectionId, value);
    });
  }

  // ---------------------------------------------------------------------
  // Sort
  // ---------------------------------------------------------------------

  void _showSortOptions() {
    final anchorRect = useAnchoredChipMenus(context) ? chipAnchorRect(_sortChipKey) : null;
    if (anchorRect != null) {
      unawaited(_showSortMenu(anchorRect));
      return;
    }
    final controller = OverlaySheetController.of(context);
    _openSortSheet((builder) => controller.show(builder: builder));
  }

  void _showSortOptionsPage(OverlaySheetController controller) {
    _openSortSheet((builder) => controller.push(builder: builder), onBack: () => controller.pop());
  }

  void _openSortSheet(Future<dynamic> Function(WidgetBuilder builder) open, {VoidCallback? onBack}) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    // Track pending state in locals so the callbacks don't trigger setState
    // while the sheet is open (which would steal focus).
    MediaSort? pendingSort = _sort;
    var pendingDescending = _sortDescending;
    var pendingCleared = false;
    open(
      (context) => SortBottomSheet(
        sortOptions: downloadSortOptions(includeDownloadFields: true),
        selectedSort: _sort,
        isSortDescending: _sortDescending,
        onBack: onBack,
        onSortChanged: (sort, descending) {
          pendingSort = sort;
          pendingDescending = descending;
          pendingCleared = false;
        },
        onClear: () {
          pendingSort = null;
          pendingDescending = false;
          pendingCleared = true;
        },
      ),
    ).then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applySortSelection(sort: pendingSort, descending: pendingDescending, cleared: pendingCleared);
      });
    });
  }

  /// Desktop counterpart of [SortBottomSheet]: selecting the active field
  /// toggles its direction; selecting another applies its default direction.
  Future<void> _showSortMenu(Rect anchorRect) async {
    final result = await showAnchoredSortMenu(
      context,
      anchorRect: anchorRect,
      sortOptions: downloadSortOptions(includeDownloadFields: true),
      selectedSort: _sort,
      isSortDescending: _sortDescending,
      clearLabel: t.common.clear,
    );
    if (!mounted || result == null) return;
    _applySortSelection(sort: result.sort, descending: result.descending, cleared: result.cleared);
  }

  void _applySortSelection({required MediaSort? sort, required bool descending, required bool cleared}) {
    if (cleared) {
      setState(() {
        _sort = null;
        _sortDescending = false;
      });
      // Persist the clear — otherwise the stored sort resurrects on the
      // next restore (tab switch, cold start).
      StorageService.getInstance().then((storage) {
        storage.clearLibrarySort(optionsSectionId);
      });
    } else if (sort != null && (sort.key != _sort?.key || descending != _sortDescending)) {
      setState(() {
        _sort = sort;
        _sortDescending = descending;
      });
      StorageService.getInstance().then((storage) {
        storage.saveLibrarySort(optionsSectionId, sort.key, descending: descending);
      });
    }
  }

  // ---------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------

  void _showFiltersOptions() {
    final anchorRect = useAnchoredChipMenus(context) ? chipAnchorRect(_filtersChipKey) : null;
    if (anchorRect != null) {
      unawaited(_showFiltersMenu(anchorRect));
      return;
    }
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    final controller = OverlaySheetController.of(context);
    _openFiltersSheet((builder) => controller.show(builder: builder));
  }

  void _showFiltersOptionsPage(OverlaySheetController controller) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    _openFiltersSheet((builder) => controller.push(builder: builder), onBack: () => controller.pop());
  }

  /// Stage edits and commit once on dismissal — same contract as the library
  /// browse tab, so both consumers of the editor behave alike.
  void _openFiltersSheet(Future<dynamic> Function(WidgetBuilder builder) open, {VoidCallback? onBack}) {
    var pending = _filters;
    open((_) => _buildFiltersSheet(onChanged: (filters) => pending = filters, onBack: onBack)).then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_applyFilters(pending));
      });
    });
  }

  Widget _buildFiltersSheet({required ValueChanged<List<LibraryFilter>> onChanged, VoidCallback? onBack}) {
    return FiltersBottomSheet(
      filters: _filterDefinitions,
      selectedFilters: _filters,
      // Cache keys only — the downloads filters resolve locally, so the
      // server/library identity just namespaces the sheet's display-name cache.
      serverId: 'downloads',
      libraryKey: optionsSectionId,
      loadFilterValues: _loadFilterValues,
      countLoader: _countFilteredDownloads,
      onBack: onBack,
      onFiltersChanged: onChanged,
    );
  }

  /// Desktop counterpart of the filter sheet: the same editor in a popup
  /// anchored to the chip, committing on dismissal.
  Future<void> _showFiltersMenu(Rect anchorRect) async {
    var pending = _filters;
    await showAnchoredFilterPanel(
      context,
      anchorRect: anchorRect,
      filters: _filterDefinitions,
      selectedFilters: _filters,
      onFiltersChanged: (filters) => pending = filters,
      // Cache keys only — the downloads filters resolve locally, so the
      // server/library identity just namespaces the value-name cache.
      serverId: 'downloads',
      libraryKey: optionsSectionId,
      loadFilterValues: _loadFilterValues,
      countLoader: _countFilteredDownloads,
    );
    if (!mounted) return;
    await _applyFilters(pending);
  }

  Future<void> _applyFilters(List<LibraryFilter> filters) async {
    if (_filters.length == filters.length && _filters.asMap().entries.every((e) => filters[e.key] == e.value)) {
      return;
    }
    setState(() {
      _filters = List<LibraryFilter>.unmodifiable(filters);
    });
    final storage = await StorageService.getInstance();
    await storage.saveLibraryFilters(filters, sectionId: optionsSectionId);
  }

  // ---------------------------------------------------------------------
  // Chips bar (desktop + TV)
  // ---------------------------------------------------------------------

  /// Whether this tab renders the inline chips bar — everywhere but mobile,
  /// which uses the app-bar options action instead.
  bool get _usesChipsBar => !PlatformDetector.isMobile(context);

  /// The chips bar, hosted in a floating [SliverPersistentHeader] by the tab.
  Widget buildOptionsChipsBar() {
    return OptionsChipsBar(
      chips: [
        OptionsChipDescriptor(
          anchorKey: _groupingChipKey,
          focusNode: _groupingChipFocusNode,
          icon: Symbols.category_rounded,
          label: _groupingLabel(_grouping),
          onPressed: _showGroupingOptions,
        ),
        OptionsChipDescriptor(
          anchorKey: _filtersChipKey,
          focusNode: _filtersChipFocusNode,
          icon: Symbols.filter_alt_rounded,
          label: _filters.isEmpty ? t.libraries.filters : t.libraries.filtersWithCount(count: _filters.length),
          onPressed: _showFiltersOptions,
        ),
        OptionsChipDescriptor(
          anchorKey: _sortChipKey,
          focusNode: _sortChipFocusNode,
          icon: Symbols.sort_rounded,
          label: _sort?.title ?? t.libraries.sort,
          onPressed: _showSortOptions,
        ),
      ],
      onNavigateDown: _navigateToContent,
      onNavigateUp: navigateToTabBar,
      onNavigateLeftEdge: navigateToSidebar,
      onBack: navigateToTabBar,
    );
  }

  /// Sliver hosting the chips bar where the platform split calls for it;
  /// returns nothing on mobile.
  Widget optionsChipsBarSliver() {
    if (!_usesChipsBar) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPersistentHeader(
      floating: true,
      pinned: false,
      delegate: OptionsChipsBarDelegate(builder: (_) => buildOptionsChipsBar()),
    );
  }

  /// Focus the first content item — the DOWN target of the chips bar.
  void _navigateToContent() {
    // Drop the chip's focus first so the item's request isn't racing the
    // chip's still-held primary focus (see library_browse_tab._navigateToGrid).
    if (FocusManager.instance.primaryFocus == _groupingChipFocusNode ||
        FocusManager.instance.primaryFocus == _filtersChipFocusNode ||
        FocusManager.instance.primaryFocus == _sortChipFocusNode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    firstItemFocusNode.requestFocus();
  }

  /// UP from the first content row: land on the chips bar where it exists,
  /// else escape to the tab bar.
  void navigateToChips() {
    if (!_usesChipsBar) {
      navigateToTabBar();
      return;
    }
    _groupingChipFocusNode.requestFocus();
  }

  @override
  void focusTopContent() {
    if (_usesChipsBar) {
      _groupingChipFocusNode.requestFocus();
    } else {
      firstItemFocusNode.requestFocus();
    }
  }

  /// BACK/UP escape to the screen's tab bar — supplied by the host widget.
  void navigateToTabBar();

  /// LEFT edge escape to the sidebar — supplied by the host widget.
  void navigateToSidebar();
}

/// One `serverId:libraryId` bucket of downloaded items for the `library`
/// grouping. [title] is the library name, the server name for downloads
/// recorded without library metadata, or the unknown-library fallback.
/// [subtitle] disambiguates same-named libraries across servers.
class DownloadsLibrarySection {
  final String key;
  final String title;
  final String? subtitle;
  final List<MediaItem> items;

  const DownloadsLibrarySection({required this.key, required this.title, this.subtitle, required this.items});
}

/// Bucket [items] into library sections ordered by title. Items with no
/// library attribution fall into their server's `serverId:` bucket, titled by
/// the server name (or the unknown-library fallback when even that is
/// missing). [serverNameOf] resolves a display name for a server id.
List<DownloadsLibrarySection> bucketDownloadsByLibrary(
  List<MediaItem> items, {
  required String? Function(String serverId) serverNameOf,
}) {
  final buckets = <String, List<MediaItem>>{};
  for (final item in items) {
    buckets.putIfAbsent(downloadLibraryFilterValue(item.serverId, item.libraryId), () => []).add(item);
  }

  final multiServer = items.map((item) => item.serverId).whereType<String>().toSet().length > 1;
  final sections = <DownloadsLibrarySection>[
    for (final entry in buckets.entries)
      () {
        final bucketItems = entry.value;
        final first = bucketItems.first;
        String? libraryTitle;
        for (final item in bucketItems) {
          libraryTitle ??= item.libraryTitle;
        }
        final serverName = first.serverId == null ? null : (first.serverName ?? serverNameOf(first.serverId!));
        final title = libraryTitle ?? serverName ?? t.downloads.unknownLibrary;
        return DownloadsLibrarySection(
          key: entry.key,
          title: title,
          subtitle: multiServer && libraryTitle != null ? serverName : null,
          items: bucketItems,
        );
      }(),
  ];
  sections.sort((a, b) {
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byTitle != 0) return byTitle;
    return a.key.compareTo(b.key);
  });
  return sections;
}

/// Header for one [DownloadsLibrarySection] — the music tab's album-header
/// visual pattern (48px rounded tile + title + optional subtitle) with a
/// library glyph in place of artwork.
class DownloadsLibrarySectionHeader extends StatelessWidget {
  final DownloadsLibrarySection section;

  const DownloadsLibrarySectionHeader({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final subtitle = section.subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: tk.surface, borderRadius: BorderRadius.circular(tk.radiusSm)),
            child: AppIcon(Symbols.video_library_rounded, fill: 1, size: 24, color: tk.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(section.title, style: textTheme.titleSmall, maxLines: 1, overflow: .ellipsis),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(color: tk.textMuted),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
