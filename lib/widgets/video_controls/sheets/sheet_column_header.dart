import 'package:flutter/material.dart';

/// Left-aligned label above a sheet selection column.
///
/// The [Align] has no `heightFactor`, so it only shrink-wraps while it sits on
/// an unbounded main axis — i.e. as a non-flex child of a [Column]. Placing it
/// under a [Flexible] would make it fill the sheet's whole height cap.
class SheetColumnHeader extends StatelessWidget {
  final String label;

  const SheetColumnHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: .centerLeft,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
