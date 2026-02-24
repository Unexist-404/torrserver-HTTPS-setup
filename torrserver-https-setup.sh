#!/bin/bash
# =============================================================================
# TorrServer Setup Script
# Установка/обновление TorrServer + HTTPS через Let's Encrypt
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓ $1${NC}"; }
err()  { echo -e "${RED}✗ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}➜ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo -e "${BOLD}"
echo "================================================="
echo "   TorrServer — Установка и настройка HTTPS"
echo "================================================="
echo -e "${NC}"

# Проверяем что запущены от root
if [ "$EUID" -ne 0 ]; then
    err "Запустите скрипт от root: sudo bash torrserver-setup.sh"
fi

# =============================================================================
# Шаг 1 — Ввод данных
# =============================================================================
echo -e "${BOLD}Введите необходимые данные:${NC}"
echo ""

read -p "Домен для TorrServer (например: mydomain.com): " DOMAIN </dev/tty
if [ -z "$DOMAIN" ]; then
    err "Домен не может быть пустым"
fi

read -p "Логин для входа в TorrServer: " TS_USER </dev/tty
if [ -z "$TS_USER" ]; then
    err "Логин не может быть пустым"
fi

while true; do
    read -s -p "Пароль для входа: " TS_PASS </dev/tty
    echo ""
    read -s -p "Повторите пароль: " TS_PASS2 </dev/tty
    echo ""
    if [ "$TS_PASS" = "$TS_PASS2" ]; then
        break
    fi
    warn "Пароли не совпадают, попробуйте снова"
done

if [ -z "$TS_PASS" ]; then
    err "Пароль не может быть пустым"
fi

echo ""
info "Домен: $DOMAIN"
info "Логин: $TS_USER"
echo ""
read -p "Всё верно? Продолжить? (y/n): " CONFIRM </dev/tty
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Отменено."
    exit 0
fi

echo ""

# =============================================================================
# Шаг 2 — Проверка DNS
# =============================================================================
info "Проверяем что домен $DOMAIN указывает на этот сервер..."

SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null)
DOMAIN_IP=$(getent hosts "$DOMAIN" | awk '{print $1}' 2>/dev/null || dig +short "$DOMAIN" 2>/dev/null | tail -1)

if [ -z "$DOMAIN_IP" ]; then
    err "Домен $DOMAIN не резолвится. Убедитесь что A-запись создана и DNS обновился."
fi

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    warn "IP сервера ($SERVER_IP) не совпадает с IP домена ($DOMAIN_IP)"
    read -p "Продолжить всё равно? (y/n): " FORCE
    if [ "$FORCE" != "y" ] && [ "$FORCE" != "Y" ]; then
        exit 1
    fi
else
    ok "Домен указывает на этот сервер ($SERVER_IP)"
fi

# =============================================================================
# Шаг 3 — Установка/обновление TorrServer
# =============================================================================
info "Устанавливаем/обновляем TorrServer..."

if [ -f /opt/torrserver/torrserver ]; then
    info "TorrServer уже установлен, обновляем до последней версии..."
    curl -s https://raw.githubusercontent.com/YouROK/TorrServer/master/installTorrServerLinux.sh | bash -s -- --update --silent --root
else
    info "Устанавливаем TorrServer..."
    curl -s https://raw.githubusercontent.com/YouROK/TorrServer/master/installTorrServerLinux.sh | bash -s -- --install --silent --root
fi

ok "TorrServer установлен"

# =============================================================================
# Шаг 4 — Настройка авторизации
# =============================================================================
info "Настраиваем авторизацию..."

TS_CONF_DIR="/opt/torrserver"
mkdir -p "$TS_CONF_DIR"

# Создаём файл accs.db с логином и паролем
cat > "$TS_CONF_DIR/accs.db" << EOF
{
    "$TS_USER": "$TS_PASS"
}
EOF

ok "Файл авторизации создан"

# =============================================================================
# Шаг 5 — Получение SSL-сертификата
# =============================================================================
info "Получаем SSL-сертификат для $DOMAIN..."

# Проверяем установлен ли certbot
if ! command -v certbot &> /dev/null; then
    info "Устанавливаем certbot..."
    apt-get update -q
    apt-get install -y certbot
fi

# Проверяем есть ли уже сертификат
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    warn "Сертификат для $DOMAIN уже существует, пропускаем получение"
else
    # Получаем сертификат
    # Используем standalone если нет nginx, иначе nginx плагин
    if command -v nginx &> /dev/null && systemctl is-active --quiet nginx; then
        certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    else
        certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    fi
fi

ok "SSL-сертификат получен"

# =============================================================================
# Шаг 6 — Открытие портов в UFW
# =============================================================================
info "Настраиваем файрвол..."

if command -v ufw &> /dev/null; then
    ufw allow 8091/tcp > /dev/null 2>&1
    # Закрываем 8090 если вдруг был открыт ранее
    ufw delete allow 8090/tcp > /dev/null 2>&1 || true
    # Перезапускаем UFW если он активен
    if ufw status | grep -q "Status: active"; then
        ufw disable > /dev/null 2>&1
        echo "y" | ufw enable > /dev/null 2>&1
    fi
    ok "Порт 8091 открыт, порт 8090 закрыт"
else
    warn "UFW не найден, пропускаем настройку файрвола"
fi

# =============================================================================
# Шаг 7 — Настройка systemd сервиса
# =============================================================================
info "Настраиваем systemd сервис..."

CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

cat > /etc/systemd/system/torrserver.service << EOF
[Unit]
Description=torrserver
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
NonBlocking=true
WorkingDirectory=/opt/torrserver
ExecStart=/opt/torrserver/torrserver -p 8090 --httpauth --ssl --sslport 8091 --sslcert $CERT_PATH --sslkey $KEY_PATH
Restart=on-failure
RestartSec=58

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable torrserver > /dev/null 2>&1
systemctl restart torrserver

sleep 3

if systemctl is-active --quiet torrserver; then
    ok "TorrServer запущен"
else
    err "TorrServer не запустился. Проверьте: journalctl -u torrserver -n 20"
fi

# =============================================================================
# Итог
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}================================================="
echo "   Готово! TorrServer настроен."
echo -e "=================================================${NC}"
echo ""
echo -e "${BOLD}Данные для доступа:${NC}"
echo ""
echo -e "  URL:     ${GREEN}https://$DOMAIN:8091${NC}"
echo -e "  Логин:   ${GREEN}$TS_USER${NC}"
echo -e "  Пароль:  ${GREEN}$TS_PASS${NC}"
echo ""
echo -e "${YELLOW}Сохраните эти данные в надёжном месте!${NC}"
echo ""
echo -e "${BOLD}Для Lampa (телевизор):${NC}"
echo -e "  Адрес:  https://$DOMAIN:8091"
echo -e "  Логин/пароль — те же что выше"
echo ""
echo -e "${BOLD}Полезные команды:${NC}"
echo -e "  Статус:      systemctl status torrserver"
echo -e "  Логи:        journalctl -u torrserver -n 50"
echo -e "  Перезапуск:  systemctl restart torrserver"
echo -e "  Обновление:  bash torrserver-setup.sh"
echo ""
