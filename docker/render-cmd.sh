#!/bin/sh
# Default container command for PaaS hosts such as Render (free plan: 512 MB RAM, needs an open $PORT).
#
# - HERMES_DASHBOARD truthy -> the dashboard service already listens on its own port; nothing extra to start.
# - otherwise               -> start a tiny keep-alive listener on $PORT (~10-20 MB) so the host sees an open
#                              port, without paying the ~130 MB the dashboard needs.
# Then run the gateway (it hands off to s6 supervision and keeps the container alive).
case "${HERMES_DASHBOARD:-}" in
    1|true|TRUE|True|yes|YES|Yes) ;;
    *) /opt/hermes/.venv/bin/python /opt/hermes/docker/keepalive_http.py & ;;
esac
exec hermes gateway run
