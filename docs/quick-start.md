# Quick Start

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) v2 or later
- A Futu account with OpenAPI access

## Steps

### 1. Pull the image

```bash
docker pull shing1211/futuopend:latest
```

Or build locally from the [futuopend](https://github.com/shing1211/futuopend) project:

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend
./dockerbuild.sh ubuntu
```

### 2. Clone this repo and configure

```bash
git clone https://github.com/shing1211/futuopend-deploy.git
cd futuopend-deploy
cp .env.example .env
```

Edit `.env` with your Futu account credentials.

### 3. Create config from template

```bash
mkdir -p secrets
cp FutuOpenD.xml.template secrets/FutuOpenD.xml
```

Edit `secrets/FutuOpenD.xml` with your settings. The template supports environment variable substitution.

### 4. (Optional) Add RSA key for trading

Generate an RSA key at [Futu OpenAPI](https://www.futunn.com/en/OpenAPI) → Manage Key, save as `secrets/rsa_key.txt`, then:

```bash
chmod 600 secrets/rsa_key.txt
```

### 5. (Optional) Set platform for ARM

For Raspberry Pi or ARM devices:

```bash
echo "PLATFORM=linux/arm64" >> .env
```

### 6. Start

```bash
docker compose up -d
docker compose logs -f
```

## Verify

```bash
curl http://localhost:11113/version
```

## Troubleshooting

See the [Troubleshooting](index.md#troubleshooting) section for common issues.
