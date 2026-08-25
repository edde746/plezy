import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/account_preferences_source.dart';
import 'package:plezy/media/account_preferences_target.dart';
import 'package:plezy/media/account_ref.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/screens/settings/account_preferences_detail_screen.dart';
import 'package:plezy/screens/settings/account_preferences_screen.dart';
import 'package:plezy/services/account_preferences_repository.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/backend_badge.dart';
import 'package:provider/provider.dart';

/// The Account preferences section edits values that live on a media server, so
/// the two things that cannot regress silently are capability gating — a row
/// the backend cannot store must not exist, not merely fail on save — and the
/// optimistic write, which is the only place in settings where the UI shows a
/// value the server has not accepted yet.
void main() {
  const jellyfinRef = AccountRef.mediaBrowser(backend: MediaBackend.jellyfin, connectionId: 'machine-1/user-1');
  const plexRef = AccountRef.plex(accountConnectionId: 'plex.account-1', homeUserUuid: 'home-1');

  const jellyfinTarget = AccountPreferenceTarget(
    ref: jellyfinRef,
    label: 'Basement',
    subtitle: 'agent · 192.168.1.3',
    isActiveProfileAccount: true,
  );
  const plexTarget = AccountPreferenceTarget(ref: plexRef, label: 'Plex', subtitle: 'Kids');

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  AccountPreferencesRepository repositoryOf(Map<AccountRef, AccountPreferencesSource> sources) {
    // `sourceFor` is the production injection seam: the repository resolves a
    // source per call, so a map lookup is the whole fake.
    final repository = AccountPreferencesRepository(sourceFor: (ref) async => sources[ref]);
    addTearDown(repository.dispose);
    return repository;
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    required AccountPreferencesRepository repository,
    required List<AccountPreferenceTarget> targets,
  }) async {
    // Tall enough that every group is laid out: SliverList only builds the
    // rows in the viewport, so an absent row must mean "gated out", never
    // "below the fold".
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      InputModeTracker(
        child: Provider<AccountPreferencesRepository>.value(
          value: repository,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: AccountPreferencesScreen(targets: targets),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool switchValueFor(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title)).value;

  testWidgets('several accounts are listed and open their own preferences', (tester) async {
    final repository = repositoryOf({
      jellyfinRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.jellyfin),
      plexRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.plex),
    });

    await pumpSection(tester, repository: repository, targets: const [plexTarget, jellyfinTarget]);

    expect(find.text('Basement'), findsOneWidget);
    expect(find.text('agent · 192.168.1.3'), findsOneWidget);
    expect(find.text('Plex'), findsOneWidget);
    expect(find.text('Kids'), findsOneWidget);
    expect(find.byType(BackendBadge), findsNWidgets(2));
    // Nothing is editable until an account is chosen.
    expect(find.byType(AccountPreferencesBody), findsNothing);

    await tester.tap(find.text('Basement'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountPreferencesDetailScreen), findsOneWidget);
    expect(find.text('Preferred audio language'), findsOneWidget);
  });

  testWidgets('the account the profile browses with is offered first', (tester) async {
    final repository = repositoryOf({
      jellyfinRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.jellyfin),
      plexRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.plex),
    });

    await pumpSection(tester, repository: repository, targets: const [plexTarget, jellyfinTarget]);

    expect(tester.getTopLeft(find.text('Basement')).dy, lessThan(tester.getTopLeft(find.text('Plex')).dy));
  });

  testWidgets('a single account skips the picker and edits in place', (tester) async {
    final repository = repositoryOf({
      jellyfinRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.jellyfin),
    });

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);

    expect(find.byType(AccountPreferencesBody), findsOneWidget);
    expect(find.byType(AccountPreferencesDetailScreen), findsNothing);
    // No picker: the account is neither a row nor the page title.
    expect(find.text('Basement'), findsNothing);
    expect(find.text('Account preferences'), findsOneWidget);
    expect(find.text('Preferred audio language'), findsOneWidget);
  });

  testWidgets('no accounts leaves an empty state instead of an empty list', (tester) async {
    final repository = repositoryOf(const {});

    await pumpSection(tester, repository: repository, targets: const []);

    expect(find.text('No accounts to configure'), findsOneWidget);
    expect(find.byType(AccountPreferencesBody), findsNothing);
  });

  testWidgets('a MediaBrowser account gets the library rows and no Plex-only rows', (tester) async {
    final repository = repositoryOf({
      jellyfinRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.jellyfin),
    });

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Show missing episodes'), findsOneWidget);
    expect(find.text('Hide watched items in Latest'), findsOneWidget);
    expect(find.text('Show the Collections view'), findsOneWidget);

    expect(find.text('SDH subtitles'), findsNothing);
    expect(find.text('Forced subtitles'), findsNothing);
    expect(find.text('Personal media'), findsNothing);
    expect(find.text('Watched indicators'), findsNothing);
  });

  testWidgets('a Plex account gets the Plex-only rows and no library card', (tester) async {
    final repository = repositoryOf({
      plexRef: _FakeAccountPreferencesSource(capabilities: AccountPreferencesCapabilities.plex),
    });

    await pumpSection(tester, repository: repository, targets: const [plexTarget]);

    expect(find.text('SDH subtitles'), findsOneWidget);
    expect(find.text('Forced subtitles'), findsOneWidget);
    expect(find.text('Personal media'), findsOneWidget);
    expect(find.text('Watched indicators'), findsOneWidget);
    expect(find.text('Ratings & reviews'), findsOneWidget);

    expect(find.text('Library'), findsNothing);
    expect(find.text('Show missing episodes'), findsNothing);
    expect(find.text('Hide watched items in Latest'), findsNothing);
  });

  testWidgets('current values are read from the account', (tester) async {
    final repository = repositoryOf({
      jellyfinRef: _FakeAccountPreferencesSource(
        capabilities: AccountPreferencesCapabilities.jellyfin,
        values: const {
          // Jellyfin stores 639-2; the row has to show the language, not the code.
          AccountPreferenceKey.preferredAudioLanguage: 'deu',
          AccountPreferenceKey.subtitleMode: SubtitlePlaybackMode.onlyForced,
          AccountPreferenceKey.hidePlayedInLatest: true,
        },
      ),
    });

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);

    expect(find.text('German'), findsOneWidget);
    expect(find.text('Only forced subtitles'), findsOneWidget);
    expect(find.text('No preference'), findsOneWidget);
    expect(switchValueFor(tester, 'Hide watched items in Latest'), isTrue);
  });

  testWidgets('a rejected write shows the new value, then reverts and reports', (tester) async {
    final gate = Completer<void>();
    final source = _FakeAccountPreferencesSource(
      capabilities: AccountPreferencesCapabilities.jellyfin,
      values: const {AccountPreferenceKey.hidePlayedInLatest: true},
      writeGate: gate,
      rejectWrites: true,
    );
    final repository = repositoryOf({jellyfinRef: source});

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);
    expect(switchValueFor(tester, 'Hide watched items in Latest'), isTrue);

    await tester.tap(find.text('Hide watched items in Latest'));
    await tester.pump();
    expect(
      switchValueFor(tester, 'Hide watched items in Latest'),
      isFalse,
      reason: 'the picked value must appear before the server has answered',
    );

    // A second toggle while the first write is outstanding must not queue a
    // conflicting value.
    await tester.tap(find.text('Hide watched items in Latest'));
    await tester.pump();
    expect(switchValueFor(tester, 'Hide watched items in Latest'), isFalse);

    gate.complete();
    await tester.pumpAndSettle();

    expect(source.writes, hasLength(1));
    expect(source.writes.single.boolAt(AccountPreferenceKey.hidePlayedInLatest), isFalse);
    expect(
      switchValueFor(tester, 'Hide watched items in Latest'),
      isTrue,
      reason: 'a rejected write must leave the account value on screen',
    );
    expect(find.text('Could not save changes. Try again.'), findsOneWidget);
  });

  testWidgets('an accepted write keeps the new value', (tester) async {
    final source = _FakeAccountPreferencesSource(
      capabilities: AccountPreferencesCapabilities.jellyfin,
      values: const {AccountPreferenceKey.hidePlayedInLatest: true},
    );
    final repository = repositoryOf({jellyfinRef: source});

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);

    await tester.tap(find.text('Hide watched items in Latest'));
    await tester.pumpAndSettle();

    expect(source.writes, hasLength(1));
    expect(switchValueFor(tester, 'Hide watched items in Latest'), isFalse);
    expect(repository.cached(jellyfinRef)?.hidePlayedInLatest, isFalse);
    expect(find.text('Could not save changes. Try again.'), findsNothing);
  });

  testWidgets('an unreachable account offers a retry instead of rows', (tester) async {
    // No source for the ref: the repository reports the account unreachable.
    final repository = repositoryOf(const {});

    await pumpSection(tester, repository: repository, targets: const [jellyfinTarget]);

    expect(find.text("Can't reach this account"), findsOneWidget);
    expect(find.text('Preferred audio language'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}

/// Stand-in for a transport. The account state is a key map rather than a
/// widened [AccountPreferences] copy path, so a patch applies the same way the
/// real sources apply one.
class _FakeAccountPreferencesSource implements AccountPreferencesSource {
  _FakeAccountPreferencesSource({
    required this.capabilities,
    Map<AccountPreferenceKey, Object?> values = const {},
    this.writeGate,
    this.rejectWrites = false,
  }) : _values = {...values};

  @override
  final AccountPreferencesCapabilities capabilities;

  /// Held open to observe the row while a write is in flight.
  final Completer<void>? writeGate;

  /// Writes fail instead of applying, for the revert path.
  final bool rejectWrites;

  final Map<AccountPreferenceKey, Object?> _values;
  final List<AccountPreferencesPatch> writes = [];

  @override
  Future<AccountPreferences> read() async => _snapshot();

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch) async {
    writes.add(patch);
    await writeGate?.future;
    if (rejectWrites) throw const _WriteRejected();
    _values.addAll(patch.values);
    return _snapshot();
  }

  AccountPreferences _snapshot() => AccountPreferences(
    preferredAudioLanguage: _values[AccountPreferenceKey.preferredAudioLanguage] as String?,
    playDefaultAudioTrack: _values[AccountPreferenceKey.autoSelectAudio] as bool?,
    preferredSubtitleLanguage: _values[AccountPreferenceKey.preferredSubtitleLanguage] as String?,
    subtitlePlaybackMode: _values[AccountPreferenceKey.subtitleMode] as SubtitlePlaybackMode?,
    rememberAudioSelections: _values[AccountPreferenceKey.rememberAudioSelections] as bool?,
    rememberSubtitleSelections: _values[AccountPreferenceKey.rememberSubtitleSelections] as bool?,
    autoPlayNextEpisode: _values[AccountPreferenceKey.autoPlayNextEpisode] as bool?,
    displayMissingEpisodes: _values[AccountPreferenceKey.displayMissingEpisodes] as bool?,
    hidePlayedInLatest: _values[AccountPreferenceKey.hidePlayedInLatest] as bool?,
    displayCollectionsView: _values[AccountPreferenceKey.displayCollectionsView] as bool?,
    watchedIndicator: _values[AccountPreferenceKey.watchedIndicator] as WatchedIndicatorScope?,
    mediaReviewsVisibility: _values[AccountPreferenceKey.mediaReviewsVisibility] as MediaReviewsVisibility?,
    subtitleAccessibility: _values[AccountPreferenceKey.subtitleAccessibility] as SubtitleAccessibilityPreference?,
    forcedSubtitles: _values[AccountPreferenceKey.forcedSubtitles] as ForcedSubtitlePreference?,
  );
}

/// The real sources throw the `MediaServerException` hierarchy; the rows only
/// need "an exception the write failed with".
class _WriteRejected implements Exception {
  const _WriteRejected();

  @override
  String toString() => '_WriteRejected';
}
