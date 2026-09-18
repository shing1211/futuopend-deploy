#!/bin/bash
#
# Submit a Futu verification code to FutuOpenD's Telnet debug interface.
#
# Usage:
#   ./scripts/verify_code.sh <SMS_CODE>              # phone/SMS code
#   ./scripts/verify_code.sh --pic <CAPTCHA_CODE>    # picture CAPTCHA
#
# Override the target with HOST / PORT env vars (default 127.0.0.1:22222).
#
# For a CAPTCHA, first copy the image out of the container:
#   docker cp futuopend:/home/futuopend/.com.futunn.FutuOpenD/F3CNN/PicVerifyCode.png .
#
set -euo pipefail

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-22222}"

if [ "${1:-}" = "--pic" ]; then
    COMMAND="input_pic_verify_code -code=${2:?usage: $0 --pic <CAPTCHA_CODE>}"
else
    COMMAND="input_phone_verify_code -code=${1:?usage: $0 <SMS_CODE>}"
fi

if ! command -v nc >/dev/null 2>&1; then
    echo "Error: netcat (nc) is required." >&2
    exit 1
fi

echo "==> ${HOST}:${PORT} <- ${COMMAND}"
printf '%s\r\n' "$COMMAND" | nc "$HOST" "$PORT"
