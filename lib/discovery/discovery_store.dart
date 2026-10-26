import '../sources/source_database.dart';
import 'discovery_choice.dart';

enum DiscoveryDecisionAction { save, notNow, removeSaved }

class DiscoveryDecision {
  const DiscoveryDecision({
    required this.action,
    required this.choice,
    required this.previousSaved,
    required this.wasSeen,
    required this.savedChanged,
  });
  final DiscoveryDecisionAction action;
  final DiscoveryChoice choice;
  final DiscoveryChoice? previousSaved;
  final bool wasSeen;
  final bool savedChanged;

  Map<String, dynamic> toJson() => {
    'action': action.name,
    'choice': choice.toSnapshot(),
    'previousSaved': previousSaved?.toSnapshot(),
    'wasSeen': wasSeen,
    'savedChanged': savedChanged,
  };

  factory DiscoveryDecision.fromJson(Map<String, dynamic> json) => DiscoveryDecision(
    action: DiscoveryDecisionAction.values.byName(json['action'] as String),
    choice: DiscoveryChoice.fromSnapshot(Map<String, dynamic>.from(json['choice'] as Map)),
    previousSaved: json['previousSaved'] is Map
        ? DiscoveryChoice.fromSnapshot(Map<String, dynamic>.from(json['previousSaved'] as Map))
        : null,
    wasSeen: json['wasSeen'] == true,
    savedChanged: json['savedChanged'] == true,
  );
}

class DiscoveryState {
  const DiscoveryState({this.saved = const [], this.seen = const {}, this.history = const []});
  final List<DiscoveryChoice> saved;
  final Set<String> seen;
  final List<DiscoveryDecision> history;

  DiscoveryChoice? get undoChoice => history.isEmpty ? null : history.last.choice;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'saved': saved.map((choice) => choice.toSnapshot()).toList(),
    'seen': seen.take(240).toList(),
    'history': history.take(500).map((decision) => decision.toJson()).toList(),
  };

  factory DiscoveryState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) return const DiscoveryState();
    final saved = <DiscoveryChoice>[];
    for (final value in (json['saved'] is List ? json['saved'] as List : const []).take(250)) {
      try {
        if (value is Map) saved.add(DiscoveryChoice.fromSnapshot(Map<String, dynamic>.from(value)));
      } catch (_) {
        // A corrupt historical snapshot is ignored without losing other picks.
      }
    }
    final history = <DiscoveryDecision>[];
    for (final value in (json['history'] is List ? json['history'] as List : const []).take(500)) {
      try {
        if (value is Map) history.add(DiscoveryDecision.fromJson(Map<String, dynamic>.from(value)));
      } catch (_) {
        // Keep the rest of the user's recoverable history.
      }
    }
    final seen = (json['seen'] is List ? json['seen'] as List : const []).whereType<String>().take(240).toSet();
    return DiscoveryState(saved: saved, seen: seen, history: history);
  }
}

/// Profile-local persistence built on the existing publication preference
/// store. A single replacement write keeps the save/decision/session update
/// atomic without adding a second database or serializing media credentials.
class DiscoveryStore {
  const DiscoveryStore(this._sources);
  static const _preferenceKey = 'discovery.find-next.v1';
  static const _maxHistory = 500;
  static const maxSaved = 250;
  final SourceRepository _sources;

  Future<DiscoveryState> load(String profileId) async {
    final data = await _sources.preference(profileId, _preferenceKey);
    try {
      return DiscoveryState.fromJson(data);
    } on FormatException {
      return const DiscoveryState();
    }
  }

  Future<DiscoveryState> decide(String profileId, DiscoveryChoice choice, DiscoveryDecisionAction action) async {
    final current = await load(profileId);
    final saved = {for (final item in current.saved) item.id: item};
    final previous = saved[choice.id];
    final wasSeen = current.seen.contains(choice.id);
    var savedChanged = false;
    switch (action) {
      case DiscoveryDecisionAction.save:
        if (previous == null && saved.length < maxSaved) {
          saved[choice.id] = choice;
          savedChanged = true;
        }
        break;
      case DiscoveryDecisionAction.notNow:
        break;
      case DiscoveryDecisionAction.removeSaved:
        savedChanged = saved.remove(choice.id) != null;
        break;
    }
    final decision = DiscoveryDecision(
      action: action,
      choice: choice,
      previousSaved: savedChanged ? previous : null,
      wasSeen: wasSeen,
      savedChanged: savedChanged,
    );
    final seen = {...current.seen, choice.id};
    final next = DiscoveryState(
      saved: saved.values.toList(growable: false),
      seen: seen.length > 240 ? seen.skip(seen.length - 240).toSet() : seen,
      history: [...current.history, decision].take(_maxHistory).toList(growable: false),
    );
    await _write(profileId, next);
    return next;
  }

  Future<(DiscoveryState, DiscoveryChoice?)> undo(String profileId) async {
    final current = await load(profileId);
    if (current.history.isEmpty) return (current, null);
    final decision = current.history.last;
    final saved = {for (final item in current.saved) item.id: item};
    if (decision.previousSaved != null) {
      saved[decision.choice.id] = decision.previousSaved!;
    } else if (decision.savedChanged) {
      saved.remove(decision.choice.id);
    }
    final seen = {...current.seen};
    if (!decision.wasSeen) seen.remove(decision.choice.id);
    final next = DiscoveryState(
      saved: saved.values.toList(growable: false),
      seen: seen,
      history: current.history.take(current.history.length - 1).toList(growable: false),
    );
    await _write(profileId, next);
    return (next, decision.choice);
  }

  Future<DiscoveryState> startFreshSession(String profileId) async {
    final current = await load(profileId);
    final next = DiscoveryState(saved: current.saved, history: current.history);
    await _write(profileId, next);
    return next;
  }

  Future<void> _write(String profileId, DiscoveryState state) =>
      _sources.savePreference(profileId, _preferenceKey, state.toJson());
}

/// Fairly interleaves media families so a large film library does not drown
/// a smaller music or reading shelf. Each family is shuffled independently.
List<DiscoveryChoice> balanceDiscoveryChoices(Iterable<DiscoveryChoice> choices, {required int seed}) {
  final buckets = <String, List<DiscoveryChoice>>{};
  for (final choice in choices) {
    final bucket = switch (choice.type) {
      DiscoveryChoiceType.video || DiscoveryChoiceType.sourceVideo || DiscoveryChoiceType.liveProgram => 'watch',
      DiscoveryChoiceType.music => 'listen',
      DiscoveryChoiceType.audiobook => 'audiobook',
      DiscoveryChoiceType.ebook || DiscoveryChoiceType.comic => 'read',
    };
    buckets.putIfAbsent(bucket, () => []).add(choice);
  }
  final random = _StableRandom(seed);
  for (final values in buckets.values) {
    for (var i = values.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final value = values[i];
      values[i] = values[j];
      values[j] = value;
    }
  }
  final keys = buckets.keys.toList()..sort();
  // Rotate family priority with the session seed to avoid always opening on
  // the same medium while preserving even interleaving.
  if (keys.isNotEmpty) {
    final shift = seed.abs() % keys.length;
    final rotated = [...keys.skip(shift), ...keys.take(shift)];
    keys
      ..clear()
      ..addAll(rotated);
  }
  final result = <DiscoveryChoice>[];
  var remaining = true;
  while (remaining) {
    remaining = false;
    for (final key in keys) {
      final values = buckets[key]!;
      if (values.isEmpty) continue;
      remaining = true;
      result.add(values.removeLast());
    }
  }
  return result;
}

class _StableRandom {
  _StableRandom(int seed) : _state = seed & 0x7fffffff;
  int _state;
  int nextInt(int max) {
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % max;
  }
}
