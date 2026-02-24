# TorrServer HTTPS Setup

🇬🇧 English | [🇷🇺 Русский](README.ru.md)

---

Automatic installation and HTTPS configuration script for [TorrServer](https://github.com/YouROK/TorrServer) on Linux VPS.

## What the script does

1. **Asks for input** - domain, login and password for access
2. **Checks DNS** - verifies that the domain points to this server
3. **Installs or updates** TorrServer to the latest version
4. **Configures authentication** - creates a login/password file
5. **Obtains SSL certificate** via Let's Encrypt (certbot) with auto-renewal
6. **Configures firewall** - opens port 8091, closes 8090
7. **Binds HTTP to localhost only** - port 8090 is not exposed to the internet
8. **Sets secure file permissions** - restricts access to credentials and private key
9. **Starts TorrServer** over HTTPS on port 8091
10. **Displays the result** - URL, login and password to save

## Requirements

- Linux VPS (Ubuntu/Debian)
- A domain with an A record pointing to the server IP (FreeDNS, DuckDNS, etc.)
- Certbot installed on the server
- UFW as firewall

## Usage

```bash
curl -s https://raw.githubusercontent.com/Unexist-404/torrserver-HTTPS-setup/main/torrserver-https-setup.sh | sudo bash
```

The script will ask three questions:
- Domain (e.g. `yourdomain.com`)
- Login
- Password (twice for confirmation)

## Result

After successful completion, TorrServer will be available at:

```
https://YOUR_DOMAIN:8091
```

For **Lampa** (TV app) - use the same address, login and password.

## Useful commands

```bash
# Service status
systemctl status torrserver

# Logs
journalctl -u torrserver -n 50

# Restart
systemctl restart torrserver

# Update TorrServer
curl -s https://raw.githubusercontent.com/YouROK/TorrServer/master/installTorrServerLinux.sh | sudo bash -s -- --update --silent --root
```

## Security notes

- HTTP (port 8090) is bound to `127.0.0.1` only - not accessible from the internet
- HTTPS (port 8091) is the only external access point
- `accs.db` has `600` permissions - readable by root only
- SSL private key has `600` permissions
- Let's Encrypt certificate auto-renews. After renewal, restart TorrServer: `systemctl restart torrserver`
- Re-running the script will update TorrServer but will not overwrite an existing certificate

## Acknowledgements

This script is a setup wrapper for the excellent [TorrServer](https://github.com/YouROK/TorrServer) project by [YouROK](https://github.com/YouROK). All credit for TorrServer itself goes to the original author and the [contributors](https://github.com/YouROK/TorrServer/graphs/contributors) who made it possible. If you find TorrServer useful, consider supporting the project via [Boosty](https://boosty.to/yourok).
