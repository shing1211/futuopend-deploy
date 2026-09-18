# FutuOpenD.xml Configuration Reference

Every tag FutuOpenD v10.11.7108 understands, documented with examples. Start with the `FutuOpenD.xml.template` in the repo root — it's pre-wired with env-var substitution and sensible defaults.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## New in v10.10+ — Login Changed

**Breaking change:** As of v10.10.7008, FutuOpenD no longer reads `<login_account>` or `<login_pwd_md5>` from `FutuOpenD.xml`. Credentials must now be passed via CLI arguments:

```bash
FutuOpenD -login_account=your_account_id -login_by_remember=1
```

The `futuopend` Docker image handles this automatically — set `FUTU_ACCOUNT` in your environment and the entrypoint passes the correct CLI args. No credentials need to be in `FutuOpenD.xml` any more.

On first run, FutuOpenD enters interactive login mode, caches your credentials locally, and on subsequent runs logs in automatically via remember-login.

## New in v10.10+

- **Search API** — keyword search to find any asset by ticker, name, or keyword
- **Search API** — news, announcements, and ratings search (one keyword, results from all sources)
- **Chart Indicators** — all technical indicators supported in Mai Language and Python
- **Comprehensive Options Analysis** — IV/HV, Put/Call Ratio, 0DTE Options, Upcoming Earnings, Seller Dashboard
- **Market Fundamentals API** — Institutional Tracker, Macroeconomic Data, Dividend & Earnings Calendars, Industry Chain, Market Movers, Fed Rate Projections
- Config schema unchanged — `FutuOpenD.xml` byte-identical to 10.7.6708

---

## The One Rule

**FutuOpenD uses lowercase XML tag names.** The root element is `<futu_opend>`. Tags like `<IP>`, `<Port>`, or `<LoginAccount>` (uppercase or CamelCase) are silently ignored. When in doubt, lowercase it.

---

## Minimal Working Config

This is everything you need for a functional session (credentials are handled automatically by the entrypoint):

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- TCP API — bind locally -->
  <ip>127.0.0.1</ip>
  <api_port>11111</api_port>

  <!-- RSA key — required for trading or remote access -->
  <rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>

  <!-- Behaviour -->
  <lang>en</lang>
  <log_level>info</log_level>
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>
</futu_opend>
```

Add whatever you need from the sections below. Everything else is optional.

---

## Account & Authentication

> **v10.10+ note:** `<login_account>` and `<login_pwd_md5>` are no longer read from `FutuOpenD.xml`. Set `FUTU_ACCOUNT` as an environment variable — the entrypoint passes your credentials via CLI arguments automatically.

### Remember-Login (v10.10+)

FutuOpenD v10.10+ uses a remember-login mechanism:

1. **First run:** OpenD enters interactive login mode, prompts for account and password, caches credentials locally
2. **Subsequent runs:** OpenD logs in automatically using the cached credentials

This means you only enter your password once — after the first successful login, the Docker data volume persists the session and FutuOpenD reuses it on every restart.

**Your `FUTU_ACCOUNT` environment variable** tells FutuOpenD which account to log in with. No password needed in config.

> **Important:** The Docker data volume (`futuopend-data`) stores the cached session. **Do not delete it** — otherwise FutuOpenD will require interactive login again on next start.

When re-verification is triggered:
- New IP or device detected by Futu's servers
- Futu invalidates the device whitelist (server-side, hours to days)
- You will need to submit a new SMS/CAPTCHA code via Telnet port 22222

### `<rsa_private_key>`

Path to your RSA private key file. Required for trading when `<ip>` is anything other than `127.0.0.1`.

Get one from the [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI) → **Manage Key** → generate and download. Then copy it to `secrets/rsa_key.txt` and `chmod 600`.

```xml
<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>
```

---

## Network & Protocol

### `<ip>` — TCP API bind address

Controls which interfaces FutuOpenD listens on.

| Value | Who can reach it |
|-------|-----------------|
| `127.0.0.1` | Local processes only (default, safest) |
| `0.0.0.0` | Anyone on the network — **set this for remote access** |

```xml
<!-- Local dev — only this machine -->
<ip>127.0.0.1</ip>

<!-- Cloud VM or remote SDK -->
<ip>0.0.0.0</ip>
```

> **Security:** When you set `<ip>0.0.0.0</ip>`, you **must** also set `<rsa_private_key>`. Trading calls get rejected without it. Quote-only works without encryption.

### `<api_port>` — TCP API port

Defaults to `11111`. Only change it if something else already owns that port.

```xml
<api_port>11111</api_port>
```

### `<websocket_ip>` / `<websocket_port>` — WebSocket

The WebSocket endpoint. Leave `<websocket_port>` unset to disable.

```xml
<websocket_ip>0.0.0.0</websocket_ip>
<websocket_port>11112</websocket_port>
```

### `<websocket_key_md5>`

WebSocket clients use this MD5 hex string to authenticate. If unset, any client can connect (subject to RSA rules for trading calls).

```xml
<!-- Generate with: echo -n "your_secret_key" | md5sum | cut -d' ' -f1 -->
<websocket_key_md5>YOUR_32CHAR_MD5_HASH_HERE</websocket_key_md5>
```

### `<websocket_private_key>` / `<websocket_cert>` — TLS/SSL

Both must be set together to enable WSS. Required when WebSocket crosses an untrusted network.

Generate a self-signed cert (fine for testing):

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout secrets/key.pem -out secrets/cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip the password — FutuOpenD can't handle encrypted keys
openssl rsa -in secrets/key.pem -out secrets/key_nopass.pem
```

```xml
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

---

## Behaviour & Tuning

### `<log_level>`

How chatty are the logs?

| Value | Use it when |
|-------|------------|
| `debug` | First setup, chasing connection issues |
| `info` | Normal day-to-day running (default) |
| `warning` | You want less noise |
| `error` | Production, keep it quiet |
| `fatal` | Only catastrophic failures get logged |
| `no` | Logging disabled entirely — don't use during setup |

```xml
<log_level>info</log_level>
```

### `<log_path>`

Custom log directory. Leave unset to use FutuOpenD's default.

```xml
<!-- <log_path>/var/log/futuopend</log_path> -->
```

### `<push_proto_type>`

Format for pushed subscription data.

| Value | Format | Best for |
|-------|--------|---------|
| `0` | Protocol Buffers | Production (compact, fast) |
| `1` | JSON | Debugging (human-readable) |

```xml
<push_proto_type>0</push_proto_type>
```

### `<qot_push_frequency>`

Cap push frequency in milliseconds per subscription. Does not affect K-line pushes. Leave unset for unlimited.

```xml
<!-- One push per second — reduces bandwidth on high-activity subscriptions -->
<qot_push_frequency>1000</qot_push_frequency>
```

### `<price_reminder_push>`

Receive price alert notifications pushed from Futu's server.

```xml
<price_reminder_push>1</price_reminder_push>  <!-- on (default) -->
<price_reminder_push>0</price_reminder_push>  <!-- off -->
```

### `<auto_hold_quote_right>`

If another terminal kicks you off your quote rights, should FutuOpenD automatically try to reclaim them for 10 seconds?

```xml
<auto_hold_quote_right>1</auto_hold_quote_right>  <!-- auto-reclaim (default) -->
<auto_hold_quote_right>0</auto_hold_quote_right>  <!-- manual re-login -->
```

### `<telnet_ip>` / `<telnet_port>`

Enable the Telnet debug console — required for first-login SMS/CAPTCHA verification. Inside a container it must bind `0.0.0.0` so the published host port can reach it.

```xml
<telnet_ip>0.0.0.0</telnet_ip>
<telnet_port>22222</telnet_port>
```

The shipped `FutuOpenD.xml.template` enables this by default (`${FUTU_TELNET_IP:-0.0.0.0}` / `${FUTU_TELNET_PORT:-22222}`).

> **Warning:** Telnet is plaintext. Keep the host port firewalled/localhost-bound and never expose `22222` to untrusted networks.

---

## Language & Locale

### `<lang>`

| Value | Language |
|-------|---------|
| `en` | English |
| `chs` | Simplified Chinese |

```xml
<lang>en</lang>
```

### `<future_trade_api_time_zone>`

Required for futures trading. Sets the time zone for timestamps in futures API responses.

```xml
<future_trade_api_time_zone>UTC+8</future_trade_api_time_zone>   <!-- HK, Singapore -->
<future_trade_api_time_zone>UTC+9</future_trade_api_time_zone>   <!-- Japan -->
<future_trade_api_time_zone>UTC+11</future_trade_api_time_zone>  <!-- Sydney -->
<future_trade_api_time_zone>UTC-5</future_trade_api_time_zone>   <!-- New York -->
<future_trade_api_time_zone>UTC-6</future_trade_api_time_zone>   <!-- Chicago -->
```

---

## US Market Protections

> Applicable only to Futu US / moomoo US accounts.

### `<pdt_protection>`

**Pattern Day Trade Protection** — blocks orders that would trigger PDT status.

```xml
<pdt_protection>1</pdt_protection>  <!-- active (recommended) -->
<pdt_protection>0</pdt_protection>  <!-- disabled -->
```

PDT protection helps, but doesn't eliminate risk. If your equity drops below $25,000 and you're flagged as a PDT, you can't open new positions until you deposit funds.

### `<dtcall_confirmation>`

**Day-Trading Call Warning** — blocks orders that would exhaust your DT buying power.

```xml
<dtcall_confirmation>1</dtcall_confirmation>  <!-- active (recommended) -->
<dtcall_confirmation>0</dtcall_confirmation>  <!-- disabled -->
```

A triggered DT Call requires depositing the full call amount to clear.

---

## Environment Variable Substitution

FutuOpenD does **not** expand environment variables itself. The image's entrypoint renders `${VAR_NAME}` placeholders with `envsubst` at container start, using the values Docker injects. Use `${VAR}` only — the `${VAR:-default}` syntax is not supported.

```xml
<rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>
<ip>${FUTU_IP}</ip>
<log_level>${FUTU_LOG_LEVEL}</log_level>
```

Defaults come from `docker-compose.yaml`/`.env`, and the entrypoint exports fallbacks for any variable that is unset.

**Via Docker Compose:**

```yaml
services:
  futuopend:
    environment:
      FUTU_ACCOUNT: "12345678"
      FUTU_RSA_KEY: "/run/secrets/rsa_key.txt"
      FUTU_IP: "0.0.0.0"
      FUTU_LOG_LEVEL: "debug"
```

**Via docker run:**

```bash
docker run \
  -e FUTU_ACCOUNT=12345678 \
  -e FUTU_RSA_KEY=/run/secrets/rsa_key.txt \
  shing1211/futuopend:latest
```

> **Note:** `FUTU_ACCOUNT` is required for v10.10+ remember-login. No password needed — credentials are cached after first interactive login and reused automatically.

### Supported variables

| Variable | Maps to | Default |
|----------|---------|---------|
| `FUTU_ACCOUNT` | CLI `-login_account` arg | _(required for remember-login)_ |
| `FUTU_RSA_KEY` | `<rsa_private_key>` | _(required for trading)_ |
| `FUTU_IP` | `<ip>` | `0.0.0.0` |
| `FUTU_TELNET_IP` | `<telnet_ip>` | `0.0.0.0` |
| `FUTU_TELNET_PORT` | `<telnet_port>` | `22222` |
| `FUTU_API_PORT` | `<api_port>` | `11111` |
| `FUTU_WS_PORT` | CLI `-websocket_port` | _(unset — WebSocket off)_ |
| `FUTU_LOG_LEVEL` | `<log_level>` | `info` |
| `FUTU_LANG` | `<lang>` | `en` |
| `FUTU_PUSH_PROTO` | `<push_proto_type>` | `0` (protobuf) |
| `FUTU_FUTURE_TZ` | `<future_trade_api_time_zone>` | `UTC+8` |
| `FUTU_AREA_CODE` | CLI `-area_code` | `+852` |

---

## First-Time Login: Phone Verification in Docker

FutuOpenD 10.10+ has **no non-interactive password login**. The account is cached after one successful login; after that `FUTU_ACCOUNT` + remember-login works. So the first login must be interactive (with a TTY) or completed via the Telnet 2FA interface.

> **Do not set `FUTU_ACCOUNT` for the very first login.** With `FUTU_ACCOUNT` set on an empty volume, OpenD tries remember-login, finds no cached credential, and exits: `登录失败，找不到记住密码信息，请使用账号密码登录`.

### First login (one time)

Run interactively with `FUTU_ACCOUNT` **unset**, enter account/password, and choose *remember*:

```bash
docker compose run --rm -it -e FUTU_ACCOUNT= futuopend
```

If Futu then challenges the device (new IP/device), it prints `Waiting for phone verify code, please input by telnet...` — continue with the Telnet steps below. The cached session is written to the `futuopend-data` volume.

Once logged in, set `FUTU_ACCOUNT` in `.env` and start normally:

```bash
docker compose up -d
```

### How verification flows

1. On first run (empty data volume) or a new device, Futu sends an SMS or requires CAPTCHA
2. OpenD waits: `Waiting for phone verify code, please input by telnet...`
3. You submit the code via Telnet → validation → credentials cached → remember-login active

### Step 1 — Start and watch the logs

```bash
docker compose up -d
docker compose logs -f futuopend
```

Two things can happen:

**Option A — Remember-login succeeds immediately:**

```
[INFO] Login succeeded. Account: 12345678
```

You're in. Skip to Step 5.

**Option B — Phone/CAPTCHA verification is triggered:**

```
[INFO] Waiting for phone verify code, please input by telnet...
[INFO] Use command: input_phone_verify_code -code=123456
```

### Step 2 — Submit the verification code

Use the helper (requires `nc`):

```bash
./scripts/verify_code.sh 123456              # SMS code
```

For CAPTCHA instead of SMS:

```bash
# Copy the CAPTCHA image out of the container
docker cp futuopend:/home/futuopend/.com.futunn.FutuOpenD/F3CNN/PicVerifyCode.png ./PicVerifyCode.png

# Then submit it
./scripts/verify_code.sh --pic YOUR_CODE
```

Or raw netcat:

```bash
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222
echo "input_pic_verify_code -code=YOUR_CODE" | nc 127.0.0.1 22222
```

### Step 3 — Confirm success

```bash
docker compose logs futuopend | grep -i "login\|verify\|success"
```

Look for:

```
[INFO] Login succeeded. Account: 12345678
```

### Step 4 — Subsequent runs

After the first successful login, FutuOpenD uses remember-login automatically:

```
[entrypoint] Starting FutuOpenD with remember-login for account: 12345678
[INFO] Login succeeded. Account: 12345678
```

No verification needed — credentials are cached in the `futuopend-data` Docker volume.

### Troubleshooting: re-verification triggered

If you see the verification prompt again on a subsequent run, it means Futu's server invalidated the device whitelist. This can happen when:

- You're on a new IP or network
- Futu reset device registrations server-side
- The data volume was deleted

Simply submit a new verification code as in Step 2 above. Your existing session will be replaced with a fresh one.

---

## Complete Config Example

```xml
<?xml version="utf-8"?>
<futu_opend>
  <!-- Remote access: bind to all interfaces -->
  <ip>0.0.0.0</ip>
  <api_port>11111</api_port>

  <!-- WebSocket on 11112 -->
  <websocket_ip>0.0.0.0</websocket_ip>
  <websocket_port>11112</websocket_port>

  <!-- RSA key — required for trading or remote access -->
  <rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>

  <!-- Behaviour -->
  <lang>en</lang>
  <log_level>info</log_level>
  <push_proto_type>0</push_proto_type>

  <!-- US market guards -->
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>

  <!-- Uncomment for WSS (TLS) -->
  <!-- <websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key> -->
  <!-- <websocket_cert>/run/secrets/ws_cert.pem</websocket_cert> -->

  <!-- Telnet for first-login verification commands -->
  <telnet_ip>0.0.0.0</telnet_ip>
  <telnet_port>22222</telnet_port>
</futu_opend>
```

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
