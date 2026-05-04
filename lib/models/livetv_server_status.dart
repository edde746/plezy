import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'livetv_server_status.g.dart';

@JsonSerializable(createToJson: false)
class LiveTvServerStatus {
  @JsonKey(name: 'livetv', fromJson: flexibleInt)
  final int? liveTvCount;
  @JsonKey(fromJson: flexibleBoolNullable)
  final bool? allowTuners;
  final String? ownerFeatures;

  const LiveTvServerStatus({this.liveTvCount, this.allowTuners, this.ownerFeatures});

  factory LiveTvServerStatus.fromJson(Map<String, dynamic> json) => _$LiveTvServerStatusFromJson(json);

  Set<String> get ownerFeatureSet =>
      (ownerFeatures ?? '').split(',').map((feature) => feature.trim()).where((feature) => feature.isNotEmpty).toSet();

  bool get hasConfiguredDvr => (liveTvCount ?? 0) > 0;
  bool get supportsTuners => allowTuners != false;
  bool get hasDvrFeature => ownerFeatureSet.contains('dvr');
  bool get hasLiveTvFeature => ownerFeatureSet.contains('livetv');
}
