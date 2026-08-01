import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../mixins/debounced_media_search.dart';
import '../services/catalog/catalog_source.dart';
import '../utils/focus_utils.dart';
import '../utils/platform_detector.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/search_input_field.dart';
import 'libraries/state_messages.dart';

/// Free-text search of one catalog source (the Explore tab's active source),
/// pushed from the Explore TV toolbar — touch/pointer builds search inline on
/// the Explore page instead. Results are catalog items rendered through the
/// synthesized-MediaItem card stack, so taps land on the catalog detail
/// screen with library matching, exactly like the Explore rows.
class CatalogSearchScreen extends StatefulWidget {
  final CatalogSource source;

  const CatalogSearchScreen({super.key, required this.source});

  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> with DebouncedMediaSearch {
  @override
  String get searchDebugLabel => 'CatalogSearch';

  @override
  Future<List<MediaItem>> performSearchQuery(String query) async {
    final items = await widget.source.search(query);
    return [for (final item in items) item.toMediaItem()];
  }

  @override
  void initState() {
    super.initState();
    FocusUtils.requestFocusAfterBuild(this, searchFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final sourceName = widget.source.displayName;
    return FocusedScrollScaffold(
      title: Text(t.explore.searchHint(source: sourceName)),
      slivers: [
        SliverToBoxAdapter(
          child: SearchInputField(
            controller: searchController,
            focusNode: searchFocusNode,
            debugLabel: searchDebugLabel,
            hintText: t.explore.searchHint(source: sourceName),
            onNavigateDown: searchResults.isNotEmpty && !isSearching ? firstResultFocusNode.requestFocus : null,
            onEditingComplete: PlatformDetector.isTV() ? handleSearchSubmit : null,
          ),
        ),
        if (isSearching)
          LoadingIndicatorBox.sliver
        else if (!hasSearched)
          SliverFillRemaining(
            child: StateMessageWidget(
              message: t.explore.searchPrompt(source: sourceName),
              icon: Symbols.search_rounded,
              iconSize: 80,
            ),
          )
        else if (lastSearchFailed)
          SliverFillRemaining(
            child: StateMessageWidget(message: t.explore.searchFailed, icon: Symbols.error_rounded, iconSize: 80),
          )
        else if (searchResults.isEmpty)
          SliverFillRemaining(
            child: StateMessageWidget(
              message: t.explore.searchEmpty(query: lastSearchedQuery),
              icon: Symbols.search_off_rounded,
              iconSize: 80,
            ),
          )
        else
          _buildResultsList(),
      ],
    );
  }

  Widget _buildResultsList() {
    return buildResultsSliver((context, index) {
      final item = searchResults[index];
      return FocusableMediaCard(
        key: Key(item.globalKey),
        item: item,
        forceListMode: true,
        disableScale: true,
        focusNode: index == 0 ? firstResultFocusNode : null,
        onNavigateUp: index == 0 ? searchFocusNode.requestFocus : null,
      );
    });
  }
}
