import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';

void main() {
  Widget host({
    required ViewMode viewMode,
    required List<MediaCardSliverPosition> positions,
    Object? listEpoch,
    Object? gridEpoch,
  }) {
    return MaterialApp(
      home: CustomScrollView(
        slivers: [
          MediaCardSliverLayout(
            viewMode: viewMode,
            itemCount: 6,
            density: 100,
            padding: EdgeInsets.zero,
            listEpoch: listEpoch,
            gridEpochBuilder: gridEpoch == null ? null : (_) => gridEpoch,
            itemBuilder: (context, position) {
              positions.add(position);
              return SizedBox(key: ValueKey(position.index), height: 40, child: Text('${position.index}'));
            },
          ),
        ],
      ),
    );
  }

  testWidgets('list mode exposes one-column card positions', (tester) async {
    final positions = <MediaCardSliverPosition>[];
    final epoch = Object();

    await tester.pumpWidget(host(viewMode: ViewMode.list, positions: positions, listEpoch: epoch));

    expect(find.byType(SliverList), findsOneWidget);
    expect(find.byType(SliverGrid), findsNothing);
    expect(positions, isNotEmpty);
    expect(positions.first.columnCount, 1);
    expect(positions.first.isFirstRow, isTrue);
    expect(positions.first.isFirstColumn, isTrue);
    expect(positions.first.disableScale, isTrue);
    expect(positions.first.layoutEpoch, same(epoch));
  });

  testWidgets('grid mode exposes geometry-derived card positions', (tester) async {
    final positions = <MediaCardSliverPosition>[];
    final epoch = Object();

    await tester.pumpWidget(host(viewMode: ViewMode.grid, positions: positions, gridEpoch: epoch));

    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(SliverList), findsNothing);
    expect(positions, isNotEmpty);
    final first = positions.first;
    expect(first.columnCount, greaterThan(1));
    expect(first.isGrid, isTrue);
    expect(first.isFirstRow, isTrue);
    expect(first.isFirstColumn, isTrue);
    expect(first.disableScale, isFalse);
    expect(first.layoutEpoch, same(epoch));
  });
}
