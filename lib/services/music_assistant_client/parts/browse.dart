part of '../../music_assistant_client.dart';

/// Library listing, paging, item lookup and children.
///
/// The paging code here is the part that carries the most weight: the reference
/// library is ~370,000 tracks across ~33,000 albums, and every list in the app
/// funnels through [fetchLibraryPagedContent].
mixin _MusicAssistantBrowseMethods on _MusicAssistantClientInternals {
  /// Item totals, memoised briefly.
  ///
  /// A total is needed on every page so the list can size itself, but it is a
  /// separate round-trip, and re-asking on each page of a fast scroll is pure
  /// overhead. It cannot be cached indefinitely either — the reference library
  /// grew 77% in 45 minutes while it was being scanned — so the memo expires.
  final Map<MaLibraryType, ({int value, DateTime at})> _counts = {};

  static const Duration _countTtl = Duration(seconds: 60);

  /// The `#` block that sits at offset 0 of every ascending `sort_name` list,
  /// held so it can be served from the *end* instead. See [_unsortableHead].
  final Map<MaLibraryType, ({List<MaItem> items, DateTime at})> _unsortableHeads = {};

  /// Longer than [_countTtl]: the total moves every time the scanner commits a
  /// batch, but a library gains a track called `!!!!!!!` roughly never.
  static const Duration _unsortableHeadTtl = Duration(minutes: 10);

  /// Child lists (album tracks, artist albums, playlist tracks) in flight or
  /// recently answered, keyed by `<command>:<uri>`.
  ///
  /// The children commands take no `limit`/`offset`, so every page of a child
  /// list is carved out of the whole list — and [PaginatedItemLoader] asks for a
  /// page per scroll step. Without this, paging a 5,000-track playlist
  /// re-downloads 5,000 rows *per page*. The **future** is held rather than the
  /// value so the concurrent requests a fast scroll produces collapse into one
  /// round-trip instead of racing.
  final Map<String, ({Future<List<MediaItem>> items, DateTime at})> _childLists = {};

  /// Short enough that a playlist edited elsewhere shows up on the next visit,
  /// long enough to cover paging through one list.
  static const Duration _childListTtl = Duration(seconds: 60);

  /// A child list is playlist-sized, so only a handful are kept.
  static const int _maxMemoisedChildLists = 4;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    return [
      MusicAssistantMappers.library(
        serverId: serverId,
        // Sanitised twice over: [MusicAssistantClient.serverName] never
        // answers null, and this is idempotent. Deliberately *not*
        // `serverName ?? connection.displayName` — that fallback is what put a
        // bare IP address on the title of someone's music collection.
        serverName: MusicAssistantMappers.serverDisplayName(serverName),
        libraryId: musicAssistantLibraryId,
      ),
    ];
  }

  /// One page of the library, honouring the requested grouping.
  ///
  /// The grouping (Artists / Albums / Tracks) arrives as [LibraryQuery.kind] and
  /// selects which `music/<type>/library_items` collection is read — this is
  /// what makes a 370,000-track collection browseable at all, since the artist
  /// list is two orders of magnitude shorter.
  ///
  /// `limit` is always sent explicitly: the server truncates a limit-less
  /// request at 500 rows and reports nothing about having done so.
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    abort?.throwIfAborted();
    final type = _libraryTypeFor(query, libraryKind);
    final limit = query.limit > 0 ? query.limit : MusicAssistantLibrary.defaultPageSize;
    final offset = query.offset < 0 ? 0 : query.offset;

    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      return _searchPage(type, search, offset: offset, limit: limit, abort: abort);
    }

    final orderBy = _orderFor(query.sort, type);

    // The alphabetical list is the one that opens on junk, so it is the only one
    // that gets rebucketed. Every other ordering either has no `#` block at its
    // head (year, date added, duration) or puts it at the tail already
    // (`sort_name_desc`), and a favourites-only list has no server total to
    // subtract the block from.
    if ((orderBy == null || orderBy == MaOrder.sortName)) {
      return _alphabeticalPage(type, offset: offset, limit: limit, abort: abort);
    }

    final items = await guard(() => music.getPage(type, limit: limit, offset: offset, orderBy: orderBy));
    abort?.throwIfAborted();

    // `count` ignores the `favorite` argument, so a favourites-only list has no
    // server-side total and has to fall back to the conservative estimate.
    final total = await _countOf(type);

    return LibraryPage(items: mapItems(items), totalCount: total, offset: offset);
  }

  /// One page of the A→Z list, with the `#` bucket moved from the front to the
  /// back.
  ///
  /// Music Assistant orders by `sort_name` and a Unicode collation gives
  /// punctuation no primary weight, so every title whose **`sort_name`** is made
  /// only of punctuation or symbols collates to the empty key and lands at
  /// offset 0. The distinction matters: the server has already reduced these to
  /// bare glyphs, so the albums displayed as `+ (plus)`, `- (subtract)` and
  /// `÷ (divide)` arrive with `sort_name` `+`, `-` and `÷`. Applying the same
  /// predicate to the *display* title would file them under P, S and D. On the
  /// reference library the head is what a user sees first: `@`, `!!!!!!!`,
  /// `...`, `/`, `+`, `-`, `÷`. Measured head sizes there are 8 albums, 1 artist
  /// and 38 tracks — small, near-contiguous, and worthless as a first impression
  /// of a 33,000-album collection.
  ///
  /// The fix is a rotation, not a re-sort. The block occupies server offsets
  /// `[0, k)`; virtual offset `i` therefore reads server offset `i + k`, and the
  /// k items are appended once the ordered region runs out. Server order is
  /// preserved exactly within both regions, so nothing here can disagree with
  /// what the server would have returned — it is the same rows, cut in a
  /// different place. That matters more than it sounds: an alpha bar built on
  /// this later can name a real offset for every letter.
  ///
  /// Numeric-leading titles are deliberately *not* moved. `1989` and `808 State`
  /// are titles people look for under their number, and that is where the
  /// server, Plex, Jellyfin and Navidrome all file them. See
  /// [LibraryAlphaBucket.of].
  Future<LibraryPage<MediaItem>> _alphabeticalPage(
    MaLibraryType type, {
    required int offset,
    required int limit,
    AbortController? abort,
  }) async {
    // Independent questions, so they travel together: serialising them put two
    // full round-trips in front of the first paint of every alphabetical list.
    // The third (the page itself) genuinely depends on both.
    //
    // `Future.wait` rather than the record `.wait`, which reports failures as a
    // `ParallelWaitError` — the transport exception `guard` produces has to
    // survive to the caller, because abort and 404 handling branch on it.
    var head = const <MaItem>[];
    var total = 0;
    await Future.wait([
      _unsortableHead(type).then((value) => head = value),
      _countOf(type).then((value) => total = value),
    ]);
    abort?.throwIfAborted();

    // Where the rotated list stops being server rows and starts being the
    // held-back `#` block.
    final orderedCount = (total - head.length).clamp(0, total);

    final fromServer = offset < orderedCount
        ? await guard(
            () => music.getPage(
              type,
              // Never read past `orderedCount`: those rows are the `#` block and
              // are about to be served from [head] instead.
              limit: limit < orderedCount - offset ? limit : orderedCount - offset,
              offset: offset + head.length,
              orderBy: MaOrder.sortName,
            ),
          )
        : const <MaItem>[];
    abort?.throwIfAborted();

    // Only reach for the tail once the ordered region is genuinely exhausted.
    // A stale `total` can make the server return a short page early, and
    // appending the `#` block there would interleave it with rows still to come
    // — the one way this rotation could produce a duplicate.
    final consumed = offset + fromServer.length;
    final tail = consumed >= orderedCount
        ? head.skip(consumed - orderedCount).take(limit - fromServer.length)
        : const <MaItem>[];

    return LibraryPage(items: mapItems([...fromServer, ...tail]), totalCount: total, offset: offset);
  }

  /// The `#` block at the head of the ascending `sort_name` list.
  ///
  /// Measured, not modelled: the block's size is read off the server's own first
  /// page rather than derived from a guess about its collation. That is the only
  /// way to be sure the rotation lands on a real boundary — the collation has
  /// quirks no client-side rule reproduces (a Cherokee-script track sorts *among*
  /// the symbols on 2.6.3, presumably because those code points post-date the
  /// server's collation data).
  ///
  /// Everything up to and including the last unsortable row of the *leading
  /// block* is taken, so an oddity like that Cherokee track travels with the
  /// block instead of splitting it. It belongs there anyway: it collates
  /// nowhere, which is exactly what the `#` bucket means.
  ///
  /// "Leading block" is what [_maxSortableGap] bounds. Taking the index after
  /// the last unsortable row *anywhere* in the page is what makes the Cherokee
  /// case work, but unbounded it also means one symbol-only title sitting 400
  /// rows deep would rotate 400 correctly-sorted rows to the end of the list.
  /// The block is allowed to contain short runs of collatable rows and ends at
  /// the first run longer than that. Measured on the reference library the
  /// longest interruption is one row (the Cherokee track at index 30 of 38).
  ///
  /// A first page that is *entirely* unsortable would mean the block is longer
  /// than one page and this measurement is wrong, so the rotation is abandoned
  /// rather than applied at a boundary that was never found.
  Future<List<MaItem>> _unsortableHead(MaLibraryType type) async {
    final memo = _unsortableHeads[type];
    if (memo != null && DateTime.now().difference(memo.at) < _unsortableHeadTtl) return memo.items;

    final page = await guard(
      () => music.getPage(type, limit: MusicAssistantLibrary.defaultPageSize, orderBy: MaOrder.sortName),
    );
    var end = 0;
    for (var i = 0; i < page.length; i++) {
      if (LibraryAlphaBucket.isOther(page[i].sortName)) {
        end = i + 1;
      } else if (i - end >= _maxSortableGap) {
        break;
      }
    }
    final head = end >= page.length ? const <MaItem>[] : page.take(end).toList(growable: false);
    _unsortableHeads[type] = (items: head, at: DateTime.now());
    return head;
  }

  /// How many consecutive collatable rows may sit inside the `#` block before
  /// the block is considered over. See [_unsortableHead].
  static const int _maxSortableGap = 4;

  /// Library-scoped free-text search, used by the browse view's title filter.
  ///
  /// `music/search` takes a flat `limit` and no offset, so a page is carved out
  /// of a single over-fetched result rather than requested. That is fine for the
  /// filter's purpose (find a handful of matches) and honest about its total.
  Future<LibraryPage<MediaItem>> _searchPage(
    MaLibraryType type,
    String search, {
    required int offset,
    required int limit,
    AbortController? abort,
  }) async {
    final results = await guard(() => music.search(search, types: [type], limit: offset + limit));
    abort?.throwIfAborted();
    final matches = switch (type) {
      MaLibraryType.albums => results.albums,
      MaLibraryType.artists => results.artists,
      MaLibraryType.tracks => results.tracks,
      MaLibraryType.playlists => results.playlists,
    };
    final page = matches.skip(offset).take(limit).toList(growable: false);
    return LibraryPage(
      items: mapItems(page),
      totalCount: fallbackPageTotal(offset: offset, itemCount: page.length, requestedSize: limit),
      offset: offset,
    );
  }

  /// Which collection the requested grouping reads.
  ///
  /// Artists is the fallback rather than tracks: the synthetic library is
  /// [MediaKind.artist], and opening 370,000 rows by default is the exact
  /// failure this backend exists to avoid.
  static MaLibraryType _libraryTypeFor(LibraryQuery query, MediaKind? libraryKind) {
    final kind = query.kind ?? (query.includeKinds.isEmpty ? libraryKind : query.includeKinds.first);
    return switch (kind) {
      MediaKind.album => MaLibraryType.albums,
      MediaKind.track => MaLibraryType.tracks,
      MediaKind.playlist => MaLibraryType.playlists,
      _ => MaLibraryType.artists,
    };
  }

  /// Neutral sort clause to an `order_by` verified against **this collection**.
  ///
  /// An unrecognised field returns `null` on purpose: an unknown `order_by` is
  /// not rejected, it is dropped, and the query then runs with no `ORDER BY` at
  /// all — insertion order, which reads as a shuffled list that reports success.
  ///
  /// The per-collection gates are not caution, they are required. `year` exists
  /// only on albums and `duration` only on tracks; asking for either anywhere
  /// else reaches SQL and comes back `error_code: 999 — no such column`, which
  /// the user sees as a library that failed to load. A saved sort preference
  /// outliving a switch from Albums to Tracks is enough to hit it.
  static String? _orderFor(LibrarySort? sort, MaLibraryType type) {
    if (sort == null) return null;
    final descending = sort.direction == LibrarySortDirection.descending;
    return switch (sort.field) {
      'title' || 'titleSort' => descending ? MaOrder.sortNameDesc : MaOrder.sortName,
      'addedAt' => descending ? MaOrder.newestFirst : MaOrder.oldestFirst,
      'year' ||
      'originallyAvailableAt' when type == MaLibraryType.albums => descending ? MaOrder.yearDesc : MaOrder.year,
      'runtime' when type == MaLibraryType.tracks => descending ? MaOrder.durationDesc : MaOrder.duration,
      _ => null,
    };
  }

  Future<int> _countOf(MaLibraryType type) async {
    final memo = _counts[type];
    if (memo != null && DateTime.now().difference(memo.at) < _countTtl) return memo.value;
    final value = await guard(() => music.getCount(type));
    _counts[type] = (value: value, at: DateTime.now());
    return value;
  }

  /// Music Assistant exposes no filter facets, so the sheet stays empty rather
  /// than offering filters that would silently do nothing.
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async =>
      LibraryFilterResult.empty;

  /// Only orderings verified to actually reorder **this collection**.
  ///
  /// "Verified" means the result set was compared against the default, not that
  /// the server accepted the argument — it accepts almost anything. Several
  /// plausible values are absent for that reason: `track_number`,
  /// `original_sort_name` and `album_name` are all taken without complaint and
  /// return the collection in insertion order.
  ///
  /// `year` is albums-only and `runtime` is tracks-only because anywhere else
  /// they are `no such column` failures, not merely useless — see [_orderFor].
  ///
  /// `play_count_desc` and `last_played_desc` do work, and their ascending forms
  /// do not (everything ties at zero and falls back to insertion order). A sort
  /// that only functions in one direction is not something to hand a user with
  /// an asc/desc toggle, so neither is offered.
  ///
  /// `random` is deliberately absent despite working: it reshuffles per request,
  /// so paging through it would repeat and skip rows. It is used for the
  /// single-page discovery row instead, where that is exactly the point.
  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async {
    final type = _sortLibraryType(libraryType);
    return [
      MediaSort(key: 'titleSort', title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
      MediaSort(key: 'addedAt', title: t.libraries.sortLabels.dateAdded, defaultDirection: 'desc'),
      if (type == MaLibraryType.albums)
        MediaSort(key: 'year', title: t.libraries.sortLabels.productionYear, defaultDirection: 'desc'),
      if (type == MaLibraryType.tracks)
        MediaSort(key: 'runtime', title: t.libraries.sortLabels.runtime, defaultDirection: 'asc'),
    ];
  }

  /// The collection a `libraryType` names, for [fetchSortOptions].
  ///
  /// The browse screen passes a [MediaKind] id, and artists is the fallback
  /// because that is the grouping a Music Assistant library opens on.
  static MaLibraryType _sortLibraryType(String? libraryType) => switch (libraryType?.toLowerCase()) {
    'album' => MaLibraryType.albums,
    'track' => MaLibraryType.tracks,
    'playlist' => MaLibraryType.playlists,
    _ => MaLibraryType.artists,
  };

  /// Empty, which suppresses the alpha-jump bar.
  ///
  /// The bar is a scroll affordance keyed on first letter, and the server has no
  /// equivalent of Plex's `/firstCharacter` — there is no way to turn a letter
  /// into an offset. Synthesising A–Z would put a control on screen that cannot
  /// jump anywhere. `MusicAssistantAlphaBarStrategy` hides the bar for the same
  /// reason; this keeps the client's answer consistent with it.
  ///
  /// Deriving the offsets by binary-searching the collection was measured and
  /// rejected: a `limit: 1` probe costs 0.03s at track offset 0 and 6.9s at
  /// offset 334,699, so locating one letter is minutes of round-trips on the
  /// list that most needs the bar. [_alphabeticalPage] is what makes an honest
  /// bar possible later — it leaves the list a plain rotation of server order,
  /// so a letter found in it is at a real offset — but it does not build one.
  Future<List<LibraryFirstCharacter>> fetchFirstCharacters(String libraryId, {Map<String, String>? filters}) async =>
      const [];

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (isOfflineMode) return _cachedItem(id);
    try {
      final raw = await rawItem(id);
      if (raw == null) return null;
      final mapped = mapItem(raw);
      if (mapped != null) await _cacheItem(mapped);
      return mapped;
    } on MediaServerHttpException catch (e) {
      // A 404 means the item is gone; anything else may be a socket that
      // dropped mid-request, where a cached row is better than an error.
      if (e.statusCode == 404) return null;
      final cached = await _cachedItem(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// No on-deck concept exists here: Music Assistant tracks no per-item
  /// playback position, so there is never a "next up" to bundle.
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async => (item: await fetchItem(id), onDeckEpisode: null);

  @override
  Future<MaItem?> rawItem(String id) async {
    try {
      final result = await guard(() => api.sendCommand('music/item_by_uri', args: {'uri': id}));
      return result is Map<String, dynamic> ? MaItem.fromJson(result) : null;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<MediaItem?> _cachedItem(String id) async {
    try {
      return await cache.getMetadata(serverId, id);
    } catch (e) {
      appLogger.w('MusicAssistantClient: cache read failed for $id', error: e);
      return null;
    }
  }

  Future<void> _cacheItem(MediaItem item) async {
    try {
      await MusicAssistantApiCache.instance.putMetadata(serverId, item);
    } catch (e) {
      appLogger.w('MusicAssistantClient: cache write failed for ${item.id}', error: e);
    }
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    final parent = await _resolve(parentId);
    if (parent == null) return const [];
    return switch (MusicAssistantMappers.kindFor(parent.mediaType)) {
      MediaKind.artist => childList('artist_albums', parent, () => music.getArtistAlbums(parent)),
      MediaKind.album => childList('album_tracks', parent, () => music.getAlbumTracks(parent)),
      MediaKind.playlist => childList('playlist_tracks', parent, () => music.getPlaylistTracks(parent)),
      _ => const [],
    };
  }

  /// Client-side paging over [fetchChildren].
  ///
  /// The children commands take no `limit`/`offset` — they return the whole
  /// child list in one (chunked) answer — so slicing here is the only option.
  /// The list is fetched once and memoised (see [_childLists]) rather than
  /// re-read per page.
  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    abort?.throwIfAborted();
    return slicePage(await fetchChildren(parentId), start: start, size: size);
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    final parent = await _resolve(parentId);
    if (parent == null) return const [];
    return switch (MusicAssistantMappers.kindFor(parent.mediaType)) {
      // An artist's tracks come from a dedicated command rather than by walking
      // its albums — one round-trip instead of one per album.
      MediaKind.artist => childList('artist_tracks', parent, () => music.getArtistTracks(parent)),
      MediaKind.album => childList('album_tracks', parent, () => music.getAlbumTracks(parent)),
      MediaKind.playlist => childList('playlist_tracks', parent, () => music.getPlaylistTracks(parent)),
      MediaKind.track => [?mapItem(parent)],
      _ => const [],
    };
  }

  /// The mapped children [load] returns, from the memo when it is still warm.
  ///
  /// [command] is part of the key because an artist has two different child
  /// lists (`artist_albums` and `artist_tracks`) under one uri.
  Future<List<MediaItem>> childList(String command, MaItem parent, Future<List<MaItem>> Function() load) {
    final key = '$command:${parent.id}';
    final memo = _childLists[key];
    if (memo != null && DateTime.now().difference(memo.at) < _childListTtl) return memo.items;

    final future = guard(load).then(mapItems);
    _childLists[key] = (items: future, at: DateTime.now());
    // A failure must not be served for the rest of the TTL, and the eviction has
    // to be conditional: a later fetch may already have replaced this entry.
    unawaited(
      future.then(
        (_) {},
        onError: (Object _, StackTrace _) {
          if (identical(_childLists[key]?.items, future)) _childLists.remove(key);
        },
      ),
    );
    if (_childLists.length > _maxMemoisedChildLists) {
      final oldest = _childLists.entries.reduce((a, b) => a.value.at.isBefore(b.value.at) ? a : b).key;
      _childLists.remove(oldest);
    }
    return future;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    abort?.throwIfAborted();
    return slicePage(await fetchPlayableDescendants(parentId), start: start, size: size);
  }

  @override
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist) async {
    final parent = await _resolve(artist.guid ?? artist.id);
    if (parent == null) return const [];
    return mapItems(await guard(() => music.getArtistAlbums(parent)));
  }

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async {
    final parent = await _resolve(albumId);
    if (parent == null) return const [];
    return mapItems(await guard(() => music.getAlbumTracks(parent)));
  }

  /// Library-only search, always.
  ///
  /// Without `library_only` the server queries every configured provider live,
  /// which measured 8.42s for `love` against 0.09s with it. Nothing in a
  /// self-hosted collection is missing from the library index, so the live
  /// query buys latency and no results. [MusicAssistantLibrary.search] pins the
  /// flag; this is the note for why it must not be made configurable.
  ///
  /// [excludedLibraryIds] needs no handling: every row carries the one
  /// synthetic library's id, so the caller can drop them itself.
  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    abort?.throwIfAborted();
    final results = await guard(() => music.search(query, limit: limit));
    abort?.throwIfAborted();
    // Artists first: on a collection this size the artist match is almost
    // always what was meant, and the caller re-ranks anyway.
    return [
      ...mapItems(results.artists),
      ...mapItems(results.albums),
      ...mapItems(results.tracks),
      ...mapItems(results.playlists),
    ];
  }

  /// Turn an item id into the wire item the children commands need.
  ///
  /// A Music Assistant uri already encodes everything those commands take —
  /// `library://album/9560` is provider `library`, type `album`, id `9560` — so
  /// the common case needs no round-trip at all. Anything that does not parse
  /// falls back to asking the server.
  Future<MaItem?> _resolve(String id) async => maRefFromUri(id) ?? await rawItem(id);

  /// One page carved out of a list that arrived whole.
  ///
  /// Shared with the playlist methods, which page the same way for the same
  /// reason: the commands behind these lists take no offset.
  static LibraryPage<MediaItem> slicePage(List<MediaItem> items, {int? start, int? size}) {
    final offset = (start ?? 0).clamp(0, items.length);
    final page = size == null ? items.sublist(offset) : items.skip(offset).take(size).toList(growable: false);
    return LibraryPage(items: page, totalCount: items.length, offset: offset);
  }
}

/// Parse a Music Assistant uri into the identity triple its commands take.
///
/// `library://album/9560` maps cleanly onto Dart's [Uri]: scheme is the
/// provider, host is the media type, first path segment is the item id.
/// Returns `null` for anything that is not one, so callers can fall back to a
/// server lookup rather than sending a malformed request.
MaItem? maRefFromUri(String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) return null;
  if (parsed.pathSegments.isEmpty || parsed.pathSegments.first.isEmpty) return null;
  return MaItem(
    itemId: parsed.pathSegments.first,
    provider: parsed.scheme,
    name: '',
    sortName: '',
    uri: uri,
    mediaType: parsed.host,
  );
}
