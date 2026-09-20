#!/bin/sh
# Entrypoint for Hugging Face Spaces (Docker SDK).
#
# Spaces run the container as UID 1000 with a single public port (app_port, 7860) and no root, so the
# s6-overlay init used by the regular image (which needs root + the `hermes` user) cannot be used here.
# This script does the essential parts of docker/stage2-hook.sh by hand and starts the processes directly:
#   1. create + seed $HERMES_HOME (config.yaml, .env, SOUL.md), sync bundled skills;
#   2. start the web dashboard on $PORT (7860) if basic-auth credentials are provided, otherwise a tiny
#      keep-alive listener so the Space still reports "Running";
#   3. run the messaging gateway (Discord, Telegram, ...) in the foreground.
set -eu

INSTALL_DIR="${INSTALL_DIR:-/opt/hermes}"
export HERMES_HOME="${HERMES_HOME:-$HOME/data}"
PORT="${PORT:-7860}"
export PORT

mkdir -p "$HERMES_HOME"
for d in backups cron sessions logs logs/gateways hooks memories skills skins plans workspace home pairing platforms/pairing lazy-packages; do
    mkdir -p "$HERMES_HOME/$d"
done

seed_one() {
    if [ ! -f "$HERMES_HOME/$1" ] && [ -f "$INSTALL_DIR/$2" ]; then
        cp "$INSTALL_DIR/$2" "$HERMES_HOME/$1"
    fi
    return 0
}
seed_one .env .env.example
seed_one config.yaml cli-config.yaml.example
seed_one SOUL.md docker/SOUL.md
[ -f "$HERMES_HOME/.env" ] && chmod 600 "$HERMES_HOME/.env" 2>/dev/null || true

if [ -d "$INSTALL_DIR/skills" ]; then
    "$INSTALL_DIR/.venv/bin/python" "$INSTALL_DIR/tools/skills_sync.py" \
        || echo "[hf-start] Warning: skills_sync.py failed; continuing"
fi

if [ -n "${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-}" ] && [ -n "${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}" ]; then
    echo "[hf-start] starting dashboard on 0.0.0.0:$PORT"
    "$INSTALL_DIR/.venv/bin/hermes" dashboard --host 0.0.0.0 --port "$PORT" --no-open &
else
    echo "[hf-start] HERMES_DASHBOARD_BASIC_AUTH_USERNAME/PASSWORD not set -> dashboard disabled, keep-alive listener only"
    "$INSTALL_DIR/.venv/bin/python" "$INSTALL_DIR/docker/keepalive_http.py" &
fi

echo "[hf-start] starting gateway"
exec "$INSTALL_DIR/.venv/bin/hermes" gateway run --no-supervise
