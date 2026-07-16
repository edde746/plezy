import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/app_icon.dart';

/// "PIN set" pill + Change/Remove text buttons. Shown on profile creation
/// and detail screens after a local PIN has been configured.
class PinStatusRow extends StatelessWidget {
  final VoidCallback onChange;
  final VoidCallback onRemove;

  /// Owned by the parent so it can restore DPAD focus when this row swaps
  /// in for the Set PIN button (whose node leaves the tree with it).
  final FocusNode? changeFocusNode;

  const PinStatusRow({super.key, required this.onChange, required this.onRemove, this.changeFocusNode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: .min,
            children: [
              AppIcon(Symbols.lock_rounded, fill: 1, color: theme.colorScheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 6),
              Text(
                t.profiles.pinSet,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FocusableButton(
          focusNode: changeFocusNode,
          onPressed: onChange,
          child: TextButton(onPressed: onChange, child: Text(t.profiles.changePin)),
        ),
        FocusableButton(
          onPressed: onRemove,
          child: TextButton(onPressed: onRemove, child: Text(t.profiles.removePin)),
        ),
      ],
    );
  }
}
