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

### Can I run on Windows without WSL2?

Docker Desktop on Windows requires either **WSL2** (recommended) or the **Hyper-V backend**.

- **WSL2** is recommended — install from Windows Features or run `wsl --install` in PowerShell as admin
- **Hyper-V** requires Windows Pro/Enterprise and must be enabled in BIOS
- **Docker Desktop without WSL2 or Hyper-V** is not supported for Linux containers on Windows

Check Docker Desktop settings → General to see which backend is active.

---

## Configuration

### How do I set up my Futu account credentials?

As of v10.10+, FutuOpenD uses remember-login. No password needed in config.

**In `.env`, set only your account ID:**

```bash
FUTU_ACCOUNT=your_futu_id_or_email_or_phone
```

On first run, FutuOpenD enters interactive login mode. After successful login, credentials are cached in the Docker data volume and reused automatically on every restart.

### What is remember-login and how does it work?

FutuOpenD v10.10+ caches your login credentials locally after the first successful interactive login. On subsequent runs, it reuses the cached session automatically via `-login_by_remember=1`.

**Benefits:**
- No password in config files or environment variables
- One-time interactive login — subsequent restarts are fully automatic
- Credentials stored locally in the Docker data volume

**When re-verification is needed:**
- New IP or network (Futu detects new device)
- Futu resets device whitelist server-side
- Docker data volume was deleted

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

### Login keeps asking for verification code

This is normal behavior when Futu's server invalidates the cached device session:

- **What changed in v10.10+:** Remember-login caches credentials after first login. If Futu detects a new device/IP, it requires fresh verification.
- **Fix:** Submit the verification code via Telnet (see [First-Time Login](configuration.md#first-time-login-phone-verification-in-docker))
- **To prevent frequent re-verification:** Keep your Docker data volume (`futuopend-data`) — deleting it forces a fresh login

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
cp .env.example .env-a
cp .env.example .env-b
# set FUTU_ACCOUNT in each .env file
mkdir -p secrets-a secrets-b
# add RSA keys if trading:
# cp key_a.txt secrets-a/rsa_key.txt && chmod 600 secrets-a/rsa_key.txt
# cp key_b.txt secrets-b/rsa_key.txt && chmod 600 secrets-b/rsa_key.txt
docker compose -f docker-compose.multi.yaml up -d
```

| Instance | TCP Port | WebSocket Port |
|----------|----------|----------------|
| futuopend-a | 11113 | 11114 |
| futuopend-b | 21113 | 21114 |

### How do I monitor container health?

Use the monitoring stack:

```bash
docker compose -f docker-compose.monitoring.yaml up -d
```

Then access:
- **Grafana:** http://localhost:23000 (admin/admin)
- **Prometheus:** http://localhost:29090
- **cAdvisor metrics:** http://localhost:29091/metrics

The Grafana dashboard shows container memory, CPU, network I/O, restart count, and uptime.

> **Note:** Change the Grafana default password immediately after first login.

---

## Performance

### Memory usage seems high

The container is configured with a 512MB memory limit. FutuOpenD itself typically uses 200-400MB depending on market data volume.

If you see memory pressure:
1. Check the Grafana dashboard (if using monitoring stack)
2. Reduce Docker Desktop memory allocation if running on Mac/Windows
3. Consider using the Rocky Linux variant which may have different memory characteristics

### How to enable TLS for WebSocket?

WebSocket TLS options are set in your `FutuOpenD.xml.template` before container start. See [Configuration Reference](configuration.md) for the `<websocket_private_key>` and `<websocket_cert>` options.

---

## Security

### Is my password safe?

- As of v10.10+, no password stored in config — remember-login caches credentials locally
- The Docker data volume (`futuopend-data`) contains the cached session — treat it as sensitive
- Config files are gitignored and never committed
- Inside the container, FutuOpenD runs as a non-root user
- See [Security Hardening Guide](security.md) for full security recommendations

### How do I rotate my credentials?

To force a fresh login after changing your Futu password:

1. Delete the Docker data volume: `docker compose down -v` (this removes the cached session)
2. Restart the container: `docker compose up -d`
3. Complete the interactive login again (submit verification code if prompted)

The new password is cached automatically on next successful login.

### How to expose FutuOpenD over the internet?

> **WARNING:** Exposing FutuOpenD directly to the internet without protection is dangerous — your trading account could be compromised.

**Recommended approach — VPN:**

Use a VPN like [Tailscale](https://tailscale.com/) or [WireGuard](https://www.wireguard.com/) to create a private network. Your trading client connects through the VPN to the Docker host.

**Alternative — SSH tunnel:**

```bash
# On your trading client machine
ssh -L 11113:localhost:11113 user@your-docker-host
```

Then connect your trading client to `127.0.0.1:11113`.

**Do NOT:**
- Open port 11113/11114 directly in your firewall to the internet
- Use plain HTTP without VPN (credentials are transmitted insecurely)
- Forward ports via router NAT without authentication

### What markets and countries are supported?

FutuOpenD supports multiple markets depending on your Futu account type:

| Market | Code | Supported |
|--------|------|-----------|
| Hong Kong | HK | ✅ |
| United States | US | ✅ |
| China A-Share | CN | ✅ |
| Singapore | SG | ✅ |
| Australia | AU | ✅ |
| Japan | JP | ✅ |

Supported markets depend on your Futu account tier and regulatory approval. Check [Futu OpenAPI](https://openapi.futunn.com/) for the latest supported list.

---

## Configuration

### How do I check FutuOpenD version inside the container?

```bash
# List FutuOpenD directory contents
docker exec futuopend ls /FutuOpenD/

# Check version file if present
docker exec futuopend cat /FutuOpenD/version.txt

# Or check the binary version
docker exec futuopend /FutuOpenD/FutuOpenD --version
```

### How do I change the WebSocket push port?

By default, WebSocket pushes on port 11112 inside the container (mapped to 11114 on host).

To change the container-internal port:

1. Edit `FutuOpenD.xml.template` before starting the container:
   ```xml
   <ws_push_port>11115</ws_push_port>
   ```

2. Update the port mapping in `docker-compose.yaml`:
   ```yaml
   ports:
     - "11113:11111"
     - "11114:11115"  # change this
   ```

3. Restart:
   ```bash
   docker compose restart futuopend
   ```

---

## Troubleshooting

### Container keeps restarting — how to debug?

1. **Check logs for errors:**
   ```bash
   docker compose logs futuopend | tail -100
   ```

2. **Check the container's built-in config:**
   ```bash
   docker exec futuopend ls -l /usr/local/bin/FutuOpenD.xml
   ```

3. **Check disk space:**
   ```bash
   docker system df
   ```
   If the data volume is full, FutuOpenD may fail to start.

4. **Check memory limits:**
   ```bash
   docker stats futuopend --no-stream
   ```
   If memory is being throttled, increase the limit in `docker-compose.yaml`.

5. **Enable debug logging** by setting `FUTU_LOG_LEVEL=debug` in your `.env` before starting.

6. **Check if the process crashes immediately:**
   ```bash
   docker compose logs --tail 200 futuopend | grep -i "crash\|segfault\|signal"
   ```

### Can I use this with Home Assistant?

Yes. FutuOpenD acts as a local API server. Configure Home Assistant to connect to `127.0.0.1:11113` as the host.

In Home Assistant, you would typically add Futu as a custom integration or use a REST sensor with the FutuOpenD API. Since this varies by Home Assistant version and setup, refer to the [FutuOpenD API documentation](api.md) for protocol details.

### How do I migrate from native FutuOpenD to Docker?

1. **Backup your native FutuOpenD data** (if any):
   ```bash
   # Find the native data directory
   # Default: ~/.com.futunn.FutuOpenD/
   cp -r ~/.com.futunn.FutuOpenD ~/backup-futuopend-native/
   ```

2. **Stop the native FutuOpenD service:**
   ```bash
   # Windows: stop the FutuOpenD service via Services app
   # Linux: sudo systemctl stop futuopend
   ```

3. **Configure Docker:**
   - Copy `.env.example` to `.env` and set only `FUTU_ACCOUNT=your_futu_id`
   - No password needed — v10.10+ uses remember-login
   - Mount your RSA key at `secrets/rsa_key.txt` (required for trading)

4. **Start Docker container:**
   ```bash
   docker compose up -d
   ```

5. **Update your trading client** to connect to `127.0.0.1:11113` instead of the native port (likely 11111).

6. **Verify connection:**
   ```bash
   curl http://localhost:11113/version
   ```

7. **Import native data** (if applicable):
   ```bash
   docker compose stop
   # Copy backed up data into the volume
   docker run --rm -v futuopend-data:/data -v ~/backup-futuopend-native:/input alpine \
     sh -c "cp -r /input/* /data/"
   docker compose start
   ```

---

## Operations
