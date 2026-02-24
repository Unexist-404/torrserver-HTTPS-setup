# TorrServer HTTPS Setup Script

Скрипт для автоматической установки и настройки [TorrServer](https://github.com/YouROK/TorrServer) с HTTPS на Linux VPS.

## Что делает скрипт

1. **Спрашивает данные** - домен, логин и пароль для доступа
2. **Проверяет DNS** - убеждается что домен указывает на этот сервер
3. **Устанавливает или обновляет** TorrServer до последней версии
4. **Настраивает авторизацию** - создаёт файл с логином и паролем
5. **Получает SSL-сертификат** через Let's Encrypt (certbot) с автопродлением
6. **Настраивает файрвол** - открывает порт 8091, закрывает 8090
7. **Запускает TorrServer** по HTTPS на порту 8091
8. **Выводит итоговые данные** - URL, логин и пароль для сохранения

## Требования

- Linux VPS (Ubuntu/Debian)
- Домен с A-записью, указывающей на IP сервера (FreeDNS, DuckDNS и т.п.)
- Nginx установлен (опционально - если есть, certbot использует его плагин)
- UFW как файрвол

## Использование

```bash
curl -s https://raw.githubusercontent.com/Unexist-404/torrserver-HTTPS-setup/main/torrserver-https-setup.sh | sudo bash
```

После запуска скрипт задаст три вопроса:
- Домен (например: `mydomen.com`)
- Логин
- Пароль (дважды для подтверждения)

## Результат

После успешного завершения TorrServer будет доступен по адресу:

```
https://ВАШ_ДОМЕН:8091
```

Для подключения в **Lampa** (телевизор) — используй тот же адрес, логин и пароль.

## Полезные команды

```bash
# Статус сервиса
systemctl status torrserver

# Логи
journalctl -u torrserver -n 50

# Перезапуск
systemctl restart torrserver

# Обновление TorrServer
curl -s https://raw.githubusercontent.com/YouROK/TorrServer/master/installTorrServerLinux.sh | sudo bash -s -- --update --silent --root
```

## Примечания

- Сертификат Let's Encrypt продлевается автоматически. После продления нужно перезапустить TorrServer: `systemctl restart torrserver`
- Порт 8090 (HTTP) закрыт   доступ только через HTTPS на 8091
- При повторном запуске скрипт обновит TorrServer, но не тронет существующий сертификат
