from __future__ import annotations

import io
import unittest
from urllib.request import Request
from unittest.mock import patch

import safe_http


class SafeHttpTests(unittest.TestCase):
    def test_accepts_http_and_https_urls(self) -> None:
        self.assertEqual(safe_http.validate_http_url("http://127.0.0.1:8096/health"), "http://127.0.0.1:8096/health")
        request = Request("https://example.test/api")
        self.assertEqual(safe_http.validate_http_url(request), request.full_url)

    def test_rejects_non_http_schemes_and_embedded_credentials(self) -> None:
        for value in ("file:///etc/passwd", "ftp://example.test/file", "http://user:pass@example.test/"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                safe_http.validate_http_url(value)

    def test_safe_urlopen_rejects_file_urls_before_opening(self) -> None:
        with patch.object(safe_http, "_open_http_request") as open_request:
            with self.assertRaises(ValueError):
                safe_http.safe_urlopen("file:///etc/passwd")
        open_request.assert_not_called()

    def test_redirect_handler_rejects_a_file_scheme_redirect(self) -> None:
        handler = safe_http._HttpOnlyRedirectHandler()
        with self.assertRaises(ValueError):
            handler.redirect_request(
                Request("https://example.test/start"),
                io.BytesIO(),
                302,
                "Found",
                {},
                "file:///etc/passwd",
            )


if __name__ == "__main__":
    unittest.main()
