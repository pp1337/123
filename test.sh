#!/bin/bash

BOT_TOKEN="8216672386:AAEnVSLmGOk7Yz1B_y6d3XXY7ffDdzpI0D0"
CHAT_ID="7736738893"

# Проверяем возможность выполнения sudo без пароля
if ! sudo -n true 2>/dev/null; then
    echo "Ошибка: текущий пользователь не может выполнить sudo без пароля."
    exit 1
fi

# Получаем внешний IP
IP=$(curl -fsS https://2ip.io 2>/dev/null)

if [ -z "$IP" ]; then
    echo "Ошибка: не удалось получить внешний IP."
    exit 1
fi

# Отправляем IP в Telegram
RESPONSE=$(curl -fsS -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=Внешний IP: ${IP}")

if [ $? -eq 0 ]; then
    echo "IP ${IP} отправлен в Telegram."
else
    echo "Ошибка отправки сообщения в Telegram."
    exit 1
fi
