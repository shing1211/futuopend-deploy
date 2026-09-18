# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
