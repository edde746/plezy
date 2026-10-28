import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/discovery/discovery_choice.dart';
import 'package:plezy/discovery/discovery_preferences.dart';
import 'package:plezy/discovery/discovery_reranker.dart';
import 'package:plezy/discovery/discovery_store.dart';
import 'package:plezy/discovery/discovery_sync.dart';
import 'package:plezy/discovery/discovery_vote.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/sync/sync_document.dart';
import 'package:plezy/sources/sync/sync_store.dart';

DiscoveryChoice _choice({
  required String id,
  String title = 'A discovery pick',
  DiscoveryChoiceType type = DiscoveryChoiceType.ebook,
  String? sourceId,
  Map<String, String> portableIds = const {},
  String? lendingLibraryId,
  String? lendingBookId,
}) => DiscoveryChoice(
  id: id,
  type: type,
  title: title,
  subtitle: 'A subtitle',
  reason: 'A reason',
  summary: 'A summary',
  durationMs: 60_000,
  totalDurationMs: 120_000,
  isEstimate: false,
  serverId: 'private-server-$id',
  mediaId: 'private-media-$id',
  mediaKind: null,
  sourceId: sourceId,
  entryId: sourceId == null ? null : 'private-entry-$id',
  lendingLibraryId: lendingLibraryId,
  lendingBookId: lendingBookId,
  year: 2025,
  portableIds: portableIds,
);

SourceRepository _repository() => SourceRepository(
  SourceDatabase(NativeDatabase.memory()),
  protect: (value) async => value,
  reveal: (value) async => value,
);

class _MemorySyncStore implements SyncStore {
  final Map<String, String> files = {};

  @override
  Future<List<SyncFile>> list(String namespace) async => files.keys
      .where((name) => name.startsWith('plezyng-state-v1-$namespace-'))
      .map((name) => SyncFile(name, name))
      .toList(growable: false);

  @override
  Future<String> read(SyncFile file) async => files[file.id]!;

  @override
  Future<void> create(String name, String text) async {
    files[name] = text;
  }

  @override
  Future<void> delete(SyncFile file) async {
    files.remove(file.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('taste preferences normalize bounded values and tolerate one bad hidden pick', () {
    final preferences = DiscoveryTastePreferences.fromJson({
      'version': 1,
      'preferredGenres': [' Mystery   Fiction ', 'Mystery Fiction', '', 'x' * 81],
      'avoidedGenres': ['Mystery Fiction', 'Horror'],
      'hidden': [
        {'id': 'pick-1', 'title': '  Hidden\n title ', 'type': 'ebook'},
        {'id': '', 'title': 'Malformed', 'type': 'ebook'},
        {'id': 'pick-1', 'title': 'Duplicate', 'type': 'ebook'},
      ],
    });

    expect(preferences.preferredGenres, {'Mystery Fiction'});
    expect(preferences.avoidedGenres, {'Horror'});
    expect(preferences.hidden, hasLength(1));
    expect(preferences.hidden.single.title, 'Hidden title');
    expect(DiscoveryTastePreferences.fromJson({'version': 2}).hidden, isEmpty);
  });

  test('portable restoration requires an exact shared public ID, matching type and kind', () {
    final saved = _choice(id: 'saved', title: 'Same title', portableIds: const {'isbn13': '9780306406157'});
    final exactId = _choice(
      id: 'candidate',
      title: 'Different edition title',
      portableIds: const {'isbn13': '9780306406157'},
    );
    final sameTitle = _choice(id: 'other', title: 'Same title', portableIds: const {'isbn13': '9781234567897'});
    final lender = _choice(
      id: 'loan',
      title: 'Same title',
      portableIds: const {'isbn13': '9780306406157'},
      lendingLibraryId: 'library',
      lendingBookId: 'book',
    );

    expect(exactId.isSamePortableWorkAs(saved), isTrue);
    expect(sameTitle.isSamePortableWorkAs(saved), isFalse);
    expect(lender.isSamePortableWorkAs(saved), isFalse);
    expect(
      _choice(
        id: 'wrong-kind',
        type: DiscoveryChoiceType.comic,
        portableIds: const {'isbn13': '9780306406157'},
      ).isSamePortableWorkAs(saved),
      isFalse,
    );
  });

  test('shortlist consensus honors vetoes, strongest shared floor and stable ties', () {
    final balanced = _choice(id: 'balanced');
    final highFloor = _choice(id: 'high-floor');
    final vetoed = _choice(id: 'vetoed');
    expect(
      DiscoveryShortlistConsensus.chooseWinner(
        choices: [balanced, highFloor, vetoed],
        ballots: [
          {'balanced': 1, 'high-floor': 2, 'vetoed': 0},
          {'balanced': 2, 'high-floor': 2, 'vetoed': 2},
        ],
      ),
      same(highFloor),
    );

    expect(
      DiscoveryShortlistConsensus.chooseWinner(
        choices: [balanced, highFloor],
        ballots: [
          {'balanced': 1, 'high-floor': 1},
          {'balanced': 2, 'high-floor': 2},
        ],
      ),
      same(balanced),
    );
    expect(
      DiscoveryShortlistConsensus.chooseWinner(
        choices: [balanced, highFloor],
        ballots: [
          {'balanced': 0, 'high-floor': 1},
          {'balanced': 1, 'high-floor': 3},
        ],
      ),
      isNull,
    );
  });

  test('taste controls remain profile-local and reset restores hidden picks', () async {
    final repository = _repository();
    addTearDown(repository.database.close);
    final store = DiscoveryTasteStore(repository);
    final pick = _choice(id: 'hidden-pick', title: 'Hidden pick');

    await store.hide('profile-one', pick);
    await store.saveGenres('profile-one', preferred: {' Mystery '}, avoided: {'Mystery', 'Drama'});
    expect((await store.load('profile-one')).hides(pick.id), isTrue);
    expect((await store.load('profile-one')).preferredGenres, {'Mystery'});
    expect((await store.load('profile-one')).avoidedGenres, {'Drama'});
    expect((await store.load('profile-two')).hidden, isEmpty);

    await store.unhide('profile-one', pick.id);
    expect((await store.load('profile-one')).hidden, isEmpty);
    await store.hide('profile-one', pick);
    await store.resetTaste('profile-one');
    expect((await store.load('profile-one')).toJson(), const DiscoveryTastePreferences().toJson());
  });

  test('reranker sends bounded opaque candidates and rejects invented IDs', () async {
    final repository = _repository();
    addTearDown(repository.database.close);
    var replyOrder = <String>[];
    Map<String, dynamic>? requestBody;
    String? authorization;
    final reranker = DiscoveryReranker(
      repository,
      clientFactory: () => MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        authorization = request.headers['authorization'];
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({'order': replyOrder}),
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final config = DiscoveryAiConfig(
      endpoint: 'http://127.0.0.1:42219/v1',
      model: 'test-model',
      apiKey: 'local-test-secret',
      enabled: true,
    );
    expect(config.isConfigured, isTrue);
    expect(
      const DiscoveryAiConfig(
        endpoint: 'http://ranking.example/v1',
        model: 'm',
        apiKey: '',
        enabled: true,
      ).isConfigured,
      isFalse,
    );
    await reranker.save('profile', config);

    final baseline = [
      for (var index = 0; index < 30; index++)
        _choice(
          id: 'opaque-local-id-$index',
          title: 'Title $index https://private.invalid/item/$index',
          type: DiscoveryChoiceType.video,
        ),
      _choice(id: 'source-backed', sourceId: 'private-source'),
    ];
    replyOrder = [for (var index = 23; index >= 0; index--) 'c$index'];
    final reordered = await reranker.reorder(
      profileId: 'profile',
      baseline: baseline,
      genresFor: (_) => const ['Drama'],
      mediaFamily: 'watch',
      maxMinutes: 90,
      genre: 'Drama',
      mood: 'quiet',
      familiarity: 'new',
      stillCurrent: () => true,
    );

    expect(reordered!.take(24).map((choice) => choice.id), [
      for (var index = 23; index >= 0; index--) 'opaque-local-id-$index',
    ]);
    expect(reordered.skip(24).map((choice) => choice.id), [
      for (var index = 24; index < 30; index++) 'opaque-local-id-$index',
      'source-backed',
    ]);
    final messages = requestBody!['messages'] as List;
    final userMessage = jsonDecode((messages[1] as Map)['content'] as String) as Map<String, dynamic>;
    final payload = userMessage['candidates'] as List;
    expect(payload, hasLength(24));
    expect(authorization, 'Bearer local-test-secret');
    expect(jsonEncode(requestBody), isNot(contains('opaque-local-id-')));
    expect(jsonEncode(requestBody), isNot(contains('private-server-')));
    expect(jsonEncode(requestBody), isNot(contains('private-media-')));
    expect(jsonEncode(requestBody), isNot(contains('private.invalid')));
    expect(jsonEncode(requestBody), isNot(contains('local-test-secret')));

    replyOrder = ['invented-id', 'c0'];
    expect(
      await reranker.reorder(
        profileId: 'profile',
        baseline: baseline,
        genresFor: (_) => const [],
        mediaFamily: 'watch',
        maxMinutes: null,
        genre: null,
        mood: null,
        familiarity: 'any',
        stillCurrent: () => true,
      ),
      isNull,
    );
  });

  test('Saved-pick sync encrypts portable picks and never exports lender identities', () async {
    final repository = _repository();
    addTearDown(repository.database.close);
    final portable = _choice(
      id: 'local-portable-choice',
      title: 'Portable book title',
      portableIds: const {'isbn13': '9780306406157'},
    );
    final lender = _choice(
      id: 'local-lender-choice',
      title: 'Local loan title',
      portableIds: const {'isbn13': '9780306406157'},
      lendingLibraryId: 'private-library-identity',
      lendingBookId: 'private-loan-identity',
    );
    expect(lender.portableReference, isNull);
    final local = DiscoveryStore(repository);
    await local.decide('profile', portable, DiscoveryDecisionAction.save);
    await local.decide('profile', lender, DiscoveryDecisionAction.save);

    final code = SyncCipher.newCode();
    final cloud = _MemorySyncStore();
    final sync = DiscoverySync(repository);
    await sync.run(profile: 'profile', code: code, store: cloud, check: () {});

    expect(sync.lastSuccess, isNotNull);
    expect(cloud.files, hasLength(1));
    final name = cloud.files.keys.single;
    final decrypted = await SyncCipher(code).open(cloud.files.values.single, name);
    expect(decrypted.records, hasLength(1));
    final record = decrypted.records.values.single.single.value;
    final serialized = jsonEncode(record);
    expect(serialized, contains('Portable book title'));
    expect(serialized, isNot(contains('Local loan title')));
    expect(serialized, isNot(contains('private-library-identity')));
    expect(serialized, isNot(contains('private-loan-identity')));
    expect(serialized, isNot(contains('private-server-')));
  });
}
