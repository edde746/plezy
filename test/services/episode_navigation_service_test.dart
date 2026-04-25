import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/episode_navigation_service.dart';
import 'package:provider/provider.dart';

// NOTE on coverage scope:
// `EpisodeNavigationService` has two methods:
//
//   1. `loadAdjacentEpisodes` — pure-ish: reads PlaybackStateProvider, asks for
//      next/prev episode, wraps the result. The interesting branch is the
//      "no queue active" short-circuit, which we exercise without any client
//      or network because PlaybackStateProvider can be constructed bare.
//
//   2. `navigateToEpisode` — performs full navigation through
//      [navigateToVideoPlayer], which depends on a Navigator, a
//      DownloadProvider, a MultiServerProvider, and the [SettingsService]
//      singleton. Skipped: not unit-testable without recreating the entire
//      app shell.
//
// We also cover the [AdjacentEpisodes] data class invariants since that's
// the public surface callers depend on.

PlexMetadata _meta(String ratingKey, {String? title}) =>
    PlexMetadata(ratingKey: ratingKey, title: title ?? 'Episode $ratingKey');

class _ProbeWidget extends StatefulWidget {
  const _ProbeWidget({required this.metadata, required this.onResult});

  final PlexMetadata metadata;
  final void Function(AdjacentEpisodes) onResult;

  @override
  State<_ProbeWidget> createState() => _ProbeWidgetState();
}

class _ProbeWidgetState extends State<_ProbeWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final svc = EpisodeNavigationService();
      final result = await svc.loadAdjacentEpisodes(context: context, metadata: widget.metadata);
      widget.onResult(result);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================
  // AdjacentEpisodes data class
  // ===========================================================

  group('AdjacentEpisodes', () {
    test('default constructor reports no neighbours', () {
      final ae = AdjacentEpisodes();
      expect(ae.next, isNull);
      expect(ae.previous, isNull);
      expect(ae.hasNext, isFalse);
      expect(ae.hasPrevious, isFalse);
    });

    test('next/previous flags reflect non-null fields', () {
      final ae = AdjacentEpisodes(next: _meta('n'), previous: _meta('p'));
      expect(ae.hasNext, isTrue);
      expect(ae.hasPrevious, isTrue);
      expect(ae.next!.ratingKey, 'n');
      expect(ae.previous!.ratingKey, 'p');
    });

    test('only-next variant', () {
      final ae = AdjacentEpisodes(next: _meta('n'));
      expect(ae.hasNext, isTrue);
      expect(ae.hasPrevious, isFalse);
    });

    test('only-previous variant', () {
      final ae = AdjacentEpisodes(previous: _meta('p'));
      expect(ae.hasNext, isFalse);
      expect(ae.hasPrevious, isTrue);
    });
  });

  // ===========================================================
  // loadAdjacentEpisodes: short-circuit without an active queue
  // ===========================================================

  group('loadAdjacentEpisodes', () {
    testWidgets('returns empty AdjacentEpisodes when no play queue is active', (tester) async {
      // Bare provider — no setPlaybackFromPlayQueue() call → isQueueActive = false.
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);

      AdjacentEpisodes? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<PlaybackStateProvider>.value(
          value: playback,
          child: _ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r),
        ),
      );
      // Drain the post-frame callback and the awaited service call.
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
    });

    testWidgets('catches downstream exceptions and returns empty AdjacentEpisodes', (tester) async {
      // PlaybackStateProvider not provided → context.read throws. The service
      // wraps the entire body in try/catch and returns AdjacentEpisodes() so
      // the UI never crashes when the queue subsystem is unavailable.
      AdjacentEpisodes? result;
      await tester.pumpWidget(_ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r));
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
    });
  });
}
