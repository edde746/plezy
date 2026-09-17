import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../utils/live_tv_matching.dart';

/// Session-local guide history. Server retrieval may omit expired airings;
/// retain previously observed overlapping airings without persistent storage.
/// An identity token, not channel ID, rejects an earlier A in A -> B -> A.
class LiveTvProgramGuide {
  Object? _owner;
  int _generation = 0;
  List<LiveTvProgram> programs = const [];
  bool stale = true;

  void reset(Object? owner) {
    _owner = owner;
    _generation++;
    programs = const [];
    stale = true;
  }

  Future<bool> refresh({
    required Object owner,
    required LiveTvChannel channel,
    required double fromEpoch,
    required double toEpoch,
    required Future<List<LiveTvProgram>> Function(DateTime from, DateTime to) fetch,
  }) async {
    if (!identical(owner, _owner)) reset(owner);
    final generation = ++_generation;
    try {
      final fetched = await fetch(
        DateTime.fromMillisecondsSinceEpoch((fromEpoch * 1000).floor(), isUtc: true),
        DateTime.fromMillisecondsSinceEpoch((toEpoch * 1000).ceil(), isUtc: true),
      );
      if (!identical(owner, _owner) || generation != _generation) return false;
      final merged = <String, LiveTvProgram>{};
      for (final program in [...programs, ...fetched]) {
        if (!liveTvProgramMatchesChannel(program, channel) ||
            program.beginsAt == null ||
            program.endsAt == null ||
            program.endsAt! <= fromEpoch ||
            program.beginsAt! >= toEpoch) {
          continue;
        }
        final key = '${program.beginsAt}:${program.ratingKey ?? program.key ?? program.guid ?? program.title}';
        merged[key] = program;
      }
      programs = merged.values.toList(growable: false);
      // Plex's existing grid API returns empty on provider failures. An
      // empty channel slice cannot prove retained history was refreshed.
      stale = !fetched.any((program) => liveTvProgramMatchesChannel(program, channel));
      return true;
    } catch (_) {
      if (!identical(owner, _owner) || generation != _generation) return false;
      stale = true;
      return true;
    }
  }
}
