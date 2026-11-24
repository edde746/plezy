import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main.dart' as app;
import 'package:plezy/theme/mono_theme.dart';

/// A style no screen sends, so each expectation reads the style this tree sent.
const _sentinel = SystemUiOverlayStyle(statusBarColor: Color(0xFFFF00FF));

const _appBarStyle = SystemUiOverlayStyle(statusBarColor: Color(0xFFFF0000));

SystemUiOverlayStyle _rootStyle({required Brightness background, required Brightness icons}) => SystemUiOverlayStyle(
  statusBarColor: const Color(0x00000000),
  statusBarBrightness: background,
  statusBarIconBrightness: icons,
);

Future<void> _pumpShell(WidgetTester tester, {required MonoPalette palette, required Widget home}) async {
  tester.view.padding = const FakeViewPadding(top: 72);
  addTearDown(tester.view.resetPadding);
  SystemChrome.setSystemUIOverlayStyle(_sentinel);
  await tester.pump();
  expect(SystemChrome.latestStyle, _sentinel);

  await tester.pumpWidget(
    MaterialApp(theme: monoTheme(palette), builder: (context, child) => app.rootShell(child), home: home),
  );
}

void main() {
  for (final (palette, icons) in [(MonoPalette.light, Brightness.dark), (MonoPalette.dark, Brightness.light)]) {
    testWidgets(
      'a ${palette.brightness.name} screen without an app bar clears the status bar with ${icons.name} icons',
      (tester) async {
        await _pumpShell(
          tester,
          palette: palette,
          home: const Scaffold(body: SizedBox.expand()),
        );

        expect(SystemChrome.latestStyle, _rootStyle(background: palette.brightness, icons: icons));
      },
    );
  }

  testWidgets('an app bar under the status bar still styles it, and leaving it restores the app style', (tester) async {
    await _pumpShell(
      tester,
      palette: MonoPalette.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(appBar: AppBar(systemOverlayStyle: _appBarStyle)),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle, _appBarStyle);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle, _rootStyle(background: Brightness.light, icons: Brightness.dark));
  });
}
