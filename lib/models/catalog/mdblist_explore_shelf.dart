import '../../utils/json_utils.dart';

/// A local shelf selection. The API list ID survives source renames; overrides
/// never change the MDBList account's list itself. List order is stored by the
/// enclosing array, independently of the order of titles inside each list.
class MdblistExploreShelf {
  final int listId;
  final String sourceName;
  final String? displayName;
  final bool enabled;

  const MdblistExploreShelf({required this.listId, required this.sourceName, this.displayName, this.enabled = true});

  String get title => displayName?.trim().isNotEmpty == true ? displayName!.trim() : sourceName;

  MdblistExploreShelf copyWith({String? sourceName, String? displayName, bool? enabled}) => MdblistExploreShelf(
    listId: listId,
    sourceName: sourceName ?? this.sourceName,
    displayName: displayName ?? this.displayName,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'id': listId,
    'name': sourceName,
    if (displayName != null) 'display_name': displayName,
    'enabled': enabled,
  };

  static MdblistExploreShelf? fromJson(Map<String, dynamic> json) {
    final id = flexibleInt(json['id']);
    final name = json['name'];
    if (id == null || id <= 0 || name is! String || name.trim().isEmpty) return null;
    return MdblistExploreShelf(
      listId: id,
      sourceName: name,
      displayName: json['display_name'] is String ? json['display_name'] as String : null,
      enabled: json['enabled'] != false,
    );
  }
}

/// Account-discovered list metadata. Do not synthesize lists from public URLs.
class MdblistAccountList {
  final int id;
  final String name;
  final String? mediaType;
  final String? type;
  final bool isPrivate;
  final int? itemCount;

  const MdblistAccountList({
    required this.id,
    required this.name,
    this.mediaType,
    this.type,
    this.isPrivate = false,
    this.itemCount,
  });

  static MdblistAccountList? fromJson(Map<String, dynamic> json) {
    final shelf = MdblistExploreShelf.fromJson(json);
    if (shelf == null) return null;
    return MdblistAccountList(
      id: shelf.listId,
      name: shelf.sourceName,
      mediaType: json['mediatype'] as String?,
      type: json['type'] as String?,
      isPrivate: flexibleBoolNullable(json['private']) ?? false,
      itemCount: flexibleInt(json['items']),
    );
  }
}
