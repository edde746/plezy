import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/refreshable.dart';

class _RefreshProbe extends StatefulWidget {
  const _RefreshProbe({this.onState});
  final void Function(_RefreshProbeState)? onState;

  @override
  State<_RefreshProbe> createState() => _RefreshProbeState();
}

class _RefreshProbeState extends State<_RefreshProbe>
    with Refreshable, FullRefreshable, FocusableTab, SearchInputFocusable, LibraryLoadable {
  int refreshCalls = 0;
  int fullRefreshCalls = 0;
  int focusActiveTabCalls = 0;
  int focusSearchInputCalls = 0;
  String? lastSearchQuery;
  String? lastLibraryKey;

  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  void refresh() => refreshCalls++;

  @override
  void fullRefresh() => fullRefreshCalls++;

  @override
  void focusActiveTabIfReady() => focusActiveTabCalls++;

  @override
  void focusSearchInput() => focusSearchInputCalls++;

  @override
  void setSearchQuery(String query) => lastSearchQuery = query;

  @override
  void loadLibraryByKey(String libraryGlobalKey) => lastLibraryKey = libraryGlobalKey;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _RefreshableOnly extends StatefulWidget {
  const _RefreshableOnly({this.onState});
  final void Function(_RefreshableOnlyState)? onState;

  @override
  State<_RefreshableOnly> createState() => _RefreshableOnlyState();
}

class _RefreshableOnlyState extends State<_RefreshableOnly> with Refreshable {
  int refreshCalls = 0;

  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  void refresh() => refreshCalls++;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _PlainProbe extends StatefulWidget {
  const _PlainProbe({this.onState});
  final void Function(_PlainProbeState)? onState;

  @override
  State<_PlainProbe> createState() => _PlainProbeState();
}

class _PlainProbeState extends State<_PlainProbe> {
  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('Refreshable', () {
    testWidgets('refresh() invokes the implementation', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      state.refresh();
      state.refresh();

      expect(state.refreshCalls, 2);
    });

    testWidgets('a State mixing in Refreshable matches an `is Refreshable` check', (tester) async {
      late _RefreshableOnlyState state;
      await tester.pumpWidget(_RefreshableOnly(onState: (s) => state = s));

      // This is the production usage: `if (currentState case final Refreshable r) r.refresh()`.
      expect(state, isA<Refreshable>());

      // Drive the refresh via the interface to mirror real callers.
      if (state case final Refreshable r) {
        r.refresh();
      }
      expect(state.refreshCalls, 1);
    });

    testWidgets('a plain State without the mixin does not match Refreshable', (tester) async {
      late _PlainProbeState state;
      await tester.pumpWidget(_PlainProbe(onState: (s) => state = s));

      expect(state, isNot(isA<Refreshable>()));
      expect(state, isNot(isA<FullRefreshable>()));
      expect(state, isNot(isA<FocusableTab>()));
      expect(state, isNot(isA<SearchInputFocusable>()));
      expect(state, isNot(isA<LibraryLoadable>()));
    });
  });

  group('FullRefreshable', () {
    testWidgets('fullRefresh() invokes the implementation', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      if (state case final FullRefreshable f) {
        f.fullRefresh();
      }

      expect(state.fullRefreshCalls, 1);
    });

    testWidgets('refresh() and fullRefresh() are independent counters', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      state.refresh();
      state.refresh();
      state.fullRefresh();

      expect(state.refreshCalls, 2);
      expect(state.fullRefreshCalls, 1);
    });
  });

  group('FocusableTab', () {
    testWidgets('focusActiveTabIfReady() invokes the implementation', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      expect(state, isA<FocusableTab>());
      state.focusActiveTabIfReady();
      expect(state.focusActiveTabCalls, 1);
    });
  });

  group('SearchInputFocusable', () {
    testWidgets('focusSearchInput() invokes the implementation', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      state.focusSearchInput();
      expect(state.focusSearchInputCalls, 1);
    });

    testWidgets('setSearchQuery() forwards the query argument', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      state.setSearchQuery('hello');
      expect(state.lastSearchQuery, 'hello');

      state.setSearchQuery('');
      expect(state.lastSearchQuery, '');
    });
  });

  group('LibraryLoadable', () {
    testWidgets('loadLibraryByKey() forwards the key argument', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      state.loadLibraryByKey('server1:42');
      expect(state.lastLibraryKey, 'server1:42');
    });
  });

  group('combined mixins', () {
    testWidgets('a State can mix in all five interface mixins simultaneously', (tester) async {
      late _RefreshProbeState state;
      await tester.pumpWidget(_RefreshProbe(onState: (s) => state = s));

      expect(state, isA<Refreshable>());
      expect(state, isA<FullRefreshable>());
      expect(state, isA<FocusableTab>());
      expect(state, isA<SearchInputFocusable>());
      expect(state, isA<LibraryLoadable>());
    });
  });
}
