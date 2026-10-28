import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/media_bookmark_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('stores a normalized local mark and removes its item when the last mark is deleted', () async {
    final saved = await MediaBookmarkService.add('open-media:opaque-hash', '  Best scene  ', 42000);

    expect(saved.label, 'Best scene');
    expect(saved.positionMs, 42000);
    final marks = MediaBookmarkService.forMedia('open-media:opaque-hash');
    expect(marks, hasLength(1));
    expect(marks.single.id, saved.id);
    expect(marks.single.label, saved.label);
    expect(marks.single.positionMs, saved.positionMs);
    expect(() => marks.clear(), throwsUnsupportedError);

    await MediaBookmarkService.remove('open-media:opaque-hash', saved.id);
    expect(MediaBookmarkService.forMedia('open-media:opaque-hash'), isEmpty);
    expect(SettingsService.instance.read(SettingsService.mediaBookmarks), isEmpty);
  });

  test('rejects invalid marks and enforces the per-item limit', () async {
    for (final (label, position) in [(' ', 0), ('valid', -1), (List.filled(81, 'x').join(), 0)]) {
      await expectLater(MediaBookmarkService.add('movie', label, position), throwsA(isA<ArgumentError>()));
    }

    for (var index = 0; index < MediaBookmarkService.maxBookmarksPerItem; index++) {
      await MediaBookmarkService.add('movie', 'Mark $index', index * 1000);
    }
    expect(MediaBookmarkService.forMedia('movie'), hasLength(MediaBookmarkService.maxBookmarksPerItem));
    await expectLater(
      MediaBookmarkService.add('movie', 'One too many', 999999),
      throwsA(isA<MediaBookmarkLimitException>()),
    );
  });
}
