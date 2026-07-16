import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../focus/key_event_utils.dart';
import '../../media/library_first_character.dart';
import '../../widgets/clickable_cursor.dart';
import 'alpha_jump_helper.dart';

/// Vertical strip of letters for jumping through sorted library items.
///
/// Pre-computes a cumulative index map from [firstCharacters] data so that
/// tapping a letter triggers [onJump] with the item index where that letter
/// begins. Alphabet-sized lists stay complete and compact vertically when
/// needed; larger character sets are thinned to the highest-count letters.
/// Supports both touch (tap/drag) and D-pad (up/down/select) input.
class AlphaJumpBar extends StatefulWidget {
  final List<LibraryFirstCharacter> firstCharacters;
  final void Function(int targetIndex) onJump;
  final bool descending;

  /// The letter currently visible at the top of the grid, derived from the
  /// actual item's sort title by the parent widget.
  final String currentLetter;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onBack;

  const AlphaJumpBar({
    super.key,
    required this.firstCharacters,
    required this.onJump,
    required this.currentLetter,
    this.descending = false,
    this.focusNode,
    this.onNavigateLeft,
    this.onBack,
  });

  @override
  State<AlphaJumpBar> createState() => _AlphaJumpBarState();
}

class _AlphaJumpBarState extends State<AlphaJumpBar> {
  late AlphaJumpHelper _helper;

  /// Subset of letters actually rendered, filtered by available height.
  List<String> _displayed = const [];

  /// Cached max-letter count from the last layout pass.
  int _lastMaxLetters = -1;

  /// Currently highlighted letter index (for D-pad navigation).
  int _highlightedIndex = 0;

  /// Whether this bar currently has focus (for D-pad mode).
  bool _hasFocus = false;

  /// Debounce timer for keyboard-driven jumps.
  Timer? _debounce;

  /// Minimum vertical space per letter slot.
  static const double _minLetterHeight = 20.0;

  /// Keep canonical alphabet bars complete instead of hiding trailing letters
  /// on shorter TV viewports.
  static const int _maxCompactLetterCount = 27;

  @override
  void initState() {
    super.initState();
    _helper = AlphaJumpHelper(widget.firstCharacters, descending: widget.descending);
    _displayed = _helper.letters;
  }

  @override
  void didUpdateWidget(AlphaJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstCharacters != widget.firstCharacters || oldWidget.descending != widget.descending) {
      _helper = AlphaJumpHelper(widget.firstCharacters, descending: widget.descending);
      _lastMaxLetters = -1; // force recompute in next layout
      _displayed = _helper.letters;
      _clampHighlight();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _clampHighlight() {
    if (_displayed.isNotEmpty) {
      _highlightedIndex = _highlightedIndex.clamp(0, _displayed.length - 1);
    } else {
      _highlightedIndex = 0;
    }
  }

  /// Recompute [_displayed] if the available letter count changed.
  void _updateDisplayed(double availableHeight) {
    final maxLetters = (availableHeight / _minLetterHeight).floor();
    if (maxLetters == _lastMaxLetters) return;
    _lastMaxLetters = maxLetters;
    _displayed = _helper.letters.length <= _maxCompactLetterCount
        ? _helper.letters
        : _helper.displayLetters(maxLetters);
    _clampHighlight();
  }

  /// Find the nearest displayed letter at or before [letter] in the full list.
  /// Returns an empty string when [letter] is empty so callers can render an
  /// "unhighlighted" state — important for the Jellyfin filter UX where no
  /// letter is selected by default.
  String _nearestDisplayed(String letter) {
    if (letter.isEmpty) return '';
    if (_displayed.isEmpty) return letter;
    if (_displayed.contains(letter)) return letter;
    final pos = _helper.letters.indexOf(letter);
    if (pos < 0) return _displayed.first;
    String result = _displayed.first;
    for (final dl in _displayed) {
      final dlPos = _helper.letters.indexOf(dl);
      if (dlPos <= pos) result = dl;
    }
    return result;
  }

  void _jumpToLetter(String letter) {
    final index = _helper.indexForLetter(letter);
    if (index != null) {
      widget.onJump(index);
    }
  }

  /// Schedule a debounced jump to the currently highlighted letter.
  void _debouncedJump() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (_highlightedIndex < _displayed.length) {
        _jumpToLetter(_displayed[_highlightedIndex]);
      }
    });
  }

  /// Resolves a vertical drag position to a displayed-letter index.
  int _letterIndexFromDy(double dy, double totalHeight) {
    if (_displayed.isEmpty) return 0;
    final index = (dy / totalHeight * _displayed.length).floor();
    return index.clamp(0, _displayed.length - 1);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final selectResult = handleOneShotSelect(event, () {
      if (_highlightedIndex < _displayed.length) {
        _jumpToLetter(_displayed[_highlightedIndex]);
      }
    });
    if (selectResult != KeyEventResult.ignored) return selectResult;
    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) return backResult;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_highlightedIndex > 0) {
        setState(() => _highlightedIndex--);
        _debouncedJump();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_highlightedIndex < _displayed.length - 1) {
        setState(() => _highlightedIndex++);
        _debouncedJump();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onNavigateLeft?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
          if (hasFocus) {
            final displayed = _nearestDisplayed(widget.currentLetter);
            final idx = _displayed.indexOf(displayed);
            if (idx >= 0) _highlightedIndex = idx;
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _updateDisplayed(constraints.maxHeight);

          if (_displayed.isEmpty) return const SizedBox.shrink();

          final currentLetter = _nearestDisplayed(widget.currentLetter);
          final letterSlotHeight = constraints.maxHeight / _displayed.length;
          final markerSize = (letterSlotHeight - 2).clamp(10.0, 18.0).toDouble();
          final fontSize = (letterSlotHeight * 0.58).clamp(7.0, 10.0).toDouble();

          return ClickableCursor(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final idx = _letterIndexFromDy(details.localPosition.dy, constraints.maxHeight);
                setState(() => _highlightedIndex = idx);
                _jumpToLetter(_displayed[idx]);
              },
              onVerticalDragUpdate: (details) {
                final idx = _letterIndexFromDy(details.localPosition.dy, constraints.maxHeight);
                if (idx != _highlightedIndex) {
                  setState(() => _highlightedIndex = idx);
                  _jumpToLetter(_displayed[idx]);
                }
              },
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  mainAxisAlignment: .spaceEvenly,
                  children: List.generate(_displayed.length, (i) {
                    final letter = _displayed[i];
                    final isCurrent = letter == currentLetter && !_hasFocus;
                    final isHighlighted = _hasFocus && i == _highlightedIndex;

                    BoxDecoration? decoration;
                    if (isHighlighted) {
                      decoration = BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle);
                    } else if (isCurrent) {
                      decoration = BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      );
                    }

                    Color letterColor;
                    if (isHighlighted) {
                      letterColor = colorScheme.onPrimary;
                    } else if (isCurrent) {
                      letterColor = colorScheme.primary;
                    } else {
                      letterColor = colorScheme.onSurface;
                    }

                    return SizedBox(
                      height: letterSlotHeight,
                      child: Center(
                        child: Container(
                          width: markerSize,
                          height: markerSize,
                          decoration: decoration,
                          alignment: .center,
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: (isCurrent || isHighlighted) ? FontWeight.bold : FontWeight.normal,
                              color: letterColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
