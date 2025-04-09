# lecbh

**lecbh** (Let's Encrypt Certbot Helper) is a lightweight bash script that automates SSL certificate setup using Certbot on Ubuntu servers running Apache.

## ✨ Features

- Installs Certbot if not present
- Obtains and installs Let's Encrypt SSL certificates
- Sets up automatic certificate renewal
- Works with Apache on Ubuntu

## 🚀 Quick Start

```bash
git clone https://github.com/yourusername/lecbh.git
cd lecbh
sudo ./lecbh.sh
```

> Make sure you run the script as `sudo` and have your domain already pointed to the server.

## 📋 Requirements

- Ubuntu (tested on 20.04 / 22.04)
- Apache2 installed and running
- Domain name pointing to the server's public IP
- Port 80/443 open on your firewall

## 🔧 What It Does

- Installs Certbot via Snap if not already installed
- Verifies Apache is running
- Obtains a Let's Encrypt certificate for your domain
- Configures Apache to use the certificate
- Sets up automatic renewal with `certbot renew`

## 📅 Renewal Check

Let's Encrypt certificates expire every 90 days. This script ensures your system is set up with a cron or systemd job to renew automatically. You can test renewal with:

```bash
sudo certbot renew --dry-run
```

## 🛠️ To Do

- [ ] Support for Nginx
- [ ] Wildcard domain support
- [ ] Log output and error handling improvements
- [ ] Unattended install flags

## 📜 License

MIT

---

Pull requests welcome!
