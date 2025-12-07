import 'package:flutter/material.dart';

/// A horizontal scrollable section with focus memory and auto-scroll support.
///
/// Use this for rows of focusable items (like HubSection) to:
/// - Remember the last focused item when navigating away
/// - Auto-scroll to keep the focused item visible
/// - Provide smooth focus traversal within the section
///
/// Example:
/// ```dart
/// FocusableScrollSection(
///   sectionId: 'recently_added',
///   itemCount: items.length,
///   itemBuilder: (context, index, focusNode) {
///     return FocusableWrapper(
///       focusNode: focusNode,
///       onSelect: () => navigateTo(items[index]),
///       child: MediaCard(item: items[index]),
///     );
///   },
/// )
/// ```
class FocusableScrollSection extends StatefulWidget {
  /// Unique identifier for focus memory persistence.
  final String sectionId;

  /// Number of items in the section.
  final int itemCount;

  /// Builder for each focusable item.
  /// The [focusNode] should be passed to a FocusableWrapper or Focus widget.
  final Widget Function(BuildContext context, int index, FocusNode focusNode)
      itemBuilder;

  /// Optional scroll controller for external control.
  final ScrollController? scrollController;

  /// Whether to remember the last focused item.
  final bool rememberFocus;

  /// Padding around the scrollable area.
  final EdgeInsets padding;

  /// Spacing between items.
  final double itemSpacing;

  /// Called when the section gains focus.
  final VoidCallback? onSectionFocused;

  /// Called when the section loses focus.
  final VoidCallback? onSectionBlurred;

  const FocusableScrollSection({
    super.key,
    required this.sectionId,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollController,
    this.rememberFocus = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    this.itemSpacing = 4.0,
    this.onSectionFocused,
    this.onSectionBlurred,
  });

  @override
  State<FocusableScrollSection> createState() => _FocusableScrollSectionState();
}

class _FocusableScrollSectionState extends State<FocusableScrollSection> {
  late ScrollController _scrollController;
  bool _ownsController = false;
  late FocusScopeNode _focusScopeNode;

  final List<FocusNode> _itemFocusNodes = [];
  int _lastFocusedIndex = 0;
  bool _hasFocus = false;

  // Global focus memory (shared across sections)
  static final Map<String, int> _focusMemory = {};

  @override
  void initState() {
    super.initState();
    _initScrollController();
    _initFocusScopeNode();
    _createFocusNodes();
    _restoreFocusMemory();
  }

  void _initScrollController() {
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
  }

  void _initFocusScopeNode() {
    _focusScopeNode = FocusScopeNode(
      debugLabel: 'FocusableScrollSection_${widget.sectionId}',
    );
  }

  void _createFocusNodes() {
    _disposeFocusNodes();
    for (int i = 0; i < widget.itemCount; i++) {
      final node = FocusNode(
        debugLabel: '${widget.sectionId}_item_$i',
      );
      node.addListener(() => _handleItemFocusChange(i, node.hasFocus));
      _itemFocusNodes.add(node);
    }
  }

  void _disposeFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes.clear();
  }

  void _restoreFocusMemory() {
    if (widget.rememberFocus) {
      _lastFocusedIndex = _focusMemory[widget.sectionId] ?? 0;
      _lastFocusedIndex = _lastFocusedIndex.clamp(0, widget.itemCount - 1);
    }
  }

  void _saveFocusMemory() {
    if (widget.rememberFocus) {
      _focusMemory[widget.sectionId] = _lastFocusedIndex;
    }
  }

  @override
  void didUpdateWidget(FocusableScrollSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle scroll controller changes
    if (widget.scrollController != oldWidget.scrollController) {
      if (_ownsController) {
        _scrollController.dispose();
      }
      _initScrollController();
    }

    // Handle item count changes
    if (widget.itemCount != oldWidget.itemCount) {
      _createFocusNodes();
      _lastFocusedIndex = _lastFocusedIndex.clamp(0, widget.itemCount - 1);
    }
  }

  @override
  void dispose() {
    _saveFocusMemory();
    _disposeFocusNodes();
    _focusScopeNode.dispose();
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleItemFocusChange(int index, bool hasFocus) {
    if (hasFocus) {
      _lastFocusedIndex = index;
      _saveFocusMemory();
      _scrollItemIntoView(index);

      if (!_hasFocus) {
        _hasFocus = true;
        widget.onSectionFocused?.call();
      }
    } else {
      // Check if section lost focus entirely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stillHasFocus =
            _itemFocusNodes.any((node) => node.hasFocus);
        if (_hasFocus && !stillHasFocus) {
          _hasFocus = false;
          widget.onSectionBlurred?.call();
        }
      });
    }
  }

  void _scrollItemIntoView(int index) {
    if (!_scrollController.hasClients) return;

    // We'll use ensureVisible which is more reliable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _itemFocusNodes.length) return;

      final focusNode = _itemFocusNodes[index];
      final context = focusNode.context;
      if (context == null) return;

      Scrollable.ensureVisible(
        context,
        alignment: 0.5, // Center the item
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Request focus to the last focused item (or first item).
  void requestFocus() {
    if (_itemFocusNodes.isEmpty) return;

    final index = _lastFocusedIndex.clamp(0, _itemFocusNodes.length - 1);
    _itemFocusNodes[index].requestFocus();
  }

  /// Request focus to a specific item by index.
  void requestFocusAt(int index) {
    if (index < 0 || index >= _itemFocusNodes.length) return;
    _itemFocusNodes[index].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }

    return FocusScope(
      node: _focusScopeNode,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            final focusNode = _itemFocusNodes[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.itemSpacing / 2),
              child: widget.itemBuilder(context, index, focusNode),
            );
          },
        ),
      ),
    );
  }
}

/// Static methods for managing focus memory across sections.
class FocusableScrollSectionMemory {
  FocusableScrollSectionMemory._();

  /// Clear focus memory for a specific section.
  static void clear(String sectionId) {
    _FocusableScrollSectionState._focusMemory.remove(sectionId);
  }

  /// Clear all focus memory.
  static void clearAll() {
    _FocusableScrollSectionState._focusMemory.clear();
  }

  /// Get the last focused index for a section.
  static int? get(String sectionId) {
    return _FocusableScrollSectionState._focusMemory[sectionId];
  }

  /// Set the focus memory for a section.
  static void set(String sectionId, int index) {
    _FocusableScrollSectionState._focusMemory[sectionId] = index;
  }
}
