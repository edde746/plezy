import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/navigation/main_screen_scope.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

/// Pumps [tab] under the ancestors every library tab requires: [provider], an
/// [InputModeTracker], a [MainScreenFocusScope] and a [NestedScrollView] whose
/// overlap absorber handle the tabs look up. Sizes the view to [size] and
/// restores it when the test ends. Settling is left to the caller.
Future<void> pumpLibraryTab(
  WidgetTester tester, {
  required MultiServerProvider provider,
  required Widget tab,
  Size size = const Size(1280, 720),
  VoidCallback? focusSidebar,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider<MultiServerProvider>.value(
      value: provider,
      child: InputModeTracker(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: MainScreenFocusScope(
            focusSidebar: focusSidebar ?? () {},
            focusContent: () {},
            isSidebarFocused: false,
            sideNavigationWidth: 0,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: const SliverToBoxAdapter(child: SizedBox(height: 1)),
                  ),
                ],
                body: tab,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Frames a library tab needs to issue its debounced request and apply the
/// response, for tabs whose loading never quiesces enough for `pumpAndSettle`.
Future<void> pumpRequestFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}
