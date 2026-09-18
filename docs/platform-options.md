# Platform Options

The compose file uses `platform: linux/${PLATFORM:-amd64}`. Set `PLATFORM` in your `.env` file.

| Platform | Use Case |
|----------|----------|
| `linux/amd64` | x86_64 desktops, servers, cloud VMs (default) |
| `linux/arm64` | Raspberry Pi 3/4/5, ARM servers |

## ARM Performance Note

Futu provides x86_64 binaries only. ARM builds use QEMU emulation (~2-5x slower than native).

For latency-sensitive trading on Raspberry Pi, consider installing [box64](https://github.com/ptitSeb/box64):

```bash
# Install box64 on the host
curl -fsSL https://ptitseb.github.io/box64/install.sh | bash
```

The container will use box64 automatically if installed on the host.

## Raspberry Pi Recommendations

- Use Raspberry Pi 4 or 5 with 4GB+ RAM for best results
- Use a high-speed SD card or SSD for storage
- Consider using the Rocky Linux variant for better compatibility
- Increase `start_period` in the compose file to accommodate slower startup
