import 'package:drift/drift.dart';

@DataClassName('DownloadedMediaItem')
class DownloadedMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get ratingKey => text()();
  TextColumn get globalKey => text().unique()();
  TextColumn get type => text()();
  TextColumn get parentRatingKey => text().nullable()();
  TextColumn get grandparentRatingKey => text().nullable()();
  IntColumn get status => integer()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get videoFilePath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get downloadedAt => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
