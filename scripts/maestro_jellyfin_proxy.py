#!/usr/bin/env python3
"""Forward to a real Jellyfin server with narrowly scoped one-shot faults."""

from __future__ import annotations

import argparse
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request

_FAULT_PATHS = {
    "music-failure": lambda path: path.startswith("/Artists/AlbumArtists"),
    "recovery": lambda path: path.startswith("/Videos/") and "/stream" in path,
}
_FORWARD_HEADERS = {
    "accept",
    "authorization",
    "content-type",
    "if-modified-since",
    "if-none-match",
    "range",
    "user-agent",
    "x-emby-authorization",
    "x-emby-token",
}
_RESPONSE_HEADERS = {
    "accept-ranges",
    "cache-control",
    "content-disposition",
    "content-range",
    "content-type",
    "date",
    "etag",
    "last-modified",
    "location",
}


class ProxyState:
    def __init__(self, upstream: str, fault: str | None, journal: Path | None) -> None:
        self.upstream = upstream.rstrip("/")
        self.fault = fault
        self.journal = journal
        self._fault_injected = False
        self._sequence = 0
        self._lock = threading.Lock()
        if journal is not None:
            journal.parent.mkdir(parents=True, exist_ok=True)
            journal.write_text("", encoding="utf-8")

    def should_fault(self, path: str) -> bool:
        predicate = _FAULT_PATHS.get(self.fault)
        if predicate is None or not predicate(path):
            return False
        with self._lock:
            if self._fault_injected:
                return False
            self._fault_injected = True
            return True

    def record(self, *, method: str, path: str, status: int, kind: str) -> None:
        if self.journal is None:
            return
        with self._lock:
            self._sequence += 1
            event = {
                "sequence": self._sequence,
                "timestampMs": int(time.time() * 1000),
                "kind": kind,
                "method": method,
                "path": urllib.parse.urlsplit(path).path,
                "status": status,
            }
            with self.journal.open("a", encoding="utf-8") as output:
                output.write(json.dumps(event, separators=(",", ":"), sort_keys=True) + "\n")


class JellyfinProxyHandler(BaseHTTPRequestHandler):
    server_version = "PlezyJellyfinProxy/1.0"

    @property
    def state(self) -> ProxyState:
        return self.server.state  # type: ignore[attr-defined]

    def do_GET(self) -> None:
        self._proxy()

    def do_HEAD(self) -> None:
        self._proxy()

    def do_POST(self) -> None:
        self._proxy()

    def do_PUT(self) -> None:
        self._proxy()

    def do_PATCH(self) -> None:
        self._proxy()

    def do_DELETE(self) -> None:
        self._proxy()

    def do_OPTIONS(self) -> None:
        self._proxy()

    def _proxy(self) -> None:
        if self.state.should_fault(self.path):
            payload = json.dumps({"error": "temporary Maestro fault"}).encode("utf-8")
            self.send_response(HTTPStatus.SERVICE_UNAVAILABLE)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(payload)
            self.state.record(method=self.command, path=self.path, status=503, kind="fault")
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length) if content_length else None
        headers = {
            name: value
            for name, value in self.headers.items()
            if name.lower() in _FORWARD_HEADERS
        }
        request = urllib.request.Request(
            self.state.upstream + self.path,
            data=body,
            method=self.command,
            headers=headers,
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                status = response.status
                response_headers = response.headers
                payload = response.read()
        except urllib.error.HTTPError as error:
            status = error.code
            response_headers = error.headers
            payload = error.read()
        except (OSError, urllib.error.URLError) as error:
            payload = json.dumps({"error": f"upstream unavailable: {error}"}).encode("utf-8")
            status = HTTPStatus.BAD_GATEWAY
            response_headers = {"Content-Type": "application/json"}

        self.send_response(status)
        for name, value in response_headers.items():
            if name.lower() in _RESPONSE_HEADERS:
                self.send_header(name, value)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            try:
                self.wfile.write(payload)
            except (BrokenPipeError, ConnectionResetError):
                pass
        self.state.record(method=self.command, path=self.path, status=int(status), kind="request")

    def log_message(self, format: str, *args: Any) -> None:
        print(f"jellyfin-proxy: {format % args}")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--upstream", required=True)
    parser.add_argument("--fault", choices=sorted(_FAULT_PATHS))
    parser.add_argument("--journal", type=Path)
    return parser


def main() -> None:
    args = _build_parser().parse_args()
    server = ThreadingHTTPServer((args.host, args.port), JellyfinProxyHandler)
    server.daemon_threads = True
    server.state = ProxyState(args.upstream, args.fault, args.journal)  # type: ignore[attr-defined]
    print(f"Jellyfin proxy listening on http://{args.host}:{args.port} -> {args.upstream}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
