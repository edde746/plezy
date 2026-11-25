#!/usr/bin/env python3
"""A fake of the tracker services (Trakt, Simkl, MDBList, MyAnimeList, AniList) and of Plezy's OAuth relay, for the
trackers tests: the app's development session sends each service's host here (--dev-trackers <this server>, on
Android inside the `dev` extra), each under its prefix below, and signs in, scrobbles, marks watched, rates and keeps
watchlists without real accounts. Standard library only; everything is in memory and per run.

Every route also answers under /run/<id> (<id>: letters, digits and hyphens), against a state of that run's own that
starts as the root's does: test runs that share one server each take their own <id>, so one run's /_reset, /_config
and writes never reach another's. The 64 runs used last are kept.

Usage: tools/media/test_trackers.py [--host 0.0.0.0] [--port 28100] [--approve-after 2] [--user plezy-tester]

Seeded titles (the test servers' NFOs carry these ids; each has community scores on every service):
  Maestro Movie   movie  imdb tt9900001  tmdb 990001  trakt 990001  simkl 990001
  Credits Movie   movie  imdb tt9900002  tmdb 990002  trakt 990002  simkl 990002
  Chapters Movie, Two Versions, Subtitled Movie, Resume Movie, Guest Galaxy
                  movies imdb tt9900003..tt9900007, tmdb/trakt/simkl 990003..990007 in that order
  Maestro Show    show   imdb tt9900101  tmdb 990101  tvdb 990101  trakt 990101  simkl 990101  episodes S1E1-3, S2E1-2
  Second Show     show   imdb tt9900102  tmdb 990102  tvdb 990102  trakt 990102  simkl 990102  episodes S1E1-2
  Maestro Anime   show   imdb tt9900201  tmdb 990201  tvdb 990201  MyAnimeList 990201  AniList 990201, 12 episodes
  Yume Anime      show   imdb tt0500092  tmdb 1087  tvdb 78814  trakt 990202  simkl 37513  MyAnimeList 339  AniList 339,
                  episodes S1E1-3: a real anime's ids (AniDB 99), so the anime mappings the app downloads map the
                  library copy to its MyAnimeList and AniList entries
The watchlists start with Maestro Movie and Maestro Show on Trakt, Simkl and MDBList. The anime lists start with Yume
Anime completed: on MyAnimeList scored 8, on AniList 7.

Routes, Trakt (docs.trakt.tv) at the root:
  POST /oauth/device/code                   a device code whose verification_url is this server's /activate
  POST /oauth/device/token                  400 (pending) until polled --approve-after times, then the tokens
  POST /oauth/token                         a refresh: new tokens (rotated refresh token)
  POST /oauth/revoke                        a revoke, counted
  GET  /users/settings                      {user: {username: --user, ids: {slug}}}
  POST /scrobble/{start,pause,stop}         recorded; a stop at 80% or more also counts as a watch (Trakt's rule)
  POST /sync/history[/remove]               watched and unwatched marks; fail while /_fail?writes=1
  POST /sync/ratings[/remove]               ratings by the items' ids; fail while /_fail?ratings=trakt
  GET  /sync/ratings/{movies,shows,seasons,episodes}  that kind's ratings, as rated items
  POST /sync/watchlist[/remove]             watchlist writes; fail while /_fail?watchlist=trakt
  GET  /sync/watchlist[/{movies,shows}]     the watchlist, as listed items
  GET  /{movies,shows}/{trending,popular}   the seeded titles (trending wrapped with watchers)
  GET  /recommendations/{movies,shows}      the seeded titles of that kind
  GET  /search/{movie,show,movie,show}?query=  the seeded titles whose name contains query, scored
  GET  /search/{tmdb,tvdb,imdb}/{id}[?type=]   the seeded title with that id, or []
  GET  /{movies,shows}/{id}/ratings         {rating, votes, distribution}
  GET  /{movies,shows}/{id}/people          a cast and crew
  GET  /{movies,shows}/{id}/related         the other seeded titles of that kind
  GET  /activate                            a page saying the code is approved automatically
  Titles carry `extended=full` fields (overview, rating, votes, runtime, genres) and `images` when asked.
Simkl under /simkl (api.simkl.com and its CDN data.simkl.in):
  POST /simkl/oauth2/device                 an RFC 8628 device code (verification_uri, verification_uri_complete)
  POST /simkl/oauth2/token                  device_code: authorization_pending until approved, then tokens with scope
                                            `media:read media:write` (simkl_at_ prefixed); refresh_token: new access token
  POST /simkl/oauth2/revoke                 a revoke, counted
  GET  /simkl/users/settings                {user: {name}, account: {id}}
  POST /simkl/scrobble/{start,pause,stop}   as Trakt's
  POST /simkl/sync/history[/remove]         marks (fail while writes fail); /remove also takes items off plan to watch
  POST /simkl/sync/ratings[/remove]         ratings; GET /simkl/sync/ratings[/{movies,shows,anime}] reads them
  POST /simkl/sync/add-to-list              an item `to: plantowatch` goes on the watchlist
  GET  /simkl/sync/all-items/{all,movies,shows,anime}/plantowatch  the watchlist
  GET  /simkl/redirect?{imdb,tmdb,tvdb}=<id> 301 to /simkl/{movies,tv}/<simkl id> (unknown: 404)
  GET  /simkl/{movies,tv,anime}/<simkl id>  ratings {simkl, imdb, mal}
  GET  /simkl/discover/trending/{movies,tv,anime}/<period>.json  the seeded titles (CDN shape)
MDBList under /mdblist:
  POST /mdblist/oauth/device-authorization/ an RFC 8628 device code
  POST /mdblist/oauth/token/                device_code (pending until approved) or refresh_token grant
  POST /mdblist/oauth/revoke_token/         a revoke, counted
  GET  /mdblist/user                        {user_id, username}
  POST /mdblist/scrobble/{start,pause,stop} as Trakt's
  POST /mdblist/sync/watched[/remove]       marks; fail while writes fail
  POST /mdblist/sync/ratings[/remove]; GET /mdblist/sync/ratings  ratings
  GET  /mdblist/watchlist/items; POST /mdblist/watchlist/items/{add,remove}  the watchlist
  GET  /mdblist/{imdb,tmdb,tvdb,mal}/{movie,show,any}/<id>  the title's ratings array: imdb, tmdb, tomatoes, popcorn,
                                            metacritic, letterboxd, trakt, myanimelist; unknown: 404
MyAnimeList under /mal (api.myanimelist.net and myanimelist.net):
  POST /mal/v1/oauth2/token                 refresh_token: new tokens
  GET  /mal/v2/users/@me                    {id, name: --user}
  GET  /mal/v2/anime/<id>                   {id, title, num_episodes, mean, num_scoring_users, my_list_status?}
  PUT  /mal/v2/anime/<id>/my_list_status    form status/score/num_watched_episodes: the entry updated and returned
  DELETE /mal/v2/anime/<id>/my_list_status  the entry gone (404 when there was none)
AniList under /anilist (graphql.anilist.co and anilist.co):
  POST /anilist                             GraphQL by operation substring: Viewer, SaveMediaListEntry,
                                            DeleteMediaListEntry, Media (averageScore, episodes, mediaListEntry;
                                            the entry's scoreRaw, 0-100, when the query asks for it)
Plezy's OAuth relay under /relay (ice.plezy.app; server/oauth.go), for MyAnimeList and AniList:
  POST /relay/auth/start {service}          {session, url, expiresIn: 600}; url is this server's /relay/auth/<service>
  GET  /relay/auth/<service>?state=         a page; fetching it approves the session
  GET  /relay/auth/result?session=          204 until approved (or polled --approve-after times), then once 200
                                            {accessToken, refreshToken (MyAnimeList only), expiresIn}; after that 410
Harness:
  GET  /_config                             {user, prefixes, tokenPrefix, approveAfter}
  POST /_config?approveAfter=<n>            sign-ins approve after n polls from now on (until /_reset): a large n
                                            holds the connect dialog up for a screenshot
  GET  /_log                                requests (method, path, status, bearer), polls, scrobbles (with progress),
                                            watches, marks, ratingWrites, userRatings, watchlistWrites, watchlists,
                                            revokes, grants (relay and device-code)
  POST /_fail?writes=1|0[&status=<code>]    watched/unwatched marks fail (503 by default) or go through again
  POST /_fail?ratings=<service>[,...][&status=]   those services' rating writes fail; empty: none
  POST /_fail?watchlist=<service>[,...][&status=] those services' watchlist writes fail; empty: none
  POST /_rating?service=<trakt|simkl|mdblist>&imdb=<tt>[&kind=movies|shows][&rating=<1-10>]
                                            the user's rating there, as if given on the service (no rating: removed)
  POST /_reset                              back to the start state
Access tokens are fake-access-<n> (Simkl's simkl_at_fake-access-<n>); any bearer passes.
"""
import argparse
import collections
import copy
import http.server
import json
import re
import secrets
import threading
import time
import urllib.parse

PREFIXES = {"trakt": "", "simkl": "/simkl", "mdblist": "/mdblist", "mal": "/mal", "anilist": "/anilist", "relay": "/relay"}
TOKEN_PREFIX = "fake-access-"
RATING_SERVICES = ("trakt", "simkl", "mdblist")
# A run's own state: /run/<id> before any route.
RUN = re.compile(r"/run/([A-Za-z0-9-]{1,64})(?=/|$)")
MAX_RUNS = 64

# The seeded titles: (kind, title, year, ids, seasons {season: episodes}, scores).
TITLES = [
    ("movie", "Maestro Movie", 2021, {"imdb": "tt9900001", "tmdb": 990001, "trakt": 990001, "simkl": 990001}, {},
     {"imdb": 7.8, "tmdb": 76, "tomatoes": 91, "popcorn": 88, "metacritic": 81, "letterboxd": 3.9, "trakt": 79,
      "simkl": 7.9}),
    ("movie", "Credits Movie", 2019, {"imdb": "tt9900002", "tmdb": 990002, "trakt": 990002, "simkl": 990002}, {},
     {"imdb": 5.4, "tmdb": 52, "tomatoes": 34, "popcorn": 41, "metacritic": 47, "letterboxd": 2.6, "trakt": 55,
      "simkl": 5.6}),
    ("show", "Maestro Show", 2020,
     {"imdb": "tt9900101", "tmdb": 990101, "tvdb": 990101, "trakt": 990101, "simkl": 990101}, {1: 3, 2: 2},
     {"imdb": 8.6, "tmdb": 84, "tomatoes": 95, "popcorn": 92, "metacritic": 88, "letterboxd": 4.2, "trakt": 86,
      "simkl": 8.5}),
    ("show", "Second Show", 2022,
     {"imdb": "tt9900102", "tmdb": 990102, "tvdb": 990102, "trakt": 990102, "simkl": 990102}, {1: 2},
     {"imdb": 6.9, "tmdb": 68, "tomatoes": 72, "popcorn": 70, "metacritic": 64, "letterboxd": 3.3, "trakt": 70,
      "simkl": 6.8}),
    ("show", "Maestro Anime", 2018,
     {"imdb": "tt9900201", "tmdb": 990201, "tvdb": 990201, "trakt": 990201, "simkl": 990201, "mal": 990201,
      "anilist": 990201}, {1: 12},
     {"imdb": 8.1, "tmdb": 80, "tomatoes": 90, "popcorn": 87, "metacritic": 79, "letterboxd": 3.8, "trakt": 82,
      "simkl": 8.2, "myanimelist": 8.31, "anilist": 83}),
    ("show", "Yume Anime", 2026,
     {"imdb": "tt0500092", "tmdb": 1087, "tvdb": 78814, "trakt": 990202, "simkl": 37513, "mal": 339, "anilist": 339},
     {1: 3},
     {"imdb": 7.6, "tmdb": 77, "tomatoes": 85, "popcorn": 83, "metacritic": 74, "letterboxd": 3.7, "trakt": 78,
      "simkl": 7.7, "myanimelist": 8.07, "anilist": 79}),
]
# The other test movies, ids 9900003.. in order, each with plain scores.
for _n, _name in enumerate(("Chapters Movie", "Two Versions", "Subtitled Movie", "Resume Movie", "Guest Galaxy"), 3):
    _id = 990000 + _n
    TITLES.append(("movie", _name, 2020, {"imdb": f"tt{9900000 + _n}", "tmdb": _id, "trakt": _id, "simkl": _id}, {},
                   {"imdb": round(6.0 + _n / 10, 1), "tmdb": 60 + _n, "tomatoes": 60 + 2 * _n, "popcorn": 62 + _n,
                    "metacritic": 55 + _n, "letterboxd": round(3.0 + _n / 20, 2), "trakt": 61 + _n,
                    "simkl": round(6.1 + _n / 10, 1)}))
ANIME = {t[3]["mal"]: t for t in TITLES if "mal" in t[3]}
INITIAL_WATCHLIST = [{"kind": "movies", "ids": dict(TITLES[0][3])}, {"kind": "shows", "ids": dict(TITLES[2][3])}]


def find_title(ids):
    """The seeded title one of [ids] names, or None."""
    for t in TITLES:
        if any(str(t[3].get(k)) == str(v) for k, v in ids.items() if v is not None and k in t[3]):
            return t
    return None


def trakt_title(t, query):
    """A seeded title as Trakt shows it; extended=full / images add those fields."""
    kind, name, year, ids, seasons, scores = t
    out = {"title": name, "year": year, "ids": {"slug": name.lower().replace(" ", "-"), **ids}}
    extended = ",".join(query.get("extended", []))
    if "full" in extended:
        out.update({"overview": f"{name}, a test title.", "rating": scores["trakt"] / 10, "votes": 1234,
                    "runtime": 100 if kind == "movie" else 45, "genres": ["drama"], "language": "en",
                    "certification": "PG-13", "status": "released" if kind == "movie" else "returning series"})
        if kind == "show":
            out["aired_episodes"] = sum(seasons.values())
    if "images" in extended:
        out["images"] = {"poster": [], "fanart": [], "logo": [], "thumb": []}
    return out


def ids_match(a, b):
    return any(str(a[k]) == str(b[k]) for k in a if k in b and a[k] is not None)


def items_of(body):
    """(kind, ids, entry) of a Trakt-shaped body's movies/shows/seasons/episodes/anime items."""
    out = []
    for kind in ("movies", "shows", "seasons", "episodes", "anime"):
        for item in body.get(kind, []) or []:
            out.append(("shows" if kind == "anime" else kind, item.get("ids", {}) or {}, item))
    return out


def scrobble_item(body):
    """The scrobble body's title ids and episode (season, number) if any."""
    for key in ("movie", "show", "anime"):
        if key in body:
            ep = body.get("episode") or {}
            episode = (ep.get("season"), ep.get("number")) if ep else None
            return body[key].get("ids", {}), episode
    if "episode" in body:
        return body["episode"].get("ids", {}), None
    return {}, None


class State:
    def __init__(self, approve_after, user):
        self.default_approve_after = approve_after
        self.user = user
        # Reentrant: replies record the request under the lock, and some reply while holding it.
        self.lock = threading.RLock()
        self.reset()

    def reset(self):
        self.approve_after = self.default_approve_after
        self.tokens = 0
        self.devices = {}  # device code -> {service, polls, claimed}
        self.relay = {}  # session -> {service, state, approved, polls, claimed}
        self.requests, self.polls, self.scrobbles, self.watches, self.marks = [], [], [], [], []
        self.rating_writes, self.watchlist_writes, self.revokes, self.grants = [], [], [], []
        self.ratings = {s: [] for s in RATING_SERVICES}
        self.watchlists = {s: copy.deepcopy(INITIAL_WATCHLIST) for s in RATING_SERVICES}
        # mal id -> my_list_status; AniList media id -> entry (its score on the 10-point scale).
        self.mal = {339: {"status": "completed", "score": 8, "num_episodes_watched": 3, "is_rewatching": False,
                          "updated_at": "2026-01-01T00:00:00+00:00"}}
        self.anilist = {339: {"id": 900339, "mediaId": 339, "status": "COMPLETED", "progress": 3, "score": 7}}
        self.fail_writes = False
        self.fail_ratings, self.fail_watchlist = set(), set()
        self.fail_status = 503

    def log(self):
        return {"requests": self.requests, "polls": self.polls, "scrobbles": self.scrobbles, "watches": self.watches,
                "marks": self.marks, "ratingWrites": self.rating_writes, "userRatings": self.ratings,
                "watchlistWrites": self.watchlist_writes, "watchlists": self.watchlists, "revokes": self.revokes,
                "grants": self.grants, "mal": self.mal, "anilist": self.anilist}

    def next_token(self):
        self.tokens += 1
        return self.tokens


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=28100)
    ap.add_argument("--approve-after", type=int, default=2, help="polls before a device code or relay session approves")
    ap.add_argument("--user", default="plezy-tester")
    a = ap.parse_args()
    root = State(a.approve_after, a.user)
    runs = collections.OrderedDict()  # run id -> State, the one used longest ago first
    runs_lock = threading.Lock()

    def state_of(run):
        """The root's state, or the run's (made on its first request)."""
        if run is None:
            return root
        with runs_lock:
            if run not in runs:
                runs[run] = State(a.approve_after, a.user)
                if len(runs) > MAX_RUNS:
                    runs.popitem(last=False)
            runs.move_to_end(run)
            return runs[run]

    class Handler(http.server.BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):
            pass

        def base(self):
            return f"http://{self.headers['Host']}{self.scope}"

        def body(self):
            length = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(length) if length else b""
            if (self.headers.get("Content-Type") or "").startswith("application/x-www-form-urlencoded"):
                return {k: v[0] for k, v in urllib.parse.parse_qs(raw.decode()).items()}
            try:
                return json.loads(raw) if raw else {}
            except ValueError:
                return {k: v[0] for k, v in urllib.parse.parse_qs(raw.decode(errors="replace")).items()}

        def reply(self, status, payload=None, content_type="application/json", headers=None):
            path = urllib.parse.urlsplit(self.path).path[len(self.scope):]
            if not path.startswith("/_"):
                with self.state.lock:
                    self.state.requests.append({"method": self.command, "path": path, "status": status,
                                                "bearer": (self.headers.get("Authorization") or "").startswith("Bearer "),
                                                "at": time.time()})
            self.send_response(status)
            for k, v in (headers or {}).items():
                self.send_header(k, v)
            if status in (204, 304):
                self.send_header("Content-Length", "0")
                self.end_headers()
                return
            data = payload if isinstance(payload, bytes) else json.dumps(payload if payload is not None else {}).encode()
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            self.route("GET")

        def do_POST(self):
            self.route("POST")

        def do_PUT(self):
            self.route("PUT")

        def do_DELETE(self):
            self.route("DELETE")

        def route(self, method):
            split = urllib.parse.urlsplit(self.path)
            run = RUN.match(split.path)
            self.scope = run.group(0) if run else ""
            self.state = state_of(run.group(1) if run else None)
            path, query = split.path[len(self.scope):], urllib.parse.parse_qs(split.query, keep_blank_values=True)
            body = self.body() if method in ("POST", "PUT", "DELETE") else {}
            try:
                for prefix, handler in (("/_", self.harness), ("/relay/", self.relay), ("/simkl/", self.simkl),
                                        ("/mdblist/", self.mdblist), ("/mal/", self.mal), ("/anilist", self.anilist)):
                    if path.startswith(prefix):
                        rest = path if prefix == "/_" else path[len(prefix.rstrip("/")):]
                        if handler(method, rest, query, body) is not False:
                            return
                        return self.reply(404, {"error": "not_found"})
                if self.trakt(method, path, query, body) is False:
                    self.reply(404, {"error": "not_found"})
            except (ValueError, KeyError, TypeError, AttributeError) as e:
                self.reply(400, {"error": "bad_request", "message": str(e)})

        # ---- shared ----

        def tokens(self, service, scope):
            with self.state.lock:
                n = self.state.next_token()
            access = ("simkl_at_" if service == "simkl" else "") + f"{TOKEN_PREFIX}{n}"
            return {"access_token": access, "refresh_token": f"fake-refresh-{n}", "token_type": "bearer",
                    "expires_in": 7776000, "scope": scope, "created_at": int(time.time())}

        def device_code(self, service, extra):
            code = secrets.token_hex(16)
            user_code = secrets.token_hex(4).upper()
            with self.state.lock:
                self.state.devices[code] = {"service": service, "polls": 0, "claimed": False}
            return {"device_code": code, "user_code": user_code, "expires_in": 600, "interval": 1, **extra(user_code)}

        def poll_device(self, service, code):
            """(status, error) of a device-code poll: None error once approved (then claimed)."""
            with self.state.lock:
                device = self.state.devices.get(code)
                if device is None or device["service"] != service:
                    self.state.polls.append({"service": service, "result": "expired"})
                    return "expired"
                if device["claimed"]:
                    return "expired"
                device["polls"] += 1
                if device["polls"] < self.state.approve_after:
                    self.state.polls.append({"service": service, "result": "pending", "poll": device["polls"]})
                    return "pending"
                device["claimed"] = True
                self.state.polls.append({"service": service, "result": "approved", "poll": device["polls"]})
                self.state.grants.append({"service": service, "op": "device_code", "at": time.time()})
                return None

        def revoke(self, service):
            with self.state.lock:
                self.state.revokes.append({"service": service, "at": time.time()})
            self.reply(200, {})

        def scrobble(self, service, action, body):
            ids, episode = scrobble_item(body)
            progress = float(body.get("progress") or 0)
            with self.state.lock:
                self.state.scrobbles.append({"service": service, "action": action, "ids": ids, "episode": episode,
                                             "progress": progress, "at": time.time()})
                if action == "stop" and progress >= 80:
                    self.state.watches.append({"service": service, "ids": ids, "episode": episode, "via": "scrobble"})
            self.reply(201, {"id": len(self.state.scrobbles), "action": "scrobble" if action == "stop" and progress >= 80
                             else action, "progress": progress, **{k: body[k] for k in body if k != "progress"}})

        def mark(self, service, op, body):
            with self.state.lock:
                failing = self.state.fail_writes
                status = self.state.fail_status if failing else 201
                items = items_of(body)
                for kind, ids, item in items:
                    self.state.marks.append({"service": service, "op": op, "kind": kind, "ids": ids, "status": status})
                    if not failing and op == "add":
                        self.state.watches.append({"service": service, "ids": ids, "via": "history",
                                                   "seasons": item.get("seasons")})
                    if not failing and op == "remove" and service == "simkl":
                        self.state.watchlists["simkl"] = [e for e in self.state.watchlists["simkl"]
                                                          if not ids_match(e["ids"], ids)]
            if failing:
                return self.reply(status, {"error": "failing"})
            key = "added" if op == "add" else "deleted"
            self.reply(201 if op == "add" else 200,
                       {key: {"movies": sum(k == "movies" for k, _, _ in items),
                              "episodes": sum(k != "movies" for k, _, _ in items)}, "not_found": {}})

        def rate(self, service, op, body):
            with self.state.lock:
                failing = service in self.state.fail_ratings
                status = self.state.fail_status if failing else (201 if op == "add" else 200)
                for kind, ids, item in items_of(body):
                    rating = item.get("rating") if op == "add" else None
                    self.state.rating_writes.append({"service": service, "op": op, "kind": kind, "ids": ids,
                                                     "rating": rating, "status": status})
                    if not failing:
                        kept = [e for e in self.state.ratings[service]
                                if not (e["kind"] == kind and ids_match(e["ids"], ids))]
                        self.state.ratings[service] = kept + ([{"kind": kind, "ids": ids, "rating": rating,
                                                                "rated_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z")}]
                                                              if rating is not None else [])
            if failing:
                return self.reply(status, {"error": "failing"})
            self.reply(status, {"added" if op == "add" else "deleted": {"movies": 0, "shows": 0}, "not_found": {}})

        def watchlist_write(self, service, op, body):
            with self.state.lock:
                failing = service in self.state.fail_watchlist
                status = self.state.fail_status if failing else (201 if op == "add" else 200)
                for kind, ids, _ in items_of(body):
                    self.state.watchlist_writes.append({"service": service, "op": op, "kind": kind, "ids": ids,
                                                        "status": status})
                    if failing:
                        continue
                    entries = [e for e in self.state.watchlists[service] if not ids_match(e["ids"], ids)]
                    if op == "add":
                        title = find_title(ids)
                        entries.append({"kind": kind, "ids": dict(title[3]) if title else ids})
                    self.state.watchlists[service] = entries
            if failing:
                return self.reply(status, {"error": "failing"})
            self.reply(status, {"added" if op == "add" else "deleted": {"movies": 0, "shows": 0}, "not_found": {}})

        def listed(self, entry):
            title = find_title(entry["ids"])
            name, year = (title[1], title[2]) if title else (None, None)
            return {"title": name, "year": year, "ids": entry["ids"]}

        # ---- Trakt ----

        def trakt(self, method, path, query, body):
            if method == "POST":
                if path == "/oauth/device/code":
                    return self.reply(200, self.device_code("trakt", lambda c: {
                        "verification_url": self.base() + "/activate"}))
                if path == "/oauth/device/token":
                    error = self.poll_device("trakt", body.get("code"))
                    if error is None:
                        return self.reply(200, self.tokens("trakt", "public"))
                    return self.reply(400 if error == "pending" else 410, {})
                if path == "/oauth/token":
                    if not str(body.get("refresh_token") or "").startswith("fake-refresh-"):
                        return self.reply(401, {"error": "invalid_grant"})
                    return self.reply(200, self.tokens("trakt", "public"))
                if path == "/oauth/revoke":
                    return self.revoke("trakt")
                m = re.fullmatch(r"/scrobble/(start|pause|stop)", path)
                if m:
                    return self.scrobble("trakt", m.group(1), body)
                m = re.fullmatch(r"/sync/(history|ratings|watchlist)(/remove)?", path)
                if m:
                    op = "remove" if m.group(2) else "add"
                    return {"history": self.mark, "ratings": self.rate,
                            "watchlist": self.watchlist_write}[m.group(1)]("trakt", op, body)
                return False
            if method != "GET":
                return False
            if path == "/users/settings":
                return self.reply(200, {"user": {"username": self.state.user, "ids": {"slug": self.state.user}},
                                        "account": {"timezone": "UTC"}})
            if path == "/activate" or path.startswith("/activate/"):
                return self.reply(200, b"<html><body>Code approved automatically.</body></html>", "text/html")
            m = re.fullmatch(r"/sync/ratings(?:/(movies|shows|seasons|episodes))?", path)
            if m:
                with self.state.lock:
                    rated = list(self.state.ratings["trakt"])
                out = []
                for e in rated:
                    if m.group(1) and e["kind"] != m.group(1):
                        continue
                    single = e["kind"].rstrip("s")
                    out.append({"rated_at": e["rated_at"], "rating": e["rating"], "type": single,
                                single: self.listed(e)})
                return self.reply(200, out)
            m = re.fullmatch(r"/sync/watchlist(?:/(movies|shows))?(?:/.*)?", path)
            if m:
                with self.state.lock:
                    entries = list(self.state.watchlists["trakt"])
                out = []
                for rank, e in enumerate(entries, 1):
                    if m.group(1) and e["kind"] != m.group(1):
                        continue
                    single = e["kind"].rstrip("s")
                    title = find_title(e["ids"])
                    out.append({"rank": rank, "id": rank, "listed_at": "2026-01-01T00:00:00.000Z", "type": single,
                                single: trakt_title(title, query) if title else self.listed(e)})
                return self.reply(200, out)
            m = re.fullmatch(r"/(movies|shows)/(trending|popular|anticipated|watched/\w+)", path)
            if m:
                kind = m.group(1).rstrip("s")
                titles = [trakt_title(t, query) for t in TITLES if t[0] == kind]
                if m.group(2) == "popular":
                    return self.reply(200, titles)
                return self.reply(200, [{"watchers": 100 - i, kind: t} for i, t in enumerate(titles)])
            m = re.fullmatch(r"/recommendations/(movies|shows)", path)
            if m:
                return self.reply(200, [trakt_title(t, query) for t in TITLES if t[0] == m.group(1).rstrip("s")])
            m = re.fullmatch(r"/search/(imdb|tmdb|tvdb|trakt)/([^/]+)", path)
            if m:
                title = find_title({m.group(1): m.group(2)})
                wanted = (query.get("type") or [""])[0].split(",")
                if not title or (wanted != [""] and title[0] not in wanted):
                    return self.reply(200, [])
                return self.reply(200, [{"type": title[0], "score": 1000, title[0]: trakt_title(title, query)}])
            m = re.fullmatch(r"/search/([a-z,]+)", path)
            if m:
                text = (query.get("query") or [""])[0].lower()
                kinds = m.group(1).split(",")
                return self.reply(200, [{"type": t[0], "score": 100, t[0]: trakt_title(t, query)} for t in TITLES
                                        if t[0] in kinds and text in t[1].lower()])
            m = re.fullmatch(r"/(movies|shows)/([^/]+)/(ratings|people|related)", path)
            if m:
                title = find_title({k: m.group(2) for k in ("imdb", "trakt", "tmdb")}) or None
                if title is None:
                    return self.reply(200, []) if m.group(3) == "related" else self.reply(404, {})
                if m.group(3) == "ratings":
                    return self.reply(200, {"rating": title[5]["trakt"] / 10, "votes": 1234,
                                            "distribution": {str(i): 10 * i for i in range(1, 11)}})
                if m.group(3) == "people":
                    return self.reply(200, {
                        "cast": [{"characters": ["Lead"], "character": "Lead", "person": {
                            "name": "Test Actor", "ids": {"trakt": 1, "slug": "test-actor", "tmdb": 1}}}],
                        "crew": {"directing": [{"jobs": ["Director"], "job": "Director", "person": {
                            "name": "Test Director", "ids": {"trakt": 2, "slug": "test-director", "tmdb": 2}}}]}})
                return self.reply(200, [trakt_title(t, query) for t in TITLES if t[0] == title[0] and t is not title])
            if path in ("/users/me/lists", "/users/me/watchlist") or path.startswith("/users/"):
                return self.reply(200, [])
            return False

        # ---- Simkl ----

        def simkl(self, method, path, query, body):
            if method == "POST":
                if path == "/oauth2/device":
                    return self.reply(200, self.device_code("simkl", lambda c: {
                        "verification_uri": self.base() + "/simkl/activate",
                        "verification_uri_complete": self.base() + "/simkl/activate?user_code=" + c}))
                if path == "/oauth2/token":
                    if body.get("grant_type") == "refresh_token":
                        tokens = self.tokens("simkl", "media:read media:write")
                        tokens.pop("refresh_token")
                        return self.reply(200, tokens)
                    error = self.poll_device("simkl", body.get("device_code"))
                    if error is None:
                        return self.reply(200, self.tokens("simkl", "media:read media:write"))
                    return self.reply(400, {"error": "authorization_pending" if error == "pending" else "expired_token"})
                if path == "/oauth2/revoke":
                    return self.revoke("simkl")
                m = re.fullmatch(r"/scrobble/(start|pause|stop)", path)
                if m:
                    return self.scrobble("simkl", m.group(1), body)
                m = re.fullmatch(r"/sync/(history|ratings)(/remove)?", path)
                if m:
                    op = "remove" if m.group(2) else "add"
                    return (self.mark if m.group(1) == "history" else self.rate)("simkl", op, body)
                if path == "/sync/add-to-list":
                    if any(item.get("to") == "plantowatch" for _, _, item in items_of(body)):
                        return self.watchlist_write("simkl", "add", body)
                    return self.reply(201, {"added": {}, "not_found": {}})
                return False
            if method != "GET":
                return False
            if path == "/users/settings":
                return self.reply(200, {"user": {"name": self.state.user}, "account": {"id": 990000, "timezone": "UTC"}})
            if path == "/activate":
                return self.reply(200, b"<html><body>Code approved automatically.</body></html>", "text/html")
            m = re.fullmatch(r"/sync/ratings(?:/(movies|shows|anime))?(?:/.*)?", path)
            if m:
                with self.state.lock:
                    rated = list(self.state.ratings["simkl"])
                out = {}
                for e in rated:
                    key = "movies" if e["kind"] == "movies" else "shows"
                    if m.group(1) and key != m.group(1):
                        continue
                    single = "movie" if key == "movies" else "show"
                    out.setdefault(key, []).append({"user_rating": e["rating"], "user_rated_at": e["rated_at"],
                                                    single: self.listed(e)})
                return self.reply(200, out)
            m = re.fullmatch(r"/sync/all-items/(all|movies|shows|anime)/plantowatch", path)
            if m:
                with self.state.lock:
                    entries = list(self.state.watchlists["simkl"])
                out = {}
                for e in entries:
                    title = find_title(e["ids"])
                    key = "movies" if e["kind"] == "movies" else ("anime" if title and "mal" in title[3] else "shows")
                    if m.group(1) not in ("all", key):
                        continue
                    single = "movie" if key == "movies" else "show"
                    out.setdefault(key, []).append({"status": "plantowatch", "added_to_watchlist_at":
                                                    "2026-01-01T00:00:00Z", single: self.listed(e)})
                return self.reply(200, out)
            if path == "/redirect":
                title = find_title({k: v[0] for k, v in query.items()})
                if not title:
                    return self.reply(404, {"error": "not_found"})
                kind = "movies" if title[0] == "movie" else ("anime" if "mal" in title[3] else "tv")
                return self.reply(301, b"", "text/plain",
                                  {"Location": f"{self.base()}/simkl/{kind}/{title[3]['simkl']}"})
            m = re.fullmatch(r"/(movies|tv|anime)/(\d+)", path)
            if m:
                title = find_title({"simkl": m.group(2)})
                if not title:
                    return self.reply(404, {"error": "not_found"})
                ratings = {"simkl": {"rating": title[5]["simkl"], "votes": 321},
                           "imdb": {"rating": title[5]["imdb"], "votes": 45678}}
                if "myanimelist" in title[5]:
                    ratings["mal"] = {"rating": title[5]["myanimelist"], "votes": 9876}
                return self.reply(200, {"title": title[1], "year": title[2], "ids": {"simkl": title[3]["simkl"],
                                        "imdb": title[3]["imdb"]}, "ratings": ratings})
            m = re.fullmatch(r"/discover/trending/(movies|tv|anime)/[^/]+\.json", path)
            if m:
                out = []
                for t in TITLES:
                    kind = "movies" if t[0] == "movie" else ("anime" if "mal" in t[3] else "tv")
                    if kind != m.group(1):
                        continue
                    out.append({"title": t[1], "url": f"/{kind}/{t[3]['simkl']}", "poster": "", "fanart": "",
                                "release_date": f"{t[2]}-01-01", "ids": {"simkl_id": t[3]["simkl"],
                                "slug": t[1].lower().replace(" ", "-"), "imdb": t[3]["imdb"], "tmdb": t[3]["tmdb"]},
                                "ratings": {"simkl": {"rating": t[5]["simkl"], "votes": 321},
                                            "imdb": {"rating": t[5]["imdb"], "votes": 45678}}})
                return self.reply(200, out)
            return False

        # ---- MDBList ----

        def mdblist(self, method, path, query, body):
            if method == "POST":
                if path == "/oauth/device-authorization/":
                    return self.reply(200, self.device_code("mdblist", lambda c: {
                        "verification_uri": self.base() + "/mdblist/oauth/device/",
                        "verification_uri_complete": self.base() + "/mdblist/oauth/device/?user_code=" + c}))
                if path == "/oauth/token/":
                    if body.get("grant_type") == "refresh_token":
                        return self.reply(200, self.tokens("mdblist", "write"))
                    error = self.poll_device("mdblist", body.get("device_code"))
                    if error is None:
                        return self.reply(200, self.tokens("mdblist", "write"))
                    return self.reply(400, {"error": "authorization_pending" if error == "pending" else "expired_token"})
                if path == "/oauth/revoke_token/":
                    return self.revoke("mdblist")
                m = re.fullmatch(r"/scrobble/(start|pause|stop)", path)
                if m:
                    return self.scrobble("mdblist", m.group(1), body)
                m = re.fullmatch(r"/sync/(watched|ratings)(/remove)?", path)
                if m:
                    op = "remove" if m.group(2) else "add"
                    return (self.mark if m.group(1) == "watched" else self.rate)("mdblist", op, body)
                m = re.fullmatch(r"/watchlist/items/(add|remove)", path)
                if m:
                    return self.watchlist_write("mdblist", m.group(1), body)
                return False
            if method != "GET":
                return False
            if path == "/user":
                return self.reply(200, {"user_id": 990000, "username": self.state.user, "patron_status": "none"})
            if path == "/oauth/device/":
                return self.reply(200, b"<html><body>Code approved automatically.</body></html>", "text/html")
            if path == "/sync/ratings":
                with self.state.lock:
                    rated = list(self.state.ratings["mdblist"])
                out = {"movies": [], "shows": []}
                for e in rated:
                    key = "movies" if e["kind"] == "movies" else "shows"
                    single = "movie" if key == "movies" else "show"
                    out[key].append({"rating": e["rating"], "rated_at": e["rated_at"], single: self.listed(e)})
                return self.reply(200, out)
            if path in ("/watchlist/items", "/watchlist/items/"):
                with self.state.lock:
                    entries = list(self.state.watchlists["mdblist"])
                out = {"movies": [], "shows": []}
                for e in entries:
                    item = self.listed(e)
                    out["movies" if e["kind"] == "movies" else "shows"].append({
                        "title": item["title"], "release_year": item["year"], "mediatype":
                        "movie" if e["kind"] == "movies" else "show", "ids": item["ids"],
                        "imdb_id": item["ids"].get("imdb"), "tmdb_id": item["ids"].get("tmdb")})
                return self.reply(200, out)
            m = re.fullmatch(r"/(imdb|tmdb|tvdb|mal)/(movie|show|any)/([^/]+)/?", path)
            if m:
                title = find_title({m.group(1): m.group(3)})
                if not title or m.group(2) not in ("any", title[0]):
                    return self.reply(404, {"error": "not_found"})
                s = title[5]
                sources = [("imdb", s["imdb"], s["imdb"] * 10), ("tmdb", s["tmdb"], s["tmdb"]),
                           ("tomatoes", s["tomatoes"], s["tomatoes"]), ("popcorn", s["popcorn"], s["popcorn"]),
                           ("metacritic", s["metacritic"], s["metacritic"]),
                           ("letterboxd", s["letterboxd"], int(s["letterboxd"] * 20)), ("trakt", s["trakt"], s["trakt"])]
                if "myanimelist" in s:
                    sources.append(("myanimelist", s["myanimelist"], int(s["myanimelist"] * 10)))
                return self.reply(200, {"title": title[1], "year": title[2], "type": title[0],
                                        "ids": {k: v for k, v in title[3].items() if k != "simkl"},
                                        "score": int(sum(x[2] for x in sources) / len(sources)),
                                        "ratings": [{"source": n, "value": v, "score": sc, "votes": 1000, "url": None}
                                                    for n, v, sc in sources]})
            return False

        # ---- MyAnimeList ----

        def mal(self, method, path, query, body):
            if method == "POST" and path == "/v1/oauth2/token":
                if not str(body.get("refresh_token") or "").startswith("fake-refresh-"):
                    return self.reply(400, {"error": "invalid_grant"})
                return self.reply(200, self.tokens("mal", ""))
            if method == "GET" and path == "/v2/users/@me":
                return self.reply(200, {"id": 990000, "name": self.state.user})
            m = re.fullmatch(r"/v2/anime/(\d+)(/my_list_status)?", path)
            if not m:
                return False
            mal_id = int(m.group(1))
            if m.group(2) is None and method == "GET":
                title = ANIME.get(mal_id)
                if not title:
                    return self.reply(404, {"error": "not_found"})
                out = {"id": mal_id, "title": title[1], "num_episodes": sum(title[4].values()),
                       "mean": title[5]["myanimelist"], "num_scoring_users": 9876}
                with self.state.lock:
                    if mal_id in self.state.mal:
                        out["my_list_status"] = self.state.mal[mal_id]
                return self.reply(200, out)
            if m.group(2) and method == "PUT":
                with self.state.lock:
                    entry = self.state.mal.setdefault(mal_id, {"status": "plan_to_watch", "score": 0,
                                                               "num_episodes_watched": 0, "is_rewatching": False})
                    if "status" in body:
                        entry["status"] = body["status"]
                    if "score" in body:
                        entry["score"] = int(body["score"])
                    if "num_watched_episodes" in body:
                        entry["num_episodes_watched"] = int(body["num_watched_episodes"])
                    entry["updated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S+00:00")
                    self.state.watchlist_writes.append({"service": "mal", "op": "put", "id": mal_id, "body": body,
                                                        "status": 200})
                    out = dict(entry)
                return self.reply(200, out)
            if m.group(2) and method == "DELETE":
                with self.state.lock:
                    existed = self.state.mal.pop(mal_id, None) is not None
                    self.state.watchlist_writes.append({"service": "mal", "op": "delete", "id": mal_id,
                                                        "status": 200 if existed else 404})
                return self.reply(200, {}) if existed else self.reply(404, {"error": "not_found"})
            return False

        # ---- AniList ----

        def anilist(self, method, path, query, body):
            if method != "POST" or path not in ("", "/"):
                return False
            text = body.get("query") or ""
            variables = body.get("variables") or {}
            if "SaveMediaListEntry" in text:
                media_id = int(variables.get("mediaId") or variables.get("id"))
                with self.state.lock:
                    entry = self.state.anilist.setdefault(media_id, {"id": media_id + 900000, "mediaId": media_id,
                                                                     "status": "PLANNING", "progress": 0, "score": 0})
                    for key in ("status", "progress", "score"):
                        if key in variables:
                            entry[key] = variables[key]
                    if "scoreRaw" in variables:
                        entry["score"] = variables["scoreRaw"] / 10
                    self.state.watchlist_writes.append({"service": "anilist", "op": "save", "id": media_id,
                                                        "variables": variables, "status": 200})
                    out = dict(entry)
                return self.reply(200, {"data": {"SaveMediaListEntry": out}})
            if "DeleteMediaListEntry" in text:
                entry_id = int(variables.get("id"))
                with self.state.lock:
                    media = next((k for k, e in self.state.anilist.items() if e["id"] == entry_id or k == entry_id), None)
                    if media is not None:
                        del self.state.anilist[media]
                    self.state.watchlist_writes.append({"service": "anilist", "op": "delete", "id": entry_id,
                                                        "status": 200})
                return self.reply(200, {"data": {"DeleteMediaListEntry": {"deleted": media is not None}}})
            if "Media" in text and ("id" in variables or "idMal" in variables or "Media(" in text):
                wanted = variables.get("id") or variables.get("idMal") or variables.get("mediaId")
                if wanted is None:
                    found = re.search(r"Media\s*\(\s*(?:id|idMal)\s*:\s*(\d+)", text)
                    wanted = found and found.group(1)
                title = next((t for t in ANIME.values() if str(wanted) in (str(t[3]["anilist"]), str(t[3]["mal"]))),
                             None)
                if title is None:
                    return self.reply(200, {"data": {"Media": None},
                                            "errors": [{"message": "Not Found.", "status": 404}]})
                anilist_id = title[3]["anilist"]
                with self.state.lock:
                    entry = dict(self.state.anilist[anilist_id]) if anilist_id in self.state.anilist else None
                # The app reads the score as `scoreRaw: score(format: POINT_100)`.
                if entry is not None and "scoreRaw" in text:
                    entry["scoreRaw"] = round(entry["score"] * 10)
                return self.reply(200, {"data": {"Media": {
                    "id": anilist_id, "idMal": title[3]["mal"], "title": {"romaji": title[1], "english": title[1]},
                    "averageScore": title[5]["anilist"], "meanScore": title[5]["anilist"],
                    "episodes": sum(title[4].values()), "mediaListEntry": entry}}})
            if "Viewer" in text:
                return self.reply(200, {"data": {"Viewer": {"id": 990000, "name": self.state.user,
                                                            "mediaListOptions": {"scoreFormat": "POINT_10"}}}})
            return self.reply(200, {"data": {}})

        # ---- Plezy's OAuth relay ----

        def relay(self, method, path, query, body):
            if method == "POST" and path == "/auth/start":
                service = body.get("service")
                if service not in ("mal", "anilist"):
                    return self.reply(400, {"error": "unknown service"})
                session, browser_state = secrets.token_urlsafe(18), secrets.token_urlsafe(18)
                with self.state.lock:
                    self.state.relay[session] = {"service": service, "state": browser_state, "approved": False,
                                                 "polls": 0, "claimed": False}
                return self.reply(200, {"session": session, "expiresIn": 600,
                                        "url": f"{self.base()}/relay/auth/{service}?state={browser_state}"},
                                  headers={"Cache-Control": "no-store, private"})
            if method == "GET" and path == "/auth/result":
                session = (query.get("session") or [""])[0]
                with self.state.lock:
                    entry = self.state.relay.get(session)
                    if entry is None or entry["claimed"]:
                        return self.reply(410, {"error": "Session expired or already used"})
                    entry["polls"] += 1
                    if not entry["approved"] and entry["polls"] < self.state.approve_after:
                        self.state.polls.append({"service": entry["service"], "result": "pending", "relay": True})
                        return self.reply(204)
                    entry["claimed"] = True
                    n = self.state.next_token()
                    self.state.grants.append({"service": entry["service"], "op": "relay", "at": time.time()})
                result = {"accessToken": f"{TOKEN_PREFIX}{n}", "expiresIn": 2592000}
                if entry["service"] == "mal":
                    result["refreshToken"] = f"fake-refresh-{n}"
                return self.reply(200, result, headers={"Cache-Control": "no-store, private"})
            m = re.fullmatch(r"/auth/(mal|anilist)", path)
            if method == "GET" and m:
                wanted = (query.get("state") or [""])[0]
                with self.state.lock:
                    entry = next((e for e in self.state.relay.values()
                                  if e["state"] == wanted and e["service"] == m.group(1)), None)
                    if entry:
                        entry["approved"] = True
                if not entry:
                    return self.reply(404, b"<html><body>This sign-in link is no longer valid.</body></html>",
                                      "text/html")
                return self.reply(200, b"<html><body>Signed in. Return to Plezy.</body></html>", "text/html")
            return False

        # ---- harness ----

        def harness(self, method, path, query, body):
            def param(name):
                return (query.get(name) or [None])[0]
            if path == "/_config":
                if method == "POST":
                    if not (param("approveAfter") or "").isdigit():
                        return self.reply(400, {"error": "approveAfter=<n> needed"})
                    with self.state.lock:
                        self.state.approve_after = int(param("approveAfter"))
                    return self.reply(204)
                return self.reply(200, {"user": self.state.user, "prefixes": sorted(set(PREFIXES.values())),
                                        "tokenPrefix": TOKEN_PREFIX, "approveAfter": self.state.approve_after})
            if path == "/_log":
                with self.state.lock:
                    return self.reply(200, self.state.log())
            if path == "/_reset" and method == "POST":
                with self.state.lock:
                    self.state.reset()
                return self.reply(204)
            if path == "/_fail" and method == "POST":
                with self.state.lock:
                    if param("status"):
                        self.state.fail_status = int(param("status"))
                    if param("writes") is not None:
                        self.state.fail_writes = param("writes") == "1"
                    if "ratings" in query:
                        self.state.fail_ratings = {s for s in (param("ratings") or "").split(",") if s}
                    if "watchlist" in query:
                        self.state.fail_watchlist = {s for s in (param("watchlist") or "").split(",") if s}
                return self.reply(204)
            if path == "/_rating" and method == "POST":
                service, imdb = param("service"), param("imdb")
                if service not in RATING_SERVICES or not imdb:
                    return self.reply(400, {"error": "service and imdb needed"})
                title = find_title({"imdb": imdb})
                kind = param("kind") or ("movies" if title and title[0] == "movie" else "shows")
                rating = int(param("rating")) if param("rating") else None
                ids = dict(title[3]) if title else {"imdb": imdb}
                with self.state.lock:
                    kept = [e for e in self.state.ratings[service]
                            if not (e["kind"] == kind and ids_match(e["ids"], ids))]
                    self.state.ratings[service] = kept + ([{"kind": kind, "ids": ids, "rating": rating,
                                                            "rated_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z")}]
                                                          if rating is not None else [])
                return self.reply(204)
            return False

    server = http.server.ThreadingHTTPServer((a.host, a.port), Handler)
    print(f"fake trackers on http://{a.host}:{a.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
