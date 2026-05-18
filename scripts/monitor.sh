#!/bin/bash
#
# Monitor FutuOpenD container health.
# Usage: ./scripts/monitor.sh                     # one-shot check
#        ./scripts/monitor.sh --watch             # loop every 60s
#        ./scripts/monitor.sh --watch --interval 30  # custom interval
#
set -euo pipefail

CONTAINER="futuopend"
COMPOSE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEBHOOK_URL="${WEBHOOK_URL:-}"
INTERVAL=60
WATCH=false

usage() {
    echo "Usage: $0 [--watch] [--interval N]"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --watch) WATCH=true; shift ;;
        --interval) INTERVAL="${2:-60}"; shift 2 ;;
        *) usage ;;
    esac
done

check() {
    local status
    status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)

    case "$status" in
        healthy)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK — $CONTAINER is healthy"
            return 0
            ;;
        unhealthy)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] UNHEALTHY — $CONTAINER health check failed"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarting $CONTAINER..."
            cd "$COMPOSE_DIR" && docker compose restart "$CONTAINER"
            if [ -n "$WEBHOOK_URL" ]; then
                curl -s -X POST "$WEBHOOK_URL" \
                    -H "Content-Type: application/json" \
                    -d "{\"text\":\"FutuOpenD unhealthy — restarted\"}" >/dev/null 2>&1 || true
            fi
            return 1
            ;;
        starting)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTING — $CONTAINER still starting"
            return 0
            ;;
        "")
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] STOPPED — $CONTAINER is not running"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting $CONTAINER..."
            cd "$COMPOSE_DIR" && docker compose up -d
            if [ -n "$WEBHOOK_URL" ]; then
                curl -s -X POST "$WEBHOOK_URL" \
                    -H "Content-Type: application/json" \
                    -d "{\"text\":\"FutuOpenD was stopped — restarted\"}" >/dev/null 2>&1 || true
            fi
            return 1
            ;;
        *)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] UNKNOWN — $status"
            return 1
            ;;
    esac
}

if $WATCH; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Monitoring $CONTAINER every ${INTERVAL}s..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Webhook: ${WEBHOOK_URL:-(none)}"
    echo ""
    while true; do
        check
        sleep "$INTERVAL"
    done
else
    check
fi
