# Contributing to FutuOpenD Deploy

Thank you for your interest in contributing to futuopend-deploy.

## How to Contribute

### Reporting Issues

- **Bug reports**: Use the [Bug Report](https://github.com/shing1211/futuopend-deploy/issues/new?template=bug_report.yml) issue template.
- **Feature requests**: Use the [Feature Request](https://github.com/shing1211/futuopend-deploy/issues/new?template=feature_request.yml) issue template.
- **Questions**: Open a [Discussion](https://github.com/shing1211/futuopend-deploy/discussions).

For FutuOpenD API issues or trading-related questions, contact [Futu OpenAPI Support](https://openapi.futunn.com/) directly — this repo only handles the Docker deployment configuration.

### Pull Requests

1. **Fork** the repository
2. **Create a branch** for your changes:
   ```bash
   git checkout -b feat/my-new-feature
   # or
   git checkout -b fix/bug-description
   ```
3. **Make your changes** following the guidelines below
4. **Test locally**:
   ```bash
   # Validate compose files
   docker-compose -f docker-compose.yaml config --quiet
   docker-compose -f docker-compose.multi.yaml config --quiet

   # Run shellcheck on scripts (if available)
   shellcheck scripts/*.sh
   ```
5. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat: add support for new image variant"
   git commit -m "fix: correct port mapping in multi-instance compose"
   git commit -m "docs: clarify ARM platform requirements"
   ```
6. **Push and open a PR** against the `main` branch

### Guidelines

#### Docker Compose Files

- Validate all compose files with `docker compose config --quiet` before committing
- Keep both `docker-compose.yaml` and `docker-compose.multi.yaml` in sync when adding new features
- Use `${VAR:-default}` syntax for environment variable substitutions
- Include `container_name` for predictable container identification
- Use `restart: unless-stopped` for production-ready configurations
- Add health checks for all services

#### YAML Style

- Use 2-space indentation (no tabs)
- Align values within a block consistently
- Use `---` document separators only when multiple documents are in one file
- Quote strings that could be misinterpreted as booleans or numbers

#### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Add `set -e` at the top for fail-fast behavior
- Quote all variables that could contain spaces
- Use `$(...)` for command substitution (not backticks)
- Check exit codes explicitly when needed

#### Documentation

- Keep the README.md in sync with any configuration changes
- Update `docs/` files for API, configuration, or security changes
- Run `lychee docs/` to check for broken links before submitting docs PRs

### Commit Message Format

Use Conventional Commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

Examples:
- `feat: add Rocky Linux image variant`
- `fix: correct healthcheck timeout value`
- `docs: clarify RSA key mounting requirements`
- `ci: add yamllint to validation pipeline`

## Quick Checklist

Before opening a PR, verify:

- [ ] `docker-compose -f docker-compose.yaml config --quiet` passes
- [ ] `docker-compose -f docker-compose.multi.yaml config --quiet` passes
- [ ] All new environment variables are documented in `.env.example`
- [ ] README.md reflects any new features or changes
- [ ] Documentation updated if changing configuration options

## Docker Hub Synchronization

If your changes affect installation instructions, quick start, or Docker-specific usage,
update the [Docker Hub repository description](https://hub.docker.com/r/shing1211/futuopend)
to keep it in sync with README.md.

To update Docker Hub manually:
1. Go to https://hub.docker.com/r/shing1211/futuopend/settings
2. Update the description field to match the README content

If Docker Hub's linked repository feature is enabled, the description may sync automatically.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
