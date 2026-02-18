enum DeleteRetentionMode { onNextRefresh, afterDays, afterWeeks }

class DownloadSettings {
  final bool downloadAllEpisodes;
  final int episodeCount;
  final DeleteRetentionMode deleteMode;
  final int retentionValue;
  final String? transcodeQuality;

  const DownloadSettings({
    this.downloadAllEpisodes = true,
    this.episodeCount = 5,
    this.deleteMode = DeleteRetentionMode.onNextRefresh,
    this.retentionValue = 7,
    this.transcodeQuality,
  });

  DownloadSettings copyWith({
    bool? downloadAllEpisodes,
    int? episodeCount,
    DeleteRetentionMode? deleteMode,
    int? retentionValue,
    String? transcodeQuality,
    bool clearTranscodeQuality = false,
  }) {
    return DownloadSettings(
      downloadAllEpisodes: downloadAllEpisodes ?? this.downloadAllEpisodes,
      episodeCount: episodeCount ?? this.episodeCount,
      deleteMode: deleteMode ?? this.deleteMode,
      retentionValue: retentionValue ?? this.retentionValue,
      transcodeQuality: clearTranscodeQuality ? null : (transcodeQuality ?? this.transcodeQuality),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadSettings &&
          downloadAllEpisodes == other.downloadAllEpisodes &&
          episodeCount == other.episodeCount &&
          deleteMode == other.deleteMode &&
          retentionValue == other.retentionValue &&
          transcodeQuality == other.transcodeQuality;

  @override
  int get hashCode => Object.hash(downloadAllEpisodes, episodeCount, deleteMode, retentionValue, transcodeQuality);

  Map<String, dynamic> toJson() => {
        'downloadAllEpisodes': downloadAllEpisodes,
        'episodeCount': episodeCount,
        'deleteMode': deleteMode.name,
        'retentionValue': retentionValue,
        'transcodeQuality': transcodeQuality,
      };

  factory DownloadSettings.fromJson(Map<String, dynamic> json) {
    return DownloadSettings(
      downloadAllEpisodes: json['downloadAllEpisodes'] as bool? ?? true,
      episodeCount: json['episodeCount'] as int? ?? 5,
      deleteMode: DeleteRetentionMode.values.firstWhere(
        (e) => e.name == json['deleteMode'],
        orElse: () => DeleteRetentionMode.onNextRefresh,
      ),
      retentionValue: json['retentionValue'] as int? ?? 7,
      transcodeQuality: json['transcodeQuality'] as String?,
    );
  }
}
