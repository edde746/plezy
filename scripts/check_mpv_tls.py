#!/usr/bin/env python3
"""Loopback-only TLS regression. Usage: check_mpv_tls.py /path/to/libmpv.so

Requires OpenSSL and a loadable libmpv (plus its runtime dependencies).
Uses only a temporary certificate, synthetic WAV, and dummy credentials.
"""
import ctypes as C
import http.server
import io
import json
import pathlib
import ssl
import sys
import subprocess
import tempfile
import threading
import time
import wave


C.CDLL("libstdc++.so.6", mode=C.RTLD_GLOBAL)
lib = C.CDLL(sys.argv[1])
lib.mpv_create.restype = C.c_void_p
lib.mpv_set_option_string.argtypes = [C.c_void_p, C.c_char_p, C.c_char_p]
lib.mpv_initialize.argtypes = [C.c_void_p]
lib.mpv_get_property_string.argtypes = [C.c_void_p, C.c_char_p]
lib.mpv_get_property_string.restype = C.c_void_p
lib.mpv_free.argtypes = [C.c_void_p]
lib.mpv_command.argtypes = [C.c_void_p, C.POINTER(C.c_char_p)]
lib.mpv_terminate_destroy.argtypes = [C.c_void_p]

wav = io.BytesIO()
with wave.open(wav, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(8000)
    w.writeframes(b"\x00\x00" * 4000)
body = wav.getvalue()
requests = []

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        requests.append(self.path)
        self.send_response(200)
        self.send_header("Content-Type", "audio/wav")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_):
        pass

def run_probe(port, force_verify, ca_file=None, host="127.0.0.1"):
    mpv = lib.mpv_create()
    assert mpv
    try:
        options = {"config": "no", "vo": "null", "ao": "null", "ytdl": "no",
                   "network-timeout": "2", "load-scripts": "no", "msg-level": "all=no"}
        if force_verify:
            options["tls-verify"] = "yes"
        if ca_file:
            options["tls-ca-file"] = ca_file
        for k, v in options.items():
            assert lib.mpv_set_option_string(mpv, k.encode(), v.encode()) >= 0, k
        assert lib.mpv_initialize(mpv) >= 0
        p = lib.mpv_get_property_string(mpv, b"options/tls-verify")
        value = C.string_at(p).decode() if p else None
        if p:
            lib.mpv_free(p)
        before = len(requests)
        label = "verified" if force_verify else "default"
        url = f"https://{host}:{port}/test.wav?api_key=DUMMY_AUDIT_TOKEN_{label}"
        argv = (C.c_char_p * 3)(b"loadfile", url.encode(), None)
        assert lib.mpv_command(mpv, argv) >= 0
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            time.sleep(0.05)
        result = {"mode": label, "tls_verify": value,
                  "untrusted_server_received": requests[before:]}
        print(json.dumps(result), flush=True)
        return result
    finally:
        lib.mpv_terminate_destroy(mpv)

with tempfile.TemporaryDirectory(prefix="plezy-tls-audit-") as d:
    key, cert = str(pathlib.Path(d) / "key.pem"), str(pathlib.Path(d) / "cert.pem")
    subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                    "-keyout", key, "-out", cert, "-days", "1", "-subj", "/CN=127.0.0.1",
                    "-addext", "subjectAltName=IP:127.0.0.1"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(cert, key)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        default = run_probe(server.server_port, False)
        verified = run_probe(server.server_port, True)
        assert verified["tls_verify"] == "yes"
        assert not verified["untrusted_server_received"]
        trusted = run_probe(server.server_port, True, cert)
        assert trusted["untrusted_server_received"], "Explicitly trusted certificate must play"
        mismatch = run_probe(server.server_port, True, cert, host="localhost")
        assert not mismatch["untrusted_server_received"], "Trust must not bypass hostname verification"
        print("PASS: untrusted and wrong-host certificates blocked before credentials; trusted TLS works.")
    finally:
        server.shutdown()
        server.server_close()
