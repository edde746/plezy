import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plex_first_character.dart';
import 'alpha_jump_helper.dart';

/// Vertical strip of letters (#, A–Z) for jumping through sorted library items.
///
/// Pre-computes a cumulative index map from [firstCharacters] data so that
/// tapping a letter triggers [onJump] with the item index where that letter
/// begins. Supports both touch (tap/drag) and D-pad (up/down/select) input.
class AlphaJumpBar extends StatefulWidget {
  final List<PlexFirstCharacter> firstCharacters;
  final void Function(int targetIndex) onJump;
  final int currentFirstVisibleIndex;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onBack;

  const AlphaJumpBar({
    super.key,
    required this.firstCharacters,
    required this.onJump,
    required this.currentFirstVisibleIndex,
    this.focusNode,
    this.onNavigateLeft,
    this.onBack,
  });

  @override
  State<AlphaJumpBar> createState() => _AlphaJumpBarState();
}

class _AlphaJumpBarState extends State<AlphaJumpBar> {
  late AlphaJumpHelper _helper;

  /// Currently highlighted letter index (for D-pad navigation).
  int _highlightedIndex = 0;

  /// Whether this bar currently has focus (for D-pad mode).
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _helper = AlphaJumpHelper(widget.firstCharacters);
  }

  @override
  void didUpdateWidget(AlphaJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstCharacters != widget.firstCharacters) {
      _helper = AlphaJumpHelper(widget.firstCharacters);
    }
  }

  void _jumpToLetter(String letter) {
    final index = _helper.indexForLetter(letter);
    if (index != null) {
      widget.onJump(index);
    }
  }

  /// Resolves a vertical drag position to a letter index.
  int _letterIndexFromDy(double dy, double totalHeight) {
    final index = (dy / totalHeight * AlphaJumpHelper.allLetters.length).floor();
    return index.clamp(0, AlphaJumpHelper.allLetters.length - 1);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_highlightedIndex > 0) {
        setState(() => _highlightedIndex--);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_highlightedIndex < AlphaJumpHelper.allLetters.length - 1) {
        setState(() => _highlightedIndex++);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _jumpToLetter(AlphaJumpHelper.allLetters[_highlightedIndex]);
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
    final currentLetter = _helper.currentLetter(widget.currentFirstVisibleIndex);
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
          if (hasFocus) {
            // Start highlight at the current letter when gaining focus
            final idx = AlphaJumpHelper.allLetters.indexOf(currentLetter);
            if (idx >= 0) _highlightedIndex = idx;
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final idx = _letterIndexFromDy(details.localPosition.dy, constraints.maxHeight);
              setState(() => _highlightedIndex = idx);
              _jumpToLetter(AlphaJumpHelper.allLetters[idx]);
            },
            onVerticalDragUpdate: (details) {
              final idx = _letterIndexFromDy(details.localPosition.dy, constraints.maxHeight);
              if (idx != _highlightedIndex) {
                setState(() => _highlightedIndex = idx);
                _jumpToLetter(AlphaJumpHelper.allLetters[idx]);
              }
            },
            child: Container(
              width: 28,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(AlphaJumpHelper.allLetters.length, (i) {
                  final letter = AlphaJumpHelper.allLetters[i];
                  final isActive = _helper.activeLetters.contains(letter);
                  final isCurrent = letter == currentLetter && !_hasFocus;
                  final isHighlighted = _hasFocus && i == _highlightedIndex;

                  return SizedBox(
                    height: constraints.maxHeight / AlphaJumpHelper.allLetters.length,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: isHighlighted
                            ? BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)
                            : isCurrent
                            ? BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle)
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: (isCurrent || isHighlighted) ? FontWeight.bold : FontWeight.normal,
                            color: isHighlighted
                                ? colorScheme.onPrimary
                                : isCurrent
                                ? colorScheme.primary
                                : isActive
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.25),
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
