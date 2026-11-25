#!/usr/bin/env python3
"""Serves tools/media/out/ (or --root) over HTTP with Range support, so mpv can seek (Python's http.server can't).

Usage: tools/media/serve.py [port] [--root <dir>] [--expire 60] [--expire-bytes 0] [--slow-rate 256]
  port            default 8765
  --root          the directory served, default the out/ beside this script (gitignored, built by make-sample.sh and
                  make-matrix.sh); a checkout without one passes another checkout's tools/media/out
  --expire        seconds a /t/ link minted by /resolve/ serves before it answers 403
  --expire-bytes  bytes a /t/ link serves in all before it drops its transfer and answers 403 (0: no limit)
  --slow-rate     KiB/s of the /slow/ prefix
The Android emulator reaches it at 10.0.2.2, the iOS/tvOS simulators at 127.0.0.1, other machines at this Mac's
LAN address.

Every file answer (200, 206, 416) but /norange/'s carries Accept-Ranges, an ETag (the file's size and modification
time, so it holds until the file changes), Last-Modified and Content-Disposition (inline, the file's name). A Range
request answers 206, or 416 past the end; with If-Range (an ETag or an HTTP date) it answers 206 when the validator
matches and 200 with the whole file when it doesn't. A request's log line ends with the Range and If-Range it sent, if
any (the download proofs' resumes). Routes besides the plain files (<path> is a file's path, matrix/remux.mkv):
  /<path>?rate=<KiB/s>     any route below takes ?rate=: the body goes out at about that rate (pause/resume proofs)
  /<path>?hold=<name>      the body (a plain file's, /slow/'s, /norange/'s, /redirect/'s, which carries the query along,
                           or the links /resolve/ mints, which keep it) goes out only as far as the hold <name> lets it:
                           each byte spends the hold's allowance, none until /hold/ grants some; with none left, a byte
                           a second, so the connection stays open (a client's idle timeout doesn't end it) while nothing
                           more comes. A download stays partway for as long as a test needs it there, however long its
                           steps take
  /hold/<name>?bytes=<n>   adds n bytes to the hold's allowance; ?bytes=all lifts it: its transfers go on at their rate;
                           ?bytes=none holds them again from their next byte, nothing granted (also after all)
  /slow/<path>             the file at --slow-rate
  /norange/<path>          the file as a server without Range support serves it: 200 with the whole file to every
                           request, its Range ignored, and no Accept-Ranges (so mpv reads it unseekable)
  /redirect/<n>/<path>     302 to /redirect/<n-1>/<path>, the last hop to /<path>: a chain of n hops, each Location
                           relative (../../2/matrix/remux.mkv); ?absolute=1 makes them absolute URLs. The query
                           goes along, and <path> may be another route (/redirect/2/resolve/matrix/remux.mkv)
  /resolve/<path>          a stream host's lazy link: 302 to a fresh /t/<token>/<path> (an absolute URL, as a
                           CDN's). ?expire=<s>, ?bytes=<n>, ?rate=<KiB/s> and ?hold=<name> set that link's lifetime
                           (default --expire), byte budget (default --expire-bytes), rate and hold
  /t/<token>/<path>        the CDN link: the file while the token is fresh, 403 once its lifetime is over (a transfer
                           already going goes on). Past its byte budget the transfer in progress stops short (the
                           connection closes) and every later request answers 403: a link that expires mid-transfer
/resolve/ logs each link it mints (its token, lifetime and byte budget), so a link's renewal reads in the log.
Live HLS made from a VOD one in a single MPEG-TS file (tools/media/make-live.sh: matrix/h264-sdr.m3u8 and .ts, cut at
its 2-s keyframes), looping forever, its segments' place following the wall clock from LIVE_EPOCH, so every server
lists the same ones at the same time, and its time running on across loops (each pass's PCR, PTS, DTS and continuity
counters moved on by the passes before it), as a live channel's does:
  /<path>.live.m3u8        the live media playlist of the VOD one at <path>.m3u8 (matrix/h264-sdr.live.m3u8): the
                           segments that started in the last ?window=<s> seconds (default LIVE_WINDOW) up to the newest
                           complete one, no #EXT-X-ENDLIST; ?ends=<s> ends it that many seconds after the first request
                           of that URL (its query included), from then on listing the same segments with
                           #EXT-X-ENDLIST: an event that ends. ?event=1 makes it an EVENT playlist
                           (#EXT-X-PLAYLIST-TYPE:EVENT) that keeps every segment from the first request of that URL on,
                           its window growing from ?window= then. ?referer=<value>&agent=<value> make it and its segments
                           answer 403 to a request without that Referer and User-Agent. ?late=<s> answers every third
                           segment that many seconds late, as a live origin that falls behind does. The query goes along
                           to the segments' URLs
  /<path>.live/<n>.ts      its segment n: the VOD playlist's segment n modulo their count, of the pass n div their count
"""
import argparse
import bisect
import email.utils
import http.server
import io
import math
import os
import posixpath
import re
import secrets
import threading
import time
import urllib.parse

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
# The live playlists' clock: 2026-01-01T00:00:00Z, when the first pass of each loop started.
LIVE_EPOCH = 1767225600
# Seconds of segments a live playlist lists without ?window=.
LIVE_WINDOW = 12
# MPEG-TS time: 90 kHz, wrapping at 33 bits.
TS_HZ, TS_WRAP = 90000, 1 << 33
# Seconds a held transfer with no allowance waits for one before it sends a byte all the same (?hold=).
HOLD_KEEPALIVE = 1.0


def pes_time(field):
    """A PES header's 5-byte PTS or DTS."""
    return (field[0] >> 1 & 7) << 30 | field[1] << 22 | (field[2] >> 1) << 15 | field[3] << 7 | field[4] >> 1


def pes_field(value, prefix):
    """[value] as a PES header's 5-byte PTS or DTS, its 4 leading bits [prefix]'s."""
    return bytes([prefix & 0xF0 | (value >> 30 & 7) << 1 | 1, value >> 22 & 0xFF, (value >> 15 & 0x7F) << 1 | 1,
                  value >> 7 & 0xFF, (value & 0x7F) << 1 | 1])


def ts_packets(data):
    """[data]'s MPEG-TS packets: (start, PID, whether it carries a payload, its payload's start, whether a PES header
    with time fields starts there, the PCR's start or None)."""
    for pos in range(0, len(data) - 187, 188):
        pid = (data[pos + 1] & 0x1F) << 8 | data[pos + 2]
        control = data[pos + 3] >> 4 & 3
        payload = pos + 4
        pcr = None
        if control & 2:
            if data[payload] and data[payload + 1] & 0x10:
                pcr = payload + 2
            payload += 1 + data[payload]
        stream_id = data[payload + 3] if payload + 3 < pos + 188 else 0
        pes = (control & 1 and data[pos + 1] & 0x40 and data[payload:payload + 3] == b"\x00\x00\x01"
               and (0xC0 <= stream_id <= 0xEF or stream_id == 0xBD))
        yield pos, pid, bool(control & 1), payload, bool(pes), pcr


class LiveSource:
    """A VOD HLS playlist of byte ranges in one MPEG-TS file as the segments of a live one (the module's docstring):
    their [ranges], [starts] and [lengths] (90 kHz), the [loop]'s length (from the first PTS to the end of the last
    frame of any stream) and each PID's [packets] with a payload in one pass."""

    def __init__(self, path):
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
        self.ranges, self.lengths = [], []
        media, length, offset = None, 0, 0
        for line in lines:
            if line.startswith("#EXTINF:"):
                length = round(float(line[8:].split(",")[0]) * TS_HZ)
            elif line.startswith("#EXT-X-BYTERANGE:"):
                size, _, start = line[17:].partition("@")
                offset = int(start) if start else offset
                self.ranges.append((offset, int(size)))
                offset += int(size)
            elif line and not line.startswith("#"):
                media = os.path.join(os.path.dirname(path), line)
                self.lengths.append(length)
        if not self.ranges or len(self.ranges) != len(self.lengths):
            raise ValueError(f"{path}: not a VOD playlist of byte ranges in one file (tools/media/make-live.sh)")
        with open(media, "rb") as f:
            self.data = f.read()
        self.starts = [sum(self.lengths[:i]) for i in range(len(self.lengths))]
        self.ends = [start + length for start, length in zip(self.starts, self.lengths)]
        self.packets = {}
        times = {}
        for _, pid, payload, at, pes, _ in ts_packets(self.data):
            self.packets[pid] = self.packets.get(pid, 0) + payload
            if pes:
                times.setdefault(pid, set()).add(pes_time(self.data[at + 9:at + 14]))
        first = min(min(t) for t in times.values())
        # A stream's last frame lasts as long as its shortest step between frames.
        self.loop = max(max(t) + min(b - a for a, b in zip(sorted(t), sorted(t)[1:])) for t in times.values()) - first

    def start(self, n):
        passes, i = divmod(n, len(self.starts))
        return passes * self.loop + self.starts[i]

    def newest(self, now):
        """The newest segment complete at [now] (90 kHz since LIVE_EPOCH)."""
        passes, within = divmod(now, self.loop)
        return passes * len(self.starts) + bisect.bisect_right(self.ends, within) - 1

    def segment(self, n):
        """Segment n: its bytes with their PCR, PTS, DTS and continuity counters moved on by the passes before."""
        passes, i = divmod(n, len(self.starts))
        offset, size = self.ranges[i]
        out = bytearray(self.data[offset:offset + size])
        shift = passes * self.loop
        for pos, pid, _, at, pes, pcr in ts_packets(out):
            out[pos + 3] = out[pos + 3] & 0xF0 | (out[pos + 3] + passes * self.packets[pid]) & 0x0F
            if pcr is not None:
                value = int.from_bytes(out[pcr:pcr + 6], "big")
                out[pcr:pcr + 6] = (((value >> 15) + shift) % TS_WRAP << 15 | value & 0x7FFF).to_bytes(6, "big")
            if pes:
                # PTS_DTS_flags: 2 a PTS, 3 a PTS and a DTS.
                for field in (at + 9, at + 14)[:{2: 1, 3: 2}.get(out[at + 7] >> 6, 0)]:
                    out[field:field + 5] = pes_field((pes_time(out[field:field + 5]) + shift) % TS_WRAP, out[field])
        return bytes(out)

    def playlist(self, now, window, ended, prefix, query, event=False):
        """The media playlist at [now] (90 kHz): the segments that started in the last [window], up to the newest
        complete one, each URI [prefix]<n>.ts[query]; [ended] closes it with #EXT-X-ENDLIST, [event] marks it an EVENT
        playlist."""
        newest = self.newest(now)
        first = newest
        while first > 0 and self.start(first - 1) >= now - window:
            first -= 1
        lines = ["#EXTM3U", "#EXT-X-VERSION:3", f"#EXT-X-TARGETDURATION:{math.ceil(max(self.lengths) / TS_HZ)}",
                 f"#EXT-X-MEDIA-SEQUENCE:{first}"] + (["#EXT-X-PLAYLIST-TYPE:EVENT"] if event else [])
        for n in range(first, newest + 1):
            lines += [f"#EXTINF:{self.lengths[n % len(self.lengths)] / TS_HZ:.3f},", f"{prefix}{n}.ts{query}"]
        if ended:
            lines.append("#EXT-X-ENDLIST")
        return "\n".join(lines) + "\n"


class Link:
    """A /t/ link: [path] served until [expires] (time.monotonic()), [budget] bytes in all (None: no limit), at [rate]
    (None: unthrottled) and as far as its [hold] lets it (None: unheld)."""

    def __init__(self, path, lifetime, budget, rate, hold):
        self.path = path
        self.expires = time.monotonic() + lifetime
        self.budget = budget
        self.rate = rate
        self.hold = hold
        self.served = 0
        self.dead = False
        self.lock = threading.Lock()

    def usable(self):
        with self.lock:
            return not self.dead and time.monotonic() < self.expires

    def take(self, wanted):
        """How many of [wanted] bytes the link may still send; the budget spent, the link is dead."""
        with self.lock:
            if self.budget is None:
                return wanted
            allowed = max(0, min(wanted, self.budget - self.served))
            self.served += allowed
            if self.served >= self.budget:
                self.dead = True
            return allowed


class Hold:
    """A ?hold= name: the bytes its transfers may still send ([allowance]; None once lifted)."""

    def __init__(self):
        self.allowance = 0
        self.changed = threading.Condition()

    def grant(self, amount):
        """[amount] bytes more for its transfers, or None: the hold lifted (until [reset])."""
        with self.changed:
            self.allowance = None if amount is None or self.allowance is None else self.allowance + amount
            self.changed.notify_all()

    def reset(self):
        """Its transfers held again from their next byte, nothing granted, also after a lift."""
        with self.changed:
            self.allowance = 0

    def take(self, wanted):
        """How many of [wanted] bytes may go now, spent from the allowance, and whether it waited for one: with none
        left it waits up to HOLD_KEEPALIVE s for a grant, then lets one byte go unspent (the connection kept alive)."""
        with self.changed:
            waited = self.allowance == 0
            if waited:
                self.changed.wait(HOLD_KEEPALIVE)
            if self.allowance is None:
                return wanted, waited
            if self.allowance == 0:
                return 1, waited
            taken = min(wanted, self.allowance)
            self.allowance -= taken
            return taken, waited


class RangeHandler(http.server.SimpleHTTPRequestHandler):
    # Set in __main__ from the command line.
    root = OUT
    expire = 60.0
    expire_bytes = None
    slow_rate = 256 * 1024
    links = {}
    links_lock = threading.Lock()
    holds = {}
    holds_lock = threading.Lock()
    # The live sources read so far by path, and each ?ends= playlist URL's first request (time.time()).
    live_sources = {}
    live_firsts = {}
    live_lock = threading.Lock()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=self.root, **kwargs)

    def send_head(self):
        self.remaining = None
        self.rate = None
        self.link = None
        split = urllib.parse.urlsplit(self.path)
        # Clients that send a relative redirect's target unnormalized (Apple's URLSession: /redirect/3/matrix/../../2/…)
        # get the dot segments removed, as RFC 3986 §5.2.4 resolves them; a trailing slash (a directory) stays.
        if "/." in split.path:
            normalized = posixpath.normpath(split.path)
            if split.path.endswith("/") and normalized != "/":
                normalized += "/"
            split = split._replace(path=normalized)
            self.path = urllib.parse.urlunsplit(split)
        query = urllib.parse.parse_qs(split.query)
        rate = query_number(query, "rate")
        if rate is not None:
            self.rate = rate * 1024
        hold = query.get("hold")
        self.hold = self.named_hold(hold[0]) if hold else None
        route = re.fullmatch(r"/hold/([^/]+)", split.path)
        if route:
            return self.grant(route.group(1), query)
        route = re.fullmatch(r"/redirect/(\d+)(/.*)", split.path)
        if route:
            return self.redirect(split, int(route.group(1)), route.group(2), query)
        route = re.fullmatch(r"/resolve(/.+)", split.path)
        if route:
            return self.resolve(route.group(1), query)
        route = re.fullmatch(r"/t/([^/]+)(/.+)", split.path)
        if route:
            with self.links_lock:
                link = self.links.get(route.group(1))
            if link is None or link.path != route.group(2) or not link.usable():
                self.send_error(403, "Link expired")
                return None
            self.link = link
            if self.rate is None:
                self.rate = link.rate
            if self.hold is None:
                self.hold = link.hold
            return self.serve_file(route.group(2))
        route = re.fullmatch(r"/slow(/.+)", split.path)
        if route:
            if self.rate is None:
                self.rate = self.slow_rate
            return self.serve_file(route.group(1))
        route = re.fullmatch(r"/norange(/.+)", split.path)
        if route:
            return self.serve_file(route.group(1), ranges=False)
        route = re.fullmatch(r"/(.+)\.live(\.m3u8|/\d+\.ts)", split.path)
        if route:
            return self.live(split, route.group(1), route.group(2), query)
        path = self.translate_path(self.path)
        if os.path.isdir(path) or not os.path.isfile(path):
            return super().send_head()
        return self.serve_file(split.path)

    def live(self, split, path, part, query):
        """A live route (the module's docstring) of the VOD playlist at [path].m3u8: the playlist or a segment."""
        file = self.translate_path(f"/{path}.m3u8")
        if not os.path.isfile(file):
            self.send_error(404, "File not found")
            return None
        wanted = {"Referer": query.get("referer", [None])[0], "User-Agent": query.get("agent", [None])[0]}
        wrong = [name for name, value in wanted.items() if value is not None and self.headers.get(name) != value]
        if wrong:
            self.send_error(403, f"Wrong or missing {' and '.join(wrong)}")
            return None
        with self.live_lock:
            source = self.live_sources.get(file)
            if source is None:
                source = self.live_sources[file] = LiveSource(file)
        if part != ".m3u8":
            n = int(part[1:-3])
            late = query_number(query, "late")
            if late and n % 3 == 0:
                time.sleep(late)
            return self.send_body("video/mp2t", source.segment(n))
        now = time.time()
        ends = query_number(query, "ends")
        ended = False
        if ends is not None:
            with self.live_lock:
                first = self.live_firsts.setdefault(self.path, now)
            ended = now >= first + ends
            now = min(now, first + ends)
        window = LIVE_WINDOW if query_number(query, "window") is None else query_number(query, "window")
        event = query_number(query, "event") == 1
        if event:
            with self.live_lock:
                first = self.live_firsts.setdefault(self.path, now)
            window += now - first
        text = source.playlist(round((now - LIVE_EPOCH) * TS_HZ), window * TS_HZ, ended,
                               f"{posixpath.basename(path)}.live/", f"?{split.query}" if split.query else "", event)
        return self.send_body("application/vnd.apple.mpegurl", text.encode())

    def send_body(self, content_type, body):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.remaining = len(body)
        return io.BytesIO(body)

    def redirect(self, split, hops, rest, query):
        if hops < 1:
            self.send_error(404, "A redirect chain needs one hop or more")
            return None
        target = f"/redirect/{hops - 1}{rest}" if hops > 1 else rest
        host = self.headers["Host"]
        if "absolute" in query and host:
            location = f"http://{host}{target}"
        else:
            location = posixpath.relpath(target, posixpath.dirname(split.path))
        self.send_response(302)
        self.send_header("Location", location + (f"?{split.query}" if split.query else ""))
        self.send_header("Content-Length", "0")
        self.end_headers()
        return None

    def resolve(self, path, query):
        if not os.path.isfile(self.translate_path(path)):
            self.send_error(404, "File not found")
            return None
        lifetime = query_number(query, "expire")
        lifetime = self.expire if lifetime is None else lifetime
        budget = query_number(query, "bytes")
        budget = self.expire_bytes if budget is None else (int(budget) or None)
        token = secrets.token_urlsafe(12)
        with self.links_lock:
            self.links[token] = Link(path, lifetime, budget, self.rate, self.hold)
        self.log_message("%s: minted /t/%s/ (lifetime %gs, byte budget %s)", path, token, lifetime, budget or "none")
        host = self.headers["Host"]
        self.send_response(302)
        self.send_header("Location", f"http://{host}/t/{token}{path}" if host else f"/t/{token}{path}")
        self.send_header("Content-Length", "0")
        self.end_headers()
        return None

    def named_hold(self, name):
        with self.holds_lock:
            return self.holds.setdefault(name, Hold())

    def grant(self, name, query):
        """/hold/<name>?bytes=<n|all|none>: the hold's allowance raised by n bytes, the hold lifted, or held again."""
        amount = query.get("bytes", [""])[0]
        if amount not in ("all", "none") and not amount.isdigit():
            self.send_error(400, "?bytes=<n>, ?bytes=all or ?bytes=none")
            return None
        hold = self.named_hold(name)
        if amount == "none":
            hold.reset()
        else:
            hold.grant(None if amount == "all" else int(amount))
        said = {"all": "lifted", "none": "held again"}.get(amount, f"{amount} bytes more")
        self.log_message("hold %s: %s", name, said)
        return self.send_body("text/plain", b"ok\n")

    def serve_file(self, url_path, ranges=True):
        path = self.translate_path(url_path)
        if not os.path.isfile(path):
            self.send_error(404, "File not found")
            return None
        stat = os.stat(path)
        size = stat.st_size
        etag = f'"{size:x}-{stat.st_mtime_ns:x}"'
        last_modified = email.utils.formatdate(stat.st_mtime, usegmt=True)
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", self.headers.get("Range", "")) if ranges else None
        if match and not self.if_range_matches(etag, stat.st_mtime):
            match = None
        start, end = 0, size - 1
        if match and (match.group(1) or match.group(2)):
            if match.group(1):
                start = int(match.group(1))
                end = int(match.group(2)) if match.group(2) else size - 1
            else:
                start = max(0, size - int(match.group(2)))
            end = min(end, size - 1)
            if start > end:
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{size}")
                self.send_validators(etag, last_modified)
                self.end_headers()
                return None
            self.send_response(206)
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        else:
            self.send_response(200)
        f = open(path, "rb")
        f.seek(start)
        self.remaining = end - start + 1
        self.send_header("Content-Type", self.guess_type(path))
        self.send_header("Content-Length", str(self.remaining))
        if ranges:
            self.send_header("Accept-Ranges", "bytes")
        self.send_validators(etag, last_modified)
        name = os.path.basename(path)
        self.send_header("Content-Disposition",
                         f"inline; filename=\"{name}\"; filename*=UTF-8''{urllib.parse.quote(name)}")
        self.end_headers()
        return f

    def if_range_matches(self, etag, mtime):
        """No If-Range, or one that matches: the ETag compared strongly, a date to the second."""
        value = self.headers.get("If-Range")
        if value is None:
            return True
        value = value.strip()
        if value.startswith('"') or value.startswith("W/"):
            return value == etag
        try:
            return int(email.utils.parsedate_to_datetime(value).timestamp()) == int(mtime)
        except (TypeError, ValueError):
            return False

    def send_validators(self, etag, last_modified):
        self.send_header("ETag", etag)
        self.send_header("Last-Modified", last_modified)

    def log_request(self, code="-", size="-"):
        extra = "".join(f" {name}={self.headers[name]}" for name in ("Range", "If-Range")
                        if getattr(self, "headers", None) and self.headers.get(name))
        if isinstance(code, http.HTTPStatus):
            code = code.value
        self.log_message('"%s" %s %s%s', self.requestline, str(code), str(size), extra)

    def copyfile(self, source, outputfile):
        remaining = getattr(self, "remaining", None)
        rate = getattr(self, "rate", None)
        link = getattr(self, "link", None)
        hold = getattr(self, "hold", None)
        # A throttled body goes out in tenths of a second's worth, each sent when the rate allows.
        block = 1 << 16 if not rate else int(max(1024, min(1 << 16, rate / 10)))
        # The rate's count: bytes sent since [started], which a wait for a hold's allowance moves on (no burst after).
        started, paced = time.monotonic(), 0
        sent = 0
        while remaining is None or remaining > 0:
            wanted = block if remaining is None else min(block, remaining)
            if hold:
                wanted, waited = hold.take(wanted)
                if waited:
                    started, paced = time.monotonic(), 0
            allowed = link.take(wanted) if link else wanted
            if allowed:
                chunk = source.read(allowed)
                if not chunk:
                    break
                try:
                    outputfile.write(chunk)
                except (BrokenPipeError, ConnectionResetError):
                    break
                sent += len(chunk)
                paced += len(chunk)
                if remaining is not None:
                    remaining -= len(chunk)
            if allowed < wanted:
                self.log_message("%s: the link's byte budget ran out after %d bytes; dropping the transfer",
                                 self.path, sent)
                self.close_connection = True
                break
            if rate:
                delay = started + paced / rate - time.monotonic()
                if delay > 0:
                    time.sleep(delay)


def query_number(query, name):
    values = query.get(name)
    if not values:
        return None
    try:
        return float(values[0])
    except ValueError:
        return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("port", nargs="?", type=int, default=8765)
    ap.add_argument("--root", default=OUT, help="the directory served (default: the out/ beside this script)")
    ap.add_argument("--expire", type=float, default=60, help="seconds a /resolve/ link serves before it answers 403")
    ap.add_argument("--expire-bytes", type=int, default=0, help="bytes a /resolve/ link serves before it expires (0: no limit)")
    ap.add_argument("--slow-rate", type=float, default=256, help="KiB/s of the /slow/ prefix")
    a = ap.parse_args()
    if not os.path.isdir(a.root):
        ap.error(f"no media directory {a.root} (tools/media/make-sample.sh and make-matrix.sh build tools/media/out; "
                 "pass one built elsewhere as --root)")
    RangeHandler.root = os.path.abspath(a.root)
    RangeHandler.expire = a.expire
    RangeHandler.expire_bytes = a.expire_bytes or None
    RangeHandler.slow_rate = a.slow_rate * 1024
    server = http.server.ThreadingHTTPServer(("0.0.0.0", a.port), RangeHandler)
    print(f"serving {RangeHandler.root} on :{a.port}", flush=True)
    server.serve_forever()
