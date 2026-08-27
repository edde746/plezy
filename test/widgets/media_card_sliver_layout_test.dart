import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

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

  SliverGridDelegateWithMaxCrossAxisExtent gridDelegateOf(WidgetTester tester) =>
      tester.widget<SliverGrid>(find.byType(SliverGrid)).gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;

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

  group('grid spacing setting', () {
    testWidgets('default tight keeps the zero gutter', (tester) async {
      await tester.pumpWidget(host(viewMode: ViewMode.grid, positions: []));

      final delegate = gridDelegateOf(tester);
      expect(delegate.crossAxisSpacing, 0);
      expect(delegate.mainAxisSpacing, 0);
    });

    testWidgets('grids re-lay out live when the setting changes', (tester) async {
      await tester.pumpWidget(host(viewMode: ViewMode.grid, positions: []));

      await SettingsService.instance.write(SettingsService.gridSpacing, GridSpacing.normal);
      await tester.pump();
      var delegate = gridDelegateOf(tester);
      expect(delegate.crossAxisSpacing, GridSpacing.normal.gridGap);
      expect(delegate.mainAxisSpacing, GridSpacing.normal.gridGap);

      await SettingsService.instance.write(SettingsService.gridSpacing, GridSpacing.spacious);
      await tester.pump();
      delegate = gridDelegateOf(tester);
      expect(delegate.crossAxisSpacing, GridSpacing.spacious.gridGap);
      expect(delegate.mainAxisSpacing, GridSpacing.spacious.gridGap);
    });

    testWidgets('square grids keep at least their base gutter; full-bleed is unaffected', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final byGridSpacing = <GridSpacing, (double square, double fullBleed)>{};
      for (final spacing in GridSpacing.values) {
        await SettingsService.instance.write(SettingsService.gridSpacing, spacing);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                byGridSpacing[spacing] = (
                  MediaGridDelegate.spacingFor(context: context, shape: CardShape.square),
                  MediaGridDelegate.spacingFor(context: context, fullBleedImage: true),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      expect(byGridSpacing[GridSpacing.tight]!.$1, GridLayoutConstants.squareGridSpacing);
      // Normal (6) is below the square base gutter (8), so square keeps 8.
      expect(byGridSpacing[GridSpacing.normal]!.$1, GridLayoutConstants.squareGridSpacing);
      expect(byGridSpacing[GridSpacing.spacious]!.$1, GridSpacing.spacious.gridGap);
      // Full-bleed TV grids keep their own scale-derived gutter.
      final fullBleedGutters = byGridSpacing.values.map((v) => v.$2).toSet();
      expect(fullBleedGutters, hasLength(1));
    });

    testWidgets('hub-row wide cell packing ignores the setting', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final widths = <double>{};
      for (final spacing in GridSpacing.values) {
        await SettingsService.instance.write(SettingsService.gridSpacing, spacing);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                widths.add(MediaGridDelegate.wideCellWidth(context, 1280, LibraryDensity.defaultValue));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      expect(widths, hasLength(1));
    });
  });
}
