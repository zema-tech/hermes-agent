"""Tiny always-200 HTTP listener for PaaS hosts (e.g. Render) that require an open $PORT.

Used when the Hermes dashboard is disabled: the gateway itself opens no HTTP port, and the
dashboard costs ~130 MB of RAM, which is too much on a 512 MB instance. This process uses ~10-20 MB
and serves no files, so nothing from the filesystem is ever exposed.
"""
import http.server
import os


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"hermes gateway running\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    do_HEAD = do_GET

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT") or os.environ.get("HERMES_DASHBOARD_PORT") or "10000")
    http.server.ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
