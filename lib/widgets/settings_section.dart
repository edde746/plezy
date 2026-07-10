import 'package:flutter/material.dart';
import '../theme/mono_tokens.dart';
import 'app_icon.dart';
import 'expressive_button_group.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tokens(context).textMuted, fontWeight: .w600),
      ),
    );
  }
}

/// M3E grouped list section: each child gets its own rounded surface card —
/// large radii on the section's outer corners, small radii between adjacent
/// items, hairline gaps — with an optional [SettingsSectionHeader] above.
///
/// Corner shapes are computed from the child list index, so conditional tiles
/// MUST be excluded with `if (...)` at list-build time. A child that renders
/// `SizedBox.shrink()` still occupies a corner slot and corrupts the group's
/// shape; hoist its condition (or wrap the whole group in a SettingsBuilder).
///
/// Each item is a shaped [Material] so the tiles' native ink focus/hover
/// highlight paints clipped inside the card — that is the d-pad focus visual
/// (background focus). The group adds no [Focus] nodes of its own; traversal
/// order and externally-owned tile focus nodes are untouched.
class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  BorderRadius _radiusFor(int i, MonoTokens t) {
    return BorderRadius.vertical(
      top: Radius.circular(i == 0 ? t.radiusLg : t.radiusXs),
      bottom: Radius.circular(i == children.length - 1 ? t.radiusLg : t.radiusXs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (title != null) SettingsSectionHeader(title!),
        Padding(
          padding: margin,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: t.groupGap),
                Material(
                  color: t.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: _radiusFor(i, t)),
                  child: children[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A setting with a label + icon row and a full-width button group below.
/// Used for settings with 2-3 short options.
class SegmentedSetting<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedSetting({
    super.key,
    required this.icon,
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              AppIcon(icon, fill: 1),
              const SizedBox(width: 16),
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          ExpressiveButtonGroup<T>(segments: segments, selected: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}
