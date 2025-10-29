import 'package:flutter/material.dart';
import '../client/plex_client.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../models/plex_filter.dart';
import '../models/plex_user_profile.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';
import '../services/storage_service.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../theme/theme_helper.dart';

class LibrariesScreen extends StatefulWidget {
  final PlexClient client;
  final PlexUserProfile? userProfile;

  const LibrariesScreen({super.key, required this.client, this.userProfile});

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen>
    with Refreshable, ItemUpdatable {
  @override
  PlexClient get client => widget.client;

  List<PlexLibrary> _libraries = [];
  List<PlexMetadata> _items = [];
  List<PlexFilter> _filters = [];
  bool _isLoadingLibraries = true;
  bool _isLoadingItems = false;
  String? _errorMessage;
  int _selectedLibraryIndex = 0;
  Map<String, String> _selectedFilters = {};
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    setState(() {
      _isLoadingLibraries = true;
      _errorMessage = null;
    });

    try {
      final libraries = await widget.client.getLibraries();
      setState(() {
        _libraries = libraries;
        _isLoadingLibraries = false;
      });

      if (libraries.isNotEmpty) {
        // Load saved preferences
        final storage = await StorageService.getInstance();
        final savedIndex = storage.getSelectedLibraryIndex();
        final savedFilters = storage.getLibraryFilters();

        // Use saved index if valid, otherwise default to 0
        final indexToLoad =
            (savedIndex != null && savedIndex < libraries.length)
            ? savedIndex
            : 0;

        // Restore filters BEFORE loading content
        if (savedFilters.isNotEmpty) {
          _selectedFilters = Map.from(savedFilters);
        }

        _loadLibraryContent(indexToLoad);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load libraries: $e';
        _isLoadingLibraries = false;
      });
    }
  }

  Future<void> _loadLibraryContent(int index) async {
    if (index < 0 || index >= _libraries.length) return;

    final isChangingLibrary = !_isInitialLoad && _selectedLibraryIndex != index;

    setState(() {
      _selectedLibraryIndex = index;
      _isLoadingItems = true;
      _errorMessage = null;
      // Only clear filters when explicitly changing library (not on initial load)
      if (isChangingLibrary) {
        _selectedFilters.clear();
      }
    });

    // Mark that initial load is complete
    if (_isInitialLoad) {
      _isInitialLoad = false;
    }

    // Save selected library index
    final storage = await StorageService.getInstance();
    await storage.saveSelectedLibraryIndex(index);

    // Clear filters in storage when changing library
    if (isChangingLibrary) {
      await storage.saveLibraryFilters({});
    }

    try {
      // Load filters for the new library
      _loadFilters(index);

      // Load content
      final items = await widget.client.getLibraryContent(
        _libraries[index].key,
        filters: _selectedFilters,
      );
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load library content: $e';
        _isLoadingItems = false;
      });
    }
  }

  Future<void> _loadFilters(int index) async {
    if (index < 0 || index >= _libraries.length) return;

    try {
      final filters = await widget.client.getLibraryFilters(
        _libraries[index].key,
      );
      setState(() {
        _filters = filters;
      });
    } catch (e) {
      setState(() {
        _filters = [];
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoadingItems = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.client.getLibraryContent(
        _libraries[_selectedLibraryIndex].key,
        filters: _selectedFilters,
      );
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load library content: $e';
        _isLoadingItems = false;
      });
    }
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _items[index] = updatedMetadata;
    }
  }

  // Public method to refresh content
  @override
  void refresh() {
    if (_libraries.isNotEmpty) {
      _applyFilters();
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FiltersBottomSheet(
        filters: _filters,
        selectedFilters: _selectedFilters,
        client: widget.client,
        onFiltersChanged: (filters) async {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });

          // Save filters to storage
          final storage = await StorageService.getInstance();
          await storage.saveLibraryFilters(filters);

          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          DesktopSliverAppBar(
            title: const Text('Libraries'),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              if (_filters.isNotEmpty)
                IconButton(
                  icon: Badge(
                    label: Text('${_selectedFilters.length}'),
                    isLabelVisible: _selectedFilters.isNotEmpty,
                    child: const Icon(Icons.filter_list),
                  ),
                  onPressed: _showFiltersBottomSheet,
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadLibraryContent(_selectedLibraryIndex),
              ),
            ],
          ),
          if (_isLoadingLibraries)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _libraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLibraries,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_libraries.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('No libraries found'),
                  ],
                ),
              ),
            )
          else ...[
            // Library selector chips
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_libraries.length, (index) {
                      final library = _libraries[index];
                      final isSelected = index == _selectedLibraryIndex;
                      final t = tokens(context);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getLibraryIcon(library.type),
                                size: 16,
                                color: isSelected ? t.bg : t.text,
                              ),
                              const SizedBox(width: 6),
                              Text(library.title),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _loadLibraryContent(index);
                            }
                          },
                          backgroundColor: t.surface,
                          selectedColor: t.text,
                          side: BorderSide(color: t.outline),
                          labelStyle: TextStyle(
                            color: isSelected ? t.bg : t.text,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Content grid
            if (_isLoadingItems)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            _loadLibraryContent(_selectedLibraryIndex),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('This library is empty'),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    childAspectRatio: 2 / 3.3,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _items[index];
                    return MediaCard(
                      key: Key(item.ratingKey),
                      client: widget.client,
                      item: item,
                      onRefresh: updateItem,
                      userProfile: widget.userProfile,
                    );
                  }, childCount: _items.length),
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getLibraryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'artist':
        return Icons.music_note;
      case 'photo':
        return Icons.photo;
      default:
        return Icons.folder;
    }
  }
}

class _FiltersBottomSheet extends StatefulWidget {
  final List<PlexFilter> filters;
  final Map<String, String> selectedFilters;
  final PlexClient client;
  final Function(Map<String, String>) onFiltersChanged;

  const _FiltersBottomSheet({
    required this.filters,
    required this.selectedFilters,
    required this.client,
    required this.onFiltersChanged,
  });

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  PlexFilter? _currentFilter;
  List<PlexFilterValue> _filterValues = [];
  bool _isLoadingValues = false;
  final Map<String, String> _tempSelectedFilters = {};
  final Map<String, String> _filterDisplayNames = {}; // Cache for display names
  late List<PlexFilter> _sortedFilters;

  @override
  void initState() {
    super.initState();
    _tempSelectedFilters.addAll(widget.selectedFilters);
    _sortFilters();
  }

  void _sortFilters() {
    // Separate boolean filters (toggles) from regular filters
    final booleanFilters = widget.filters
        .where((f) => f.filterType == 'boolean')
        .toList();
    final regularFilters = widget.filters
        .where((f) => f.filterType != 'boolean')
        .toList();

    // Combine with boolean filters first
    _sortedFilters = [...booleanFilters, ...regularFilters];
  }

  bool _isBooleanFilter(PlexFilter filter) {
    return filter.filterType == 'boolean';
  }

  Future<void> _loadFilterValues(PlexFilter filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoadingValues = true;
    });

    try {
      final values = await widget.client.getFilterValues(filter.key);
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
    } catch (e) {
      setState(() {
        _filterValues = [];
        _isLoadingValues = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _currentFilter = null;
      _filterValues = [];
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempSelectedFilters);
    Navigator.pop(context);
  }

  String _extractFilterValue(String key, String filterName) {
    if (key.contains('?')) {
      final queryStart = key.indexOf('?');
      final queryString = key.substring(queryStart + 1);
      final params = Uri.splitQueryString(queryString);
      return params[filterName] ?? key;
    } else if (key.startsWith('/')) {
      return key.split('/').last;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        if (_currentFilter != null) {
          // Show filter options view
          return Column(
            children: [
              // Header with back button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    AppBarBackButton(
                      style: BackButtonStyle.plain,
                      onPressed: _goBack,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentFilter!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Filter options list
              if (_isLoadingValues)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filterValues.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = !_tempSelectedFilters.containsKey(
                          _currentFilter!.filter,
                        );
                        return ListTile(
                          title: const Text('All'),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _tempSelectedFilters.remove(
                                _currentFilter!.filter,
                              );
                            });
                            _applyFilters();
                          },
                        );
                      }

                      final value = _filterValues[index - 1];
                      final filterValue = _extractFilterValue(
                        value.key,
                        _currentFilter!.filter,
                      );
                      final isSelected =
                          _tempSelectedFilters[_currentFilter!.filter] ==
                          filterValue;

                      return ListTile(
                        title: Text(value.title),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _tempSelectedFilters[_currentFilter!.filter] =
                                filterValue;
                            // Cache the display name for this filter value
                            _filterDisplayNames['${_currentFilter!.filter}:$filterValue'] =
                                value.title;
                          });
                          _applyFilters();
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        }

        // Show main filters view
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_tempSelectedFilters.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _tempSelectedFilters.clear();
                        });
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // All Filters (boolean toggles first, then regular filters)
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _sortedFilters.length,
                itemBuilder: (context, index) {
                  final filter = _sortedFilters[index];

                  // Handle boolean filters as switches (unwatched, inProgress, unmatched, hdr, etc.)
                  if (_isBooleanFilter(filter)) {
                    final isActive =
                        _tempSelectedFilters.containsKey(filter.filter) &&
                        _tempSelectedFilters[filter.filter] == '1';
                    return SwitchListTile(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _tempSelectedFilters[filter.filter] = '1';
                          } else {
                            _tempSelectedFilters.remove(filter.filter);
                          }
                        });
                        _applyFilters();
                      },
                      title: Text(filter.title),
                    );
                  }

                  // Regular navigable filters - show selected value instead of checkmark
                  final selectedValue = _tempSelectedFilters[filter.filter];
                  String? displayValue;
                  if (selectedValue != null) {
                    // Try to get the cached display name, fall back to the value itself
                    displayValue =
                        _filterDisplayNames['${filter.filter}:$selectedValue'] ??
                        selectedValue;
                  }

                  return ListTile(
                    title: Text(filter.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (displayValue != null)
                          Flexible(
                            child: Text(
                              displayValue,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (displayValue != null) const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _loadFilterValues(filter),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
