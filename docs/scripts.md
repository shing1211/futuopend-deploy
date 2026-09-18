# Scripts

## monitor.sh

Health monitor with auto-restart capability.

### One-shot check

```bash
./scripts/monitor.sh
```

Exits `0` if healthy, `1` if FutuOpenD process is not running.

### Watch mode

```bash
./scripts/monitor.sh --watch
```

Continuously monitors and restarts the container if the health check fails.

### Options

| Option | Description |
|--------|-------------|
| `--watch` | Continuous monitoring loop |
| `--interval SECONDS` | Check interval (default: 30) |
| `--restart` | Auto-restart container on failure |

## backup.sh

Backup and restore persistent data volume.

### Backup

```bash
./scripts/backup.sh backup
```

Creates a timestamped tarball of the data volume in `backups/`.

### Restore

```bash
./scripts/backup.sh restore backups/futuopend-data-20260101-120000.tar.gz
```

### List backups

```bash
./scripts/backup.sh list
```
