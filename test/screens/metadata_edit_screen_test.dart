import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/metadata_edit/metadata_edit_models.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/metadata_edit_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/file_picker_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:provider/provider.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('immediate choices serialize commits and block edits and route dismissal', (tester) async {
    final requests = _PlexMetadataRequests();
    final harness = await _pumpEditor(tester, requests);
    final first = requests.holdNextPreferenceUpdate();

    await _chooseEpisodeSort(tester, 'Oldest first');
    await tester.pump();

    expect(requests.preferenceUpdateCalls, 1);
    expect(find.byType(LoadingIndicatorBox), findsOneWidget);
    expect(find.byTooltip('Save'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(_fieldTile('Episode Sorting'), warnIfMissed: false);
    await tester.tap(_fieldTile('Keep'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(requests.preferenceUpdateCalls, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MetadataEditScreen), findsOneWidget);

    first.complete(_ok());
    await tester.pumpAndSettle();
    expect(_tileText('Episode Sorting', 'Oldest first'), findsOneWidget);

    final second = requests.holdNextPreferenceUpdate();
    await _chooseEpisodeSort(tester, 'Newest first');
    await tester.pump();
    expect(requests.preferenceUpdateCalls, 2);
    expect(requests.maxConcurrentPreferenceUpdates, 1);

    second.complete(_ok());
    await tester.pumpAndSettle();
    expect(_tileText('Episode Sorting', 'Newest first'), findsOneWidget);
    expect(requests.serverPreferences['episodeSort'], '1');

    await harness.dispose();
  });

  testWidgets('boolean preference selection and updates use canonical choice values', (tester) async {
    final requests = _PlexMetadataRequests();
    final harness = await _pumpEditor(tester, requests);
    addTearDown(harness.dispose);

    await _scrollToImmediateChoice(tester, 'Use Original Title');
    expect(_tileText('Use Original Title', 'Yes'), findsOneWidget);

    await _chooseImmediateChoice(tester, 'Use Original Title', 'No');
    await tester.pumpAndSettle();

    expect(_tileText('Use Original Title', 'No'), findsOneWidget);
    expect(requests.preferenceUpdatePayloads.single['useOriginalTitle'], '0');
    expect(requests.serverPreferences['useOriginalTitle'], '0');

    await _chooseImmediateChoice(tester, 'Use Original Title', 'Yes');
    await tester.pumpAndSettle();

    expect(_tileText('Use Original Title', 'Yes'), findsOneWidget);
    expect(requests.preferenceUpdatePayloads.last['useOriginalTitle'], '1');
    expect(requests.preferenceUpdatePayloads.map((payload) => payload['useOriginalTitle']), orderedEquals(['0', '1']));
  });

  testWidgets('immediate failure rolls back its value and re-enables controls', (tester) async {
    final requests = _PlexMetadataRequests()..queuePreferenceResponse(_response(503));
    final harness = await _pumpEditor(tester, requests);

    await _chooseEpisodeSort(tester, 'Oldest first');
    await tester.pumpAndSettle();

    expect(_tileText('Episode Sorting', 'Library default'), findsOneWidget);
    expect(find.text('Failed to update metadata'), findsOneWidget);
    expect(find.byType(LoadingIndicatorBox), findsNothing);

    await _chooseEpisodeSort(tester, 'Newest first');
    await tester.pumpAndSettle();
    expect(_tileText('Episode Sorting', 'Newest first'), findsOneWidget);
    expect(requests.preferenceUpdateCalls, 2);

    await harness.dispose();
  });

  testWidgets('final save rejects duplicate submit and back then recovers after failure', (tester) async {
    final requests = _PlexMetadataRequests();
    final harness = await _pumpEditor(tester, requests);
    await _editTitle(tester, 'Updated title');
    final save = requests.holdNextMetadataUpdate();

    final saveAction = find.byTooltip('Save');
    await tester.tap(saveAction);
    await tester.tap(saveAction);
    await tester.pump();

    expect(requests.metadataUpdateCalls, 1);
    expect(find.byTooltip('Save'), findsNothing);
    await tester.tap(_fieldTile('Title'), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(MetadataEditScreen), findsOneWidget);

    save.complete(_response(500));
    await tester.pumpAndSettle();
    expect(find.byType(MetadataEditScreen), findsOneWidget);
    expect(find.text('Failed to update metadata'), findsOneWidget);
    expect(_tileText('Title', 'Updated title'), findsOneWidget);
    expect(find.byTooltip('Save'), findsOneWidget);

    await harness.dispose();
  });

  testWidgets('late final save completion cannot pop a replacement media editor', (tester) async {
    final requests = _PlexMetadataRequests();
    final harness = await _pumpEditor(tester, requests);
    await _editTitle(tester, 'Updated first title');
    final save = requests.holdNextMetadataUpdate();

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(requests.metadataUpdateCalls, 1);

    harness.metadata.value = _show(id: 'show-2', title: 'Second show');
    await tester.pump();
    await tester.pump();
    expect(_tileText('Title', 'Second show'), findsOneWidget);

    save.complete(_ok());
    await tester.pumpAndSettle();
    expect(find.byType(MetadataEditScreen), findsOneWidget);
    expect(_tileText('Title', 'Second show'), findsOneWidget);
    expect(find.text('Metadata updated'), findsNothing);

    await harness.dispose();
  });

  testWidgets('artwork mutation blocks cancel, back, actions, and duplicate options until success', (tester) async {
    final apply = Completer<bool>();
    final adapter = _ArtworkAdapter()..applyResult = apply.future;
    final result = _DialogResult();
    await _pumpArtworkDialog(tester, adapter, result);

    await tester.tap(_artworkOption());
    await tester.pump();
    expect(adapter.applyCalls, 1);
    expect(_dialogButton(tester, 'From URL').onPressed, isNull);
    expect(_dialogButton(tester, 'Upload File').onPressed, isNull);
    expect(_dialogButton(tester, 'Cancel').onPressed, isNull);

    await tester.tap(find.text('Cancel'), warnIfMissed: false);
    await tester.tap(_artworkOption(), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ArtworkPickerDialog), findsOneWidget);
    expect(adapter.applyCalls, 1);
    expect(result.completions, 0);

    apply.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(ArtworkPickerDialog), findsNothing);
    expect(result.completions, 1);
    expect(result.value, isTrue);
    expect(find.text('Artwork updated'), findsOneWidget);
  });

  testWidgets('upload failure keeps artwork dialog mounted and restores cancellation', (tester) async {
    final picker = _FakeFilePicker()
      ..queueResult(
        FilePickerResult([
          PlatformFile(name: 'poster.png', size: 3, bytes: Uint8List.fromList([1, 2, 3])),
        ]),
      );
    FilePickerService.setDelegateForTesting(picker);
    addTearDown(() => FilePickerService.setDelegateForTesting(null));

    final adapter = _ArtworkAdapter()..uploadResult = Future<bool>.value(false);
    final result = _DialogResult();
    await _pumpArtworkDialog(tester, adapter, result);

    await tester.tap(find.text('Upload File'));
    await tester.pumpAndSettle();

    expect(adapter.uploadCalls, 1);
    expect(find.byType(ArtworkPickerDialog), findsOneWidget);
    expect(find.text('Failed to update artwork'), findsOneWidget);
    expect(_dialogButton(tester, 'Cancel').onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result.completions, 1);
    expect(result.value, isNull);
  });

  testWidgets('picker cancellation and stale picker completion never start an upload', (tester) async {
    final picker = _FakeFilePicker()..queueResult(null);
    FilePickerService.setDelegateForTesting(picker);
    addTearDown(() => FilePickerService.setDelegateForTesting(null));

    final adapter = _ArtworkAdapter();
    final firstResult = _DialogResult();
    await _pumpArtworkDialog(tester, adapter, firstResult);

    await tester.tap(find.text('Upload File'));
    await tester.pumpAndSettle();
    expect(adapter.uploadCalls, 0);
    expect(find.byType(ArtworkPickerDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final pendingPicker = Completer<FilePickerResult?>();
    picker.queueFuture(pendingPicker.future);
    final staleResult = _DialogResult();
    await _pumpArtworkDialog(tester, adapter, staleResult);
    await tester.tap(find.text('Upload File'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    pendingPicker.complete(
      FilePickerResult([
        PlatformFile(name: 'stale.png', size: 1, bytes: Uint8List.fromList([1])),
      ]),
    );
    await tester.pumpAndSettle();

    expect(adapter.uploadCalls, 0);
    expect(staleResult.completions, 1);
    expect(staleResult.value, isNull);
    expect(find.text('Artwork updated'), findsNothing);
  });
}

Finder _fieldTile(String label) => find.widgetWithText(FocusableListTile, label);

Finder _tileText(String label, String value) {
  return find.descendant(of: _fieldTile(label), matching: find.text(value));
}

Finder _artworkOption() {
  return find.descendant(of: find.byType(GridView), matching: find.byType(FocusableWrapper)).first;
}

DialogActionButton _dialogButton(WidgetTester tester, String label) {
  return tester.widget<DialogActionButton>(find.widgetWithText(DialogActionButton, label));
}

Future<void> _chooseEpisodeSort(WidgetTester tester, String option) {
  return _chooseImmediateChoice(tester, 'Episode Sorting', option);
}

Future<void> _chooseImmediateChoice(WidgetTester tester, String labelText, String option) async {
  await _scrollToImmediateChoice(tester, labelText);
  await tester.tap(_fieldTile(labelText));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pump();
}

Future<void> _scrollToImmediateChoice(WidgetTester tester, String labelText) async {
  final label = find.text(labelText);
  await tester.scrollUntilVisible(
    label,
    300,
    scrollable: find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
  );
  await Scrollable.ensureVisible(tester.element(label), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _editTitle(WidgetTester tester, String title) async {
  final tile = _fieldTile('Title');
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), title);
  await tester.tap(find.widgetWithText(DialogActionButton, 'Save'));
  await tester.pumpAndSettle();
  expect(_tileText('Title', title), findsOneWidget);
}

Future<_EditorHarness> _pumpEditor(WidgetTester tester, _PlexMetadataRequests requests) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(database);
  final client = testPlexClient(serverId: ServerId('server-1'), handler: requests.handle);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final provider = MultiServerProvider(manager, DataAggregationService(manager));
  final metadata = ValueNotifier<MediaItem>(_show());

  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<MultiServerProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ValueListenableBuilder<MediaItem>(
                          valueListenable: metadata,
                          builder: (context, item, _) => MetadataEditScreen(metadata: item),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
  expect(find.byType(MetadataEditScreen), findsOneWidget);
  expect(_tileText('Title', 'First show'), findsOneWidget);

  return _EditorHarness(tester: tester, database: database, manager: manager, provider: provider, metadata: metadata);
}

MediaItem _show({String id = 'show-1', String title = 'First show'}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.show,
  title: title,
  originalTitle: 'Original $title',
  summary: 'Summary',
  libraryId: '1',
  serverId: 'server-1',
  thumbPath: '',
);

class _EditorHarness {
  final WidgetTester tester;
  final AppDatabase database;
  final MultiServerManager manager;
  final MultiServerProvider provider;
  final ValueNotifier<MediaItem> metadata;

  const _EditorHarness({
    required this.tester,
    required this.database,
    required this.manager,
    required this.provider,
    required this.metadata,
  });

  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    manager.dispose();
    metadata.dispose();
    await database.close();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

class _PlexMetadataRequests {
  final serverPreferences = <String, Object>{
    'episodeSort': '-1',
    'autoDeletionItemPolicyUnwatchedLibrary': '0',
    'autoDeletionItemPolicyWatchedLibrary': '0',
    'flattenSeasons': '-1',
    'showOrdering': '',
    'languageOverride': '',
    'useOriginalTitle': true,
    'audioLanguage': '',
    'subtitleLanguage': '',
    'subtitleMode': '-1',
  };
  final Queue<Future<http.Response>> _preferenceResponses = Queue();
  final List<Map<String, String>> preferenceUpdatePayloads = [];
  final Queue<Future<http.Response>> _metadataResponses = Queue();
  int preferenceUpdateCalls = 0;
  int metadataUpdateCalls = 0;
  int _activePreferenceUpdates = 0;
  int maxConcurrentPreferenceUpdates = 0;

  Completer<http.Response> holdNextPreferenceUpdate() {
    final completer = Completer<http.Response>();
    _preferenceResponses.add(completer.future);
    return completer;
  }

  Completer<http.Response> holdNextMetadataUpdate() {
    final completer = Completer<http.Response>();
    _metadataResponses.add(completer.future);
    return completer;
  }

  void queuePreferenceResponse(http.Response response) {
    _preferenceResponses.add(Future.value(response));
  }

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'GET' &&
        path.startsWith('/library/metadata/') &&
        request.url.queryParameters['includePreferences'] == '1') {
      final id = path.split('/').last;
      return jsonResponse({
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': id,
              'Setting': [
                for (final entry in serverPreferences.entries) {'id': entry.key, 'value': entry.value},
              ],
            },
          ],
        },
      });
    }

    if (request.method == 'PUT' && path.endsWith('/prefs')) {
      preferenceUpdateCalls++;
      preferenceUpdatePayloads.add(Map<String, String>.of(request.url.queryParameters));
      _activePreferenceUpdates++;
      if (_activePreferenceUpdates > maxConcurrentPreferenceUpdates) {
        maxConcurrentPreferenceUpdates = _activePreferenceUpdates;
      }
      final response = await (_preferenceResponses.isEmpty ? Future.value(_ok()) : _preferenceResponses.removeFirst());
      _activePreferenceUpdates--;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (final key in serverPreferences.keys) {
          final value = request.url.queryParameters[key];
          if (value != null) serverPreferences[key] = value;
        }
      }
      return response;
    }

    if (request.method == 'PUT' && path == '/library/sections/1/all') {
      metadataUpdateCalls++;
      return _metadataResponses.isEmpty ? _ok() : await _metadataResponses.removeFirst();
    }

    return _response(404);
  }
}

Future<void> _pumpArtworkDialog(WidgetTester tester, _ArtworkAdapter adapter, _DialogResult result) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final value = await showDialog<bool>(
                    context: context,
                    builder: (_) => ArtworkPickerDialog(adapter: adapter, draft: adapter.draft, field: adapter.field),
                  );
                  result.value = value;
                  result.completions++;
                },
                child: const Text('Open artwork'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open artwork'));
  await tester.pumpAndSettle();
  expect(find.byType(ArtworkPickerDialog), findsOneWidget);
}

class _DialogResult {
  int completions = 0;
  bool? value;
}

class _ArtworkAdapter extends MetadataEditAdapter {
  final MediaServerClient _client = _NoopMediaClient();
  late final MetadataEditDraft draft = MetadataEditDraft(
    sourceItem: _show(),
    currentItem: _show(),
    values: {'artwork:posters': ''},
  );
  late final MetadataEditField field = const MetadataEditField(
    id: 'artwork:posters',
    label: 'Poster',
    type: MetadataEditFieldType.artwork,
    saveMode: MetadataEditSaveMode.immediate,
    artwork: MetadataArtworkConfig(
      key: 'posters',
      selectTitle: 'Select Poster',
      previewWidth: 40,
      previewHeight: 60,
      gridColumns: 2,
      gridAspectRatio: 2 / 3,
    ),
  );
  Future<bool> applyResult = Future.value(true);
  Future<bool> uploadResult = Future.value(true);
  int applyCalls = 0;
  int uploadCalls = 0;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  MediaServerClient get mediaClient => _client;

  @override
  bool supportsKind(MediaKind kind) => true;

  @override
  Future<MetadataEditDraft> load(MediaItem item) async => draft;

  @override
  List<MetadataEditSection> buildSchema(MetadataEditDraft draft) => const [];

  @override
  Future<bool> save(MetadataEditDraft draft) async => true;

  @override
  Future<List<MetadataArtworkOption>> fetchArtwork(MetadataEditDraft draft, MetadataEditField field) async {
    return const [MetadataArtworkOption(id: 'option-1', thumbnailPath: '', sourceUrl: 'option-1')];
  }

  @override
  Future<bool> applyArtworkOption(MetadataEditDraft draft, MetadataEditField field, MetadataArtworkOption option) {
    applyCalls++;
    return applyResult;
  }

  @override
  Future<bool> applyArtworkFromUrl(MetadataEditDraft draft, MetadataEditField field, String url) async => true;

  @override
  Future<bool> uploadArtwork(MetadataEditDraft draft, MetadataEditField field, List<int> bytes, {String? fileName}) {
    uploadCalls++;
    return uploadResult;
  }
}

class _NoopMediaClient implements MediaServerClient {
  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  ServerId get serverId => ServerId('server-1');

  @override
  String? get serverName => 'Server';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFilePicker implements FilePickerDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final Queue<Future<FilePickerResult?>> _results = Queue();

  void queueResult(FilePickerResult? result) {
    _results.add(Future.value(result));
  }

  void queueFuture(Future<FilePickerResult?> result) {
    _results.add(result);
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) {
    return _results.removeFirst();
  }
}

http.Response _ok() => _response(200);

http.Response _response(int statusCode) {
  return http.Response('{}', statusCode, headers: const {'content-type': 'application/json'});
}
