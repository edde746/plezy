import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/multiview/workspace_models.dart';
import 'package:plezy/multiview/workspace_overlay.dart';
import 'package:plezy/theme/mono_theme.dart';

WorkspaceSurfaceRegistration _registration({
  required String id,
  required String title,
  required MultiviewMediaKind kind,
  VoidCallback? onRestore,
  VoidCallback? onClose,
  bool acceptsInput = false,
  WorkspaceOwnershipHandler? onInputOwnershipChanged,
}) => WorkspaceSurfaceRegistration(
  descriptor: WorkspaceSessionDescriptor(
    id: id,
    kind: kind,
    title: title,
    hasVideo: kind == MultiviewMediaKind.video,
    acceptsInput: acceptsInput,
    openedAt: DateTime.utc(2026, 1, 1),
  ),
  buildSurface: (_) => const ColoredBox(key: ValueKey('workspace_surface'), color: Colors.black),
  onRestore: onRestore ?? () {},
  onClose: onClose,
  onInputOwnershipChanged: onInputOwnershipChanged ?? (acceptsInput ? (_) {} : null),
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

final class _MountProbe extends StatefulWidget {
  const _MountProbe({super.key});

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

final class _MountProbeState extends State<_MountProbe> {
  @override
  Widget build(BuildContext context) => const Text('Retained game surface');
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

  testWidgets('long press and drag moves reader, comic and game panes', (tester) async {
    for (final (id, kind) in [
      ('reader', MultiviewMediaKind.publication),
      ('comic', MultiviewMediaKind.comic),
      ('game', MultiviewMediaKind.game),
    ]) {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(id: id, title: id, kind: kind));
      await _mount(tester, controller);

      final surface = find.byKey(const ValueKey('workspace_surface'));
      final initial = controller.placementFor(id);
      final gesture = await tester.startGesture(tester.getCenter(surface));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(60, 40));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.placementFor(id).left, greaterThan(initial.left), reason: '$kind body long press');
      expect(controller.placementFor(id).top, greaterThan(initial.top), reason: '$kind body long press');

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
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

  testWidgets('floating media windows expose a direct, accessible return action', (tester) async {
    for (final (id, kind, returnLabel, closeLabel) in [
      ('video', MultiviewMediaKind.video, 'Return to full player', 'Close mini player'),
      ('music', MultiviewMediaKind.music, 'Return to full view', 'Close window'),
    ]) {
      var restored = 0;
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(id: id, title: id, kind: kind, onRestore: () => restored++));
      await _mount(tester, controller);

      final returnButton = find.byTooltip(returnLabel);
      expect(returnButton, findsOneWidget, reason: '$kind return action');
      expect(find.byTooltip(closeLabel), findsOneWidget, reason: '$kind close action');
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      expect(restored, 1, reason: '$kind restored callback');
      expect(controller.isRestored(id), isTrue, reason: '$kind restored state');

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('move and resize affordances explain their accessible interactions', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video));
    await _mount(tester, controller);

    expect(find.byTooltip('Move window'), findsOneWidget);
    expect(find.byTooltip('Resize window'), findsOneWidget);
    final moveSemantics = tester.getSemantics(find.bySemanticsLabel('Move window'));
    expect(moveSemantics.getSemanticsData().hint, contains('Long-press and drag'));
    final resizeSemantics = tester.getSemantics(find.bySemanticsLabel('Resize window'));
    expect(resizeSemantics.getSemanticsData().hint, contains('arrow keys to resize'));

    await tester.tap(find.byTooltip('Move window'));
    await tester.pump();
    expect(find.byTooltip('Finish moving window'), findsOneWidget);
    expect(find.textContaining('Drag to move'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    semantics.dispose();
  });

  testWidgets('parking keeps the session reachable and close ends it from the tray', (tester) async {
    var closes = 0;
    final controller = MultiviewWorkspaceController();
    controller.register(
      _registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video, onClose: () => closes++),
    );
    await _mount(tester, controller);

    await tester.tap(find.byTooltip('Move to session tray'));
    await tester.pumpAndSettle();

    expect(controller.visibleSessions, isEmpty);
    expect(controller.sessionTrayVisible, isTrue);
    expect(find.text('Media sessions'), findsOneWidget);
    expect(find.text('Parked'), findsOneWidget);

    await tester.tap(find.text(isolateDisplayText('Film')));
    await tester.pumpAndSettle();
    expect(controller.visibleSessions.map((session) => session.descriptor.id), ['video']);
    expect(controller.sessionTrayVisible, isFalse);

    await tester.tap(find.byTooltip('Move to session tray'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Close mini player'));
    await tester.pumpAndSettle();

    expect(controller.sessionCount, 0);
    expect(controller.sessionTrayVisible, isFalse);
    expect(closes, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('a hidden game surface stays mounted while another pane is fullscreen', (tester) async {
    final controller = MultiviewWorkspaceController();
    final gameSurfaceKey = GlobalKey<_MountProbeState>();
    controller.register(
      WorkspaceSurfaceRegistration(
        descriptor: WorkspaceSessionDescriptor(
          id: 'game',
          kind: MultiviewMediaKind.game,
          title: 'Game',
          hasVideo: true,
          openedAt: DateTime.utc(2026, 1, 1),
        ),
        buildSurface: (_) => _MountProbe(key: gameSurfaceKey),
        onRestore: () {},
      ),
    );
    controller.register(
      WorkspaceSurfaceRegistration(
        descriptor: WorkspaceSessionDescriptor(
          id: 'video',
          kind: MultiviewMediaKind.video,
          title: 'Film',
          hasVideo: true,
          openedAt: DateTime.utc(2026, 1, 1),
        ),
        buildSurface: (_) => const ColoredBox(color: Colors.black),
        onRestore: () {},
      ),
    );
    await _mount(tester, controller);
    expect(gameSurfaceKey.currentState, isNotNull);

    controller.promoteToFullscreen('video');
    await tester.pumpAndSettle();

    expect(gameSurfaceKey.currentState, isNotNull);
    expect(find.text('Retained game surface', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('a route taking focus suspends and restores the gamepad input lease', (tester) async {
    final controller = MultiviewWorkspaceController();
    final gameInput = <bool>[];
    controller.register(
      _registration(
        id: 'game',
        title: 'Game',
        kind: MultiviewMediaKind.game,
        acceptsInput: true,
        onInputOwnershipChanged: gameInput.add,
      ),
    );
    await _mount(tester, controller);
    await tester.pumpAndSettle();

    expect(controller.inputSessionId, 'game');
    expect(gameInput, [true]);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    final route = navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Blocking dialog'))),
    );
    await tester.pumpAndSettle();

    expect(controller.inputSessionId, isNull);
    expect(gameInput, [true, false]);

    navigator.pop();
    await tester.pumpAndSettle();
    await route;

    expect(controller.inputSessionId, 'game');
    expect(gameInput, [true, false, true]);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('double tap on a pane title promotes it while preserving the session', (tester) async {
    final controller = MultiviewWorkspaceController();
    controller.register(_registration(id: 'video', title: 'Film', kind: MultiviewMediaKind.video));
    await _mount(tester, controller);

    await tester.tap(find.text(isolateDisplayText('Film')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text(isolateDisplayText('Film')));
    await tester.pumpAndSettle();

    expect(controller.fullscreenSessionId, 'video');
    expect(controller.sessionCount, 1);
    expect(controller.visibleSessions.single.descriptor.title, 'Film');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
