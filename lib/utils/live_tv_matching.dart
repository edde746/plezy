import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';

bool liveTvProgramMatchesChannel(LiveTvProgram program, LiveTvChannel channel) {
  final programChannel = liveTvNonEmpty(program.channelIdentifier);
  if (programChannel == null) return false;
  if (programChannel != channel.key && programChannel != channel.identifier) return false;

  if (!_nullableIdsMatch(program.serverId, channel.serverId)) return false;
  if (!_nullableIdsMatch(program.liveDvrKey, channel.liveDvrKey)) return false;

  final programProvider = liveTvNonEmpty(program.providerIdentifier);
  final channelProvider = liveTvProviderIdentifierForChannel(channel);
  if (programProvider != null && channelProvider != null && programProvider != channelProvider) return false;

  return true;
}

String? liveTvProviderIdentifierForChannel(LiveTvChannel channel) {
  final source = liveTvNonEmpty(channel.favoriteSource);
  if (source != null) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.pathSegments.isNotEmpty) return liveTvNonEmpty(uri.pathSegments.last);

    final slashIndex = source.lastIndexOf('/');
    if (slashIndex >= 0 && slashIndex < source.length - 1) {
      return liveTvNonEmpty(source.substring(slashIndex + 1));
    }
  }
  return liveTvNonEmpty(channel.lineup);
}

bool _nullableIdsMatch(String? a, String? b) {
  final left = liveTvNonEmpty(a);
  final right = liveTvNonEmpty(b);
  return left == null || right == null || left == right;
}

/// Trimmed [value], or null when it is null, empty, or whitespace-only.
String? liveTvNonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
