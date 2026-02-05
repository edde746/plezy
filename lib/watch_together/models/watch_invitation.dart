class WatchInvitation {
  final String sessionId;
  final String hostUserUUID;
  final String hostDisplayName;
  final String targetUserUUID;
  final String mediaTitle;
  final String? mediaThumb;
  final DateTime createdAt;
  final DateTime expiresAt;

  WatchInvitation({
    required this.sessionId,
    required this.hostUserUUID,
    required this.hostDisplayName,
    required this.targetUserUUID,
    required this.mediaTitle,
    this.mediaThumb,
    required this.createdAt,
    required this.expiresAt,
  });

  factory WatchInvitation.fromJson(Map<String, dynamic> json) {
    return WatchInvitation(
      sessionId: json['sessionId'] as String? ?? '',
      hostUserUUID: json['hostUserUUID'] as String? ?? '',
      hostDisplayName: json['hostDisplayName'] as String? ?? 'Unknown',
      targetUserUUID: json['targetUserUUID'] as String? ?? '',
      mediaTitle: json['mediaTitle'] as String? ?? 'Unknown',
      mediaThumb: json['mediaThumb'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'hostUserUUID': hostUserUUID,
      'hostDisplayName': hostDisplayName,
      'targetUserUUID': targetUserUUID,
      'mediaTitle': mediaTitle,
      'mediaThumb': mediaThumb,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
