#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parent))

from maestro_jellyfin_proxy import JellyfinProxyHandler, ProxyState  # noqa: E402


class _UpstreamHandler(BaseHTTPRequestHandler):
    requests: list[tuple[str, str, bytes, str | None, str | None]] = []

    def do_GET(self) -> None:
        self._respond()

    def do_POST(self) -> None:
        self._respond()

    def _respond(self) -> None:
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length) if length else b""
        self.requests.append(
            (
                self.command,
                self.path,
                body,
                self.headers.get("X-Emby-Token"),
                self.headers.get("Accept-Encoding"),
            )
        )
        payload = b"real jellyfin response"
        self.send_response(206 if self.headers.get("Range") else 200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args: object) -> None:
        pass

class _ResponseFailureHandler:
    def __init__(self, state: ProxyState, path: str) -> None:
        self.state = state
        self.path = path
        self.command = "GET"
        self.headers: dict[str, str] = {}

    def send_response(self, status: int) -> None:
        raise BrokenPipeError(f"client disconnected before status {status}")


class JellyfinProxyTests(unittest.TestCase):
    def setUp(self) -> None:
        _UpstreamHandler.requests = []
        self.temp_dir = tempfile.TemporaryDirectory()
        self.upstream = ThreadingHTTPServer(("127.0.0.1", 0), _UpstreamHandler)
        self.upstream_thread = threading.Thread(target=self.upstream.serve_forever, daemon=True)
        self.upstream_thread.start()

    def tearDown(self) -> None:
        self.upstream.shutdown()
        self.upstream.server_close()
        self.upstream_thread.join(timeout=5)
        self.temp_dir.cleanup()

    def _start_proxy(self, fault: str | None) -> tuple[ThreadingHTTPServer, threading.Thread, str, Path]:
        journal = Path(self.temp_dir.name) / "journal.jsonl"
        proxy = ThreadingHTTPServer(("127.0.0.1", 0), JellyfinProxyHandler)
        proxy.daemon_threads = True
        upstream_url = f"http://127.0.0.1:{self.upstream.server_port}"
        proxy.state = ProxyState(upstream_url, fault, journal)  # type: ignore[attr-defined]
        thread = threading.Thread(target=proxy.serve_forever, daemon=True)
        thread.start()
        return proxy, thread, f"http://127.0.0.1:{proxy.server_port}", journal

    def _stop_proxy(self, proxy: ThreadingHTTPServer, thread: threading.Thread) -> None:
        proxy.shutdown()
        proxy.server_close()
        thread.join(timeout=5)

    def test_forwards_methods_bodies_tokens_and_range_responses(self) -> None:
        proxy, thread, base_url, _ = self._start_proxy(None)
        try:
            request = urllib.request.Request(
                base_url + "/Items?id=movie",
                data=b'{"played":true}',
                method="POST",
                headers={
                    "X-Emby-Token": "token",
                    "Range": "bytes=0-9",
                    "Content-Type": "application/json",
                    "Accept-Encoding": "gzip",
                },
            )
            with urllib.request.urlopen(request) as response:
                self.assertEqual(response.status, 206)
                self.assertEqual(response.headers["Accept-Ranges"], "bytes")
                self.assertEqual(response.read(), b"real jellyfin response")
            self.assertEqual(
                _UpstreamHandler.requests,
                [("POST", "/Items?id=movie", b'{"played":true}', "token", "identity")],
            )
        finally:
            self._stop_proxy(proxy, thread)

    def test_recovery_faults_only_the_first_video_stream_request(self) -> None:
        proxy, thread, base_url, journal = self._start_proxy("recovery")
        try:
            with self.assertRaises(urllib.error.HTTPError) as first:
                urllib.request.urlopen(base_url + "/Videos/movie/stream.mp4?Static=true")
            self.assertEqual(first.exception.code, 503)
            first.exception.close()
            with urllib.request.urlopen(base_url + "/Videos/movie/stream.mp4?Static=true") as second:
                self.assertEqual(second.status, 200)
            self.assertEqual(len(_UpstreamHandler.requests), 1)
            events = [json.loads(line) for line in journal.read_text(encoding="utf-8").splitlines()]
            self.assertEqual([event["kind"] for event in events], ["fault", "request"])
            self.assertEqual(
                [event["path"] for event in events],
                ["/Videos/movie/stream.mp4", "/Videos/movie/stream.mp4"],
            )
        finally:
            self._stop_proxy(proxy, thread)

    def test_offline_control_blocks_requests_until_reenabled(self) -> None:
        proxy, thread, base_url, journal = self._start_proxy("offline")
        try:
            enable = urllib.request.Request(
                base_url + "/__maestro/offline",
                data=b'{"enabled":true}',
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(enable) as response:
                self.assertEqual(response.status, 204)

            with self.assertRaises(urllib.error.HTTPError) as failure:
                urllib.request.urlopen(base_url + "/Items")
            self.assertEqual(failure.exception.code, 503)
            failure.exception.close()
            self.assertEqual(_UpstreamHandler.requests, [])

            disable = urllib.request.Request(
                base_url + "/__maestro/offline",
                data=b'{"enabled":false}',
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(disable) as response:
                self.assertEqual(response.status, 204)
            with urllib.request.urlopen(base_url + "/Items") as response:
                self.assertEqual(response.status, 200)

            events = [json.loads(line) for line in journal.read_text(encoding="utf-8").splitlines()]
            self.assertEqual([event["kind"] for event in events], ["control", "offline", "control", "request"])
        finally:
            self._stop_proxy(proxy, thread)

    def test_music_fault_does_not_affect_other_requests(self) -> None:
        proxy, thread, base_url, _ = self._start_proxy("music-failure")
        try:
            with urllib.request.urlopen(base_url + "/Items") as response:
                self.assertEqual(response.status, 200)
            with self.assertRaises(urllib.error.HTTPError) as failure:
                urllib.request.urlopen(base_url + "/Artists/AlbumArtists?UserId=user")
            self.assertEqual(failure.exception.code, 503)
            failure.exception.close()
            with urllib.request.urlopen(base_url + "/Artists/AlbumArtists?UserId=user") as recovered:
                self.assertEqual(recovered.status, 200)
        finally:
            self._stop_proxy(proxy, thread)

    def test_records_events_before_response_write(self) -> None:
        upstream_url = f"http://127.0.0.1:{self.upstream.server_port}"
        cases = [
            ("fault", "recovery", "/Videos/movie/stream.mp4?Static=true", "fault", 503),
            ("request", None, "/Items", "request", 200),
        ]

        for name, fault, path, expected_kind, expected_status in cases:
            with self.subTest(name=name):
                journal = Path(self.temp_dir.name) / f"{name}.jsonl"
                state = ProxyState(upstream_url, fault, journal)
                handler = _ResponseFailureHandler(state, path)

                with self.assertRaises(BrokenPipeError):
                    JellyfinProxyHandler._proxy(handler)

                events = [json.loads(line) for line in journal.read_text(encoding="utf-8").splitlines()]
                self.assertEqual(len(events), 1)
                self.assertEqual(events[0]["kind"], expected_kind)
                self.assertEqual(events[0]["status"], expected_status)


if __name__ == "__main__":
    unittest.main()
