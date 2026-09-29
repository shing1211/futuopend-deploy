#!/bin/bash
#
# Backup or restore futuopend persistent data volume.
# Usage: ./scripts/backup.sh                         # create backup
#        ./scripts/backup.sh --restore FILE.tar.gz   # restore from backup
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Drive the same compose file that actually started the container. A local
# override file is a common setup; using the default file instead would stop and
# restart a differently-configured container.
if [ -f "$SCRIPT_DIR/docker-compose.local.yaml" ]; then
    COMPOSE=(docker compose -f docker-compose.local.yaml)
else
    COMPOSE=(docker compose)
fi

cd "$SCRIPT_DIR"

# Resolve the real volume name. Compose prefixes it with the project name
# (e.g. futuopend-data -> futuopend-deploy_futuopend-data), so the logical name
# in the compose file does not exist as a volume: `docker run -v <logical>:/data`
# would silently create a brand-new empty volume and archive nothing.
resolve_volume() {
    local project
    project="$("${COMPOSE[@]}" config --format json 2>/dev/null \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("name",""))' 2>/dev/null)"
    [ -n "$project" ] || project="$(basename "$SCRIPT_DIR")"
    docker volume ls -q \
        --filter "label=com.docker.compose.project=$project" \
        --filter "label=com.docker.compose.volume=futuopend-data" | head -1
}

VOLUME="${FUTU_VOLUME:-$(resolve_volume)}"
if [ -z "$VOLUME" ]; then
    echo "Error: could not resolve the futuopend data volume." >&2
    echo "  Looked for a volume with project label and compose volume 'futuopend-data'." >&2
    echo "  If the volume has a different name, pass it explicitly:" >&2
    echo "      $0 --volume <name>" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

usage() {
    cat <<EOF
Usage: $0 [--restore FILE.tar.gz] [--volume NAME]

  (no args) or backup  create a backup of the futuopend data volume
  --restore FILE       restore the volume from a previous archive
  --volume NAME        override the volume name (default: auto-detected)

Override via environment instead: FUTU_VOLUME=<name>
EOF
    exit 1
}

do_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local archive="$BACKUP_DIR/futuopend-data-$timestamp.tar.gz"

    echo "==> Backing up volume '$VOLUME'..."
    echo "    Archive: $archive"

    # The volume must be quiescent for a consistent archive (it holds live
    # SQLite files), so stop the gateway first. Restart it on any exit path --
    # with 'set -e', a failure between down and up would otherwise leave the
    # gateway down.
    trap '"${COMPOSE[@]}" up -d >/dev/null 2>&1 || true' EXIT
    "${COMPOSE[@]}" down

    docker run --rm \
        -v "${VOLUME}:/data:ro" \
        -v "$BACKUP_DIR:/backup" \
        alpine tar -czf "/backup/$(basename "$archive")" -C /data .

    trap - EXIT
    "${COMPOSE[@]}" up -d

    echo ""
    echo "==> Backup complete: $archive"
    echo "    Size: $(du -h "$archive" | cut -f1)"
    echo "    Verify with: tar tzf $archive | head"
    echo "    Restore with: $0 --restore $archive"
}

do_restore() {
    local archive="$1"

    if [ ! -f "$archive" ]; then
        echo "Error: backup file not found: $archive" >&2
        exit 1
    fi

    echo "==> Restoring volume '$VOLUME' from $archive..."

    # Same reason as backup: trap so a failed restore still leaves it running.
    trap '"${COMPOSE[@]}" up -d >/dev/null 2>&1 || true' EXIT
    "${COMPOSE[@]}" down

    docker run --rm \
        -v "${VOLUME}:/data" \
        -v "$BACKUP_DIR:/backup" \
        alpine sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null; tar -xzf \"/backup/$(basename "$archive")\" -C /data"

    trap - EXIT
    "${COMPOSE[@]}" up -d

    echo "==> Restore complete."
}

case "${1:-}" in
    --restore)
        [ -z "${2:-}" ] && usage
        do_restore "$2"
        ;;
    --volume)
        VOLUME="${2:-}"
        [ -z "$VOLUME" ] && usage
        echo "==> Using volume '$VOLUME'"
        do_backup
        ;;
    --help|-h)
        usage
        ;;
    "")
        do_backup
        ;;
    backup)
        # The no-arg form above is the documented one, but `backup` is what people
        # reach for first, so accept it rather than printing usage.
        do_backup
        ;;
    *)
        usage
        ;;
esac
