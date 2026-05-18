#!/bin/bash
#
# Backup or restore futuopend persistent data volume.
# Usage: ./scripts/backup.sh                         # create backup
#        ./scripts/backup.sh --restore FILE.tar.gz   # restore from backup
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
VOLUME="futuopend-data"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yaml"

mkdir -p "$BACKUP_DIR"

usage() {
    echo "Usage: $0 [--restore FILE.tar.gz]"
    exit 1
}

do_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local archive="$BACKUP_DIR/futuopend-data-$timestamp.tar.gz"

    echo "==> Backing up volume '$VOLUME'..."
    echo "    Archive: $archive"

    cd "$SCRIPT_DIR"
    docker compose down

    docker run --rm \
        -v "${VOLUME}:/data" \
        -v "$(pwd)/backups:/backup" \
        alpine tar -czf "/backup/$(basename "$archive")" -C /data .

    docker compose up -d

    echo ""
    echo "==> Backup complete: $archive"
    echo "    Size: $(du -h "$archive" | cut -f1)"
    echo "    Restore with: $0 --restore $archive"
}

do_restore() {
    local archive="$1"

    if [ ! -f "$archive" ]; then
        echo "Error: backup file not found: $archive" >&2
        exit 1
    fi

    echo "==> Restoring volume '$VOLUME' from $archive..."

    cd "$SCRIPT_DIR"
    docker compose down

    docker run --rm \
        -v "${VOLUME}:/data" \
        -v "$(pwd)/backups:/backup" \
        alpine sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null; tar -xzf \"/backup/$(basename "$archive")\" -C /data"

    docker compose up -d

    echo "==> Restore complete."
}

case "${1:-}" in
    --restore)
        [ -z "${2:-}" ] && usage
        do_restore "$2"
        ;;
    --help|-h)
        usage
        ;;
    "")
        do_backup
        ;;
    *)
        usage
        ;;
esac
