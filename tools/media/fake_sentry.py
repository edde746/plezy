#!/usr/bin/env python3
"""A fake Sentry for the crash-report tests (the desktop and Android crash tests, Apple's crash test): a
development session given this server's DSN, http://public@<host>:<port>/1
(`--dev-crash-reports <dsn>`, on Android inside the `dev` launch extra), sends its crash reports here.

It takes them as the release builds' server, edde746/bugs (a self-hosted error tracker for Sentry's SDKs), does, so a
report this fake keeps is one bugs keeps too:
  - the key: the DSN's, `public`, in X-Sentry-Auth, an `Authorization: Sentry|DSN|Basic` header or ?sentry_key=, and
    the DSN's project, 1, in the path; anything else is 401;
  - the body: at most 20 MB as sent and 10 MB unpacked (413 beyond); gzip is unpacked when the body starts with gzip's
    magic bytes, whatever Content-Encoding says, and nothing else is (bugs takes no deflate, brotli or zstd);
  - the items: an item without a type is an event; events are kept, once per event id; an envelope it can't parse, or
    an event whose fields bugs reads with a type don't have that type (BUGS_EVENT), is answered 200 as bugs answers
    it, and kept nowhere, as bugs gives it up after five tries; the reason goes to /_log and stdout.

Usage: tools/media/fake_sentry.py [--port 8773] [--out <dir>]
Routes:
  POST /api/1/envelope/  an envelope: its event items are kept; every envelope is written to --out as <n>.envelope
  POST /api/1/store/     a lone event (the older endpoint), kept the same way
  GET  /_events          the event items kept so far, each its parsed JSON, in order, each id once
  GET  /_log             every envelope received: its item types, the size of each and why bugs would drop it, in order
  POST /_reset           forgets everything received
The /_ routes take no key: they are for a trusted network only.
Answers every envelope it takes with 200 {"id": <the envelope's event id>}, as bugs does.

The tests judge what came with probe_crash and leaks, which they import from here (a test that runs on another host
takes this file there beside its own scripts).
"""
import argparse
import base64
import gzip
import http.server
import io
import json
import pathlib
import sys
import threading
import urllib.parse
import uuid

LOCK = threading.Lock()
EVENTS = []
ENVELOPES = []
KEY = "public"
PROJECT = "1"
MAX_REQUEST = 20 * 1024 * 1024
MAX_ENVELOPE = 10 * 1024 * 1024
# The test builds' crash (dev's DevCrashException): its message holds an addon URL with this made-up API key, which
# no report may hold, at this addon's origin, which the scrubbed message keeps.
PROBE_TYPE = "DevCrashException"
PROBE_KEY = "PLEZYCRASHPROBEABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABC"
PROBE_ORIGIN = "https://addon.example/"

# The event fields bugs reads with a type (src/sentry_protocol/types.rs at 1ed1ad6): an object's are checked where
# present, a list is an array of its one kind (absent is empty, null is not), and a field of another kind than the one
# named here fails the whole event there. bugs keeps every other field as sent; it reads message and breadcrumbs in
# any shape.
FRAME = {"filename": "str", "function": "str", "module": "str", "lineno": "u32", "colno": "u32", "abs_path": "str",
         "in_app": "bool", "context_line": "str", "pre_context": "strs", "post_context": "strs",
         "instruction_addr": "str", "symbol_addr": "str", "image_addr": "str", "package": "str", "addr_mode": "str",
         "trust": "str"}
STACKTRACE = {"frames": [FRAME]}
BUGS_EVENT = {
    **{key: "str" for key in ("event_id", "level", "platform", "logger", "release", "dist", "environment",
                              "server_name", "transaction", "type")},
    "logentry": {"message": "str"},
    "exception": {"values": [{"type": "str", "value": "str", "module": "str", "stacktrace": STACKTRACE,
                              "mechanism": {"type": "str", "handled": "bool", "description": "str"}}]},
    "threads": {"values": [{"name": "str", "crashed": "bool", "current": "bool", "stacktrace": STACKTRACE}]},
    "fingerprint": "array",
}
KINDS = {
    "str": lambda v: isinstance(v, str),
    "bool": lambda v: isinstance(v, bool),
    "u32": lambda v: isinstance(v, int) and not isinstance(v, bool) and 0 <= v < 2 ** 32,
    "strs": lambda v: isinstance(v, list) and all(isinstance(s, str) for s in v),
    "array": lambda v: isinstance(v, list),
}


def misread(value, kind, where="event"):
    """Why bugs couldn't read [value] at [where] as [kind] (BUGS_EVENT's notation), or None when it can."""
    if isinstance(kind, list):
        if not isinstance(value, list):
            return f"{where} is not an array"
        for i, item in enumerate(value):
            found = f"{where}[{i}] is null" if item is None else misread(item, kind[0], f"{where}[{i}]")
            if found:
                return found
        return None
    if value is None:
        return None
    if isinstance(kind, dict):
        if not isinstance(value, dict):
            return f"{where} is not an object"
        return next((found for key, sub in kind.items() if key in value
                     for found in [misread(value[key], sub, f"{where}.{key}")] if found), None)
    return None if KINDS[kind](value) else f"{where} is {json.dumps(value)[:80]}, not {kind}"


def probe_crash(event):
    """The probe crash's exception in [event] (type DevCrashException, qualified on Apple), or None."""
    values = (event.get("exception") or {}).get("values") or []
    return next((e for e in values if str(e.get("type")).rsplit(".", 1)[-1] == PROBE_TYPE), None)


def leaks(event):
    """What [event] holds that no crash report may, one line each (none: []): the probe's key or any addon path with an
    API key's name, a user or IP address, a device's id or name, the app's device hash, a server (host) name, a
    request."""
    text = json.dumps(event)
    contexts = event.get("contexts") or {}
    device, app = contexts.get("device") or {}, contexts.get("app") or {}
    found = [
        "the probe URL's key" if PROBE_KEY in text else None,
        "an addon path with apikey=" if "apikey=" in text else None,
        f"user {event['user']}" if event.get("user") else None,
        "an ip_address" if "ip_address" in text else None,
        f"device id {device['id']}" if device.get("id") else None,
        f"device name {device['name']}" if device.get("name") else None,
        "app.device_app_hash" if app.get("device_app_hash") else None,
        f"server_name {event['server_name']}" if event.get("server_name") else None,
        "a request" if event.get("request") else None,
    ]
    return [f for f in found if f]


def parse_envelope(body):
    """The envelope's header and its items as (header, payload bytes), as bugs parses them: a JSON header line, then
    each item's header line (no type: an event) and its payload, `length` bytes long when the header says so, else up
    to the next newline. Raises ValueError where bugs fails."""
    head, newline, rest = body.partition(b"\n")
    if not newline:
        raise ValueError("no newline after the envelope header")
    header = json.loads(head)
    if not isinstance(header, dict):
        raise ValueError("the envelope header is not an object")
    items = []
    while rest.strip(b"\r\n"):
        header_line, newline, rest = rest.partition(b"\n")
        if not header_line:
            break
        if not newline:
            raise ValueError("an item header without its payload")
        item = json.loads(header_line)
        if not isinstance(item, dict):
            raise ValueError("an item header is not an object")
        length = item.get("length")
        if length is None:
            payload, _, rest = rest.partition(b"\n")
        else:
            if not isinstance(length, int) or isinstance(length, bool) or length < 0:
                raise ValueError(f"an item length of {json.dumps(length)[:80]}, not a byte count")
            if length > len(rest):
                raise ValueError("an item shorter than its length")
            payload, rest = rest[:length], rest[length:]
            if rest.startswith(b"\n"):
                rest = rest[1:]
        items.append(({"type": "event", **item}, payload))
    return header, items


class Handler(http.server.BaseHTTPRequestHandler):
    out = None

    def log_message(self, fmt, *args):
        sys.stderr.write("fake_sentry: " + (fmt % args) + "\n")

    def reply(self, status, value):
        data = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def sentry_key(self, query):
        """The key the request authenticates with, where bugs looks for it, or None."""
        def pair(text):
            pairs = (p.strip().partition("=") for p in text.split(","))
            return next((v.strip() for k, _, v in pairs if k.strip() == "sentry_key"), None)
        auth = self.headers.get("X-Sentry-Auth")
        if auth and (key := pair(auth.removeprefix("Sentry ").removeprefix("DSN ").removeprefix("sentry "))):
            return key
        auth = self.headers.get("Authorization") or ""
        if auth.startswith(("Sentry ", "DSN ")) and (key := pair(auth.removeprefix("Sentry ").removeprefix("DSN "))):
            return key
        if auth.startswith("Basic "):
            try:
                return base64.b64decode(auth[6:].strip()).decode().split(":", 1)[0]
            except ValueError:
                pass
        return next(iter(urllib.parse.parse_qs(query).get("sentry_key", [])), None)

    def do_GET(self):
        with LOCK:
            if self.path == "/_events":
                return self.reply(200, EVENTS)
            if self.path == "/_log":
                return self.reply(200, ENVELOPES)
        self.reply(404, {"detail": "not found"})

    def do_POST(self):
        path, _, query = self.path.partition("?")
        if path == "/_reset":
            with LOCK:
                EVENTS.clear()
                ENVELOPES.clear()
            return self.reply(200, {})
        parts = path.strip("/").split("/")
        if len(parts) != 3 or parts[0] != "api" or parts[2] not in ("envelope", "store"):
            return self.reply(404, {"detail": "not found"})
        if self.sentry_key(query) != KEY or parts[1] != PROJECT:
            return self.reply(401, "unauthorized")
        # The length is checked before anything is read, so no request is held in memory beyond the limit.
        declared = self.headers.get("Content-Length") or "0"
        if not (declared.isascii() and declared.isdigit()):
            return self.reply(400, "Invalid Content-Length")
        if int(declared) > MAX_REQUEST:
            return self.reply(413, "Request too large")
        body = self.rfile.read(int(declared))
        if body[:2] == b"\x1f\x8b":
            try:
                with gzip.GzipFile(fileobj=io.BytesIO(body)) as unpacked:
                    body = unpacked.read(MAX_ENVELOPE + 1)
            except (OSError, EOFError) as e:
                return self.reply(400, f"Decompression failed: {e}")
        if len(body) > MAX_ENVELOPE:
            return self.reply(413, "Envelope too large")
        envelope_id = uuid.uuid4().hex
        try:
            if parts[2] == "store":
                header, items = {}, [({"type": "event"}, body)]
            else:
                header, items = parse_envelope(body)
            envelope_id = header.get("event_id") or envelope_id
            events = [json.loads(p) for h, p in items if h["type"] == "event"]
            dropped = next((found for event in events for found in [misread(event, BUGS_EVENT)] if found), None)
        except ValueError as e:
            items, events, dropped = [], [], f"unreadable envelope: {e}"
        types = [str(h["type"]) for h, _ in items]
        with LOCK:
            n = len(ENVELOPES) + 1
            ENVELOPES.append({"n": n, "items": [{"type": t, "bytes": len(p)} for t, (_, p) in zip(types, items)],
                              **({"dropped": dropped} if dropped else {})})
            # bugs keeps an event id once: an SDK sends a crash again from its outbox when the process ended before
            # the first send was recorded.
            for event in [] if dropped else events:
                if all(e.get("event_id") != event.get("event_id") for e in EVENTS):
                    EVENTS.append(event)
            if self.out:
                (self.out / f"{n}.envelope").write_bytes(body)
        print(f"ENVELOPE {n} types={','.join(types)}" + (f" DROPPED {dropped}" if dropped else ""), flush=True)
        self.reply(200, {"id": envelope_id})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8773)
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--out", type=pathlib.Path, help="a directory each envelope is written to, as <n>.envelope")
    a = ap.parse_args()
    if a.out:
        a.out.mkdir(parents=True, exist_ok=True)
    Handler.out = a.out
    server = http.server.ThreadingHTTPServer((a.host, a.port), Handler)
    print(f"fake_sentry: listening on {a.host}:{a.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
