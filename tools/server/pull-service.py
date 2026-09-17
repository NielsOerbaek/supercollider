#!/usr/bin/env python3
"""Tiny endpoint behind Caddy: runs update.sh and returns its output.

Binds the docker gateway only, so it is not reachable from the internet;
Caddy proxies mix.raakode.dk/api/pull to it and holds the password.
"""
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

SCRIPT = "/opt/mix.raakode.dk/update.sh"


class Handler(BaseHTTPRequestHandler):
    def run(self):
        try:
            r = subprocess.run([SCRIPT], capture_output=True, text=True, timeout=180)
            body, code = (r.stdout or r.stderr), (200 if r.returncode == 0 else 500)
        except subprocess.TimeoutExpired:
            body, code = "update timed out\n", 504
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body.encode())

    do_POST = do_GET = run

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


HTTPServer(("172.17.0.1", 8765), Handler).serve_forever()
