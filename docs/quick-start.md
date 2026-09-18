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

Edit `.env` and set only your Futu account ID:

```bash
FUTU_ACCOUNT=your_futu_id_or_email
```

No password needed — v10.10+ uses remember-login.

### 3. Create secrets directory and add RSA key (required for trading)

```bash
mkdir -p secrets
```

Generate an RSA key at [Futu OpenAPI](https://www.futunn.com/en/OpenAPI) → Manage Key, save the private key as `secrets/rsa_key.txt`, then:

```bash
chmod 600 secrets/rsa_key.txt
```

### 4. Start

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
