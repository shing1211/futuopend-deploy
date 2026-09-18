# FutuOpenD Deploy

> Run [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) — the local gateway for Futu's trading API — in Docker.

[![CI](https://github.com/shing1211/futuopend-deploy/actions/workflows/ci.yml/badge.svg)](https://github.com/shing1211/futuopend-deploy/actions/workflows/ci.yml)
[![FutuOpenD v10.11.7108](https://img.shields.io/badge/FutuOpenD-v10.11.7108-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)
[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-blue)](https://shing1211.github.io/futuopend-deploy/)

This repo provides **Docker Compose configurations** for running FutuOpenD. The image is built by the [futuopend](https://github.com/shing1211/futuopend) project.

---

## Quick Start

```bash
# 1. Pull or build the image
docker pull shing1211/futuopend:latest
# or build locally: cd ../futuopend && ./dockerbuild.sh ubuntu

# 2. Clone this repo & configure
cd futuopend-deploy
cp .env.example .env
# FIRST RUN only: log in interactively WITHOUT FUTU_ACCOUNT, then set it for restarts
#   docker compose run --rm -it -e FUTU_ACCOUNT= futuopend
# Every other run: set FUTU_ACCOUNT in .env (no password needed)

# 3. (Optional) Add RSA key for trading
# Generate at https://www.futunn.com/en/OpenAPI → Manage Key
# Save as secrets/rsa_key.txt, then chmod 600

# 4. (Optional) Set platform for ARM (Raspberry Pi)
echo "PLATFORM=arm64" >> .env

# 5. Start
docker compose up -d
docker compose logs -f
```

**Verify:**
```bash
curl http://localhost:11113/version
```

---

## Platform Options

The compose file uses `platform: linux/${PLATFORM:-amd64}`. Set `PLATFORM` in `.env`:

| Platform | Use Case |
|----------|----------|
| `linux/amd64` | x86_64 desktops, servers, cloud VMs (default) |
| `linux/arm64` | Raspberry Pi 3/4/5, ARM servers |

## Image Variants

Pull the variant that matches your platform:

| Image Tag | OS | Arch | When to use |
|-----------|-----|------|-------------|
| `:latest` | Ubuntu 26.04 | amd64 | Default |
| `:ubuntu-amd64` | Ubuntu 26.04 | amd64 | Explicit Ubuntu |
| `:ubuntu-arm64` | Ubuntu 26.04 | arm64 | Raspberry Pi |
| `:rocky-amd64` | Rocky Linux 9 | amd64 | RHEL-based preference |
| `:rocky-arm64` | Rocky Linux 9 | arm64 | ARM + RHEL compat |
| `:centos-amd64` | Rocky Linux 9 | amd64 | CentOS backward compat |
| `:centos-arm64` | Rocky Linux 9 | arm64 | ARM + CentOS compat |
| `:10.11.7108-*` | Both | Both | Version-pinned, e.g. `:10.11.7108-ubuntu-arm64` |

```bash
# Pull a specific variant
docker pull shing1211/futuopend:ubuntu-arm64

# Override image in .env (not set by default)
echo "FUTU_IMAGE=shing1211/futuopend:rocky-amd64" >> .env
```

**ARM performance note:** Futu provides x86_64 binaries only. ARM builds use QEMU
emulation (~2-5x slower than native). For latency-sensitive trading on Pi, consider
[box64](https://github.com/ptitSeb/box64) — install it on the host and the container
uses it automatically.

## Compose Variants

Choose the file that matches your use case:

| File | Use Case | Command |
|------|----------|---------|
| `docker-compose.yaml` | Single futuopend instance (default) | `docker compose up -d` |
| `docker-compose.multi.yaml` | High Availability — two instances with automatic failover | `docker compose -f docker-compose.multi.yaml up -d` |
| `docker-compose.monitoring.yaml` | Monitoring add-on — Prometheus + Grafana + cAdvisor | `docker compose -f docker-compose.monitoring.yaml up -d` |

**Note:** The multi-instance deployment runs two independent futuopend containers
(ports 11113 and 21113) for HA scenarios. Both instances share the same Docker host
but have separate configs, volumes, and networks.

**Combine futuopend + monitoring:**
```bash
docker compose -f docker-compose.yaml -f docker-compose.monitoring.yaml up -d
```

---

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | Single-instance deployment (default) |
| `docker-compose.multi.yaml` | High Availability deployment (two instances) |
| `docker-compose.monitoring.yaml` | Monitoring stack (Prometheus + Grafana + cAdvisor) |
| `.env.example` | Runtime env vars template |
| `FutuOpenD.xml.template` | Config template with env-var substitution |
| `secrets/` | Your config and keys (gitignored) |
| `scripts/monitor.sh` | Health monitor with auto-restart |
| `scripts/backup.sh` | Backup/restore persistent data |
| `docs/api.md` | API protocol documentation |
| `docs/configuration.md` | Full config reference |
| `docs/security.md` | Security hardening guide |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/monitor.sh` | Health monitor — one-shot check or `--watch` loop, auto-restart on failure |
| `scripts/backup.sh` | Backup/restore persistent data volume |

## Multi-Instance

Run two accounts side-by-side:

```bash
cp .env.example .env-a
cp .env.example .env-b
# edit FUTU_ACCOUNT in each .env file
mkdir -p secrets-a secrets-b
# mount RSA keys if trading:
# cp key_a.txt secrets-a/rsa_key.txt && chmod 600 secrets-a/rsa_key.txt
# cp key_b.txt secrets-b/rsa_key.txt && chmod 600 secrets-b/rsa_key.txt
docker compose -f docker-compose.multi.yaml up -d
```

Instance `a` uses ports 11113/11114, instance `b` uses 21113/21114.

---

## Documentation

- [API Protocol Reference](docs/api.md)
- [Configuration Reference](docs/configuration.md)
- [Security Hardening Guide](docs/security.md)

---

## Troubleshooting

**Container fails to start with "FutuOpenD not found"**
- Make sure you have pulled the image: `docker pull shing1211/futuopend:latest`
- Verify your `.env` has `FUTU_ACCOUNT` set: `grep FUTU_ACCOUNT .env`

**Health check failing on ARM (Raspberry Pi)**
- ARM builds use QEMU emulation and may take longer to start. Increase `start_period` in the compose file.
- For latency-sensitive trading on Pi, consider installing [box64](https://github.com/ptitSeb/box64) on the host.

**Connection refused on ports 11113/11114**
- Check the container is running: `docker compose ps`
- Check logs: `docker compose logs futuopend`
- Verify ports are not in use: `lsof -i :11113`

**Invalid MD5 password hash**
- Ensure your password hash is 32 hex characters (no spaces or newlines)
- Linux: `echo -n "password" | md5sum | cut -d' ' -f1`
- macOS: `md5 -s "password"`
- Windows: Use an online MD5 generator or PowerShell

**RSA key not accepted for trading**
- Ensure the key file is mounted at `/run/secrets/rsa_key.txt` inside the container
- Verify file permissions are 600: `chmod 600 secrets/rsa_key.txt`

---

## Building from Source

To build your own image instead of pulling from Docker Hub:

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend
./dockerbuild.sh ubuntu
```

Then reference the locally built image:
```bash
echo "FUTU_IMAGE=shing1211/futuopend:latest" >> .env
```

---

## Support

Ask questions and get help from the community via [GitHub Discussions](https://github.com/shing1211/futuopend-deploy/discussions).

Report bugs and issues using the [issue tracker](https://github.com/shing1211/futuopend-deploy/issues).

## Contributing

*See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.*
