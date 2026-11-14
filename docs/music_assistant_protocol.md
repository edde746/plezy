# Music Assistant WebSocket protocol

Everything here was verified directly against a live Music Assistant **2.6.3**
server (`schema_version` 26) holding a ~320,000-track OpenSubsonic/Navidrome
library, except where it says 2.10.9. Where a number is quoted it was measured,
not assumed.

## Transport

Single WebSocket: `ws://<host>:<port>/ws` (`wss` for https). Default port 8095.

On connect the server sends an unsolicited greeting:

```json
{
  "server_id": "fe2f5b6fd78e4608bb8b075a6c269fbf",
  "server_version": "2.6.3",
  "schema_version": 26,
  "min_supported_schema_version": 24,
  "base_url": "http://10.0.2.107:8095",
  "homeassistant_addon": false,
  "onboard_done": true
}
```

### Requests

```json
{"message_id": "<unique>", "command": "<command>", "args": {…}}
```

Responses echo `message_id` and carry either `result` or an error:

```json
{"message_id": "1", "result": …, "partial": false}
{"message_id": "1", "error_code": 12, "details": "Invalid command: …"}
```

### `partial` — chunked responses

Every response carries `partial`, and it is load-bearing. Generator commands
stream their answer as several frames sharing one `message_id`:

```json
{"message_id": "1", "result": [ …500 items… ], "partial": true}
{"message_id": "1", "result": [ …500 items… ], "partial": true}
{"message_id": "1", "result": [], "partial": false}
```

The `partial: false` frame terminates the stream and normally carries an empty
list. **A client that completes on the first frame silently truncates the
answer** — a 2,000-track playlist comes back as 500 tracks with no error.
`music/playlists/playlist_tracks` is the command that does this in practice;
`library_items` returns a single frame even at `limit: 1200`.

There are two families of `error_code`: `12` for an unknown command, and `999`
for argument validation (`Value notanint of type <class 'str'> is invalid for
limit…`, and the missing-field errors from `builtin_player/update_state`).
Treat both as request failures.

Responses can arrive out of order and interleaved with events, so match on
`message_id`; never assume the next frame is your reply.

### Events

```json
{"event": "<name>", "object_id": "<id>", "data": {…}}
```

Observed: `player_added`, `player_updated`, `players_updated`, `queue_added`,
`queue_updated`, `queue_items_updated`, `media_item_added`, `builtin_player`.

### Authentication

**None on a LAN server at schema 26.** All commands below work unauthenticated.

**Required on 2.10.9 (schema 65), verified live.** The greeting is still sent to
everyone, so a socket that has not signed in looks connected while every
command is refused. Only `auth`, `auth/login`, `auth/providers` and the like
answer before signing in.

```json
{"message_id": "1", "command": "players/all"}
→ {"message_id": "1", "error_code": 20, "details": "Authentication is required."}

{"message_id": "2", "command": "auth", "args": {"token": "…"}}
→ {"message_id": "2", "result": {"authenticated": true, "user": {…}}}
```

A socket's sign-in dies with the socket, so `auth` is sent on every connect, and
before anything else: the server only pushes events to a socket once it has
signed in.

| Code | Meaning |
| --- | --- |
| `20` | Authentication required |
| `21` | Authentication failed |
| `22` | Signed in, but this user lacks the permission |
| `23` | Token invalid or expired |

Getting a token:

1. `auth/login` with `username`, `password` and `device_name`. Bad credentials
   are **not** an error frame: the reply is a `result` of
   `{"success": false, "error": "Invalid username or password"}`. Good ones give
   `{"success": true, "access_token": "…", "user": {…}}`.
2. That session token has a 30-day sliding expiry, capped at 90 days. Send it
   with `auth`, then `auth/token/create` with a `name`, whose `result` is a bare
   string: a long-lived token lasting one year. That is the one to store.

### What changed by 2.10.9

- `builtin_player/*` is gone, removed upstream in favour of Sendspin
  (`error_code` `12`). The server can no longer stream to this app as a player,
  so a Music Assistant library track cannot play on the phone. Playing to the
  server's own speakers is unaffected, including the Plex URL path.
- Players gained `playback_state`, `group_members` and `name`; `state`,
  `group_childs` and `display_name` remain as aliases.
- `group_members` on a leader lists the leader first. A follower has
  `group_members: []`, `active_group: null`, `active_source: <leader>` and only
  `synced_to: <leader>` to identify it.
- `private` marks a player belonging to one client, such as a browser tab, and
  `hide_in_ui` is the owner's choice. Neither should be offered as an output.
- Unchanged: `player_queues/play_media` takes bare URLs, a URL still comes back
  as `current_item.streamdetails.item_id`, and `queue_time_updated` still
  carries a bare number.

### Sync groups (2.10.9)

`players/create_group_player` with `provider: "sync_group"`, `name`, `members`
and `dynamic: true` makes a permanent player with its own queue, so
`player_queues/*` and `players/cmd/volume_set` work on its id unchanged. It takes
the `config.players.write` scope: a non-admin gets `error_code` `22`, but can
still play to a group that already exists. Measured with demo players:

- The reply reports `group_members: []` whatever was accepted, and members the
  server cannot sync are dropped without an error. Read the group back from
  `players/all` to see what it kept.
- `volume_level` is always null on a group. `group_volume` holds the average of
  its members, except that it reads `0` until the group first plays.
- `supported_features` omits `seek` and `next_previous`, yet `player_queues/seek`
  and `next` work.
- While playing, the leader has `active_group: <group>` and is otherwise
  indistinguishable from a free room with members of its own.
- Starting a group takes its rooms over, from a single-room queue or from another
  group, which carries on with whoever is left.
- Rooms keep `active_source: syncgroup_…` after the group stops, and after it is
  deleted.

## Library browsing

`music/<type>/library_items` where `<type>` is `albums`, `artists`, `tracks`,
`playlists`.

```json
{"command": "music/albums/library_items", "args": {"limit": 500, "offset": 0}}
```

**A request with no `limit` is silently truncated at 500 items** regardless of
library size — the single most important detail here. Always page explicitly.

The result is normally a bare JSON array, but handle both shapes:

```
result: [ … ]                       // observed on 2.6.3
result: {"items": [ … ], …}         // other versions
```

Counts, for deciding whether another page exists:

```json
{"command": "music/albums/count"}   →  {"result": 28671}
```

Works for `albums`, `artists`, `tracks`, `playlists`.

### Ordering — important for paging

Results are ordered by `sort_name` ascending, deterministically, and contiguous
across page boundaries (verified by re-requesting the same offset and by
checking adjacent pages). Deep offsets are fast: 0.19s at album offset 12,800;
2.49s at track offset 140,000.

**Do not re-sort pages client-side.** `name` and `sort_name` disagree for about
one item in nine (`The 100 Greatest Hits of Ella Fitzgerald` sorts under `1`,
not `T`), so sorting by `name` makes rows jump as later pages arrive.

### The collation, and the `#` block at offset 0

`sort_name` is stored lower-cased and ordered by a Unicode collation in which
punctuation and symbols carry **no primary weight**. Three consequences, all
verified:

- A title made only of punctuation collates to the empty key and lands at the
  very front. That is what a user sees first: albums open on `+ (plus)`,
  `- (subtract)`, `÷ (divide)`, `. (period)`; tracks on `@`, `!!!!!!!`, `...`,
  `/`. Measured block sizes: **8 albums, 1 artist, 38 tracks, 0 playlists** —
  small, and contiguous at offsets `[0, k)`.
- Those items are all *equal* to each other, so their order among themselves is
  arbitrary (insertion order): `$$$` appears at index 11 and again at 13, `?` at
  21, 28 and 37. Do not expect a stable order inside the block.
- **Leading punctuation is ignored everywhere else.** `#10` sorts among the
  `10`s, `=1` between `05 …` and `1`, `"99" (Kat Krazy remix)` among the `99`s,
  and `¡Tré!` 90% of the way through the album list under `t`. Bucketing a
  title by its *leading character* therefore disagrees with the server;
  bucketing by its **first letter or digit** matches it exactly. Checked across
  the head of all three collections: with that rule the head partitions into
  exactly `[#][0-9][letters]` with no interleaving.

Full order is `[symbols] [digits] [non-Latin scripts] [Latin a–z]`; on this
library the first Latin album is at offset 674 and the first Latin artist just
past 100.

One quirk no client-side rule reproduces: a Cherokee-script track
(`ꭱꭿꮝꮫ ꮰꮣ`, U+ABxx) sorts *inside* the symbol block, presumably because those
code points post-date the server's collation data and are treated as ignorable.
This is why the app measures the block's size off the server's own first page
rather than computing it — see `_alphabeticalPage` in
`lib/services/music_assistant_client/parts/browse.dart`, which rotates the block
to the end of the list so the alphabetical view opens on `A`.

### Deep offsets are not cheap on `tracks`

Re-measured at 372,000 tracks, `limit: 1`:

| offset | albums (33k) | artists (11k) | tracks (372k) |
|---|---|---|---|
| 0 | 33ms | 24ms | 330ms |
| 25% | 213ms | 54ms | 3.9s |
| 50% | 311ms | 63ms | 5.7s |
| 90% | 371ms | 79ms | 6.9s |

This is worse than the 2.49s at offset 140,000 recorded earlier, and it scales
with the library. It rules out binary-searching the track list for anything —
locating one letter for an alpha bar would be a minute of round-trips. Sequential
500-row paging is unaffected (0.45s at offset 0 rising to 0.84s at 5,500).

### `order_by` — and the two ways it fails

`order_by` is **not validated**, and gets a wrong value wrong in two different
ways. Neither is a clean rejection, so only send values verified against a live
server *for that collection*.

1. **A value the server does not recognise is dropped, and the query then runs
   with no `ORDER BY` at all.** `bogus_field_xyz`, `track_number`, `album_name`
   and `original_sort_name` all return 200 and all return the identical list —
   insertion order, **not** the `sort_name` default. (An earlier note here said
   it fell back to the default ordering; it does not. Re-verified on 2.6.3: the
   album list starts `8 Days of Christmas`, `12 Nights of Christmas`, … where
   `sort_name` starts `+`, `-`, `÷`.) A typo therefore produces a list that
   looks shuffled and reports success.
2. **A value it recognises but which is not a column on that collection reaches
   SQL and fails outright**, `error_code: 999`:
   `no such column: year`, `no such column: duration`,
   `no such column: artists.search_name`. The user sees a library that failed
   to load.

Descending is a `_desc` **suffix on the field**, not a separate keyword.
`order_by: "timestamp_added DESC"` is accepted and silently ordered *ascending*
— it returns the oldest albums, which is exactly backwards for a "Recently
added" row.

Verified on 2.6.3 by comparing result sets against the default, per collection:

| value | albums | artists | tracks | playlists |
|---|---|---|---|---|
| `sort_name` / `_desc` | ✅ A→Z / Z→A | ✅ | ✅ | ✅ |
| `name` / `name_desc` | ✅ differs from `sort_name` | = `sort_name` | = `sort_name` | ✅ |
| `timestamp_added` | ✅ oldest first | ✅ | ✅ | ✅ |
| `timestamp_added_desc` | ✅ **newest first** | ✅ | ✅ | ✅ |
| `timestamp_modified` / `_desc` | ✅ | ✅ | ✅ | ✅ |
| `year` / `year_desc` | ✅ (nulls first ascending) | ❌ 999 | ❌ 999 | ❌ 999 |
| `duration` / `duration_desc` | ❌ 999 | ❌ 999 | ✅ | ❌ 999 |
| `artist_name` / `_desc` | ✅ | = `sort_name` | ❌ 999 | — |
| `play_count_desc`, `last_played_desc` | ✅ | ✅ | ✅ | ✅ |
| `play_count`, `last_played` (asc) | ⚠️ everything ties at 0 → insertion order | ⚠️ | ⚠️ | ⚠️ |
| `random` | ✅ | ✅ | ✅ | ✅ |
| `position`, `track_number`, `album_name`, `original_sort_name` | ⚠️ silently ignored | ⚠️ | ⚠️ | ⚠️ |
| `timestamp_added DESC` | ⚠️ ascending — the space-separated form is ignored | ⚠️ | ⚠️ | ⚠️ |

`random` is a real server-side shuffle (two identical requests return different
items), which is a better "surprise me" row than paging at a random offset.

### `play_count_desc` and `last_played_desc` are a tie, not a ranking

The table above marks both ✅ because they are accepted and do order the rows
that have data. On this library that is **ten albums out of 33,369**. Measured:
`play_count_desc` and `last_played_desc` return byte-identical lists from index
10 onwards, and are still identical at offsets 200, 1,000 and 5,000 — the
remaining 33,359 albums tie at zero and fall back to insertion order. (That tail
is insertion order, not the `sort_name` default, which is the same fallback an
unrecognised `order_by` gets.)

So a twenty-card "Most played" row built on either is ten real answers followed
by ten arbitrary albums, with nothing on screen distinguishing them, and no
cheap way to find the boundary — the item payload carries no `play_count` or
`last_played` field to test. `year_desc` fails the same way for a different
reason: **594 albums are tagged 2026** (1.8% of the library) and the tie breaks
on insertion order, so its head is arbitrary too.

`music/recently_played_items` is the honest alternative for the play axis: it
returns only rows that exist in the log.

`library_items` also accepts `favorite: <bool>`, which filters. `count` accepts
the argument but ignores it, so a favourites list has no matching total.

### `library_items` also takes `search`

Undocumented but real, and it honours `limit`, `offset` and `order_by`:

```json
{"command": "music/albums/library_items",
 "args": {"limit": 20, "offset": 0, "search": "radiohead", "order_by": "sort_name"}}
```

It is a **substring** match, not a prefix one — `search: "zz"` returns
`All That Jazz` — so it cannot stand in for an alpha-bar prefix filter. It also
matches artist names, not just titles: `music/tracks/library_items` with
`search: "love"` returns `$` by The Egyptian Lover. Fast (34ms albums, 100ms
tracks) and stable across repeated calls.

Two traps before reaching for it:

- **`count` ignores `search`** and returns the unfiltered total, so a searched
  list has no server-side total.
- **On `tracks` it returns up to *twice* `limit`.** `limit: 20, offset: 0`
  returned 40 rows: the title match and the artist match are separate queries,
  each limited, and both frames arrive under one `message_id`. Offsets past the
  first page returned `limit` rows again. The limit contract is therefore not
  reliable enough to page a browse list on, which is why the app's in-library
  filter still goes through `music/search`.

### Deduplicate appended pages

While the server is still scanning, offsets shift under you — this library grew
77% in 45 minutes during testing. An item already held reappears in the next
page, so filter appended pages against what is already loaded.

### Item shape

```json
{
  "item_id": "9560",
  "provider": "library",
  "name": "+ (plus)",
  "sort_name": "+",
  "uri": "library://album/9560",
  "media_type": "album",
  "favorite": false,
  "year": 2011,
  "artists": [ … ],
  "metadata": {"images": [{"type": "thumb", "path": "…"}]},
  "provider_mappings": [{"provider_domain": "opensubsonic", …}]
}
```

`uri` is what playback commands take.

Real items carry more than this. Tracks add `duration`, `album`, `disc_number`
and `track_number`. Nested artist and album objects use a single `image` key
rather than a `metadata.images` array, so artwork lookup needs to fall back to
it.

### A single item

```json
{"command": "music/item_by_uri", "args": {"uri": "library://album/9560"}}
```

Returns the fully-expanded item. `music/item`
(`{"media_type": …, "item_id": …, "provider_instance_id_or_domain": …}`) returns
the same thing from the split identity. `uri` is the only globally unique handle
— `item_id` is scoped to both `provider` and `media_type`.

**Do not fan out concurrent requests. The server has a hard backpressure limit.**
Music Assistant drops a client with `Client exceeded max pending messages: 512`,
and a saturated server degrades in a way that is easy to misread: `count`
answers in 9ms while `players/all` and **every** `library_items` request hang
for an hour or more. It looks like specific commands or specific items are
broken. They are not.

This was misdiagnosed twice during development. Seven parallel `music/item_by_uri`
calls wedged the server, and the five uris in flight when it went down were
recorded as individually poisonous — `library://track/371883`, `/60473`,
`/44060`, `/35583` and `library://album/923`. Re-measured serially against a
freshly restarted server, **every one answers in 0.02s**, and their
`provider_mappings` contain only `opensubsonic`, so the Plex-expansion theory
that seemed to explain them is wrong too.

The rule is about concurrency, not about any command or item: bound how many
requests are outstanding on one socket, and treat a sudden hang in an unrelated
command family as the symptom of an overloaded server rather than as a property
of what you last asked for. Recovery is a restart of the server container.

**The transport enforces this now.** `MusicAssistantApi` keeps at most
`defaultMaxConcurrentRequests` (3) requests on the wire and queues the rest, so
callers no longer have to hand-serialise — a fan-out is safe to write, it just
takes longer. Three is chosen against the seven that wedged the server, not
against the 512 the protocol allows; the damage starts nowhere near 512. The
request timeout starts when a request is dispatched rather than when it was
asked for, so waiting for a slot is never mistaken for server slowness. Do not
raise the limit without a measurement, and do not add a second socket to get
around it — the bound is only meaningful because one client owns one socket.

### `music/recently_played_items`

```json
{"command": "music/recently_played_items",
 "args": {"limit": 20, "media_types": ["artist", "album", "track"]}}
```

The play log, most recent first. Honours `media_types`; `limit` caps it but
never pads — a server with six plays answers six rows to `limit: 100`. There is
no `offset`.

Rows are **abbreviated** (`item_id`, `provider`, `name`, `sort_name`, `uri`,
`media_type`, `available` and a single `image` map): no `artists`, no `album`,
no `metadata`. The `image` key is the one nested items use, so artwork resolves;
a subtitle does not.

This is the only honest "recently played" source. See the `order_by` table
below for why `last_played_desc` is not one.

### Children

```json
{"command": "music/albums/album_tracks",
 "args": {"item_id": "…", "provider_instance_id_or_domain": "…"}}
```

Also `music/artists/artist_albums`, `music/artists/artist_tracks`,
`music/playlists/playlist_tracks`. `provider` on the item supplies
`provider_instance_id_or_domain`. These take no `limit`/`offset` — they return
the whole child list.

`playlist_tracks` differs from the other three in two ways, both of which look
like "the playlist is empty" rather than like an error:

- It is the chunked command (see `partial` above).
- A playlist the server has not resolved yet returns `[]` with no error.
  `force_refresh: true` resolves it. There is a `page` argument, but every value
  returned the same first chunk, so it is not a pagination handle.

## Search

```json
{"command": "music/search",
 "args": {"search_query": "love",
          "media_types": ["album", "artist", "track"],
          "limit": 50,
          "library_only": true}}
```

**`library_only` is the difference between usable and unusable.** Without it the
server queries every configured provider live:

| query | unrestricted | `library_only: true` |
|---|---|---|
| `love` | **8.42s** | **0.09s** |
| `radiohead` | 0.19s | 0.05s |

The unrestricted figure depends on which providers are configured and how they
are feeling — a later run of the same `love` query measured 0.41s rather than
8.42s. Treat 8.42s as the worst case that has actually happened, not as a
constant. `library_only` is still 4–90× faster and cannot regress that way.

Everything in a self-hosted collection is already in the library index, so
`library_only: true` is the right default. Result is a map keyed by
`albums`, `artists`, `tracks`, `playlists`, `radio`, `audiobooks`, `podcasts`,
each capped at `limit` (so `limit: 25` over four media types is up to 100 rows).
There is no `offset`: a page has to be carved out of a single over-fetch.

A query that matches nothing returns every bucket empty in 0.08s rather than
falling back to a provider sweep.

## Players and playback

`players/all` returns every known player:

```json
{"player_id": "RINCON_74CA6074EA9A01400", "name": "Sonos",
 "provider": "sonos", "available": true, "powered": true, "state": "idle",
 "volume_level": 4, "group_childs": [], "synced_to": null,
 "active_source": "RINCON_…", "supported_features": ["enqueue","seek",…]}
```

`provider` values seen: `sonos`, `builtin_player`. There is no `sendspin`
provider on a stock server — that is a separate protocol needing its own server,
and assuming otherwise is what left the previous app unable to play anything
locally.

Player objects are much larger than the excerpt above (36 keys), including
`display_name`, `volume_muted`, `elapsed_time`, `current_media`, `device_info`
and separate `power_control` / `volume_control` / `mute_control` entries.
Note `volume_level` **can be null** — a registered but idle `builtin_player`
reports null rather than 0, so it must not be typed as a plain int. A player is only controllable
while `available` is true — a Sonos drops out whenever another source (AirPlay,
the Sonos app) takes it, reporting `available: false` with
`active_source: "airplay"`.

Playback is driven server-side through the queue, and the queue id is the
player id:

```json
{"command": "player_queues/play_media",
 "args": {"queue_id": "<player_id>", "media": ["library://track/68057"],
          "option": "replace"}}
```

Transport: `player_queues/play_pause`, `next`, `previous`, `stop`,
`seek` (`{"position": <int seconds>}`), `shuffle` (`{"shuffle_enabled": bool}`),
`repeat` (`{"repeat_mode": "off"|"all"|"one"}`) — all keyed by `queue_id`.
Volume is per player: `players/cmd/volume_set`
`{"player_id": …, "volume_level": 0-100}`.

Favourites: `music/favorites/add_item` / `remove_item` with `{"item": "<uri>"}`.

### The queue commands lie quietly — read the queue back

Four behaviours verified on 2.6.3, none of them detectable from the reply.
Together they are why a client must never treat "what I sent" as "what the
server holds":

- **`play_media` skips uris it cannot resolve and still answers
  `result: null`.** Sending `["plex://track/12345", "library://track/193073",
  "plex://track/999"]` produced a **one-item** queue and reported success. Only
  an all-unresolvable push errors (`error_code: 2`, "No playable items found").
- **`replace_next` keeps every item *before* the current one.** `[A,B,C,D]` at
  `current_index` 1 plus `replace_next [E,F]` leaves `[A,B,E,F]` — the prefix
  survives, so the resulting queue is *longer* than the list that was sent.
- **`play_index` past the end is accepted.** `play_index(7)` on a two-item
  queue returns `null`, sets `current_index: 7` and goes idle. Silence, no
  error.
- **`play_index` into a queue another controller replaced is accepted too**,
  and plays that controller's track. Only an unknown `queue_id` errors
  (`error_code: 999`), so the diverged-but-alive case is completely silent.

The reconciliation the server does offer:

```json
{"command": "player_queues/items",
 "args": {"queue_id": "<player_id>", "limit": 50, "offset": 0}}
```

Returns the real rows in order, each with `media_item.uri`. It honours `limit`
and `offset`, measured 15–22ms for 20 rows on a LAN (~2.4 KB per row), and
answers `[]` — not an error — for a queue that does not exist or an offset past
the end. `player_queues/get` gives the summary: `items` is a **count**, plus
`current_index` and `current_item`.

`queue_items_updated` is the event that says the item list changed, and it is
precise: verified to fire for a foreign `move_item` and a `play_media`, and
**not** for `next`, `play_index` or a repeat-mode change (those emit
`queue_updated` alone). That makes it usable as an exact "re-read the queue"
trigger.

One trap in `queue_updated` itself: `current_index` and `current_item` can
disagree within a single frame. Immediately after a `play_index(1)` the frame
carried `current_index: 1` with the *previous* item's uri, and only a later
read showed the pair agreeing. So the index is a hint and the uri names what is
sounding — never conclude "diverged" from the two disagreeing.

Note the Sonos topology can go stale. Reloading the provider
(`config/providers/reload` with `{"instance_id": "sonos"}`) corrected wrong
names and a phantom unavailable player.

## Playing on this device — `builtin_player`

This is how a client becomes an output. It needs no server plugin; it is part of
stock Music Assistant.

```json
{"command": "builtin_player/register",
 "args": {"player_name": "iPhone", "player_id": "ma_myapp_abc123"}}
```

**Always pass an explicit `player_id`.** Registration is then idempotent —
registering twice with the same id returns the same player. Letting the server
allocate one mints a brand new player on every connect and fills the user's
Music Assistant with abandoned duplicates. Derive a stable id from a device
identifier and persist it.

The server then drives the client with `builtin_player` events:

```json
{"event": "builtin_player", "object_id": "<player_id>",
 "data": {"type": "play_media", "volume": null,
          "media_url": "builtin_player/flow/<player_id>.mp3"}}
```

`type` values: `power_on`, `power_off`, `play_media`, `pause`, `resume`, `stop`,
`mute`, `unmute`, `set_volume`, `timeout`.

`media_url` is **relative to the server base URL**:
`http://<host>:<port>/builtin_player/flow/<player_id>.mp3`

A client that drives playback itself does not have to wait for the event — the
same URL can be built directly. Verified end to end: `builtin_player/register`,
then `player_queues/play_media` with `queue_id` set to the player id, then a GET
of that URL returns `200 audio/mp3`.

This is **flow mode**: the entire queue is one continuous MP3 stream. Track
changes happen server-side inside the stream, so the client plays a single URL
and never needs per-track URLs or gapless handling. Track metadata for display
comes from `queue_updated` events, not from the stream.

State must be reported back regularly or the server declares the player dead and
sends `type: "timeout"`:

```json
{"command": "builtin_player/update_state",
 "args": {"player_id": "…",
          "state": {"powered": true, "playing": true, "paused": false,
                    "muted": false, "volume": 100, "position": 12}}}
```

**Every field is required** — omitting any one is rejected outright
(`Field "volume" of type int is missing in BuiltinPlayerState instance`).
`volume` and `position` are ints; `position` is seconds into the stream. A 5s
reporting interval works.

### After a seek, keep reporting *cut-relative* positions

`player_queues/seek` re-cuts the flow stream and pushes a fresh `play_media` at
the player. The client re-opens the same URL, and its own position starts again
at zero — which looks like it must be wrong, and is not. **The server adds the
seek offset itself.** Measured with a real consumer on the stream, seeking to
120s and then reporting 0, 2, 4 … 10:

| reported `position` | server `elapsed_time` |
|---|---|
| 10 (cut-relative, after seek to 120) | **128.1** — correct |
| 140 (flow-absolute: 120 + 20) | **258.1** — double-counted |

So do not "correct" the report by adding the seek target back on. The number
the server wants is seconds into the stream **this device currently has open**,
not seconds into the queue.

### `player_queues/seek` reports an elapsed with no ceiling

Measured with a real consumer on the flow stream, three tracks queued, seeking
inside the first (169s):

| seek target | accepted? | what `player_queues/get` then reported |
|---|---|---|
| duration − 60s | ✅ | `elapsed_time` = 109 + seconds into the new cut |
| duration − 20s | ✅ | 149 + …, reaching **179** and still `current_index: 0` |
| duration − 15s | ✅ | 154 + …, reaching **184** |
| duration − 12s | ✅ | 157 + …, reaching **187** |
| duration − 11s | ✅ | 158 + …, reaching **188** |
| duration − 10s | ✅ | 159 + …, reaching **189** |

**There is no offset it refuses**, and `elapsed_time` is not bounded by the
item's own duration — every one of those runs past 169. `current_index` did not
advance in any of them.

The mechanism is in `player_queues.py`: `seek` delegates to `play_index`, which
sets `flow_mode_stream_log = []`, and `_get_flow_queue_stream_index` derives both
the index and the elapsed by walking that log. A log entry gets its
`seconds_streamed` only once the flow generator has finished streaming that item;
until then the walk treats the entry as `3600 * 24 * 7` seconds long, always
selects it, and returns `deviceStreamPosition + streamdetails.seek_position`.
Nothing clamps it to the item.

So `elapsed_time` after a seek is **seconds into the cut this device has open,
plus the seek offset** — not a position inside the track — and a client cannot
wait on `current_index` to notice the track ended.

### Two failures that look like a near-the-end seek and are not

Both were on the way to the above and neither is caused by seeking:

- **`player_queues/seek` → `Queue <name> has no item(s) loaded.`** means
  `queue.current_item` is `None`, i.e. playback never started. Reproduced by
  opening the flow URL before the server has set `player.current_media`: the
  route has already called `resp.prepare()`, so it cannot answer 404 and instead
  returns **a 200 with an empty body**. Silence, no error. Wait for the
  `builtin_player` `play_media` event before opening.
- **`player_queues/stop` → `'NoneType' object has no attribute 'queue_id'`**
  means the queue does not exist at all — the player was removed or never
  registered. `stop` binds `queue := self.get(queue_id)` and then dereferences
  it unconditionally.

Teardown: `builtin_player/unregister` `{"player_id": …}` marks it unavailable
but leaves the record; `config/players/remove` `{"player_id": …}` deletes it.

**A registered player does not yet have a queue.** `builtin_player/register`
answers with a complete, `available: true` player, and
`player_queues/play_media` for that same id can still answer `error_code: 10,
Queue <id> is not available` — observed for the whole of a 30-second poll, on
both a fresh id and a reused one. Wait for `player_queues/get` to return an
object rather than `null` before pushing a queue.

## Artwork

Images come through the server's proxy:

```
http://<host>:<port>/imageproxy?path=<image path>&provider=<image provider>&size=<pixels>
```

**All three parameters are required.** `path` alone returns 404 — the same path
exists under several providers, so `provider` (the sibling
`metadata.images[].provider` key, e.g. `opensubsonic--pu5hhsYV` or `builtin`) is
what identifies the image. A non-integer `size` returns 500, and omitting `size`
returns the original file: 2.4 MB versus 166 KB at `size=300` for one album
cover, so it is not optional in practice either.

An item's images array can hold both a provider-local path
(`al-4e9Hni3gptmRhnfiL6Y6iJ_692d2ed2`, `remotely_accessible: false`) and an
absolute URL to the backing server, and the proxy accepts either as `path`.
Prefer the local one; the remote URL points at an address this device may not
be able to reach.

Artwork is immutable once
fetched, so cache it on disk — re-fetching thumbnails on every cold start is the
main cause of a slow first scroll through a large library.

## Discovery

The server advertises over mDNS on the LAN, so a client can auto-discover rather
than asking for a URL.

The service type is **`_mass._tcp`** — not `_music-assistant._tcp`, which is what
the app this replaces declared and is why its auto-discovery never found
anything. Verified with `dns-sd -B _mass._tcp local.`; browsing
`_music-assistant._tcp` returns nothing on a network with a live server.

The advertised instance name is the server id, matching `server_id` in the
greeting (`fe2f5b6fd78e4608bb8b075a6c269fbf` on this network), which makes it
usable for matching a discovered server against a stored connection.

On iOS the service type must also be declared in `Info.plist` under
`NSBonjourServices` or the local-network privacy rules block the browse
entirely, with no error that points at the cause.

## Base URL

The greeting carries `base_url`, but prefer the address the client actually
connected on. A server behind a container or on a multi-homed host can advertise
an address that is not reachable from the client.
