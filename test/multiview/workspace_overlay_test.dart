import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/multiview/workspace_models.dart';
import 'package:plezy/multiview/workspace_overlay.dart';
import 'package:plezy/theme/mono_theme.dart';

WorkspaceSurfaceRegistration _registration({
  required String id,
  required String title,
  required MultiviewMediaKind kind,
}) => WorkspaceSurfaceRegistration(
  descriptor: WorkspaceSessionDescriptor(
    id: id,
    kind: kind,
    title: title,
    hasVideo: kind == MultiviewMediaKind.video,
    openedAt: DateTime.utc(2026, 1, 1),
  ),
  buildSurface: (_) => const ColoredBox(key: ValueKey('workspace_surface'), color: Colors.black),
  onRestore: () {},
);

Future<void> _mount(WidgetTester tester, MultiviewWorkspaceController controller) async {
  final overlayKey = GlobalKey<OverlayState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: monoTheme(MonoPalette.dark),
      home: Overlay(
        key: overlayKey,
        initialEntries: [
          OverlayEntry(
            builder: (_) => MultiviewOverlayHost(controller: controller, overlayKey: overlayKey),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('long press and drag moves a video pane on the shared surface', (tester) async {
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video));
    await _mount(tester, controller);

    final initial = controller.placementFor('video');
    final surface = find.byKey(const ValueKey('workspace_surface'));
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(80, 48));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.placementFor('video').left, greaterThan(initial.left));
    expect(controller.placementFor('video').top, greaterThan(initial.top));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('reader body dragging requires the explicit Move mode', (tester) async {
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'reader', title: 'Book', kind: MultiviewMediaKind.publication));
    await _mount(tester, controller);

    final surface = find.byKey(const ValueKey('workspace_surface'));
    final initial = controller.placementFor('reader');
    var gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(60, 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(controller.placementFor('reader').left, initial.left);

    await tester.tap(find.widgetWithIcon(IconButton, Symbols.drag_handle_rounded));
    await tester.pump();
    gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(60, 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.placementFor('reader').left, greaterThan(initial.left));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('fullscreen is available through an explicit accessible control', (tester) async {
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video));
    await _mount(tester, controller);

    final fullscreen = find.byIcon(Symbols.open_in_full_rounded);
    expect(fullscreen, findsOneWidget);
    await tester.tap(fullscreen);
    await tester.pumpAndSettle();

    expect(controller.fullscreenSessionId, 'video');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('double tap on a pane title promotes it while preserving the session', (tester) async {
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video));
    await _mount(tester, controller);

    await tester.tap(find.text('Film'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Film'));
    await tester.pumpAndSettle();

    expect(controller.fullscreenSessionId, 'video');
    expect(controller.sessionCount, 1);
    expect(controller.visibleSessions.single.descriptor.title, 'Film');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
