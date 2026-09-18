# Frequently Asked Questions

> Common questions about FutuOpenD Docker deployment. For API-related questions, see [Futu OpenAPI Support](https://openapi.futunn.com/).

## Installation & Setup

### What are the default ports?

| Port | Protocol | Description |
|------|----------|-------------|
| `11113` | TCP | Main trading and quote API |
| `11114` | WebSocket | Real-time push, web clients |
| `22222` | Telnet | Debug console (internal) |

> **Note:** Docker container ports were remapped from `11111/11112` to `11113/11114` in v1.0.1 to avoid conflict with native FutuOpenD installations.

### How do I check if the container is running?

```bash
docker compose ps
```

The status should show `(healthy)` under STATUS.

### How do I view logs?

```bash
# All logs
docker compose logs futuopend

# Follow in real-time
docker compose logs -f futuopend

# Last 100 lines
docker compose logs --tail 100 futuopend
```

---

## Configuration

### How do I set up my Futu account credentials?

**Option A: Via `.env` file (recommended)**

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set:
   ```bash
   FUTU_ACCOUNT=your_email_or_phone
   FUTU_PWD_MD5=your_md5_hashed_password
   ```

3. The `FutuOpenD.xml.template` automatically substitutes `${FUTU_ACCOUNT}` and `${FUTU_PWD_MD5}` from your `.env`.

**Option B: Directly editing `FutuOpenD.xml`**

1. Copy the template: `cp FutuOpenD.xml.template secrets/FutuOpenD.xml`
2. Edit `secrets/FutuOpenD.xml` directly:
   ```xml
   <login_account>your_email_or_phone</login_account>
   <login_pwd_md5>your_md5_hashed_password</login_pwd_md5>
   ```

### How do I generate an MD5 hash for my password?

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
md5 -s "your_password"

# PowerShell
[System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes("your_password")) | ForEach-Object { $_.ToString("x2") } | Join-String
```

The result should be a 32-character hex string.

### How do I set up RSA key for trading?

1. Generate an RSA key at [Futu OpenAPI](https://www.futunn.com/en/OpenAPI) → Manage Key
2. Save the private key as `secrets/rsa_key.txt`
3. Set permissions: `chmod 600 secrets/rsa_key.txt`
4. The compose file mounts it automatically at `/run/secrets/rsa_key.txt`

---

## Troubleshooting

### Port 11113 not responding

1. **Check container is running:**
   ```bash
   docker compose ps
   ```

2. **Check logs for errors:**
   ```bash
   docker compose logs futuopend | grep -i error
   ```

3. **Verify port is open:**
   ```bash
   # Windows
   Test-NetConnection -ComputerName localhost -Port 11113

   # Linux/macOS
   nc -zv localhost 11113
   ```

4. **Check if another process is using the port:**
   ```bash
   # Windows
   netstat -ano | Select-String ":11113"

   # Linux
   lsof -i :11113
   ```

### ARM build slow on Raspberry Pi

**This is expected.** Futu provides x86_64 binaries only. ARM builds use QEMU emulation which is 2-5x slower than native execution.

**Solutions:**
- Increase `start_period` in `docker-compose.yaml` to 120s
- Consider installing [box64](https://github.com/ptitSeb/box64) on your Pi for native-like performance

### Health check failing

The health check uses `pgrep -x FutuOpenD` to verify the process is running.

1. **Check if process is running inside container:**
   ```bash
   docker exec futuopend pgrep -x FutuOpenD
   ```

2. **Increase health check timeouts** in `docker-compose.yaml`:
   ```yaml
   healthcheck:
     start_period: 120s  # increase from 60s
     interval: 30s
     timeout: 15s
     retries: 5
   ```

3. **Check logs for startup issues:**
   ```bash
   docker compose logs futuopend | tail -50
   ```

### RSA key not accepted for trading

1. Ensure the key file is mounted at the correct path:
   ```bash
   docker exec futuopend ls -la /run/secrets/
   ```

2. Verify file permissions inside container are 600:
   ```bash
   docker exec futuopend ls -la /run/secrets/rsa_key.txt
   ```

3. Ensure the key format is correct (PEM format, starts with `-----BEGIN RSA PRIVATE KEY-----`)

### Invalid MD5 password hash

- Ensure the hash is exactly 32 hex characters with no spaces, newlines, or prefixes
- The hash is case-insensitive
- On Windows, ensure there are no hidden characters (use a plain text editor)

---

## Operations

### How do I update FutuOpenD to the latest version?

```bash
# Pull the latest image
docker pull shing1211/futuopend:latest

# Restart the container
docker compose up -d futuopend
```

### How do I backup my data?

**Using the backup script:**
```bash
# Create a backup
./scripts/backup.sh backup

# List existing backups
./scripts/backup.sh list

# Restore from a backup
./scripts/backup.sh restore backups/futuopend-data-20260918-120000.tar.gz
```

**Manual backup:**
```bash
docker run --rm \
  -v futuopend-data:/data \
  -v $(pwd):/output \
  alpine:latest \
  tar czf /output/backup-$(date +%Y%m%d).tar.gz -C /data .
```

### How do I run multiple instances?

Use `docker-compose.multi.yaml` for two accounts side-by-side:

```bash
mkdir -p secrets-a secrets-b
cp FutuOpenD.xml.template secrets-a/FutuOpenD.xml
cp FutuOpenD.xml.template secrets-b/FutuOpenD.xml
# edit both configs with different accounts
docker compose -f docker-compose.multi.yaml up -d
```

| Instance | TCP Port | WebSocket Port |
|----------|----------|----------------|
| futuopend-a | 11113 | 11114 |
| futuopend-b | 21113 | 21114 |

---

## Performance

### Memory usage seems high

The container is configured with a 512MB memory limit. FutuOpenD itself typically uses 200-400MB depending on market data volume.

If you see memory pressure:
1. Check the Grafana dashboard (if using monitoring stack)
2. Reduce Docker Desktop memory allocation if running on Mac/Windows
3. Consider using the Rocky Linux variant which may have different memory characteristics

### How to enable TLS for WebSocket?

Edit `secrets/FutuOpenD.xml` and set the WebSocket TLS options. See [Configuration Reference](configuration.md) for details.

---

## Security

### Is my password safe?

- Passwords are stored as MD5 hashes (one-way, not reversible)
- Config files are gitignored and never committed
- Inside the container, FutuOpenD runs as a non-root user
- See [Security Hardening Guide](security.md) for full security recommendations

### How do I rotate my credentials?

1. Update your password at [Futu OpenAPI](https://www.futunn.com/en/OpenAPI)
2. Generate new MD5 hash
3. Update `.env` or `secrets/FutuOpenD.xml`
4. Restart the container: `docker compose restart futuopend`
