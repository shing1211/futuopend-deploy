# Multi-Instance Deployment

Run two FutuOpenD instances side-by-side for two accounts, using the `multi`
profile of the single `docker-compose.yaml`.

Services behind a `profiles:` key stay inert until that profile is enabled, so
the default single-instance run is unaffected by them.

## Setup

Each instance uses its own env file, so the accounts stay separate:

```bash
cp .env.example .env-a
cp .env.example .env-b
```

Edit `.env-a` and `.env-b` and set a different `FUTU_ACCOUNT` in each.

If using the Rocky Linux variant, set `FUTU_IMAGE` in each:

```bash
# .env-a
FUTU_IMAGE=shing1211/futuopend:10.11.7108-rocky-amd64
FUTU_ACCOUNT=account_a@example.com

# .env-b
FUTU_IMAGE=shing1211/futuopend:10.11.7108-rocky-amd64
FUTU_ACCOUNT=account_b@example.com
```

Each instance needs its own RSA key if trading:

```bash
mkdir -p secrets-a secrets-b
cp your_rsa_key_a.txt secrets-a/rsa_key.txt
cp your_rsa_key_b.txt secrets-b/rsa_key.txt
chmod 600 secrets-a/rsa_key.txt secrets-b/rsa_key.txt
```

and `FUTU_RSA_KEY=/run/secrets/rsa_key.txt` in the matching env file.

## Start

```bash
docker compose --profile multi up -d
```

## Port Mapping

All ports bind to `127.0.0.1` by default — see
[Network Security](security.md#two-ways-in-and-how-to-choose) for remote
access. Override the published ports with `FUTU_API_PORT_A`,
`FUTU_API_PORT_B`, `FUTU_WS_PORT_A`, `FUTU_WS_PORT_B`, `FUTU_TELNET_PORT_A` and
`FUTU_TELNET_PORT_B`.

| Instance | API | WebSocket | Telnet |
|----------|-----|-----------|--------|
| futuopend-a | 11113 | 11114 | 22222 |
| futuopend-b | 21113 | 21114 | 22223 |

## Verify

A listening port does not mean the session authenticated. Check both instances:

```bash
docker compose --profile multi logs futuopend-a | grep -E 'Login successful|Required data is ready'
docker compose --profile multi logs futuopend-b | grep -E 'Login successful|Required data is ready'
```

## Stop

```bash
docker compose --profile multi down
```

## Monitoring alongside

```bash
docker compose --profile multi --profile monitoring up -d
```

Grafana is at <http://localhost:23000> (`admin`/`admin`, or set
`GRAFANA_PASSWORD`).
