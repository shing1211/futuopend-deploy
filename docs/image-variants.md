# Image Variants

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
| `:10.8.6808-*` | Both | Both | Version-pinned, e.g. `:10.8.6808-ubuntu-arm64` |

## Pulling a Specific Variant

```bash
docker pull shing1211/futuopend:ubuntu-arm64
```

## Overriding the Default Image

Set `FUTU_IMAGE` in your `.env`:

```bash
echo "FUTU_IMAGE=shing1211/futuopend:rocky-amd64" >> .env
```
