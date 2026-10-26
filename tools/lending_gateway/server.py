#!/usr/bin/env python3
"""OverDrive QR token exchange for approved PlezyNG integrations.

Bind to loopback behind an HTTPS reverse proxy. Never embed client secrets in
PlezyNG. This service performs token exchange only; circulation requests use the
patron's scoped bearer token directly. See docs/LENDING_SETUP.md.
"""
import base64
import hashlib
import hmac
import json
import ipaddress
import os
import re
import secrets
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


class InvalidRequest(Exception):
    def __init__(self, status=400):
        self.status = status


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def pkce(value):
    return base64.urlsafe_b64encode(hashlib.sha256(value.encode('ascii')).digest()).decode().rstrip('=')


class Gateway:
    def __init__(self, config, exchange=None, clock=time.monotonic):
        self.origin = config['origin'].rstrip('/')
        origin = urlsplit(self.origin)
        if origin.scheme != 'https' or not origin.hostname or origin.username or origin.path or origin.query or origin.fragment:
            raise ValueError('origin must be an HTTPS origin')
        self.client_id = config['client_id']
        self.secret = config['client_secret']
        self.code_parameter = config.get('code_parameter', 'code')
        self.signing_key = config['signing_key'].encode()
        if len(self.signing_key) < 32:
            raise ValueError('signing_key must contain at least 32 random characters')
        self.libraries = {str(lib['id']): lib for lib in config['libraries']}
        for lib in self.libraries.values():
            if not re.fullmatch(r'[A-Za-z0-9_-]{1,80}', str(lib['id'])) or not str(lib['websiteId']).isdigit():
                raise ValueError('invalid library identifiers')
        self.pending = {}
        self.rates = {}
        self.lock = threading.Lock()
        self.clock = clock
        self.exchange = exchange or self._exchange

    def public_libraries(self):
        allowed = ('id', 'name', 'websiteId', 'libraryId', 'home', 'integration', 'circulation')
        return [{key: lib[key] for key in allowed if key in lib} for lib in self.libraries.values()]

    def rate_limit(self, address):
        with self.lock:
            now = self.clock()
            self.rates = {key: value for key, value in self.rates.items() if now - value[0] < 60}
            start, count = self.rates.get(address, (now, 0))
            if count >= 120 or len(self.rates) >= 10000:
                raise InvalidRequest(429)
            self.rates[address] = (start, count + 1)

    def initiate(self, data):
        library = str(data.get('library', ''))
        challenge = data.get('challenge', '')
        if library not in self.libraries or not isinstance(challenge, str) or not re.fullmatch(r'[A-Za-z0-9_-]{43}', challenge):
            raise InvalidRequest()
        with self.lock:
            now = self.clock()
            self.pending = {key: value for key, value in self.pending.items() if value['expires'] > now}
            if len(self.pending) >= 1000:
                raise InvalidRequest(429)
            identifier, callback_secret = secrets.token_urlsafe(32), secrets.token_urlsafe(32)
            self.pending[identifier] = dict(challenge=challenge, callback=callback_secret, library=library, expires=now + 600, code=None)
        callback = f'{self.origin}/callback/{identifier}/{callback_secret}'
        query = dict(redirect_url=callback, abandon_url=callback + '?cancelled=1', error_url=callback + '?failed=1',
                     website_id=str(self.libraries[library]['websiteId']), client_id=self.client_id)
        return dict(id=identifier, authorizeUrl='https://oauth-patron.overdrive.com/device/initiate?' + urlencode(query), expiresIn=600)

    def callback(self, identifier, secret, query):
        with self.lock:
            pending = self.pending.get(identifier)
            if not pending or pending['expires'] <= self.clock() or not hmac.compare_digest(pending['callback'], secret):
                raise InvalidRequest(404)
            if pending.get('received'):
                raise InvalidRequest(409)
            pending['received'] = True
            if query.get('cancelled') or query.get('failed'):
                pending['cancelled'] = True
                return
            # OverDrive documents a 64-character code. Confirm the callback
            # parameter name with the assigned integration before production.
            code = query.get(self.code_parameter, [''])[0]
            if len(code) != 64 or any(ord(character) < 33 or ord(character) > 126 for character in code):
                pending['cancelled'] = True
                raise InvalidRequest()
            pending['code'] = code

    def poll(self, identifier, data):
        verifier = data.get('verifier', '')
        if not isinstance(verifier, str) or not re.fullmatch(r'[A-Za-z0-9_-]{43,128}', verifier):
            raise InvalidRequest()
        with self.lock:
            pending = self.pending.get(identifier)
            if not pending or pending['expires'] <= self.clock():
                raise InvalidRequest(410)
            if not hmac.compare_digest(pending['challenge'], pkce(verifier)):
                raise InvalidRequest(403)
            if data.get('cancel') is True or pending.get('cancelled'):
                del self.pending[identifier]
                raise InvalidRequest(410)
            if not pending['code']:
                return 202, {'pending': True}
            # Consume before network exchange: one code can never be replayed.
            del self.pending[identifier]
        return 200, self._tokens(self.exchange('code', {'grant_type': 'authorization_code', 'code': pending['code']}), pending['library'])

    def proof(self, token, library):
        return hmac.new(self.signing_key, json.dumps([library, token], separators=(',', ':')).encode(), hashlib.sha256).hexdigest()

    def _tokens(self, result, library):
        if not isinstance(result.get('access_token'), str) or not result['access_token']:
            raise InvalidRequest(502)
        # Only issue sessions for the requested website and environment.
        scopes = result.get('scope', '').split()
        lib = self.libraries[library]
        required = 'PATRONINT' if lib.get('integration', False) else 'PATRON'
        if f"website:{lib['websiteId']}" not in scopes or required not in scopes:
            raise InvalidRequest(403)
        result = {key: result[key] for key in ('access_token', 'refresh_token', 'expires_in', 'scope', 'token_type') if key in result}
        if result.get('refresh_token'):
            result['refreshProof'] = self.proof(result['refresh_token'], library)
        return result

    def refresh(self, data):
        library, token, proof = data.get('library'), data.get('refresh_token'), data.get('refreshProof')
        if library not in self.libraries or not isinstance(token, str) or not isinstance(proof, str):
            raise InvalidRequest()
        if not hmac.compare_digest(proof, self.proof(token, library)):
            raise InvalidRequest(403)
        return self._tokens(self.exchange('refresh', {'grant_type': 'refresh_token', 'refresh_token': token}), library)

    def _exchange(self, endpoint, fields):
        basic = base64.b64encode(f'{self.client_id}:{self.secret}'.encode()).decode()
        request = Request(f'https://oauth-patron.overdrive.com/patrontoken/{endpoint}', data=urlencode(fields).encode(),
                          headers={'Authorization': f'Basic {basic}', 'Content-Type': 'application/x-www-form-urlencoded',
                                   'User-Agent': 'PlezyNG-Lending/1'})
        try:
            with build_opener(NoRedirect()).open(request, timeout=20) as response:
                payload = response.read(65537)
                if len(payload) > 65536:
                    raise InvalidRequest(502)
                return json.loads(payload)
        except (HTTPError, OSError, ValueError):
            raise InvalidRequest(502) from None


def handler(gateway):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass  # Authorization codes and tokens must not enter access logs.

        def _reply(self, status, payload):
            data = json.dumps(payload).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'")
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _run(self, post=False):
            try:
                self.connection.settimeout(25)
                # The reverse proxy must preserve Host and limit connections.
                if self.headers.get('Host') != urlsplit(gateway.origin).netloc or self.headers.get('Origin'):
                    raise InvalidRequest(403)
                address = self.headers.get('X-Real-IP', self.client_address[0])
                try:
                    address = str(ipaddress.ip_address(address))
                except ValueError:
                    raise InvalidRequest(400) from None
                gateway.rate_limit(address)
                parsed = urlsplit(self.path)
                parts = parsed.path.strip('/').split('/')
                if not post:
                    if parsed.path == '/v1/libraries':
                        return self._reply(200, {'libraries': gateway.public_libraries()})
                    if len(parts) == 3 and parts[0] == 'callback':
                        gateway.callback(parts[1], parts[2], parse_qs(parsed.query))
                        return self._reply(200, {'message': 'Return to PlezyNG to finish signing in.'})
                    raise InvalidRequest(404)
                length = int(self.headers.get('Content-Length', '0'))
                if length <= 0 or length > 16384 or self.headers.get('Content-Type', '').split(';')[0] != 'application/json':
                    raise InvalidRequest(400)
                data = json.loads(self.rfile.read(length))
                if not isinstance(data, dict):
                    raise InvalidRequest()
                if parts == ['v1', 'authorizations']:
                    return self._reply(201, gateway.initiate(data))
                if len(parts) == 4 and parts[:2] == ['v1', 'authorizations'] and parts[3] == 'token':
                    status, result = gateway.poll(parts[2], data)
                    return self._reply(status, result)
                if parts == ['v1', 'refresh']:
                    return self._reply(200, gateway.refresh(data))
                raise InvalidRequest(404)
            except InvalidRequest as error:
                self._reply(error.status, {'error': 'Request could not be completed.'})
            except (ValueError, KeyError, TypeError, OSError):
                self._reply(400, {'error': 'Invalid request.'})

        def do_GET(self):
            self._run()

        def do_POST(self):
            self._run(post=True)
    return Handler


if __name__ == '__main__':
    with open(os.environ['PLEZY_LENDING_CONFIG'], encoding='utf-8') as stream:
        config = json.load(stream)
    ThreadingHTTPServer(('127.0.0.1', int(os.environ.get('PORT', '8788'))), handler(Gateway(config))).serve_forever()
