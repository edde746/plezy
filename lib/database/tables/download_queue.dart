import 'package:drift/drift.dart';

@DataClassName('DownloadQueueItem')
class DownloadQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaGlobalKey => text().unique()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();
  BoolColumn get downloadSubtitles =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get downloadArtwork =>
      boolean().withDefault(const Constant(true))();
}
