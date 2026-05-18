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

# 5. Start
docker compose up -d
docker compose logs -f
```

**Verify:**
```bash
curl http://localhost:11111/version
```

---

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | Docker Compose deployment |
| `.env.example` | Runtime env vars template |
| `FutuOpenD.xml.template` | Config template with env-var substitution |
| `secrets/` | Your config and keys (gitignored) |
| `docs/api.md` | API protocol documentation |
| `docs/configuration.md` | Full config reference |
| `docs/security.md` | Security hardening guide |

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

Then reference the locally built `shing1211/futuopend:latest` in the compose file.

---

*See [CONTRIBUTING.md](https://github.com/shing1211/futuopend/blob/main/CONTRIBUTING.md) to contribute.*
