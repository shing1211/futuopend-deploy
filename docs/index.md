# FutuOpenD Deploy

> Run [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) — the local gateway for Futu's trading API — in Docker.

[![CI](https://github.com/shing1211/futuopend-deploy/actions/workflows/ci.yml/badge.svg)](https://github.com/shing1211/futuopend-deploy/actions/workflows/ci.yml)
[![FutuOpenD v10.8.6808](https://img.shields.io/badge/FutuOpenD-v10.8.6808-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/shing1211/futuopend-deploy/blob/main/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)
[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-blue)](https://shing1211.github.io/futuopend-deploy/)

This repo provides **Docker Compose configurations** for running FutuOpenD. The image is built by the [futuopend](https://github.com/shing1211/futuopend) project.

## Features

- Single and multi-instance deployment via Docker Compose
- Support for both x86_64 (amd64) and ARM (arm64) architectures
- Multiple image variants: Ubuntu, Rocky Linux, CentOS
- Environment variable-based configuration
- Health monitoring with auto-restart
- Backup and restore scripts for persistent data

## Quick Start

See the [Quick Start](quick-start.md) guide to get up and running.

## Documentation

- [Quick Start Guide](quick-start.md)
- [Platform Options](platform-options.md)
- [Image Variants](image-variants.md)
- [Scripts Reference](scripts.md)
- [Multi-Instance Deployment](multi-instance.md)
- [API Protocol Reference](api.md)
- [Configuration Reference](configuration.md)
- [Security Hardening Guide](security.md)

## Support

Ask questions via [GitHub Discussions](https://github.com/shing1211/futuopend-deploy/discussions).
Report bugs using the [issue tracker](https://github.com/shing1211/futuopend-deploy/issues).

## Troubleshooting

**Container fails to start with "FutuOpenD not found"**

Make sure you have pulled the image:

```bash
docker pull shing1211/futuopend:latest
```

Verify your `secrets/FutuOpenD.xml` is readable:

```bash
ls -la secrets/
```

**Health check failing on ARM (Raspberry Pi)**

ARM builds use QEMU emulation and may take longer to start. Increase `start_period` in the compose file.

For latency-sensitive trading on Raspberry Pi, consider installing [box64](https://github.com/ptitSeb/box64) on the host.

**Connection refused on ports 11113/11114**

Check the container is running:

```bash
docker compose ps
```

Check logs:

```bash
docker compose logs futuopend
```

Verify ports are not in use:

```bash
lsof -i :11113
```

**Remember-login keeps prompting for verification**

Normal on first run or after a network change. Submit the code via Telnet — see [First-Time Login](configuration.md#first-time-login-phone-verification-in-docker).

**RSA key not accepted for trading**

Ensure the key file is mounted at `/run/secrets/rsa_key.txt` inside the container and has permissions 600:

```bash
chmod 600 secrets/rsa_key.txt
```
