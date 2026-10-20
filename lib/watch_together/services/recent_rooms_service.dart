import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../services/settings_service.dart';
import 'watch_party_relays.dart';

part 'recent_rooms_service.g.dart';

/// A room this profile created or joined, to join again by its code.
@JsonSerializable(includeIfNull: false)
class RecentRoom {
  final String code;

  /// The relay setting the code belongs to ([relayScopeOf]).
  final String relayScope;
  final String? name;
  @JsonKey(fromJson: _dateTimeFromMillis, toJson: _dateTimeToMillis)
  final DateTime lastUsed;

  const RecentRoom({required this.code, required this.relayScope, this.name, required this.lastUsed});

  Map<String, dynamic> toJson() => _$RecentRoomToJson(this);

  factory RecentRoom.fromJson(Map<String, dynamic> json) => _$RecentRoomFromJson(json);

  RecentRoom copyWith({String? name, DateTime? lastUsed, bool clearName = false}) => RecentRoom(
    code: code,
    relayScope: relayScope,
    name: clearName ? null : (name ?? this.name),
    lastUsed: lastUsed ?? this.lastUsed,
  );
}

DateTime _dateTimeFromMillis(int value) => DateTime.fromMillisecondsSinceEpoch(value);

int _dateTimeToMillis(DateTime value) => value.millisecondsSinceEpoch;

/// Recent rooms per profile. Only Open Watch Party codes (6 symbols) are kept:
/// rooms of Plezy's former relay had 5, and no relay knows them any more.
class RecentRoomsService {
  static const int _maxRooms = 20;

  static List<RecentRoom> getRecentRooms({required String profileId, required String relayScope}) =>
      _load(profileId).where((room) => room.relayScope == relayScope).toList(growable: false);

  static List<RecentRoom> _load(String profileId) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return [];
    final json = settings.read(SettingsService.recentRoomsForProfile(profileId));
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      final rooms = [
        for (final entry in list)
          if (entry is Map<String, dynamic>) RecentRoom.fromJson(entry),
      ]..retainWhere((room) => normalizeRoomCode(room.code) == room.code);
      rooms.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return rooms;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(String profileId, List<RecentRoom> rooms) async {
    rooms.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    if (rooms.length > _maxRooms) rooms.removeRange(_maxRooms, rooms.length);
    await SettingsService.instanceOrNull?.write(
      SettingsService.recentRoomsForProfile(profileId),
      jsonEncode(rooms.map((room) => room.toJson()).toList()),
    );
  }

  static Future<void> addOrUpdateRoom(String code, {required String profileId, required String relayScope}) async {
    final rooms = _load(profileId);
    final index = rooms.indexWhere((room) => room.relayScope == relayScope && room.code == code);
    if (index >= 0) {
      rooms[index] = rooms[index].copyWith(lastUsed: DateTime.now());
    } else {
      rooms.add(RecentRoom(code: code, relayScope: relayScope, lastUsed: DateTime.now()));
    }
    await _save(profileId, rooms);
  }

  static Future<void> removeRoom(String code, {required String profileId, required String relayScope}) async {
    final rooms = _load(profileId)..removeWhere((room) => room.relayScope == relayScope && room.code == code);
    await _save(profileId, rooms);
  }

  static Future<void> renameRoom(
    String code,
    String? name, {
    required String profileId,
    required String relayScope,
  }) async {
    final rooms = _load(profileId);
    final index = rooms.indexWhere((room) => room.relayScope == relayScope && room.code == code);
    if (index < 0) return;
    rooms[index] = rooms[index].copyWith(name: name, clearName: name == null);
    await _save(profileId, rooms);
  }
}
