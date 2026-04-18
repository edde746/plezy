import 'package:flutter/material.dart';
import '../theme/mono_tokens.dart';
import 'app_icon.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: tokens(context).textMuted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A setting with a label + icon row and a full-width SegmentedButton below.
/// Used for settings with 2-4 short options.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, fill: 1),
              const SizedBox(width: 16),
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              segments: segments,
              selected: {selected},
              onSelectionChanged: (Set<T> newSelection) {
                onChanged(newSelection.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}
