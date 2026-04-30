import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../widgets/app_icon.dart';

/// "PIN set" pill + Change/Remove text buttons. Shown on profile creation
/// and detail screens after a local PIN has been configured.
class PinStatusRow extends StatelessWidget {
  final VoidCallback onChange;
  final VoidCallback onRemove;

  const PinStatusRow({super.key, required this.onChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.lock_rounded, fill: 1, color: theme.colorScheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 6),
              Text(
                'PIN set',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onChange, child: const Text('Change')),
        TextButton(onPressed: onRemove, child: const Text('Remove')),
      ],
    );
  }
}
