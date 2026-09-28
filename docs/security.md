# Security Hardening Guide

Your trading credentials live inside this container. This guide shows you how to keep them there.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## The Golden Rules

1. **Never hardcode secrets.** As of v10.10+, no password in config — remember-login handles credentials. Mount keys as files.
2. **Least privilege.** Run as non-root, drop capabilities, lock down the filesystem.
3. **Network is enemy territory.** TLS on everything that crosses a wire. Firewall everything else.
4. **Rotate.** Keys wear out. Change them periodically via the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI).

---

## Credential Handling

### Remember-login (v10.10+)

FutuOpenD v10.10+ uses remember-login — credentials are cached after the first interactive login and reused automatically. Your `FUTU_ACCOUNT` environment variable identifies the account; no password in config.

> **Protect the data volume.** The Docker volume `futuopend-data` contains the cached session. If compromised, an attacker could potentially access your trading account. Treat the volume as sensitive.

### Your RSA private key — chmod 600, never commit it

Your RSA key is the most sensitive piece here. Guard it accordingly:

```bash
chmod 600 secrets/rsa_key.txt
```

And keep it out of version control — the repo's `.gitignore` handles this.

### FutuOpenD.xml — built-in default is usually sufficient

The image ships with a built-in `FutuOpenD.xml` at `/usr/local/bin/FutuOpenD.xml`. The deploy compose mounts your own `./FutuOpenD.xml` over it (OpenD resolves `${VAR}` placeholders itself).

If you need custom settings, mount your own at container startup — but keep sensitive values out of it. v10.10+ remember-login means no password in the config file.

---

## Network Security

### Two ways in, and how to choose

The stock compose file binds every published port to `127.0.0.1`, so nothing is
reachable from the network. Remote clients need one of two options.

**Option A - SSH tunnel (recommended default).** Nothing is exposed; the client
opens a tunnel to the host.

```bash
# on the remote client
ssh -N -L 11113:127.0.0.1:11113 user@host
```

No key to distribute, no listener on the internet, and traffic is encrypted by
SSH. Leave the bindings at their defaults and this just works.

**Option B - RSA, direct access.** The API is published on a routable address
and protected by FutuOpenD's own protocol encryption.

```bash
# .env
FUTU_API_BIND=0.0.0.0
FUTU_RSA_KEY=/run/secrets/rsa_key.txt
```

```bash
mkdir -p secrets
# generate at https://www.futunn.com/en/OpenAPI -> Manage Key
cp rsa_key.txt secrets/rsa_key.txt
chmod 600 secrets/rsa_key.txt
```

```bash
# then uncomment the rsa_key.txt volume in docker-compose.yaml
# and set FUTU_RSA_KEY=/run/secrets/rsa_key.txt in .env
```

The volume is commented out by default so that a missing key cannot become an
empty directory that quietly shadows it.

Trade-offs, and one that is easy to miss:

- **The RSA private key is a shared secret.** Clients do not get a public key to
  encrypt with; the SDK loads *the same private key the server uses* to wrap the
  per-session AES key. Every client that connects therefore holds the server's
  private key. Distributing it widens the blast radius, so treat it like a
  credential and use per-client copies if that matters to you.
- **Clients must opt in explicitly.** `is_encrypt` defaults to `None`, which
  resolves to *disabled* -- a client that forgets it connects unencrypted and no
  error is raised:

  ```python
  from futu import OpenQuoteContext
  q = OpenQuoteContext(host='api.example.com', port=11113, is_encrypt=True)
  ```

- **The key is not set by default here.** With `FUTU_IP=0.0.0.0` inside the
  container, trading calls are rejected unless `rsa_private_key` is configured.
  Quote-only access works without it.

Whichever you pick, keep `FUTU_TELNET_BIND` on `127.0.0.1`. Telnet is plaintext
and is only needed for the interactive first login and 2FA, both of which happen
on the host itself. Note that `FUTU_TELNET_IP` (in-container) must stay
`0.0.0.0` for a published port to reach it -- the two are different things, and
the host-side binding is the one that controls exposure.

### Firewall - default deny

If you bind the API broadly, restrict it to the clients that need it:

```bash
# Allow only your client subnet
iptables -A INPUT -p tcp --dport 11113 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 11113 -j DROP
```

> The port to filter is the **host** port (`11113` by default, or
> `FUTU_API_PORT_HOST`), not the container's `11111`.

Or isolate FutuOpenD inside a Docker internal network so it can't reach the
outside world except where you explicitly allow:

```yaml
services:
  futuopend:
    networks:
      - futu-internal

networks:
  futu-internal:
    internal: true   # No external egress by default
```


### WebSocket clients — TLS required off-host

The above covers the TCP API. WebSocket pushes are a separate listener and must be encrypted with a certificate if anything off-host subscribes to it:

```xml
<websocket_ip>0.0.0.0</websocket_ip>
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
<websocket_port>33333</websocket_port>
```

Generate a self-signed cert for testing:

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout secrets/key.pem -out secrets/cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip the password — FutuOpenD doesn't handle encrypted keys
openssl rsa -in secrets/key.pem -out secrets/key_nopass.pem
```

Leave `FUTU_WS_BIND` on `127.0.0.1` unless you need off-host subscriptions.

---

## Container Hardening

### Read-only filesystem + dropped capabilities

This is the production baseline. Add it to your `docker-compose.yaml`:

```yaml
services:
  futuopend:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
```

What each line does:

| Option | What it does |
|--------|-------------|
| `no-new-privileges` | Prevents the container from gaining privileges via suid binaries |
| `read_only` | Filesystem is immutable except for mounted volumes |
| `tmpfs` | Temp data lives in RAM, not on disk |
| `cap_drop: ALL` | Strips every Linux capability the process doesn't need |

### Non-root user

The image already creates a `futuopend` user (UID 1000) and switches to it. No action needed.

### External secrets managers

For larger deployments, pull secrets at runtime:

| Tool | How it works |
|------|-------------|
| HashiCorp Vault | Vault Agent sidecar injects secrets into the container |
| AWS Secrets Manager | aws-secrets-manager-sidecar pulls keys at startup |
| Azure Key Vault | akv-sidecar handles injection |

---

## Monitoring & Audit

- Start with `log_level=debug` during setup. Once everything is stable, switch to `info`.
- Ship logs somewhere centralized — ELK, Loki, CloudWatch.
- Set up alerts on authentication failures.
- Watch resource usage. Sudden spikes in CPU or memory can be an early warning.

---

## Dependency Updates

Rebuild the image periodically to pull fresh OS security patches:

```bash
cd ../futuopend
docker build --no-cache -t shing1211/futuopend:latest .
```

Pin the FutuOpenD version in production. Auto-upgrades at the wrong time can break your trading system.

---

## Security Checklist

Run through this before going live:

- [ ] RSA private key has no password and `chmod 600`
- [ ] `FutuOpenD.xml` does not contain hardcoded credentials (v10.10+ uses remember-login)
- [ ] Remote access uses TLS (both `websocket_private_key` and `websocket_cert` set)
- [ ] Firewall restricts port `11111` to known client IPs
- [ ] Container runs with `read_only: true`, `cap_drop: ALL`, and `no-new-privileges: true`
- [ ] Logs are forwarded to a central system and reviewed for auth failures
- [ ] FutuOpenD version is pinned (not `latest`)
- [ ] Separate keys used for dev and production
- [ ] Docker data volume (`futuopend-data`) is backed up and secured

---

*This project is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
