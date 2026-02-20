import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/app_icon.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';

class RatingBottomSheet extends StatefulWidget {
  final double currentRating;
  final Future<void> Function(double stars) onRate;
  final Future<void> Function() onClear;

  const RatingBottomSheet({
    super.key,
    required this.currentRating,
    required this.onRate,
    required this.onClear,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  late double _selectedRating;
  late final FocusNode _starsFocusNode;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.currentRating;
    _starsFocusNode = FocusNode(debugLabel: 'rating_stars');
  }

  @override
  void dispose() {
    _starsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedRating > 0
                  ? '${_selectedRating == _selectedRating.truncateToDouble() ? _selectedRating.toInt().toString() : _selectedRating.toStringAsFixed(1)} / 5'
                  : t.mediaMenu.rate,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Focus(
              focusNode: _starsFocusNode,
              autofocus: true,
              onKeyEvent: _handleStarsKeyEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final starSize = (constraints.maxWidth / 5).clamp(0.0, 48.0);
                  return GestureDetector(
                    onTapDown: (details) => _handleStarTap(details.localPosition.dx, starSize),
                    onPanUpdate: (details) => _handleStarTap(details.localPosition.dx, starSize),
                    child: AnimatedBuilder(
                      animation: _starsFocusNode,
                      builder: (context, child) {
                        final hasFocus = _starsFocusNode.hasFocus;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: hasFocus
                                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                : null,
                          ),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final starIndex = i + 1;
                          final IconData icon;
                          if (_selectedRating >= starIndex) {
                            icon = Symbols.star_rounded;
                          } else if (_selectedRating >= starIndex - 0.5) {
                            icon = Symbols.star_half_rounded;
                          } else {
                            icon = Symbols.star_rounded;
                          }
                          return SizedBox(
                            width: starSize,
                            height: starSize,
                            child: Center(
                              child: AppIcon(
                                icon,
                                fill: _selectedRating >= starIndex - 0.5 ? 1 : 0,
                                color: _selectedRating >= starIndex - 0.5
                                    ? Colors.amber
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                size: starSize * 0.8,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.currentRating > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      child: Text(t.common.clear),
                    ),
                  ),
                if (widget.currentRating > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedRating > 0
                        ? () {
                            widget.onRate(_selectedRating);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(t.mediaMenu.rate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleStarsKeyEvent(FocusNode _, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isRightKey) {
      setState(() {
        _selectedRating = (_selectedRating + 0.5).clamp(0.5, 5.0);
      });
      return KeyEventResult.handled;
    }
    if (key.isLeftKey) {
      setState(() {
        _selectedRating = (_selectedRating - 0.5).clamp(0.5, 5.0);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_selectedRating > 0) {
        widget.onRate(_selectedRating);
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleStarTap(double dx, double starSize) {
    final totalWidth = starSize * 5;
    final clampedX = dx.clamp(0.0, totalWidth);
    final halfStars = (clampedX / (starSize / 2)).ceil().clamp(1, 10);
    setState(() {
      _selectedRating = halfStars / 2.0;
    });
  }
}
