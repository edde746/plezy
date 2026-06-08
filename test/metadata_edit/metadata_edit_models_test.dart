import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/metadata_edit/metadata_edit_models.dart';

void main() {
  test('adapter dirty tracking ignores immediate fields', () {
    final item = MediaItem(id: '1', backend: MediaBackend.plex, kind: MediaKind.movie);
    final adapter = _TestMetadataEditAdapter();
    final draft = MetadataEditDraft(
      sourceItem: item,
      currentItem: item,
      values: {'title': 'Original', 'artwork:posters': 'old-poster'},
    );

    draft.setValue('artwork:posters', 'new-poster');
    expect(adapter.hasChanges(draft), isFalse);

    draft.setValue('title', 'Edited');
    expect(adapter.hasChanges(draft), isTrue);
  });

  test('adapter dirty tracking compares string lists as sets', () {
    final item = MediaItem(id: '1', backend: MediaBackend.plex, kind: MediaKind.movie);
    final adapter = _TestMetadataEditAdapter();
    final draft = MetadataEditDraft(
      sourceItem: item,
      currentItem: item,
      values: {
        'title': 'Original',
        'genre': ['Drama', 'Action'],
        'artwork:posters': 'old-poster',
      },
    );

    draft.setValue('genre', ['Action', 'Drama']);
    expect(adapter.hasChanges(draft), isFalse);

    draft.setValue('genre', ['Action', 'Comedy']);
    expect(adapter.hasChanges(draft), isTrue);
  });
}

class _TestMetadataEditAdapter extends MetadataEditAdapter {
  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  MediaServerClient get mediaClient => throw UnimplementedError();

  @override
  bool supportsKind(MediaKind kind) => true;

  @override
  Future<MetadataEditDraft> load(MediaItem item) async => throw UnimplementedError();

  @override
  List<MetadataEditSection> buildSchema(MetadataEditDraft draft) {
    return const [
      MetadataEditSection(
        id: 'test',
        title: 'Test',
        fields: [
          MetadataEditField(id: 'title', label: 'Title', type: MetadataEditFieldType.text),
          MetadataEditField(id: 'genre', label: 'Genre', type: MetadataEditFieldType.stringList),
          MetadataEditField(
            id: 'artwork:posters',
            label: 'Poster',
            type: MetadataEditFieldType.artwork,
            saveMode: MetadataEditSaveMode.immediate,
          ),
        ],
      ),
    ];
  }

  @override
  Future<bool> save(MetadataEditDraft draft) async => true;

  @override
  Future<List<MetadataArtworkOption>> fetchArtwork(MetadataEditDraft draft, MetadataEditField field) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> applyArtworkOption(
    MetadataEditDraft draft,
    MetadataEditField field,
    MetadataArtworkOption option,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> applyArtworkFromUrl(MetadataEditDraft draft, MetadataEditField field, String url) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadArtwork(
    MetadataEditDraft draft,
    MetadataEditField field,
    List<int> bytes, {
    String? fileName,
  }) async {
    throw UnimplementedError();
  }
}
