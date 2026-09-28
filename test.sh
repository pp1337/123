#!/bin/bash

set -e

BOT_TOKEN="ВСТАВЬ_ТОКЕН_БОТА"
CHAT_ID="ВСТАВЬ_CHAT_ID"
PORT="1080"

apt update -y
apt install -y dante-server curl

IFACE=$(ip route | awk '/default/ {print $5; exit}')
IP=$(curl -4 -fsS https://2ip.io)

read -p "Логин: " USER
read -s -p "Пароль: " PASS
echo

[ -n "$USER" ] && [ -n "$PASS" ] || exit 1

if id "$USER" &>/dev/null; then
    echo "${USER}:${PASS}" | chpasswd
else
    useradd --no-create-home --shell /usr/sbin/nologin "$USER"
    echo "${USER}:${PASS}" | chpasswd
fi

cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: 0.0.0.0 port = ${PORT}
external: ${IFACE}
method: username
user.privileged: root
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

proxy pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: connect
    protocol: tcp
    method: username
}
EOF

systemctl enable danted
systemctl restart danted

if ! systemctl is-active --quiet danted; then
    echo "Ошибка запуска Dante."
    exit 1
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow "${PORT}/tcp" >/dev/null
fi

PROXY="socks5://${USER}:${PASS}@${IP}:${PORT}"

echo
echo "$PROXY"
echo

curl -fsS -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${PROXY}" \
    >/dev/null

echo "SOCKS5 установлен и отправлен в Telegram."
