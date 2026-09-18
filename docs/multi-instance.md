# Multi-Instance Deployment

Run two FutuOpenD instances side-by-side for two accounts.

## Setup

```bash
mkdir -p secrets-a secrets-b
cp FutuOpenD.xml.template secrets-a/FutuOpenD.xml
cp FutuOpenD.xml.template secrets-b/FutuOpenD.xml
# edit both configs with different account credentials
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
