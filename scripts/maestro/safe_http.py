"""HTTP-only URL opening for local regression helpers and their fixtures."""

from __future__ import annotations

from typing import IO, Any
import urllib.parse
import urllib.request


def _url_value(url: str | urllib.request.Request) -> str:
    return url.full_url if isinstance(url, urllib.request.Request) else url


def validate_http_url(url: str | urllib.request.Request) -> str:
    """Reject non-HTTP schemes before passing a dynamic URL to urllib."""
    value = _url_value(url)
    parsed = urllib.parse.urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ValueError("URL must be an HTTP or HTTPS address without embedded credentials")
    return value


class _HttpOnlyRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(
        self,
        request: urllib.request.Request,
        file: IO[bytes],
        code: int,
        message: str,
        headers: Any,
        new_url: str,
    ) -> urllib.request.Request | None:
        validate_http_url(new_url)
        return super().redirect_request(request, file, code, message, headers, new_url)


def _open_http_request(url: str | urllib.request.Request, timeout: float | None) -> Any:
    request = url if isinstance(url, urllib.request.Request) else urllib.request.Request(url)
    opener = urllib.request.build_opener(_HttpOnlyRedirectHandler())
    return opener.open(request, timeout=timeout)


def safe_urlopen(url: str | urllib.request.Request, timeout: float | None = None) -> Any:
    """Open only HTTP(S) URLs, including after redirects."""
    validate_http_url(url)
    return _open_http_request(url, timeout)
