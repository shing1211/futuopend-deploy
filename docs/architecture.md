# Architecture

## Connection Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Trading Client (Python / JavaScript / etc.)                  │
│                                                              │
│  Connects to: 127.0.0.1:11113 (TCP)                          │
│              127.0.0.1:11114 (WebSocket)                     │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           │ TCP Binary Protocol / WebSocket
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  Docker Container (futuopend)                                 │
│                                                              │
│  Host ports:        Container ports:                         │
│  11113 (TCP)   ───►  11111 (FutuOpenD TCP API)               │
│  11114 (WS)    ───►  11112 (FutuOpenD WebSocket)             │
│                                                              │
│  Persistent data: /home/futuopend/.com.futunn.FutuOpenD      │
│  Config file:     /run/secrets/FutuOpenD.xml                 │
│  RSA key:         /run/secrets/rsa_key.txt                   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           │ Encrypted Internet connection
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  Futu Servers (api.futunn.com / openapi.futunn.com)          │
│                                                              │
│  Handles: market data, trading, account info, push notifications │
└──────────────────────────────────────────────────────────────┘
```

## Port Reference

| Host Port | Container Port | Protocol | Description |
|-----------|----------------|----------|-------------|
| `11113` | `11111` | TCP | Main trading and quote API |
| `11114` | `11112` | WebSocket | Real-time push, web clients |
| `22222` | `22222` | Telnet | Debug console (internal) |

## Multi-Instance Deployment

```
┌──────────────────────────────────────────────────────────────┐
│  Host Machine                                                 │
│                                                              │
│  ┌────────────────────┐    ┌────────────────────┐           │
│  │  futuopend-a       │    │  futuopend-b       │           │
│  │  Container A       │    │  Container B       │           │
│  │                    │    │                    │           │
│  │  11113→11111 (TCP) │    │  21113→11111 (TCP) │           │
│  │  11114→11112 (WS)  │    │  21114→11112 (WS)  │           │
│  └────────────────────┘    └────────────────────┘           │
└──────────────────────────────────────────────────────────────┘
```

Instance A and Instance B run independently with separate configs, credentials, and data volumes.

## Key Directories

| Path | Description |
|------|-------------|
| `secrets/FutuOpenD.xml` | FutuOpenD configuration (credentials, settings) |
| `secrets/rsa_key.txt` | RSA private key for trading (optional) |
| `futuopend-data` (volume) | Persistent data (market data cache, logs) |

## Security

- Credentials live in `secrets/` which is `.gitignore`'d and never committed
- Inside the container, FutuOpenD runs as a non-root user
- WebSocket connections to Futu servers use TLS encryption
- See [Security Hardening Guide](security.md) for firewall and hardening details
