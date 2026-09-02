import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/semantics_tree_gate.dart';

class _GateTestBinding extends AutomatedTestWidgetsFlutterBinding with SemanticsTreeGate {}

void main() {
  final binding = _GateTestBinding();

  SemanticsOwner? owner() => binding.rootPipelineOwner.semanticsOwner;

  // The tester's own semantics handle is an explicit client, which the gate
  // deliberately never suppresses, so every case runs without it and drives
  // the platform request directly.
  void platformSemantics(bool enabled) => binding.platformDispatcher.semanticsEnabledTestValue = enabled;

  setUp(() => binding.semanticsTreeWanted = true);

  testWidgets('closing the gate tears the semantics owner down and reopening restores it', semanticsEnabled: false, (
    tester,
  ) async {
    await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: Text('hello')));
    expect(owner(), isNull);

    platformSemantics(true);
    await tester.pump();
    expect(owner(), isNotNull);
    expect(binding.semanticsEnabled, isTrue);
    expect(binding.platformSemanticsRequested, isTrue);

    binding.semanticsTreeWanted = false;
    await tester.pump();
    expect(owner(), isNull);
    expect(binding.semanticsEnabled, isFalse);
    expect(binding.platformSemanticsRequested, isTrue, reason: 'the platform request is untouched');

    binding.semanticsTreeWanted = true;
    await tester.pump();
    expect(owner(), isNotNull);
    expect(find.bySemanticsLabel('hello'), findsOneWidget);

    platformSemantics(false);
    await tester.pump();
    expect(owner(), isNull);
  });

  testWidgets('an explicit ensureSemantics client reopens a closed gate', semanticsEnabled: false, (tester) async {
    await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: Text('hello')));
    platformSemantics(true);
    binding.semanticsTreeWanted = false;
    await tester.pump();
    expect(owner(), isNull);

    final handle = binding.ensureSemantics();
    await tester.pump();
    expect(owner(), isNotNull);
    expect(binding.semanticsEnabled, isTrue);

    handle.dispose();
    // Disposal is invisible to the gate; the next evaluation applies it.
    binding.semanticsTreeWanted = true;
    binding.semanticsTreeWanted = false;
    await tester.pump();
    expect(owner(), isNull);

    platformSemantics(false);
    await tester.pump();
  });

  testWidgets('gate flips notify semantics-enabled listeners but not platform listeners', semanticsEnabled: false, (
    tester,
  ) async {
    var enabledCalls = 0;
    var platformCalls = 0;
    void onEnabled() => enabledCalls++;
    void onPlatform() => platformCalls++;
    binding.addSemanticsEnabledListener(onEnabled);
    binding.addPlatformSemanticsListener(onPlatform);
    addTearDown(() {
      binding.removeSemanticsEnabledListener(onEnabled);
      binding.removePlatformSemanticsListener(onPlatform);
    });

    binding.semanticsTreeWanted = false;
    expect(enabledCalls, 1);
    expect(platformCalls, 0);

    platformSemantics(true);
    expect(enabledCalls, 2);
    expect(platformCalls, 1);

    platformSemantics(false);
    expect(enabledCalls, 3);
    expect(platformCalls, 2);
  });
}
