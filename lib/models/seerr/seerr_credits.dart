/// One cast member from /movie/{id} or /tv/{id} credits.
class SeerrCastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;

  const SeerrCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order = 0,
  });

  factory SeerrCastMember.fromJson(Map<String, dynamic> json) {
    return SeerrCastMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String?,
      profilePath: json['profilePath'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Credits block returned alongside the movie/tv details. Currently only
/// surfaces the cast — crew isn't shown in the v1 detail screen.
class SeerrCredits {
  final List<SeerrCastMember> cast;

  const SeerrCredits({this.cast = const []});

  factory SeerrCredits.fromJson(Map<String, dynamic> json) {
    final rawCast = json['cast'];
    final cast = <SeerrCastMember>[];
    if (rawCast is List) {
      for (final c in rawCast) {
        if (c is Map<String, dynamic>) cast.add(SeerrCastMember.fromJson(c));
      }
    }
    // Order by `order` so the top-billed cast renders first regardless of
    // server-side array order.
    cast.sort((a, b) => a.order.compareTo(b.order));
    return SeerrCredits(cast: cast);
  }
}
