import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/music/music_detail_header.dart';

void main() {
  Widget host({required double width, required MusicDetailHeader header}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: header),
        ),
      ),
    );
  }

  testWidgets('compact header stacks centered metadata between artwork and actions', (tester) async {
    double? artworkSize;
    bool? centeredValue;

    await tester.pumpWidget(
      host(
        width: 500,
        header: MusicDetailHeader(
          artworkBuilder: (size) {
            artworkSize = size;
            return const SizedBox(key: Key('artwork'), width: 1, height: 1);
          },
          infoBuilder: ({required centered}) {
            centeredValue = centered;
            return const SizedBox(key: Key('info'), width: 1, height: 1);
          },
          actionBar: const SizedBox(key: Key('actions'), width: 1, height: 1),
          compactArtworkSize: 140,
          compactArtworkSpacing: 12,
          compactBottomSpacing: 8,
        ),
      ),
    );

    expect(artworkSize, 140);
    expect(centeredValue, isTrue);
    expect(find.byType(Column), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('artwork'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('info'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('info'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('actions'))).dy),
    );
  });

  testWidgets('wide header places full-size artwork beside left-aligned metadata', (tester) async {
    double? artworkSize;
    bool? centeredValue;

    await tester.pumpWidget(
      host(
        width: 800,
        header: MusicDetailHeader(
          artworkBuilder: (size) {
            artworkSize = size;
            return const SizedBox(key: Key('artwork'), width: 1, height: 1);
          },
          infoBuilder: ({required centered}) {
            centeredValue = centered;
            return const SizedBox(key: Key('info'), width: 1, height: 1);
          },
          actionBar: const SizedBox(key: Key('actions'), width: 1, height: 1),
          compactArtworkSize: 140,
          compactArtworkSpacing: 12,
        ),
      ),
    );

    expect(artworkSize, 180);
    expect(centeredValue, isFalse);
    expect(find.byType(Row), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('artwork'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const Key('info'))).dx),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('info'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('actions'))).dy),
    );
  });
}
