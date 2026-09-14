import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/assistive_technology_service.dart';
import 'package:plezy/utils/semantics_tree_gate.dart';

class _GateTestBinding extends AutomatedTestWidgetsFlutterBinding with SemanticsTreeGate {}

void main() {
  final binding = _GateTestBinding();
  final service = AssistiveTechnologyService.instance;

  SemanticsOwner? owner() => binding.rootPipelineOwner.semanticsOwner;
  void platformSemantics(bool enabled) => binding.platformDispatcher.semanticsEnabledTestValue = enabled;

  // Both must be restored before the binding's end-of-test invariants run,
  // which is earlier than tearDown.
  void finish() {
    platformSemantics(false);
    debugDefaultTargetPlatformOverride = null;
  }

  late bool consumes;
  late int queries;

  Future<void> pushChanged() async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      AssistiveTechnologyService.channel.name,
      AssistiveTechnologyService.channel.codec.encodeMethodCall(const MethodCall('onChanged')),
      (_) {},
    );
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    consumes = true;
    queries = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(AssistiveTechnologyService.channel, (call) async {
      if (call.method != 'getSignals') throw MissingPluginException();
      queries++;
      return <String, dynamic>{'accessibilityEnabled': true, 'consumesSemantics': consumes};
    });
  });

  tearDown(() {
    service.debugReset();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(AssistiveTechnologyService.channel, null);
  });

  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: Text('hello')));

  testWidgets('gates the tree off when no enabled service consumes it, and back on when one does', (tester) async {
    await pumpApp(tester);
    consumes = false;
    service.ensureStarted();
    expect(queries, 0, reason: 'nothing to gate while the platform has semantics off');

    platformSemantics(true);
    await tester.pump();
    expect(queries, 1);
    expect(owner(), isNull);
    expect(binding.semanticsEnabled, isFalse);

    consumes = true;
    await pushChanged();
    await tester.pump();
    expect(queries, 2);
    expect(owner(), isNotNull);
    expect(find.bySemanticsLabel('hello'), findsOneWidget);
    finish();
  }, semanticsEnabled: false);

  testWidgets('keeps the tree when the platform side cannot answer', (tester) async {
    await pumpApp(tester);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(AssistiveTechnologyService.channel, null);
    service.ensureStarted();
    platformSemantics(true);
    await tester.pump();
    expect(owner(), isNotNull);
    finish();
  }, semanticsEnabled: false);

  testWidgets('re-evaluates on resume', (tester) async {
    await pumpApp(tester);
    consumes = false;
    service.ensureStarted();
    platformSemantics(true);
    await tester.pump();
    expect(owner(), isNull);

    consumes = true;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(owner(), isNotNull);
    finish();
  }, semanticsEnabled: false);

  testWidgets('a closed gate reopens once the platform drops semantics', (tester) async {
    await pumpApp(tester);
    consumes = false;
    service.ensureStarted();
    platformSemantics(true);
    await tester.pump();
    expect(binding.semanticsTreeWanted, isFalse);

    platformSemantics(false);
    await tester.pump();
    expect(binding.semanticsTreeWanted, isTrue);
    expect(queries, 1, reason: 'no query while the platform has semantics off');
    finish();
  }, semanticsEnabled: false);

  testWidgets('is a no-op off Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpApp(tester);
    consumes = false;
    service.ensureStarted();
    platformSemantics(true);
    await tester.pump();
    expect(queries, 0);
    expect(owner(), isNotNull);
    finish();
  }, semanticsEnabled: false);
}
