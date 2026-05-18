# FutuOpenD Deploy

> Run [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) — the local gateway for Futu's trading API — in Docker.

[![FutuOpenD v10.5.6508](https://img.shields.io/badge/FutuOpenD-v10.5.6508-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

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
# edit .env with your Futu account credentials

# 3. Create config from template
mkdir -p secrets
cp FutuOpenD.xml.template secrets/FutuOpenD.xml
# edit secrets/FutuOpenD.xml with your settings

# 4. (Optional) Add RSA key for trading
# Generate at https://www.futunn.com/en/OpenAPI → Manage Key
# Save as secrets/rsa_key.txt, then chmod 600

# 5. (Optional) Set platform for ARM (Raspberry Pi)
echo "PLATFORM=linux/arm64" >> .env

# 6. Start
docker compose up -d
docker compose logs -f
```

**Verify:**
```bash
curl http://localhost:11111/version
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
| `:latest` | Ubuntu 24.04 | amd64 | Default |
| `:ubuntu-amd64` | Ubuntu 24.04 | amd64 | Explicit Ubuntu |
| `:ubuntu-arm64` | Ubuntu 24.04 | arm64 | Raspberry Pi |
| `:rocky-amd64` | Rocky Linux 9 | amd64 | RHEL-based preference |
| `:rocky-arm64` | Rocky Linux 9 | arm64 | ARM + RHEL compat |
| `:centos-amd64` | Rocky Linux 9 | amd64 | CentOS backward compat |
| `:centos-arm64` | Rocky Linux 9 | arm64 | ARM + CentOS compat |
| `:10.5.6508-*` | Both | Both | Version-pinned, e.g. `:10.5.6508-ubuntu-arm64` |

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

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | Docker Compose deployment |
| `docker-compose.multi.yaml` | Multi-instance deployment (two accounts) |
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
mkdir -p secrets-a secrets-b
cp FutuOpenD.xml.template secrets-a/FutuOpenD.xml
cp FutuOpenD.xml.template secrets-b/FutuOpenD.xml
# edit each config with different accounts
docker compose -f docker-compose.multi.yaml up -d
```

Instance `a` uses ports 11111/11112, instance `b` uses 21111/21112.

---

## Documentation

- [API Protocol Reference](docs/api.md)
- [Configuration Reference](docs/configuration.md)
- [Security Hardening Guide](docs/security.md)

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

*See [CONTRIBUTING.md](https://github.com/shing1211/futuopend/blob/main/CONTRIBUTING.md) to contribute.*
