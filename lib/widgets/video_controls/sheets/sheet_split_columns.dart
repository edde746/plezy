import 'package:flutter/material.dart';

/// Side-by-side pair of sheet columns separated by a hairline rule.
///
/// The pair is as tall as its taller column, not as tall as the sheet allows.
/// That rules out a plain [VerticalDivider] between the columns: it has no
/// intrinsic height, so under loose constraints it expands to the incoming
/// maximum and drags the whole row to full height. Instead the row sizes
/// itself from the columns alone and the rule is painted over it, stretched to
/// the resolved height.
class SheetSplitColumns extends StatelessWidget {
  final Widget start;
  final Widget end;

  const SheetSplitColumns({super.key, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(child: start),
            const SizedBox(width: 1),
            Expanded(child: end),
          ],
        ),
        // Both halves have equal flex, so the reserved 1px gap above is exactly
        // at the horizontal centre. VerticalDivider has no intrinsic height and
        // fills whatever it is given — harmless here, because a positioned
        // child cannot influence the Stack's size.
        Positioned.fill(
          child: Center(child: VerticalDivider(width: 1, color: Theme.of(context).dividerColor)),
        ),
      ],
    );
  }
}
