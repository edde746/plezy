import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vibe_stream/utils/dialogs.dart';

void main() {
  testWidgets('toggle label stays on one line in narrow option picker dialog', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    bool includeSpecials = true;
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showOptionPickerDialog<String>(
                    context,
                    title: 'Download',
                    toggle: (
                      label: 'Include Specials',
                      icon: Symbols.star_rounded,
                      value: includeSpecials,
                      onChanged: (value) => includeSpecials = value,
                    ),
                    options: [
                      (icon: Symbols.download_rounded, label: 'All Episodes', value: 'all'),
                      (icon: Symbols.visibility_off_rounded, label: 'Unwatched Only', value: 'unwatched'),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final includeSpecialsLabel = find.text('Include Specials');
    expect(includeSpecialsLabel, findsOneWidget);

    final paragraph = tester.renderObject<RenderParagraph>(includeSpecialsLabel);
    final lineBoxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 'Include Specials'.length),
    );
    expect(lineBoxes, hasLength(1));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(includeSpecials, isFalse);
    expect(selected, isNull);
    expect(find.byType(SimpleDialog), findsOneWidget);
    expect(includeSpecialsLabel, findsOneWidget);

    await tester.tap(find.text('All Episodes'));
    await tester.pumpAndSettle();

    expect(selected, 'all');
    expect(find.byType(SimpleDialog), findsNothing);
  });
}
