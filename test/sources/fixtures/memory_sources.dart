import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:plezy/sources/content_access.dart';
import 'package:plezy/sources/publication_shelf.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

class MemorySources extends ChangeNotifier implements SourceController {
  MemorySources(this.repository, Directory directory) : downloads = PublicationDownloads(repository, directory);
  @override
  final SourceRepository repository;
  @override
  final PublicationDownloads downloads;
  @override
  Future<void> get ready => Future.value();
  @override
  String? profileId = 'alice';
  @override
  bool blocked = false;
  @override
  bool loading = false;
  @override
  int generation = 1;
  @override
  SourceFailure? failure;
  @override
  List<FileSource> sources = [];
  @override
  Set<PublicationShelf> shelves = {};
  @override
  Map<String, int> scanning = {};
  @override
  Future<void> Function()? stopPlayback;
  @override
  bool current(int epoch) => generation == epoch;
  @override
  void requireSession([int? epoch]) {
    if (blocked || profileId == null || epoch != null && !current(epoch)) {
      throw const SourceException(SourceFailure.cancelled);
    }
  }

  @override
  void scheduleSync() {}
  @override
  void holdProgress(String key) {}
  @override
  void releaseProgress(String key) {}
  @override
  bool cloudConflict(String key) => false;
  @override
  Future<File?> cover(SourceEntry entry, {bool refresh = false}) async => null;
  @override
  Future<PublicationProgress> openProgress(SourceEntry entry, PublicationProgress initial) async =>
      await repository.progress(profileId!, initial.key) ?? initial;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
