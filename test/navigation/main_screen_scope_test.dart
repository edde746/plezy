import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/main_screen_scope.dart';

void main() {
  testWidgets('focusSidebarOf invokes the scope callback', (tester) async {
    var focusCalls = 0;
    late BuildContext childContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreenFocusScope(
          focusSidebar: () => focusCalls++,
          focusContent: () {},
          isSidebarFocused: false,
          sideNavigationWidth: 0,
          child: Builder(
            builder: (context) {
              childContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    MainScreenFocusScope.focusSidebarOf(childContext);

    expect(focusCalls, 1);
  });

  testWidgets('focusSidebarOf is a no-op without a scope', (tester) async {
    late BuildContext childContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            childContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(() => MainScreenFocusScope.focusSidebarOf(childContext), returnsNormally);
  });

  testWidgets('focusSidebarOf does not register an inherited dependency', (tester) async {
    var isSidebarFocused = false;
    var childBuilds = 0;
    var focusCalls = 0;
    late StateSetter rebuildScope;
    final child = Builder(
      builder: (context) {
        childBuilds++;
        MainScreenFocusScope.focusSidebarOf(context);
        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuildScope = setState;
            return MainScreenFocusScope(
              focusSidebar: () => focusCalls++,
              focusContent: () {},
              isSidebarFocused: isSidebarFocused,
              sideNavigationWidth: 0,
              child: child,
            );
          },
        ),
      ),
    );

    expect(childBuilds, 1);
    expect(focusCalls, 1);

    rebuildScope(() => isSidebarFocused = true);
    await tester.pump();

    expect(childBuilds, 1);
    expect(focusCalls, 1);
  });
}
