import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/utils/platform_detector.dart';

const _library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies');

class _ProbeTab extends BaseLibraryTab<String> {
  const _ProbeTab({super.key, required this.loadedItems, required super.onBack, super.isActive = true})
    : super(library: _library);

  final List<String> loadedItems;

  @override
  State<_ProbeTab> createState() => _ProbeTabState();
}

class _ProbeTabState extends BaseLibraryTabState<String, _ProbeTab> {
  int focusFirstItemCalls = 0;

  @override
  Future<List<String>> loadData() async => widget.loadedItems;

  @override
  Widget buildContent(List<String> items) => const SizedBox.shrink();

  @override
  IconData get emptyIcon => Icons.inbox_rounded;

  @override
  String get emptyMessage => 'Empty';

  @override
  String get errorContext => 'probe';

  @override
  void focusFirstItem() {
    focusFirstItemCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  Future<_ProbeTabState> pumpProbe(
    WidgetTester tester, {
    required List<String> loadedItems,
    required VoidCallback onBack,
  }) async {
    final key = GlobalKey<_ProbeTabState>();
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: _ProbeTab(key: key, loadedItems: loadedItems, onBack: onBack),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return key.currentState!;
  }

  testWidgets('empty active tab focuses library chrome fallback', (tester) async {
    var fallbackCalls = 0;

    final state = await pumpProbe(tester, loadedItems: const [], onBack: () => fallbackCalls++);

    expect(fallbackCalls, 1);
    expect(state.focusFirstItemCalls, 0);
  });

  testWidgets('non-empty active tab focuses first item', (tester) async {
    var fallbackCalls = 0;

    final state = await pumpProbe(tester, loadedItems: const ['item'], onBack: () => fallbackCalls++);

    expect(fallbackCalls, 0);
    expect(state.focusFirstItemCalls, 1);
  });
}
