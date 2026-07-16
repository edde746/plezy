import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_text_field.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../mixins/debounced_media_search.dart';
import '../services/catalog/catalog_source.dart';
import '../utils/focus_utils.dart';
import '../utils/platform_detector.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/pill_input_decoration.dart';
import 'libraries/state_messages.dart';

/// Free-text search of one catalog source (the Explore tab's active source),
/// pushed from the Explore app bar. Results are catalog items rendered
/// through the synthesized-MediaItem card stack, so taps land on the catalog
/// detail screen with library matching, exactly like the Explore rows.
class CatalogSearchScreen extends StatefulWidget {
  final CatalogSource source;

  const CatalogSearchScreen({super.key, required this.source});

  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> with DebouncedMediaSearch {
  final _clearFocusNode = FocusNode(debugLabel: 'CatalogSearch.clear');
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
  void dispose() {
    _clearFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    searchController.clear();
    searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final sourceName = widget.source.displayName;
    return FocusedScrollScaffold(
      title: Text(t.explore.searchHint(source: sourceName)),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                FocusableTextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onNavigateDown: searchResults.isNotEmpty && !isSearching ? firstResultFocusNode.requestFocus : null,
                  onNavigateRight: searchController.text.isNotEmpty ? _clearFocusNode.requestFocus : null,
                  onEditingComplete: PlatformDetector.isTV() ? handleSearchSubmit : null,
                  decoration: pillInputDecoration(
                    context,
                    hintText: t.explore.searchHint(source: sourceName),
                    prefixIcon: const AppIcon(Symbols.search_rounded, fill: 1),
                    suffixIcon: searchController.text.isNotEmpty ? const SizedBox(width: 48) : null,
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  FocusableButton(
                    focusNode: _clearFocusNode,
                    onPressed: _clearSearch,
                    onNavigateLeft: searchFocusNode.requestFocus,
                    onNavigateDown: searchResults.isNotEmpty && !isSearching ? firstResultFocusNode.requestFocus : null,
                    autoScroll: false,
                    child: IconButton(icon: const AppIcon(Symbols.clear_rounded, fill: 1), onPressed: _clearSearch),
                  ),
              ],
            ),
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
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = searchResults[index];
            return FocusableMediaCard(
              key: Key(item.globalKey),
              item: item,
              forceListMode: true,
              disableScale: true,
              focusNode: index == 0 ? firstResultFocusNode : null,
              onNavigateUp: index == 0 ? searchFocusNode.requestFocus : null,
            );
          },
          childCount: searchResults.length,
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
        ),
      ),
    );
  }
}
