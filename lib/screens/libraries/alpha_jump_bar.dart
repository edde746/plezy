import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/plex_first_character.dart';
import 'alpha_jump_helper.dart';

/// Vertical strip of letters for jumping through sorted library items.
///
/// Pre-computes a cumulative index map from [firstCharacters] data so that
/// tapping a letter triggers [onJump] with the item index where that letter
/// begins. When more letters exist than fit vertically, the bar keeps the
/// highest-count letters (by item size) and drops the rest.
/// Supports both touch (tap/drag) and D-pad (up/down/select) input.
class AlphaJumpBar extends StatefulWidget {
  final List<PlexFirstCharacter> firstCharacters;
  final void Function(int targetIndex) onJump;

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

  @override
  void initState() {
    super.initState();
    _helper = AlphaJumpHelper(widget.firstCharacters);
    _displayed = _helper.letters;
  }

  @override
  void didUpdateWidget(AlphaJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstCharacters != widget.firstCharacters) {
      _helper = AlphaJumpHelper(widget.firstCharacters);
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
    _displayed = _helper.displayLetters(maxLetters);
    _clampHighlight();
  }

  /// Find the nearest displayed letter at or before [letter] in the full list.
  String _nearestDisplayed(String letter) {
    if (_displayed.contains(letter)) return letter;
    final pos = _helper.letters.indexOf(letter);
    if (pos < 0 && _displayed.isNotEmpty) return _displayed.first;
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
    final index = (dy / totalHeight * _displayed.length).floor();
    return index.clamp(0, _displayed.length - 1);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
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
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB) {
      widget.onBack?.call();
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

          final currentLetter = _nearestDisplayed(widget.currentLetter);

          return GestureDetector(
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
              width: 28,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    height: constraints.maxHeight / _displayed.length,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: decoration,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 10,
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
          );
        },
      ),
    );
  }
}
