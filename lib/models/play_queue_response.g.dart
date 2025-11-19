// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_queue_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayQueueResponse _$PlayQueueResponseFromJson(Map<String, dynamic> json) =>
    PlayQueueResponse(
      playQueueID: (json['playQueueID'] as num).toInt(),
      playQueueSelectedItemID: (json['playQueueSelectedItemID'] as num?)
          ?.toInt(),
      playQueueSelectedItemOffset: (json['playQueueSelectedItemOffset'] as num?)
          ?.toInt(),
      playQueueSelectedMetadataItemID:
          json['playQueueSelectedMetadataItemID'] as String?,
      playQueueShuffled: const BoolOrIntConverter().fromJson(
        json['playQueueShuffled'] as Object,
      ),
      playQueueSourceURI: json['playQueueSourceURI'] as String?,
      playQueueTotalCount: (json['playQueueTotalCount'] as num?)?.toInt(),
      playQueueVersion: (json['playQueueVersion'] as num).toInt(),
      size: (json['size'] as num?)?.toInt(),
      items: (json['Metadata'] as List<dynamic>?)
          ?.map((e) => PlexMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
