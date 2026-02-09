// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DownloadedMediaTable extends DownloadedMedia
    with TableInfo<$DownloadedMediaTable, DownloadedMediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingKeyMeta = const VerificationMeta(
    'ratingKey',
  );
  @override
  late final GeneratedColumn<String> ratingKey = GeneratedColumn<String>(
    'rating_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalKeyMeta = const VerificationMeta(
    'globalKey',
  );
  @override
  late final GeneratedColumn<String> globalKey = GeneratedColumn<String>(
    'global_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentRatingKeyMeta = const VerificationMeta(
    'parentRatingKey',
  );
  @override
  late final GeneratedColumn<String> parentRatingKey = GeneratedColumn<String>(
    'parent_rating_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grandparentRatingKeyMeta =
      const VerificationMeta('grandparentRatingKey');
  @override
  late final GeneratedColumn<String> grandparentRatingKey =
      GeneratedColumn<String>(
        'grandparent_rating_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _videoFilePathMeta = const VerificationMeta(
    'videoFilePath',
  );
  @override
  late final GeneratedColumn<String> videoFilePath = GeneratedColumn<String>(
    'video_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<int> downloadedAt = GeneratedColumn<int>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    ratingKey,
    globalKey,
    type,
    parentRatingKey,
    grandparentRatingKey,
    status,
    progress,
    totalBytes,
    downloadedBytes,
    videoFilePath,
    thumbPath,
    downloadedAt,
    errorMessage,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedMediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('rating_key')) {
      context.handle(
        _ratingKeyMeta,
        ratingKey.isAcceptableOrUnknown(data['rating_key']!, _ratingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingKeyMeta);
    }
    if (data.containsKey('global_key')) {
      context.handle(
        _globalKeyMeta,
        globalKey.isAcceptableOrUnknown(data['global_key']!, _globalKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_globalKeyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('parent_rating_key')) {
      context.handle(
        _parentRatingKeyMeta,
        parentRatingKey.isAcceptableOrUnknown(
          data['parent_rating_key']!,
          _parentRatingKeyMeta,
        ),
      );
    }
    if (data.containsKey('grandparent_rating_key')) {
      context.handle(
        _grandparentRatingKeyMeta,
        grandparentRatingKey.isAcceptableOrUnknown(
          data['grandparent_rating_key']!,
          _grandparentRatingKeyMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('video_file_path')) {
      context.handle(
        _videoFilePathMeta,
        videoFilePath.isAcceptableOrUnknown(
          data['video_file_path']!,
          _videoFilePathMeta,
        ),
      );
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadedMediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedMediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      ratingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_key'],
      )!,
      globalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_key'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      parentRatingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_rating_key'],
      ),
      grandparentRatingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grandparent_rating_key'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      videoFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_file_path'],
      ),
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $DownloadedMediaTable createAlias(String alias) {
    return $DownloadedMediaTable(attachedDatabase, alias);
  }
}

class DownloadedMediaItem extends DataClass
    implements Insertable<DownloadedMediaItem> {
  final int id;
  final String serverId;
  final String ratingKey;
  final String globalKey;
  final String type;
  final String? parentRatingKey;
  final String? grandparentRatingKey;
  final int status;
  final int progress;
  final int? totalBytes;
  final int downloadedBytes;
  final String? videoFilePath;
  final String? thumbPath;
  final int? downloadedAt;
  final String? errorMessage;
  final int retryCount;
  const DownloadedMediaItem({
    required this.id,
    required this.serverId,
    required this.ratingKey,
    required this.globalKey,
    required this.type,
    this.parentRatingKey,
    this.grandparentRatingKey,
    required this.status,
    required this.progress,
    this.totalBytes,
    required this.downloadedBytes,
    this.videoFilePath,
    this.thumbPath,
    this.downloadedAt,
    this.errorMessage,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['rating_key'] = Variable<String>(ratingKey);
    map['global_key'] = Variable<String>(globalKey);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentRatingKey != null) {
      map['parent_rating_key'] = Variable<String>(parentRatingKey);
    }
    if (!nullToAbsent || grandparentRatingKey != null) {
      map['grandparent_rating_key'] = Variable<String>(grandparentRatingKey);
    }
    map['status'] = Variable<int>(status);
    map['progress'] = Variable<int>(progress);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    if (!nullToAbsent || videoFilePath != null) {
      map['video_file_path'] = Variable<String>(videoFilePath);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<int>(downloadedAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  DownloadedMediaCompanion toCompanion(bool nullToAbsent) {
    return DownloadedMediaCompanion(
      id: Value(id),
      serverId: Value(serverId),
      ratingKey: Value(ratingKey),
      globalKey: Value(globalKey),
      type: Value(type),
      parentRatingKey: parentRatingKey == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRatingKey),
      grandparentRatingKey: grandparentRatingKey == null && nullToAbsent
          ? const Value.absent()
          : Value(grandparentRatingKey),
      status: Value(status),
      progress: Value(progress),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      videoFilePath: videoFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoFilePath),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryCount: Value(retryCount),
    );
  }

  factory DownloadedMediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedMediaItem(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      ratingKey: serializer.fromJson<String>(json['ratingKey']),
      globalKey: serializer.fromJson<String>(json['globalKey']),
      type: serializer.fromJson<String>(json['type']),
      parentRatingKey: serializer.fromJson<String?>(json['parentRatingKey']),
      grandparentRatingKey: serializer.fromJson<String?>(
        json['grandparentRatingKey'],
      ),
      status: serializer.fromJson<int>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      videoFilePath: serializer.fromJson<String?>(json['videoFilePath']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      downloadedAt: serializer.fromJson<int?>(json['downloadedAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'ratingKey': serializer.toJson<String>(ratingKey),
      'globalKey': serializer.toJson<String>(globalKey),
      'type': serializer.toJson<String>(type),
      'parentRatingKey': serializer.toJson<String?>(parentRatingKey),
      'grandparentRatingKey': serializer.toJson<String?>(grandparentRatingKey),
      'status': serializer.toJson<int>(status),
      'progress': serializer.toJson<int>(progress),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'videoFilePath': serializer.toJson<String?>(videoFilePath),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'downloadedAt': serializer.toJson<int?>(downloadedAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  DownloadedMediaItem copyWith({
    int? id,
    String? serverId,
    String? ratingKey,
    String? globalKey,
    String? type,
    Value<String?> parentRatingKey = const Value.absent(),
    Value<String?> grandparentRatingKey = const Value.absent(),
    int? status,
    int? progress,
    Value<int?> totalBytes = const Value.absent(),
    int? downloadedBytes,
    Value<String?> videoFilePath = const Value.absent(),
    Value<String?> thumbPath = const Value.absent(),
    Value<int?> downloadedAt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    int? retryCount,
  }) => DownloadedMediaItem(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    ratingKey: ratingKey ?? this.ratingKey,
    globalKey: globalKey ?? this.globalKey,
    type: type ?? this.type,
    parentRatingKey: parentRatingKey.present
        ? parentRatingKey.value
        : this.parentRatingKey,
    grandparentRatingKey: grandparentRatingKey.present
        ? grandparentRatingKey.value
        : this.grandparentRatingKey,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    videoFilePath: videoFilePath.present
        ? videoFilePath.value
        : this.videoFilePath,
    thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryCount: retryCount ?? this.retryCount,
  );
  DownloadedMediaItem copyWithCompanion(DownloadedMediaCompanion data) {
    return DownloadedMediaItem(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      ratingKey: data.ratingKey.present ? data.ratingKey.value : this.ratingKey,
      globalKey: data.globalKey.present ? data.globalKey.value : this.globalKey,
      type: data.type.present ? data.type.value : this.type,
      parentRatingKey: data.parentRatingKey.present
          ? data.parentRatingKey.value
          : this.parentRatingKey,
      grandparentRatingKey: data.grandparentRatingKey.present
          ? data.grandparentRatingKey.value
          : this.grandparentRatingKey,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      videoFilePath: data.videoFilePath.present
          ? data.videoFilePath.value
          : this.videoFilePath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedMediaItem(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('ratingKey: $ratingKey, ')
          ..write('globalKey: $globalKey, ')
          ..write('type: $type, ')
          ..write('parentRatingKey: $parentRatingKey, ')
          ..write('grandparentRatingKey: $grandparentRatingKey, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    ratingKey,
    globalKey,
    type,
    parentRatingKey,
    grandparentRatingKey,
    status,
    progress,
    totalBytes,
    downloadedBytes,
    videoFilePath,
    thumbPath,
    downloadedAt,
    errorMessage,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedMediaItem &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.ratingKey == this.ratingKey &&
          other.globalKey == this.globalKey &&
          other.type == this.type &&
          other.parentRatingKey == this.parentRatingKey &&
          other.grandparentRatingKey == this.grandparentRatingKey &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.videoFilePath == this.videoFilePath &&
          other.thumbPath == this.thumbPath &&
          other.downloadedAt == this.downloadedAt &&
          other.errorMessage == this.errorMessage &&
          other.retryCount == this.retryCount);
}

class DownloadedMediaCompanion extends UpdateCompanion<DownloadedMediaItem> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> ratingKey;
  final Value<String> globalKey;
  final Value<String> type;
  final Value<String?> parentRatingKey;
  final Value<String?> grandparentRatingKey;
  final Value<int> status;
  final Value<int> progress;
  final Value<int?> totalBytes;
  final Value<int> downloadedBytes;
  final Value<String?> videoFilePath;
  final Value<String?> thumbPath;
  final Value<int?> downloadedAt;
  final Value<String?> errorMessage;
  final Value<int> retryCount;
  const DownloadedMediaCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.ratingKey = const Value.absent(),
    this.globalKey = const Value.absent(),
    this.type = const Value.absent(),
    this.parentRatingKey = const Value.absent(),
    this.grandparentRatingKey = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.videoFilePath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  DownloadedMediaCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String ratingKey,
    required String globalKey,
    required String type,
    this.parentRatingKey = const Value.absent(),
    this.grandparentRatingKey = const Value.absent(),
    required int status,
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.videoFilePath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : serverId = Value(serverId),
       ratingKey = Value(ratingKey),
       globalKey = Value(globalKey),
       type = Value(type),
       status = Value(status);
  static Insertable<DownloadedMediaItem> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? ratingKey,
    Expression<String>? globalKey,
    Expression<String>? type,
    Expression<String>? parentRatingKey,
    Expression<String>? grandparentRatingKey,
    Expression<int>? status,
    Expression<int>? progress,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? videoFilePath,
    Expression<String>? thumbPath,
    Expression<int>? downloadedAt,
    Expression<String>? errorMessage,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (ratingKey != null) 'rating_key': ratingKey,
      if (globalKey != null) 'global_key': globalKey,
      if (type != null) 'type': type,
      if (parentRatingKey != null) 'parent_rating_key': parentRatingKey,
      if (grandparentRatingKey != null)
        'grandparent_rating_key': grandparentRatingKey,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (videoFilePath != null) 'video_file_path': videoFilePath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  DownloadedMediaCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? ratingKey,
    Value<String>? globalKey,
    Value<String>? type,
    Value<String?>? parentRatingKey,
    Value<String?>? grandparentRatingKey,
    Value<int>? status,
    Value<int>? progress,
    Value<int?>? totalBytes,
    Value<int>? downloadedBytes,
    Value<String?>? videoFilePath,
    Value<String?>? thumbPath,
    Value<int?>? downloadedAt,
    Value<String?>? errorMessage,
    Value<int>? retryCount,
  }) {
    return DownloadedMediaCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      ratingKey: ratingKey ?? this.ratingKey,
      globalKey: globalKey ?? this.globalKey,
      type: type ?? this.type,
      parentRatingKey: parentRatingKey ?? this.parentRatingKey,
      grandparentRatingKey: grandparentRatingKey ?? this.grandparentRatingKey,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      thumbPath: thumbPath ?? this.thumbPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (ratingKey.present) {
      map['rating_key'] = Variable<String>(ratingKey.value);
    }
    if (globalKey.present) {
      map['global_key'] = Variable<String>(globalKey.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentRatingKey.present) {
      map['parent_rating_key'] = Variable<String>(parentRatingKey.value);
    }
    if (grandparentRatingKey.present) {
      map['grandparent_rating_key'] = Variable<String>(
        grandparentRatingKey.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (videoFilePath.present) {
      map['video_file_path'] = Variable<String>(videoFilePath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<int>(downloadedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedMediaCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('ratingKey: $ratingKey, ')
          ..write('globalKey: $globalKey, ')
          ..write('type: $type, ')
          ..write('parentRatingKey: $parentRatingKey, ')
          ..write('grandparentRatingKey: $grandparentRatingKey, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $DownloadQueueTable extends DownloadQueue
    with TableInfo<$DownloadQueueTable, DownloadQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaGlobalKeyMeta = const VerificationMeta(
    'mediaGlobalKey',
  );
  @override
  late final GeneratedColumn<String> mediaGlobalKey = GeneratedColumn<String>(
    'media_global_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadSubtitlesMeta = const VerificationMeta(
    'downloadSubtitles',
  );
  @override
  late final GeneratedColumn<bool> downloadSubtitles = GeneratedColumn<bool>(
    'download_subtitles',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("download_subtitles" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _downloadArtworkMeta = const VerificationMeta(
    'downloadArtwork',
  );
  @override
  late final GeneratedColumn<bool> downloadArtwork = GeneratedColumn<bool>(
    'download_artwork',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("download_artwork" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaGlobalKey,
    priority,
    addedAt,
    downloadSubtitles,
    downloadArtwork,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_global_key')) {
      context.handle(
        _mediaGlobalKeyMeta,
        mediaGlobalKey.isAcceptableOrUnknown(
          data['media_global_key']!,
          _mediaGlobalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaGlobalKeyMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('download_subtitles')) {
      context.handle(
        _downloadSubtitlesMeta,
        downloadSubtitles.isAcceptableOrUnknown(
          data['download_subtitles']!,
          _downloadSubtitlesMeta,
        ),
      );
    }
    if (data.containsKey('download_artwork')) {
      context.handle(
        _downloadArtworkMeta,
        downloadArtwork.isAcceptableOrUnknown(
          data['download_artwork']!,
          _downloadArtworkMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mediaGlobalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_global_key'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      downloadSubtitles: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}download_subtitles'],
      )!,
      downloadArtwork: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}download_artwork'],
      )!,
    );
  }

  @override
  $DownloadQueueTable createAlias(String alias) {
    return $DownloadQueueTable(attachedDatabase, alias);
  }
}

class DownloadQueueItem extends DataClass
    implements Insertable<DownloadQueueItem> {
  final int id;
  final String mediaGlobalKey;
  final int priority;
  final int addedAt;
  final bool downloadSubtitles;
  final bool downloadArtwork;
  const DownloadQueueItem({
    required this.id,
    required this.mediaGlobalKey,
    required this.priority,
    required this.addedAt,
    required this.downloadSubtitles,
    required this.downloadArtwork,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_global_key'] = Variable<String>(mediaGlobalKey);
    map['priority'] = Variable<int>(priority);
    map['added_at'] = Variable<int>(addedAt);
    map['download_subtitles'] = Variable<bool>(downloadSubtitles);
    map['download_artwork'] = Variable<bool>(downloadArtwork);
    return map;
  }

  DownloadQueueCompanion toCompanion(bool nullToAbsent) {
    return DownloadQueueCompanion(
      id: Value(id),
      mediaGlobalKey: Value(mediaGlobalKey),
      priority: Value(priority),
      addedAt: Value(addedAt),
      downloadSubtitles: Value(downloadSubtitles),
      downloadArtwork: Value(downloadArtwork),
    );
  }

  factory DownloadQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadQueueItem(
      id: serializer.fromJson<int>(json['id']),
      mediaGlobalKey: serializer.fromJson<String>(json['mediaGlobalKey']),
      priority: serializer.fromJson<int>(json['priority']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      downloadSubtitles: serializer.fromJson<bool>(json['downloadSubtitles']),
      downloadArtwork: serializer.fromJson<bool>(json['downloadArtwork']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaGlobalKey': serializer.toJson<String>(mediaGlobalKey),
      'priority': serializer.toJson<int>(priority),
      'addedAt': serializer.toJson<int>(addedAt),
      'downloadSubtitles': serializer.toJson<bool>(downloadSubtitles),
      'downloadArtwork': serializer.toJson<bool>(downloadArtwork),
    };
  }

  DownloadQueueItem copyWith({
    int? id,
    String? mediaGlobalKey,
    int? priority,
    int? addedAt,
    bool? downloadSubtitles,
    bool? downloadArtwork,
  }) => DownloadQueueItem(
    id: id ?? this.id,
    mediaGlobalKey: mediaGlobalKey ?? this.mediaGlobalKey,
    priority: priority ?? this.priority,
    addedAt: addedAt ?? this.addedAt,
    downloadSubtitles: downloadSubtitles ?? this.downloadSubtitles,
    downloadArtwork: downloadArtwork ?? this.downloadArtwork,
  );
  DownloadQueueItem copyWithCompanion(DownloadQueueCompanion data) {
    return DownloadQueueItem(
      id: data.id.present ? data.id.value : this.id,
      mediaGlobalKey: data.mediaGlobalKey.present
          ? data.mediaGlobalKey.value
          : this.mediaGlobalKey,
      priority: data.priority.present ? data.priority.value : this.priority,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      downloadSubtitles: data.downloadSubtitles.present
          ? data.downloadSubtitles.value
          : this.downloadSubtitles,
      downloadArtwork: data.downloadArtwork.present
          ? data.downloadArtwork.value
          : this.downloadArtwork,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadQueueItem(')
          ..write('id: $id, ')
          ..write('mediaGlobalKey: $mediaGlobalKey, ')
          ..write('priority: $priority, ')
          ..write('addedAt: $addedAt, ')
          ..write('downloadSubtitles: $downloadSubtitles, ')
          ..write('downloadArtwork: $downloadArtwork')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaGlobalKey,
    priority,
    addedAt,
    downloadSubtitles,
    downloadArtwork,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadQueueItem &&
          other.id == this.id &&
          other.mediaGlobalKey == this.mediaGlobalKey &&
          other.priority == this.priority &&
          other.addedAt == this.addedAt &&
          other.downloadSubtitles == this.downloadSubtitles &&
          other.downloadArtwork == this.downloadArtwork);
}

class DownloadQueueCompanion extends UpdateCompanion<DownloadQueueItem> {
  final Value<int> id;
  final Value<String> mediaGlobalKey;
  final Value<int> priority;
  final Value<int> addedAt;
  final Value<bool> downloadSubtitles;
  final Value<bool> downloadArtwork;
  const DownloadQueueCompanion({
    this.id = const Value.absent(),
    this.mediaGlobalKey = const Value.absent(),
    this.priority = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.downloadSubtitles = const Value.absent(),
    this.downloadArtwork = const Value.absent(),
  });
  DownloadQueueCompanion.insert({
    this.id = const Value.absent(),
    required String mediaGlobalKey,
    this.priority = const Value.absent(),
    required int addedAt,
    this.downloadSubtitles = const Value.absent(),
    this.downloadArtwork = const Value.absent(),
  }) : mediaGlobalKey = Value(mediaGlobalKey),
       addedAt = Value(addedAt);
  static Insertable<DownloadQueueItem> custom({
    Expression<int>? id,
    Expression<String>? mediaGlobalKey,
    Expression<int>? priority,
    Expression<int>? addedAt,
    Expression<bool>? downloadSubtitles,
    Expression<bool>? downloadArtwork,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaGlobalKey != null) 'media_global_key': mediaGlobalKey,
      if (priority != null) 'priority': priority,
      if (addedAt != null) 'added_at': addedAt,
      if (downloadSubtitles != null) 'download_subtitles': downloadSubtitles,
      if (downloadArtwork != null) 'download_artwork': downloadArtwork,
    });
  }

  DownloadQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? mediaGlobalKey,
    Value<int>? priority,
    Value<int>? addedAt,
    Value<bool>? downloadSubtitles,
    Value<bool>? downloadArtwork,
  }) {
    return DownloadQueueCompanion(
      id: id ?? this.id,
      mediaGlobalKey: mediaGlobalKey ?? this.mediaGlobalKey,
      priority: priority ?? this.priority,
      addedAt: addedAt ?? this.addedAt,
      downloadSubtitles: downloadSubtitles ?? this.downloadSubtitles,
      downloadArtwork: downloadArtwork ?? this.downloadArtwork,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaGlobalKey.present) {
      map['media_global_key'] = Variable<String>(mediaGlobalKey.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (downloadSubtitles.present) {
      map['download_subtitles'] = Variable<bool>(downloadSubtitles.value);
    }
    if (downloadArtwork.present) {
      map['download_artwork'] = Variable<bool>(downloadArtwork.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadQueueCompanion(')
          ..write('id: $id, ')
          ..write('mediaGlobalKey: $mediaGlobalKey, ')
          ..write('priority: $priority, ')
          ..write('addedAt: $addedAt, ')
          ..write('downloadSubtitles: $downloadSubtitles, ')
          ..write('downloadArtwork: $downloadArtwork')
          ..write(')'))
        .toString();
  }
}

class $ApiCacheTable extends ApiCache
    with TableInfo<$ApiCacheTable, ApiCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, data, pinned, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  ApiCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCacheData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ApiCacheTable createAlias(String alias) {
    return $ApiCacheTable(attachedDatabase, alias);
  }
}

class ApiCacheData extends DataClass implements Insertable<ApiCacheData> {
  /// Composite key: serverId:endpoint (e.g., "abc123:/library/metadata/12345")
  final String cacheKey;

  /// JSON response data
  final String data;

  /// Whether this item is pinned for offline access
  final bool pinned;

  /// Timestamp for cache invalidation (optional future use)
  final DateTime cachedAt;
  const ApiCacheData({
    required this.cacheKey,
    required this.data,
    required this.pinned,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data'] = Variable<String>(data);
    map['pinned'] = Variable<bool>(pinned);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ApiCacheCompanion toCompanion(bool nullToAbsent) {
    return ApiCacheCompanion(
      cacheKey: Value(cacheKey),
      data: Value(data),
      pinned: Value(pinned),
      cachedAt: Value(cachedAt),
    );
  }

  factory ApiCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      data: serializer.fromJson<String>(json['data']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'data': serializer.toJson<String>(data),
      'pinned': serializer.toJson<bool>(pinned),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ApiCacheData copyWith({
    String? cacheKey,
    String? data,
    bool? pinned,
    DateTime? cachedAt,
  }) => ApiCacheData(
    cacheKey: cacheKey ?? this.cacheKey,
    data: data ?? this.data,
    pinned: pinned ?? this.pinned,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ApiCacheData copyWithCompanion(ApiCacheCompanion data) {
    return ApiCacheData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      data: data.data.present ? data.data.value : this.data,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('pinned: $pinned, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, data, pinned, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCacheData &&
          other.cacheKey == this.cacheKey &&
          other.data == this.data &&
          other.pinned == this.pinned &&
          other.cachedAt == this.cachedAt);
}

class ApiCacheCompanion extends UpdateCompanion<ApiCacheData> {
  final Value<String> cacheKey;
  final Value<String> data;
  final Value<bool> pinned;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ApiCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.data = const Value.absent(),
    this.pinned = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCacheCompanion.insert({
    required String cacheKey,
    required String data,
    this.pinned = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       data = Value(data);
  static Insertable<ApiCacheData> custom({
    Expression<String>? cacheKey,
    Expression<String>? data,
    Expression<bool>? pinned,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (data != null) 'data': data,
      if (pinned != null) 'pinned': pinned,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCacheCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? data,
    Value<bool>? pinned,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return ApiCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      data: data ?? this.data,
      pinned: pinned ?? this.pinned,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('pinned: $pinned, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineWatchProgressTable extends OfflineWatchProgress
    with TableInfo<$OfflineWatchProgressTable, OfflineWatchProgressItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineWatchProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingKeyMeta = const VerificationMeta(
    'ratingKey',
  );
  @override
  late final GeneratedColumn<String> ratingKey = GeneratedColumn<String>(
    'rating_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalKeyMeta = const VerificationMeta(
    'globalKey',
  );
  @override
  late final GeneratedColumn<String> globalKey = GeneratedColumn<String>(
    'global_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewOffsetMeta = const VerificationMeta(
    'viewOffset',
  );
  @override
  late final GeneratedColumn<int> viewOffset = GeneratedColumn<int>(
    'view_offset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shouldMarkWatchedMeta = const VerificationMeta(
    'shouldMarkWatched',
  );
  @override
  late final GeneratedColumn<bool> shouldMarkWatched = GeneratedColumn<bool>(
    'should_mark_watched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("should_mark_watched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    ratingKey,
    globalKey,
    actionType,
    viewOffset,
    duration,
    shouldMarkWatched,
    createdAt,
    updatedAt,
    syncAttempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_watch_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineWatchProgressItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('rating_key')) {
      context.handle(
        _ratingKeyMeta,
        ratingKey.isAcceptableOrUnknown(data['rating_key']!, _ratingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingKeyMeta);
    }
    if (data.containsKey('global_key')) {
      context.handle(
        _globalKeyMeta,
        globalKey.isAcceptableOrUnknown(data['global_key']!, _globalKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_globalKeyMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('view_offset')) {
      context.handle(
        _viewOffsetMeta,
        viewOffset.isAcceptableOrUnknown(data['view_offset']!, _viewOffsetMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('should_mark_watched')) {
      context.handle(
        _shouldMarkWatchedMeta,
        shouldMarkWatched.isAcceptableOrUnknown(
          data['should_mark_watched']!,
          _shouldMarkWatchedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineWatchProgressItem map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineWatchProgressItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      ratingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_key'],
      )!,
      globalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_key'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      viewOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}view_offset'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      shouldMarkWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}should_mark_watched'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OfflineWatchProgressTable createAlias(String alias) {
    return $OfflineWatchProgressTable(attachedDatabase, alias);
  }
}

class OfflineWatchProgressItem extends DataClass
    implements Insertable<OfflineWatchProgressItem> {
  /// Auto-incrementing primary key
  final int id;

  /// Server ID this media belongs to
  final String serverId;

  /// Rating key of the media item
  final String ratingKey;

  /// Global key (serverId:ratingKey) for easy lookup
  final String globalKey;

  /// Type of action: 'progress', 'watched', 'unwatched'
  final String actionType;

  /// Current playback position in milliseconds (for 'progress' actions)
  final int? viewOffset;

  /// Duration of the media in milliseconds (for calculating percentage)
  final int? duration;

  /// Whether this item should be marked as watched (for progress sync)
  /// Auto-set to true when viewOffset >= 90% of duration
  final bool shouldMarkWatched;

  /// Timestamp when this action was recorded (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when this action was last updated (for merging progress updates)
  final int updatedAt;

  /// Number of sync attempts (for retry logic)
  final int syncAttempts;

  /// Last sync error message
  final String? lastError;
  const OfflineWatchProgressItem({
    required this.id,
    required this.serverId,
    required this.ratingKey,
    required this.globalKey,
    required this.actionType,
    this.viewOffset,
    this.duration,
    required this.shouldMarkWatched,
    required this.createdAt,
    required this.updatedAt,
    required this.syncAttempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['rating_key'] = Variable<String>(ratingKey);
    map['global_key'] = Variable<String>(globalKey);
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || viewOffset != null) {
      map['view_offset'] = Variable<int>(viewOffset);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['should_mark_watched'] = Variable<bool>(shouldMarkWatched);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OfflineWatchProgressCompanion toCompanion(bool nullToAbsent) {
    return OfflineWatchProgressCompanion(
      id: Value(id),
      serverId: Value(serverId),
      ratingKey: Value(ratingKey),
      globalKey: Value(globalKey),
      actionType: Value(actionType),
      viewOffset: viewOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(viewOffset),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      shouldMarkWatched: Value(shouldMarkWatched),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncAttempts: Value(syncAttempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OfflineWatchProgressItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineWatchProgressItem(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      ratingKey: serializer.fromJson<String>(json['ratingKey']),
      globalKey: serializer.fromJson<String>(json['globalKey']),
      actionType: serializer.fromJson<String>(json['actionType']),
      viewOffset: serializer.fromJson<int?>(json['viewOffset']),
      duration: serializer.fromJson<int?>(json['duration']),
      shouldMarkWatched: serializer.fromJson<bool>(json['shouldMarkWatched']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'ratingKey': serializer.toJson<String>(ratingKey),
      'globalKey': serializer.toJson<String>(globalKey),
      'actionType': serializer.toJson<String>(actionType),
      'viewOffset': serializer.toJson<int?>(viewOffset),
      'duration': serializer.toJson<int?>(duration),
      'shouldMarkWatched': serializer.toJson<bool>(shouldMarkWatched),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OfflineWatchProgressItem copyWith({
    int? id,
    String? serverId,
    String? ratingKey,
    String? globalKey,
    String? actionType,
    Value<int?> viewOffset = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    bool? shouldMarkWatched,
    int? createdAt,
    int? updatedAt,
    int? syncAttempts,
    Value<String?> lastError = const Value.absent(),
  }) => OfflineWatchProgressItem(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    ratingKey: ratingKey ?? this.ratingKey,
    globalKey: globalKey ?? this.globalKey,
    actionType: actionType ?? this.actionType,
    viewOffset: viewOffset.present ? viewOffset.value : this.viewOffset,
    duration: duration.present ? duration.value : this.duration,
    shouldMarkWatched: shouldMarkWatched ?? this.shouldMarkWatched,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OfflineWatchProgressItem copyWithCompanion(
    OfflineWatchProgressCompanion data,
  ) {
    return OfflineWatchProgressItem(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      ratingKey: data.ratingKey.present ? data.ratingKey.value : this.ratingKey,
      globalKey: data.globalKey.present ? data.globalKey.value : this.globalKey,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      viewOffset: data.viewOffset.present
          ? data.viewOffset.value
          : this.viewOffset,
      duration: data.duration.present ? data.duration.value : this.duration,
      shouldMarkWatched: data.shouldMarkWatched.present
          ? data.shouldMarkWatched.value
          : this.shouldMarkWatched,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineWatchProgressItem(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('ratingKey: $ratingKey, ')
          ..write('globalKey: $globalKey, ')
          ..write('actionType: $actionType, ')
          ..write('viewOffset: $viewOffset, ')
          ..write('duration: $duration, ')
          ..write('shouldMarkWatched: $shouldMarkWatched, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    ratingKey,
    globalKey,
    actionType,
    viewOffset,
    duration,
    shouldMarkWatched,
    createdAt,
    updatedAt,
    syncAttempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineWatchProgressItem &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.ratingKey == this.ratingKey &&
          other.globalKey == this.globalKey &&
          other.actionType == this.actionType &&
          other.viewOffset == this.viewOffset &&
          other.duration == this.duration &&
          other.shouldMarkWatched == this.shouldMarkWatched &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncAttempts == this.syncAttempts &&
          other.lastError == this.lastError);
}

class OfflineWatchProgressCompanion
    extends UpdateCompanion<OfflineWatchProgressItem> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> ratingKey;
  final Value<String> globalKey;
  final Value<String> actionType;
  final Value<int?> viewOffset;
  final Value<int?> duration;
  final Value<bool> shouldMarkWatched;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> syncAttempts;
  final Value<String?> lastError;
  const OfflineWatchProgressCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.ratingKey = const Value.absent(),
    this.globalKey = const Value.absent(),
    this.actionType = const Value.absent(),
    this.viewOffset = const Value.absent(),
    this.duration = const Value.absent(),
    this.shouldMarkWatched = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OfflineWatchProgressCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String ratingKey,
    required String globalKey,
    required String actionType,
    this.viewOffset = const Value.absent(),
    this.duration = const Value.absent(),
    this.shouldMarkWatched = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : serverId = Value(serverId),
       ratingKey = Value(ratingKey),
       globalKey = Value(globalKey),
       actionType = Value(actionType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OfflineWatchProgressItem> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? ratingKey,
    Expression<String>? globalKey,
    Expression<String>? actionType,
    Expression<int>? viewOffset,
    Expression<int>? duration,
    Expression<bool>? shouldMarkWatched,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? syncAttempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (ratingKey != null) 'rating_key': ratingKey,
      if (globalKey != null) 'global_key': globalKey,
      if (actionType != null) 'action_type': actionType,
      if (viewOffset != null) 'view_offset': viewOffset,
      if (duration != null) 'duration': duration,
      if (shouldMarkWatched != null) 'should_mark_watched': shouldMarkWatched,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OfflineWatchProgressCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? ratingKey,
    Value<String>? globalKey,
    Value<String>? actionType,
    Value<int?>? viewOffset,
    Value<int?>? duration,
    Value<bool>? shouldMarkWatched,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? syncAttempts,
    Value<String?>? lastError,
  }) {
    return OfflineWatchProgressCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      ratingKey: ratingKey ?? this.ratingKey,
      globalKey: globalKey ?? this.globalKey,
      actionType: actionType ?? this.actionType,
      viewOffset: viewOffset ?? this.viewOffset,
      duration: duration ?? this.duration,
      shouldMarkWatched: shouldMarkWatched ?? this.shouldMarkWatched,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (ratingKey.present) {
      map['rating_key'] = Variable<String>(ratingKey.value);
    }
    if (globalKey.present) {
      map['global_key'] = Variable<String>(globalKey.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (viewOffset.present) {
      map['view_offset'] = Variable<int>(viewOffset.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (shouldMarkWatched.present) {
      map['should_mark_watched'] = Variable<bool>(shouldMarkWatched.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineWatchProgressCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('ratingKey: $ratingKey, ')
          ..write('globalKey: $globalKey, ')
          ..write('actionType: $actionType, ')
          ..write('viewOffset: $viewOffset, ')
          ..write('duration: $duration, ')
          ..write('shouldMarkWatched: $shouldMarkWatched, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadedMediaTable downloadedMedia = $DownloadedMediaTable(
    this,
  );
  late final $DownloadQueueTable downloadQueue = $DownloadQueueTable(this);
  late final $ApiCacheTable apiCache = $ApiCacheTable(this);
  late final $OfflineWatchProgressTable offlineWatchProgress =
      $OfflineWatchProgressTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    downloadedMedia,
    downloadQueue,
    apiCache,
    offlineWatchProgress,
  ];
}

typedef $$DownloadedMediaTableCreateCompanionBuilder =
    DownloadedMediaCompanion Function({
      Value<int> id,
      required String serverId,
      required String ratingKey,
      required String globalKey,
      required String type,
      Value<String?> parentRatingKey,
      Value<String?> grandparentRatingKey,
      required int status,
      Value<int> progress,
      Value<int?> totalBytes,
      Value<int> downloadedBytes,
      Value<String?> videoFilePath,
      Value<String?> thumbPath,
      Value<int?> downloadedAt,
      Value<String?> errorMessage,
      Value<int> retryCount,
    });
typedef $$DownloadedMediaTableUpdateCompanionBuilder =
    DownloadedMediaCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> ratingKey,
      Value<String> globalKey,
      Value<String> type,
      Value<String?> parentRatingKey,
      Value<String?> grandparentRatingKey,
      Value<int> status,
      Value<int> progress,
      Value<int?> totalBytes,
      Value<int> downloadedBytes,
      Value<String?> videoFilePath,
      Value<String?> thumbPath,
      Value<int?> downloadedAt,
      Value<String?> errorMessage,
      Value<int> retryCount,
    });

class $$DownloadedMediaTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedMediaTable> {
  $$DownloadedMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratingKey => $composableBuilder(
    column: $table.ratingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalKey => $composableBuilder(
    column: $table.globalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentRatingKey => $composableBuilder(
    column: $table.parentRatingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grandparentRatingKey => $composableBuilder(
    column: $table.grandparentRatingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoFilePath => $composableBuilder(
    column: $table.videoFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedMediaTable> {
  $$DownloadedMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratingKey => $composableBuilder(
    column: $table.ratingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalKey => $composableBuilder(
    column: $table.globalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentRatingKey => $composableBuilder(
    column: $table.parentRatingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grandparentRatingKey => $composableBuilder(
    column: $table.grandparentRatingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoFilePath => $composableBuilder(
    column: $table.videoFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedMediaTable> {
  $$DownloadedMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get ratingKey =>
      $composableBuilder(column: $table.ratingKey, builder: (column) => column);

  GeneratedColumn<String> get globalKey =>
      $composableBuilder(column: $table.globalKey, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get parentRatingKey => $composableBuilder(
    column: $table.parentRatingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grandparentRatingKey => $composableBuilder(
    column: $table.grandparentRatingKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoFilePath => $composableBuilder(
    column: $table.videoFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$DownloadedMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedMediaTable,
          DownloadedMediaItem,
          $$DownloadedMediaTableFilterComposer,
          $$DownloadedMediaTableOrderingComposer,
          $$DownloadedMediaTableAnnotationComposer,
          $$DownloadedMediaTableCreateCompanionBuilder,
          $$DownloadedMediaTableUpdateCompanionBuilder,
          (
            DownloadedMediaItem,
            BaseReferences<
              _$AppDatabase,
              $DownloadedMediaTable,
              DownloadedMediaItem
            >,
          ),
          DownloadedMediaItem,
          PrefetchHooks Function()
        > {
  $$DownloadedMediaTableTableManager(
    _$AppDatabase db,
    $DownloadedMediaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> ratingKey = const Value.absent(),
                Value<String> globalKey = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> parentRatingKey = const Value.absent(),
                Value<String?> grandparentRatingKey = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> videoFilePath = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<int?> downloadedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => DownloadedMediaCompanion(
                id: id,
                serverId: serverId,
                ratingKey: ratingKey,
                globalKey: globalKey,
                type: type,
                parentRatingKey: parentRatingKey,
                grandparentRatingKey: grandparentRatingKey,
                status: status,
                progress: progress,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                videoFilePath: videoFilePath,
                thumbPath: thumbPath,
                downloadedAt: downloadedAt,
                errorMessage: errorMessage,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String ratingKey,
                required String globalKey,
                required String type,
                Value<String?> parentRatingKey = const Value.absent(),
                Value<String?> grandparentRatingKey = const Value.absent(),
                required int status,
                Value<int> progress = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> videoFilePath = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<int?> downloadedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => DownloadedMediaCompanion.insert(
                id: id,
                serverId: serverId,
                ratingKey: ratingKey,
                globalKey: globalKey,
                type: type,
                parentRatingKey: parentRatingKey,
                grandparentRatingKey: grandparentRatingKey,
                status: status,
                progress: progress,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                videoFilePath: videoFilePath,
                thumbPath: thumbPath,
                downloadedAt: downloadedAt,
                errorMessage: errorMessage,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedMediaTable,
      DownloadedMediaItem,
      $$DownloadedMediaTableFilterComposer,
      $$DownloadedMediaTableOrderingComposer,
      $$DownloadedMediaTableAnnotationComposer,
      $$DownloadedMediaTableCreateCompanionBuilder,
      $$DownloadedMediaTableUpdateCompanionBuilder,
      (
        DownloadedMediaItem,
        BaseReferences<
          _$AppDatabase,
          $DownloadedMediaTable,
          DownloadedMediaItem
        >,
      ),
      DownloadedMediaItem,
      PrefetchHooks Function()
    >;
typedef $$DownloadQueueTableCreateCompanionBuilder =
    DownloadQueueCompanion Function({
      Value<int> id,
      required String mediaGlobalKey,
      Value<int> priority,
      required int addedAt,
      Value<bool> downloadSubtitles,
      Value<bool> downloadArtwork,
    });
typedef $$DownloadQueueTableUpdateCompanionBuilder =
    DownloadQueueCompanion Function({
      Value<int> id,
      Value<String> mediaGlobalKey,
      Value<int> priority,
      Value<int> addedAt,
      Value<bool> downloadSubtitles,
      Value<bool> downloadArtwork,
    });

class $$DownloadQueueTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadQueueTable> {
  $$DownloadQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaGlobalKey => $composableBuilder(
    column: $table.mediaGlobalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get downloadSubtitles => $composableBuilder(
    column: $table.downloadSubtitles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get downloadArtwork => $composableBuilder(
    column: $table.downloadArtwork,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadQueueTable> {
  $$DownloadQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaGlobalKey => $composableBuilder(
    column: $table.mediaGlobalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get downloadSubtitles => $composableBuilder(
    column: $table.downloadSubtitles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get downloadArtwork => $composableBuilder(
    column: $table.downloadArtwork,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadQueueTable> {
  $$DownloadQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaGlobalKey => $composableBuilder(
    column: $table.mediaGlobalKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<bool> get downloadSubtitles => $composableBuilder(
    column: $table.downloadSubtitles,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get downloadArtwork => $composableBuilder(
    column: $table.downloadArtwork,
    builder: (column) => column,
  );
}

class $$DownloadQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadQueueTable,
          DownloadQueueItem,
          $$DownloadQueueTableFilterComposer,
          $$DownloadQueueTableOrderingComposer,
          $$DownloadQueueTableAnnotationComposer,
          $$DownloadQueueTableCreateCompanionBuilder,
          $$DownloadQueueTableUpdateCompanionBuilder,
          (
            DownloadQueueItem,
            BaseReferences<
              _$AppDatabase,
              $DownloadQueueTable,
              DownloadQueueItem
            >,
          ),
          DownloadQueueItem,
          PrefetchHooks Function()
        > {
  $$DownloadQueueTableTableManager(_$AppDatabase db, $DownloadQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mediaGlobalKey = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<bool> downloadSubtitles = const Value.absent(),
                Value<bool> downloadArtwork = const Value.absent(),
              }) => DownloadQueueCompanion(
                id: id,
                mediaGlobalKey: mediaGlobalKey,
                priority: priority,
                addedAt: addedAt,
                downloadSubtitles: downloadSubtitles,
                downloadArtwork: downloadArtwork,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mediaGlobalKey,
                Value<int> priority = const Value.absent(),
                required int addedAt,
                Value<bool> downloadSubtitles = const Value.absent(),
                Value<bool> downloadArtwork = const Value.absent(),
              }) => DownloadQueueCompanion.insert(
                id: id,
                mediaGlobalKey: mediaGlobalKey,
                priority: priority,
                addedAt: addedAt,
                downloadSubtitles: downloadSubtitles,
                downloadArtwork: downloadArtwork,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadQueueTable,
      DownloadQueueItem,
      $$DownloadQueueTableFilterComposer,
      $$DownloadQueueTableOrderingComposer,
      $$DownloadQueueTableAnnotationComposer,
      $$DownloadQueueTableCreateCompanionBuilder,
      $$DownloadQueueTableUpdateCompanionBuilder,
      (
        DownloadQueueItem,
        BaseReferences<_$AppDatabase, $DownloadQueueTable, DownloadQueueItem>,
      ),
      DownloadQueueItem,
      PrefetchHooks Function()
    >;
typedef $$ApiCacheTableCreateCompanionBuilder =
    ApiCacheCompanion Function({
      required String cacheKey,
      required String data,
      Value<bool> pinned,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$ApiCacheTableUpdateCompanionBuilder =
    ApiCacheCompanion Function({
      Value<String> cacheKey,
      Value<String> data,
      Value<bool> pinned,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$ApiCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ApiCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCacheTable,
          ApiCacheData,
          $$ApiCacheTableFilterComposer,
          $$ApiCacheTableOrderingComposer,
          $$ApiCacheTableAnnotationComposer,
          $$ApiCacheTableCreateCompanionBuilder,
          $$ApiCacheTableUpdateCompanionBuilder,
          (
            ApiCacheData,
            BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheData>,
          ),
          ApiCacheData,
          PrefetchHooks Function()
        > {
  $$ApiCacheTableTableManager(_$AppDatabase db, $ApiCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion(
                cacheKey: cacheKey,
                data: data,
                pinned: pinned,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String data,
                Value<bool> pinned = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion.insert(
                cacheKey: cacheKey,
                data: data,
                pinned: pinned,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCacheTable,
      ApiCacheData,
      $$ApiCacheTableFilterComposer,
      $$ApiCacheTableOrderingComposer,
      $$ApiCacheTableAnnotationComposer,
      $$ApiCacheTableCreateCompanionBuilder,
      $$ApiCacheTableUpdateCompanionBuilder,
      (
        ApiCacheData,
        BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheData>,
      ),
      ApiCacheData,
      PrefetchHooks Function()
    >;
typedef $$OfflineWatchProgressTableCreateCompanionBuilder =
    OfflineWatchProgressCompanion Function({
      Value<int> id,
      required String serverId,
      required String ratingKey,
      required String globalKey,
      required String actionType,
      Value<int?> viewOffset,
      Value<int?> duration,
      Value<bool> shouldMarkWatched,
      required int createdAt,
      required int updatedAt,
      Value<int> syncAttempts,
      Value<String?> lastError,
    });
typedef $$OfflineWatchProgressTableUpdateCompanionBuilder =
    OfflineWatchProgressCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> ratingKey,
      Value<String> globalKey,
      Value<String> actionType,
      Value<int?> viewOffset,
      Value<int?> duration,
      Value<bool> shouldMarkWatched,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> syncAttempts,
      Value<String?> lastError,
    });

class $$OfflineWatchProgressTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineWatchProgressTable> {
  $$OfflineWatchProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratingKey => $composableBuilder(
    column: $table.ratingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalKey => $composableBuilder(
    column: $table.globalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viewOffset => $composableBuilder(
    column: $table.viewOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shouldMarkWatched => $composableBuilder(
    column: $table.shouldMarkWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineWatchProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineWatchProgressTable> {
  $$OfflineWatchProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratingKey => $composableBuilder(
    column: $table.ratingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalKey => $composableBuilder(
    column: $table.globalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viewOffset => $composableBuilder(
    column: $table.viewOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shouldMarkWatched => $composableBuilder(
    column: $table.shouldMarkWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineWatchProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineWatchProgressTable> {
  $$OfflineWatchProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get ratingKey =>
      $composableBuilder(column: $table.ratingKey, builder: (column) => column);

  GeneratedColumn<String> get globalKey =>
      $composableBuilder(column: $table.globalKey, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get viewOffset => $composableBuilder(
    column: $table.viewOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get shouldMarkWatched => $composableBuilder(
    column: $table.shouldMarkWatched,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OfflineWatchProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineWatchProgressTable,
          OfflineWatchProgressItem,
          $$OfflineWatchProgressTableFilterComposer,
          $$OfflineWatchProgressTableOrderingComposer,
          $$OfflineWatchProgressTableAnnotationComposer,
          $$OfflineWatchProgressTableCreateCompanionBuilder,
          $$OfflineWatchProgressTableUpdateCompanionBuilder,
          (
            OfflineWatchProgressItem,
            BaseReferences<
              _$AppDatabase,
              $OfflineWatchProgressTable,
              OfflineWatchProgressItem
            >,
          ),
          OfflineWatchProgressItem,
          PrefetchHooks Function()
        > {
  $$OfflineWatchProgressTableTableManager(
    _$AppDatabase db,
    $OfflineWatchProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineWatchProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineWatchProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineWatchProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> ratingKey = const Value.absent(),
                Value<String> globalKey = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<int?> viewOffset = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<bool> shouldMarkWatched = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OfflineWatchProgressCompanion(
                id: id,
                serverId: serverId,
                ratingKey: ratingKey,
                globalKey: globalKey,
                actionType: actionType,
                viewOffset: viewOffset,
                duration: duration,
                shouldMarkWatched: shouldMarkWatched,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncAttempts: syncAttempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String ratingKey,
                required String globalKey,
                required String actionType,
                Value<int?> viewOffset = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<bool> shouldMarkWatched = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OfflineWatchProgressCompanion.insert(
                id: id,
                serverId: serverId,
                ratingKey: ratingKey,
                globalKey: globalKey,
                actionType: actionType,
                viewOffset: viewOffset,
                duration: duration,
                shouldMarkWatched: shouldMarkWatched,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncAttempts: syncAttempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineWatchProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineWatchProgressTable,
      OfflineWatchProgressItem,
      $$OfflineWatchProgressTableFilterComposer,
      $$OfflineWatchProgressTableOrderingComposer,
      $$OfflineWatchProgressTableAnnotationComposer,
      $$OfflineWatchProgressTableCreateCompanionBuilder,
      $$OfflineWatchProgressTableUpdateCompanionBuilder,
      (
        OfflineWatchProgressItem,
        BaseReferences<
          _$AppDatabase,
          $OfflineWatchProgressTable,
          OfflineWatchProgressItem
        >,
      ),
      OfflineWatchProgressItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadedMediaTableTableManager get downloadedMedia =>
      $$DownloadedMediaTableTableManager(_db, _db.downloadedMedia);
  $$DownloadQueueTableTableManager get downloadQueue =>
      $$DownloadQueueTableTableManager(_db, _db.downloadQueue);
  $$ApiCacheTableTableManager get apiCache =>
      $$ApiCacheTableTableManager(_db, _db.apiCache);
  $$OfflineWatchProgressTableTableManager get offlineWatchProgress =>
      $$OfflineWatchProgressTableTableManager(_db, _db.offlineWatchProgress);
}
