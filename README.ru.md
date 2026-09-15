# TorrServer HTTPS Setup

[🇬🇧 English](README.md) | 🇷🇺 Русский

---

Скрипт для автоматической установки и настройки [TorrServer](https://github.com/YouROK/TorrServer) с HTTPS на Linux VPS.

## Что делает скрипт

1. **Спрашивает данные** - домен, логин и пароль для доступа
2. **Проверяет DNS** - убеждается что домен указывает на этот сервер
3. **Устанавливает или обновляет** TorrServer до последней версии
4. **Настраивает авторизацию** - создаёт файл с логином и паролем
5. **Получает SSL-сертификат** через Let's Encrypt (certbot) с автопродлением
6. **Настраивает файрвол** - открывает порт 8091, закрывает 8090
7. **Привязывает HTTP только к localhost** - порт 8090 недоступен из интернета
8. **Устанавливает права на файлы** - ограничивает доступ к паролям и приватному ключу
9. **Запускает TorrServer** по HTTPS на порту 8091
10. **Выводит итог** - URL, логин и пароль для сохранения

## Требования

- Linux VPS (Ubuntu/Debian)
- Домен с A-записью, указывающей на IP сервера (FreeDNS, DuckDNS и т.п.)
- Certbot установлен на сервере
- UFW как файрвол

## Использование

```bash
curl -s https://raw.githubusercontent.com/Unexist-404/torrserver-HTTPS-setup/main/torrserver-https-setup.sh | sudo bash
```

Скрипт задаст три вопроса:
- Домен (например: `yourdomain.com`)
- Логин
- Пароль (дважды для подтверждения)

## Результат

После успешного завершения TorrServer будет доступен по адресу:

```
https://ВАШ_ДОМЕН:8091
```

Для **Lampa** (приложение на телевизоре) - используй тот же адрес, логин и пароль.

## Полезные команды

```bash
# Статус сервиса
systemctl status torrserver

# Логи
journalctl -u torrserver -n 50

# Перезапуск
systemctl restart torrserver

# Обновление TorrServer
curl -fsSL https://raw.githubusercontent.com/Unexist-404/torrserver-HTTPS-setup/main/torrserver-https-setup.sh | sudo bash -s -- --update
```

## Безопасность

- HTTP (порт 8090) привязан только к `127.0.0.1` - снаружи недоступен
- HTTPS (порт 8091) - единственная точка внешнего доступа
- `accs.db` имеет права `600` - читается только root
- Приватный ключ SSL имеет права `600`
- Сертификат Let's Encrypt продлевается автоматически. После продления перезапусти TorrServer: `systemctl restart torrserver`
- При повторном запуске скрипт обновит TorrServer, но не перезапишет существующий сертификат


## Благодарности

Этот скрипт является оболочкой для установки замечательного проекта [TorrServer](https://github.com/YouROK/TorrServer), созданного [YouROK](https://github.com/YouROK). Вся заслуга за сам TorrServer принадлежит автору и [контрибьюторам](https://github.com/YouROK/TorrServer/graphs/contributors), которые сделали его возможным. Если TorrServer оказался вам полезен — поддержите проект на [Boosty](https://boosty.to/yourok).
