# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- CI validates every profile, not just the default -- a typo inside a profiled service was previously invisible -- and asserts that no published port defaults to a non-loopback address.
- `docs/configuration.md`: the login prompts arrive on **two different channels** -- the account prompt is printed to stdout and read from stdin, while the password and verification prompts are delivered only to telnet clients. Without a published telnet port the first login appears to hang after the account is entered, with no error and no timeout. The documented command now works.
- `docs/configuration.md` and `docs/faq.md`: a "verify the login actually worked" step. A listening port does not mean the session authenticated, since the port opens before login completes; check FutuOpenD's `Login successful` log and a per-account `GTWLog_<account>_` file rather than `GTWLog_0_`.
- `docs/faq.md`: crash-looping entry framed as an account-safety issue -- each restart consumes a Futu login attempt, and enough of them can lock the account. Includes a table mapping each distinct log message to its fix.
- `docs/security.md`: SSH tunnel vs. RSA comparison, including that the RSA private key is a **shared secret** every client must hold, and that clients must pass `is_encrypt=True` (it defaults to `None`, which resolves to disabled, so a client that forgets connects in plaintext with no error).
- CI: validates bind-mount sources, catching a `FutuOpenD.xml` directory and an enabled-but-missing RSA key.

### Changed

- **Breaking:** the three compose files are merged into a single `docker-compose.yaml`, selected by profile. Update any command that referenced the old files:
  - `docker compose -f docker-compose.multi.yaml up -d` -> `docker compose --profile multi up -d`
  - `docker compose -f docker-compose.monitoring.yaml up -d` -> `docker compose --profile monitoring up -d`
  - combining them -> `docker compose --profile multi --profile monitoring up -d`

  The default single-instance run is unchanged: services behind a `profiles:`
  key stay inert until that profile is enabled.
- **Breaking:** all published ports in every profile now bind to `127.0.0.1` by default. This includes the `multi` instances, whose API and telnet ports were previously on `0.0.0.0`, and the monitoring stack, whose Prometheus (`29090`), Grafana (`23000`) and cAdvisor (`29091`) ports were on all interfaces. Set `FUTU_API_BIND=0.0.0.0` for direct access, or reach them over an SSH tunnel.
- **Breaking:** `FUTU_RSA_KEY` now defaults to empty instead of `/run/secrets/rsa_key.txt`. The RSA mount is commented out in the default profile, so the old default pointed at a path that was never mounted -- harmless at runtime (OpenD reports `API RSA Enabled: No`) but a silent way to believe RSA was on when it was not.
- Per-instance port overrides are now available for the `multi` profile: `FUTU_API_PORT_A` / `FUTU_API_PORT_B`, `FUTU_WS_PORT_A` / `FUTU_WS_PORT_B`, `FUTU_TELNET_PORT_A` / `FUTU_TELNET_PORT_B`, plus `PROMETHEUS_PORT`, `CADVISOR_PORT` and `GRAFANA_PORT`.
- `.env.example`: documents `FUTU_NO_MONITOR`, which the entrypoint already read but which was never listed, and clarifies that `FUTU_TELNET_IP` binds inside the container while `FUTU_TELNET_BIND` controls host exposure.

### Removed

- `docker-compose.multi.yaml` and `docker-compose.monitoring.yaml`, folded into `docker-compose.yaml` as the `multi` and `monitoring` profiles. `docs/multi-instance.md` is retained and updated.

### Fixed

- `FutuOpenD.xml` is mounted with `bind.create_host_path: false` in every profile, so a missing config file is a hard error instead of a silently created directory that leaves FutuOpenD unable to start.
- Dropped the `pgrep -x FutuOpenD` healthcheck override everywhere so the image's TCP probe applies. `pgrep` reports healthy for a process that is alive but not serving -- hung on a login prompt, or bound to nothing.
- `multi` profile: dropped the `pgrep -x FutuOpenD` healthcheck override, which reported healthy for a process that was alive but not serving. The image ships a TCP probe of the API port; the override was re-introducing the weak check.
- `multi` profile: `FutuOpenD.xml` is now mounted with `create_host_path: false`, so a missing config file is a hard error rather than a silently created directory.
- `scripts/verify_code.sh`: `nc` closed the connection as soon as stdin reached EOF, so a verification code was sent but the reply was usually lost and the operator could not tell whether it had been accepted. The raw-netcat examples in the docs also sent a bare `\n` where the telnet parser needs `\r\n`.
- `docs/quick-start.md`: step 4 was titled "Start" but contained a second copy of the RSA instructions and no start command.
- `docs/security.md`: removed a duplicated Firewall section and the now-superseded "Local binding" / "Remote access" sections. WebSocket TLS guidance is kept and rescoped to WebSocket, since the TCP API uses FutuOpenD's own RSA/AES scheme.

### Migration

Existing `.env` files need one of:
- nothing, if loopback + SSH tunnel is acceptable (the new default);
- `FUTU_API_BIND=0.0.0.0` plus an RSA key, for direct remote access; or
- the `secrets/rsa_key.txt` volume uncommented and `FUTU_RSA_KEY=/run/secrets/rsa_key.txt`, to restore RSA.

`FutuOpenD.xml` must exist as a file: `cp FutuOpenD.xml.template FutuOpenD.xml`.

---

## [1.1.0] - 2026-09-18

### Fixed

- `docker-compose.yaml` / `docker-compose.multi.yaml`: re-added the `./FutuOpenD.xml` config mount (dropped in 1.0.6), so the env-substituted template is actually read by OpenD.
- `docker-compose.multi.yaml`: instance B now publishes Telnet on `22223` (was `22222`, colliding with instance A).
- Config is rendered by the container entrypoint via `envsubst`: `FutuOpenD.xml.template` now uses `${VAR}` (no `:-default`) and `docker-compose*.yaml` supply defaults, because FutuOpenD does not expand environment variables.

### Changed

- `FutuOpenD.xml.template`: `<ip>` and `<telnet_ip>` default to `0.0.0.0`, and `<telnet_port>` is enabled by default — required for host port mapping and first-login 2FA.
- `.env.example`: added `FUTU_IP`, `FUTU_TELNET_IP`, `FUTU_TELNET_PORT`, `FUTU_RSA_KEY`.
- Docs: corrected the config path (`/usr/local/bin/FutuOpenD.xml`), documented the two-phase first login (interactive first, then `FUTU_ACCOUNT`), and added a host-network workaround note.

### Added

- `scripts/verify_code.sh` — submit SMS/CAPTCHA verification codes over the Telnet interface.

## [1.0.6] - 2026-09-18

### Changed

- **Breaking:** FutuOpenD v10.10+ removed `<login_account>` and `<login_pwd_md5>` from `FutuOpenD.xml`. Credentials are now passed via `--login_account` CLI argument with `--login_by_remember=1`. Only `FUTU_ACCOUNT` env var is required (no password).
- `FutuOpenD.xml.template`: removed deprecated `<login_account>` and `<login_pwd_md5>` fields
- `.env.example`: removed `FUTU_PWD_MD5` variable and MD5 generation instructions
- `docker-compose.yaml` and `docker-compose.multi.yaml`: removed `secrets/FutuOpenD.xml` volume mount, added `22222:22222` port (Telnet)
- Dockerfiles: added `EXPOSE 22222` for Telnet interface
- `entrypoint.sh`: now passes `--login_account="${FUTU_ACCOUNT}" --login_by_remember=1` to FutuOpenD

### Added

- Telnet port 22222 now exposed in all compose files for phone/CAPTCHA verification
- Documentation: updated phone verification guide with remember-login flow, CAPTCH support, and troubleshooting

### Deprecated

- `FUTU_PWD_MD5` environment variable — no longer used

## [1.0.5] - 2026-09-18

### Added

- Custom SVG logo and favicon (blue container whale icon)
- Custom 404 not-found page with navigation links
- "Edit this page" links on all documentation pages
- Version announcement banner (v1.0.4 release notes link)
- Social links footer (GitHub repo + sponsor link)

### Changed

- mkdocs.yml: navigation.top feature added
- mkdocs.yml: announcement.dismiss feature added

## [1.0.4] - 2026-09-18

### Added

- 8 new FAQ entries covering Windows/WSL2, version checking, Home Assistant integration,
  remote access security, supported markets, WebSocket port configuration, crash loop debugging,
  and native-to-Docker migration
- 7 new Grafana dashboard panels: Uptime, Memory Working Set, Disk I/O Read/Write,
  CPU Throttling, Process Count, Data Volume Size
- Prometheus alerting rules: FutuOpenDCrashLoop, FutuOpenDMemoryHigh, FutuOpenDCPUThrottling,
  FutuOpenDDown, FutuOpenDNetworkErrors
- Grafana alerting contact point documentation in CONTRIBUTING.md
- Monitoring stack alert rules loaded by Prometheus

### Fixed

- Monitoring stack ports remapped to uncommon ranges (29090/29091/23000) to avoid conflicts
- cAdvisor updated from v0.49.0 to v0.51.0 (v0.49.0 no longer available at gcr.io)

### Changed

- README now documents all 3 compose file variants with use cases and descriptions
- Grafana dashboard expanded from 6 to 13 panels (version bump to 2)
- Prometheus configured to load alerting rules via `rule_files`

## [1.0.3] - 2026-09-18

### Added

- Monitoring stack (`docker-compose.monitoring.yaml`) with Prometheus + Grafana + cAdvisor
- Pre-built Grafana dashboard for FutuOpenD container health
- FAQ documentation page (`docs/faq.md`) covering common questions
- Docs preview workflow for PRs
- Nightly backup automation workflow (GitHub Actions)
- Prometheus configuration for container metrics scraping

### Changed

- FAQ added to documentation navigation

## [1.0.2] - 2026-09-18

### Security

- Added Trivy container vulnerability scanning to CI
- Added CodeQL security scanning workflow
- Added Dependabot for GitHub Actions auto-updates

### Changed

- Docker Compose hardened: resource limits (512M memory), logging rotation (10m/3 files), custom bridge networks
- Both `docker-compose.yaml` and `docker-compose.multi.yaml` updated with security hardening

## [1.0.1] - 2026-09-18

### Changed

- **Breaking:** Docker container ports remapped from `11111/11112` to `11113/11114` to avoid conflict with native FutuOpenD installations. Update your trading client to connect to `127.0.0.1:11113` instead.

### Fixed

- Multi-instance deployment port numbers corrected in documentation
- CI workflow simplified to use Docker Compose v2 built-in (no manual installation)
- mkdocs build issues fixed (removed broken extension, added missing plugin)

### Added

- Architecture diagram documentation (`docs/architecture.md`)
- `.yamllint.yaml` configuration for YAML linting in CI
- Troubleshooting section in documentation
- Support link and Docker pulls badge in README
- OCI labels on Docker Compose services

## [1.0.0] - 2026-09-18

### Added

- Initial release of futuopend-deploy
- `docker-compose.yaml` for single-instance FutuOpenD deployment
- `docker-compose.multi.yaml` for multi-instance deployment (two accounts)
- `FutuOpenD.xml.template` with environment variable substitution support
- `.env.example` with all configurable environment variables
- `scripts/monitor.sh` for health monitoring and auto-restart
- `scripts/backup.sh` for persistent data volume backup/restore
- `docs/api.md` with complete FutuOpenD API protocol documentation
- `docs/configuration.md` with full `FutuOpenD.xml` configuration reference
- `docs/security.md` with security hardening guide
- Support for multiple image variants (Ubuntu, Rocky Linux, CentOS)
- Support for both amd64 and arm64 architectures
- GitHub Actions CI workflow for compose file validation
- GitHub Actions workflow for GitHub Pages documentation deployment
- GitHub Actions docs link checker workflow
- GitHub Discussions configuration (Q&A, Ideas, General, Announcements)
- Issue templates for bug reports and feature requests
- Pull request template
- CONTRIBUTING.md with contribution guidelines
- CODE_OF_CONDUCT.md based on Contributor Covenant v2.1
- SECURITY.md with vulnerability reporting policy
- MkDocs configuration for documentation site with Material theme
