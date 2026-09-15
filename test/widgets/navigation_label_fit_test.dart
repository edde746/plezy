import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/utils/text_measure_cache.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/navigation_label_fit.dart';

void main() {
  const style = TextStyle(fontSize: 11);

  double widthOf(String text, {TextScaler scaler = TextScaler.noScaling}) =>
      cachedSingleLineTextSize(text, style: style, textScaler: scaler, textDirection: TextDirection.ltr).width;

  double factorFor(List<String> labels, double labelWidth, {TextScaler scaler = TextScaler.noScaling}) =>
      navigationLabelScaleFactor(
        labels: labels,
        labelWidth: labelWidth,
        style: style,
        textScaler: scaler,
        textDirection: TextDirection.ltr,
      );

  group('navigationLabelScaleFactor', () {
    test('labels that already fit keep the ambient scale', () {
      expect(factorFor(['Home', 'Downloads'], widthOf('Downloads') + kNavigationLabelFitMargin), 1.0);
    });

    test('the widest label decides how far the labels shrink, and it then fits', () {
      final labelWidth = widthOf('Téléchargement') * 0.9;
      final factor = factorFor(['Accueil', 'Téléchargement'], labelWidth);

      expect(factor, lessThan(1.0));
      expect(widthOf('Téléchargement', scaler: TextScaler.linear(factor)), lessThan(labelWidth));
    });

    test('shrinking stops at a readable size and leaves the rest to the ellipsis', () {
      expect(factorFor(['Téléchargement'], 8), closeTo(kNavigationLabelMinFontSize / 11, 0.001));
    });

    test('an enlarged system font never exceeds the ceiling the bar itself applies', () {
      expect(factorFor(['Home'], 1000, scaler: const TextScaler.linear(2)), kNavigationLabelMaxScaleFactor);
    });

    test('an enlarged system font still shrinks until the label fits', () {
      final labelWidth = widthOf('Downloads', scaler: const TextScaler.linear(kNavigationLabelMaxScaleFactor)) * 0.8;
      final factor = factorFor(['Downloads'], labelWidth, scaler: const TextScaler.linear(2));

      expect(factor, lessThan(kNavigationLabelMaxScaleFactor));
      expect(widthOf('Downloads', scaler: TextScaler.linear(factor)), lessThan(labelWidth));
    });

    test('a viewer who shrank the system font keeps their smaller text', () {
      expect(factorFor(['Téléchargement'], 8, scaler: const TextScaler.linear(0.5)), 0.5);
    });
  });

  group('bottom bar destinations', () {
    final tabs = [
      NavigationTab(id: NavigationTabId.discover, onlineOnly: false, icon: Icons.home, getLabel: () => 'Accueil'),
      NavigationTab(
        id: NavigationTabId.libraries,
        onlineOnly: false,
        icon: Icons.video_library,
        getLabel: () => 'Bibliothèque',
      ),
      NavigationTab(id: NavigationTabId.explore, onlineOnly: false, icon: Icons.explore, getLabel: () => 'Explorer'),
      NavigationTab(id: NavigationTabId.search, onlineOnly: false, icon: Icons.search, getLabel: () => 'Recherche'),
      NavigationTab(
        id: NavigationTabId.downloads,
        onlineOnly: false,
        icon: Icons.download,
        getLabel: () => 'Téléchargement',
      ),
    ];

    Future<void> pumpBar(WidgetTester tester, {TextScaler scaler = TextScaler.noScaling, bool fit = true}) async {
      // A Pixel-class phone in portrait: 384dp wide, so five destinations get
      // 76.8dp each — less than "Téléchargement" needs (#2316).
      tester.view.physicalSize = const Size(384 * 3, 840 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final bar = NavigationBar(
                selectedIndex: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [for (final tab in tabs) tab.toDestination()],
              );
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaler),
                child: Scaffold(
                  bottomNavigationBar: fit
                      ? NavigationLabelScale(
                          labels: [for (final tab in tabs) tab.getLabel()],
                          labelWidth: 384 / tabs.length,
                          style: navigationBarLabelStyle(context),
                          child: bar,
                        )
                      : bar,
                ),
              );
            },
          ),
        ),
      );
    }

    List<double> labelHeights(WidgetTester tester) => [
      for (final tab in tabs) tester.getSize(find.text(tab.getLabel())).height,
    ];

    List<double> iconTops(WidgetTester tester) => [
      for (var i = 0; i < tabs.length; i++) tester.getTopLeft(find.byType(AppIcon).at(i)).dy,
    ];

    testWidgets('a label too long for its destination stays on one line, icons in line', (tester) async {
      await pumpBar(tester);

      final heights = labelHeights(tester);
      expect(heights, everyElement(heights.first), reason: 'a wrapped label would be taller than its siblings');
      expect(iconTops(tester), everyElement(iconTops(tester).first));
    });

    testWidgets('an enlarged system font does not wrap or misalign either', (tester) async {
      await pumpBar(tester, scaler: const TextScaler.linear(2));

      final heights = labelHeights(tester);
      expect(heights, everyElement(heights.first));
      expect(iconTops(tester), everyElement(iconTops(tester).first));
    });

    testWidgets('the fit clamp shrinks the labels rather than cutting more of them', (tester) async {
      await pumpBar(tester, fit: false);
      final unclamped = labelHeights(tester).first;

      await pumpBar(tester, fit: true);
      expect(labelHeights(tester).first, lessThan(unclamped));
    });
  });
}
