import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/recent_tags_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('tags are isolated by profile, server, and field', () async {
    await RecentTagsService.addRecentTags(['kids'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');
    await RecentTagsService.addRecentTags(['horror'], profileId: 'p1', serverId: 'srv-1', fieldId: 'genre');
    await RecentTagsService.addRecentTags(['other-server-tag'], profileId: 'p1', serverId: 'srv-2', fieldId: 'label');
    await RecentTagsService.addRecentTags(['other-profile-tag'], profileId: 'p2', serverId: 'srv-1', fieldId: 'label');

    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), ['kids']);
    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'genre'), ['horror']);
    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-2', fieldId: 'label'), ['other-server-tag']);
    expect(RecentTagsService.getRecentTags(profileId: 'p2', serverId: 'srv-1', fieldId: 'label'), [
      'other-profile-tag',
    ]);
  });

  test('most recent first and re-adding moves a tag to the front', () async {
    await RecentTagsService.addRecentTags(['a', 'b'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');
    await RecentTagsService.addRecentTags(['c'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');

    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), ['c', 'a', 'b']);

    await RecentTagsService.addRecentTags(['b'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');
    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), ['b', 'c', 'a']);
  });

  test('re-adding with different casing updates instead of duplicating', () async {
    await RecentTagsService.addRecentTags(['Kids'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');
    await RecentTagsService.addRecentTags(['kids'], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');

    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), ['kids']);
  });

  test('blank tags are ignored', () async {
    await RecentTagsService.addRecentTags(['', '  '], profileId: 'p1', serverId: 'srv-1', fieldId: 'label');
    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), isEmpty);
  });

  test('a corrupt payload reads as empty instead of throwing', () async {
    await SettingsService.instanceOrNull!.write(SettingsService.recentMetadataTagsForProfile('p1'), 'not json');
    expect(RecentTagsService.getRecentTags(profileId: 'p1', serverId: 'srv-1', fieldId: 'label'), isEmpty);
  });

  test('mergeSuggestions puts recents first, dedupes, and drops applied tags', () {
    final merged = RecentTagsService.mergeSuggestions(
      recent: ['kids'],
      serverTags: ['Kids', 'horror', 'documentary'],
      existing: ['documentary'],
    );

    // The recent entry wins over the server's casing variant; the already
    // applied 'documentary' is excluded.
    expect(merged, ['kids', 'horror']);
  });
}
