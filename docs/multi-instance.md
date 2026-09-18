# Multi-Instance Deployment

Run two FutuOpenD instances side-by-side for two accounts.

## Setup

Each instance uses its own `.env` file:

```bash
cp .env.example .env-a
cp .env.example .env-b
```

Edit `.env-a` and `.env-b` and set a different `FUTU_ACCOUNT` in each.

If using Rocky Linux variant, set `FUTU_IMAGE` in each `.env`:

```bash
# .env-a
FUTU_IMAGE=shing1211/futuopend:rocky-amd64
FUTU_ACCOUNT=account_a@example.com

# .env-b
FUTU_IMAGE=shing1211/futuopend:rocky-amd64
FUTU_ACCOUNT=account_b@example.com
```

Each instance needs its own RSA key if trading:

```bash
# Instance A
mkdir -p secrets-a
cp your_rsa_key_a.txt secrets-a/rsa_key.txt
chmod 600 secrets-a/rsa_key.txt

# Instance B
mkdir -p secrets-b
cp your_rsa_key_b.txt secrets-b/rsa_key.txt
chmod 600 secrets-b/rsa_key.txt
```

## Start

```bash
docker compose -f docker-compose.multi.yaml up -d
```

## Port Mapping

| Instance | TCP Port | WebSocket Port |
|----------|----------|----------------|
| futuopend-a | 11113 | 11114 |
| futuopend-b | 21113 | 21114 |

## Verify

```bash
curl http://localhost:11113/version  # Instance A
curl http://localhost:21113/version  # Instance B
```

## Stop

```bash
docker compose -f docker-compose.multi.yaml down
```
