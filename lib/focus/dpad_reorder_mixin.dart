import 'package:flutter/material.dart';

import '../widgets/overlay_sheet.dart';
import 'back_press.dart';
import 'dpad_navigator.dart';

/// D-pad "move mode" reordering for a remote/keyboard-driven list of rows
/// inside a sheet or dialog.
///
/// The host keeps its list and row widgets; this mixin owns the virtual cursor
/// ([focusedIndex] / [focusedColumn]), the move-mode state and the key handler.
/// Wire it up by passing [handleReorderKeyEvent] to the list's
/// `Focus.onKeyEvent` and by reading [focusedIndex], [focusedColumn] and
/// [movingIndex] when building rows.
///
/// Navigation mode: UP/DOWN move between rows (resetting to column 0),
/// LEFT/RIGHT move between the row (column 0) and the trailing action columns
/// up to [lastReorderColumn], SELECT on column 0 enters move mode and on any
/// other column calls [onReorderColumnActivated].
///
/// Move mode: UP/DOWN swap the moving row with its neighbour, SELECT confirms
/// through [onReorderMoveConfirmed], and BACK restores the order captured when
/// move mode was entered. BACK outside move mode dismisses the hosting sheet.
/// D-pad keys are consumed at the list boundaries so focus cannot escape.
mixin DpadReorderListMixin<E, W extends StatefulWidget> on State<W> {
  /// Row height assumed by [ensureFocusedVisible] (Material `ListTile` with a
  /// subtitle) and the list's top padding.
  static const double _itemHeight = 72.0;
  static const double _listTopPadding = 8.0;

  /// Row the virtual cursor sits on.
  int focusedIndex = 0;

  /// Column within [focusedIndex]: 0 is the row itself, 1..[lastReorderColumn]
  /// are the trailing action buttons.
  int focusedColumn = 0;

  /// Row being moved, or null when not in move mode.
  int? movingIndex;

  int? _originalIndex;
  List<E>? _originalOrder;
  final BackPressGate _backGate = BackPressGate();

  /// The list being reordered. Mutated in place while moving and replaced
  /// wholesale when a move is cancelled.
  List<E> get reorderItems;
  set reorderItems(List<E> value);

  /// Right-most focusable column index (0 when the row has no action buttons).
  int get lastReorderColumn;

  /// Scrollable holding the rows, or null when the host does not scroll the
  /// focused row into view.
  ScrollController? get reorderScrollController;

  /// Called when SELECT confirms a move; [reorderItems] already holds the new
  /// order.
  void onReorderMoveConfirmed();

  /// Called when SELECT activates a trailing action column (1 or greater).
  void onReorderColumnActivated(int column, int index);

  /// Scrolls [focusedIndex] into view, parking it ~25% from the viewport top.
  void ensureFocusedVisible() {
    final scrollController = reorderScrollController;
    if (scrollController == null || !scrollController.hasClients) return;

    final double targetTop = _listTopPadding + (focusedIndex * _itemHeight);
    final double targetBottom = targetTop + _itemHeight;

    final double viewportTop = scrollController.offset;
    final double viewportHeight = scrollController.position.viewportDimension;
    final double viewportBottom = viewportTop + viewportHeight;

    if (targetTop >= viewportTop && targetBottom <= viewportBottom) return;

    final double destination = (targetTop - viewportHeight * 0.25).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    scrollController.animateTo(destination, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  KeyEventResult handleReorderKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    // The gate ignores a Back release whose press landed elsewhere (focus was
    // on a sheet during KeyDown and returned here before KeyUp).
    final backResult = _backGate.handle(event, () {
      if (movingIndex != null) {
        setState(() {
          final originalOrder = _originalOrder;
          if (originalOrder != null) {
            reorderItems = List<E>.from(originalOrder);
          }
          focusedIndex = _originalIndex ?? 0;
          movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
      } else {
        OverlaySheetController.popAdaptive(context);
      }
    });
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    final int? moving = movingIndex;
    if (moving != null) {
      // Move mode - arrows reorder the item
      if (key.isUpKey && moving > 0) {
        _swapMovingItem(moving, moving - 1);
        return KeyEventResult.handled;
      }
      if (key.isDownKey && moving < reorderItems.length - 1) {
        _swapMovingItem(moving, moving + 1);
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        // Confirm move - apply the reorder
        onReorderMoveConfirmed();
        setState(() {
          movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
        return KeyEventResult.handled;
      }
    } else {
      // Navigation mode
      if (key.isUpKey && focusedIndex > 0) {
        setState(() {
          focusedIndex--;
          focusedColumn = 0; // Reset to row when changing rows
        });
        ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && focusedIndex < reorderItems.length - 1) {
        setState(() {
          focusedIndex++;
          focusedColumn = 0; // Reset to row when changing rows
        });
        ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isLeftKey && focusedColumn > 0) {
        setState(() => focusedColumn--);
        return KeyEventResult.handled;
      }
      if (key.isRightKey && focusedColumn < lastReorderColumn) {
        setState(() => focusedColumn++);
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        if (focusedColumn == 0) {
          // Enter move mode
          setState(() {
            movingIndex = focusedIndex;
            _originalIndex = focusedIndex;
            _originalOrder = List<E>.from(reorderItems);
          });
        } else {
          onReorderColumnActivated(focusedColumn, focusedIndex);
        }
        return KeyEventResult.handled;
      }
    }

    // Block d-pad keys at boundaries so focus doesn't escape the dialog
    if (key.isDpadDirection) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _swapMovingItem(int from, int to) {
    setState(() {
      final item = reorderItems.removeAt(from);
      reorderItems.insert(to, item);
      movingIndex = to;
      focusedIndex = to;
    });
    ensureFocusedVisible();
  }
}
