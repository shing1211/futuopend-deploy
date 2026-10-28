# Bare-metal install (systemd)

For a host that runs FutuOpenD **without Docker** — a gateway box, a NAS, a small
VM. The container path is [the compose deployment](../README.md#quick-start); this
page is the same gateway, supervised by systemd, with a CLI.

Files:

| file | installed to |
|---|---|
| [`systemd/futuopend.service`](../systemd/futuopend.service) | `/etc/systemd/system/futuopend.service` |
| [`bin/futuopend`](../bin/futuopend) | `/usr/local/bin/futuopend` |

## 1. Install the binary

Futu ships a tarball whose *headless* variant is the directory named
`Futu_OpenD_<version>_Ubuntu18.04/` (the sibling `Futu_OpenD-GUI_…AppImage` is the
desktop login tool — see step 3):

```bash
VER=10.11.7108
mkdir -p ~/futuopend-dl && cd ~/futuopend-dl
curl -sSL -o "Futu_OpenD_${VER}_Ubuntu18.04.tar.gz" \
  "https://softwaredownload.futunn.com/Futu_OpenD_${VER}_Ubuntu18.04.tar.gz"
tar xzf "Futu_OpenD_${VER}_Ubuntu18.04.tar.gz"

sudo mkdir -p /opt/futuopend
sudo cp -a "Futu_OpenD_${VER}_Ubuntu18.04/Futu_OpenD_${VER}_Ubuntu18.04/." /opt/futuopend/
printf '%s\n' "$VER" | sudo tee /opt/futuopend/VERSION
sudo chown -R "$USER:$USER" /opt/futuopend      # the process writes AppData.dat here
```

> **Download into `$HOME`, never `/tmp`.** On the estate's gateway `/tmp` is a
> 233 MB tmpfs and the tarball is 447 MB, so `curl` fails with
> `(23) Failure writing output to destination` and leaves a 0-byte file.

> **Preserve the config and the RSA key on an upgrade.** The tarball ships its own
> `FutuOpenD.xml` and no keys. Copy the live `FutuOpenD.xml` and `.futu/keys/`
> over after extracting — the key is what the API client on the other side already
> trusts, and a different key means the client cannot connect.

## 2. Install the unit and the CLI

```bash
sudo install -m 644 systemd/futuopend.service /etc/systemd/system/futuopend.service
sudo install -m 755 bin/futuopend /usr/local/bin/futuopend
sudo systemctl daemon-reload
```

Edit the unit's `User=`, `Group=`, `Environment=HOME=` and `ExecStart=` account to
match the host.

## 3. One interactive login (10.10+ only)

**`login_account` / `login_pwd` in the XML are ignored from 10.10 on.** The gateway
needs a *remembered session*, which only an interactive login can create. Without
it the unit starts and flaps:

```
OutputErr, enError = 4, strDescUTF8 = Login failed,Unable to find remembered password
```

On a headless host, forward X and run the **GUI** variant once:

```bash
ssh -X user@gateway
./Futu_OpenD-GUI_10.11.7108_Ubuntu18.04.AppImage --appimage-extract-and-run
# log in · tick "Remember password" · quit
```

`--appimage-extract-and-run` is needed where only `fuse3` is installed (the AppImage
runtime wants `libfuse2`).

The session lands in **`$HOME/.com.futunn.FutuOpenD`** (≈4.6 GB on the estate). That
is why the unit pins `Environment=HOME=` — run it as a dedicated user with a clean
home and the login silently does not carry.

## 4. Start and verify

```bash
sudo systemctl enable --now futuopend
futuopend
```

```
  FutuOpenD  ● active  pid 123456
  ──────────────────────────────────────────────────────────
  version     10.11.7108   (on disk: 10.11.7108)
  endpoint    open           127.0.0.1:11111
  login       20123456       remembered session   # your account id
  session     4.6G   ~/.com.futunn.FutuOpenD
  boot        auto-start   active, restarts 0
  log         GTWLog_20123456_…log  ·  18:31:02
  errors      none   in the current log
```

## Using the CLI

```
futuopend                 the status card                     (exit 1 if unhealthy)
futuopend status --json   the same facts, machine-readable
futuopend accounts        the account list the gateway serves
futuopend health          endpoint + a live quote + latency   (exit 1 if unhealthy)
futuopend start|stop|restart
futuopend logs [-f] [n]   the gateway's own log (the readable one)
futuopend logs --unit     the unit's lifecycle, from the journal
futuopend version         running vs on-disk vs the rollback copy
futuopend backup          snapshot /opt/futuopend
futuopend upgrade <ver>   backup → download → verify → install → restart
```

`NO_COLOR=1` disables colour. `FUTU_ACCOUNT`, `FUTU_PORT`, `FUTU_HOST` override the
defaults.

Two notes from using it:

* **`logs` reads the gateway's own file by default.** OpenD writes binary to stdout,
  so the journal shows `[NNB blob data]` — `--unit` is there for the lifecycle
  (start/stop/exit), not for the traffic.
* **`upgrade` keeps `~/futuopend` as the rollback.** It also writes
  `/opt/futuopend/VERSION`, because the binary has no `--version` flag.

## After the gateway restarts: the client may be blind

A restart of the gateway invalidates the **API client's** cached contexts. The
estate's bridge then fails the venue read with

```
RuntimeError: futu filled_orders: market US read failed: get_acc_list failed: invalid connid
```

and stays blind until it is restarted. A wait-for-port in the client is not enough —
the port is open, the *session id* is stale — so the client has to reconnect (or be
restarted) when that error appears. Worth wiring into whatever supervises the
consumer.
