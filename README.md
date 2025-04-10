[![Test Status](https://github.com/pa-ulander/lecbh/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/pa-ulander/lecbh/actions/workflows/test.yml)

# lecbh 

**lecbh** (Let's Encrypt Certbot Helper) is a lightweight bash script that automates SSL certificate setup using Certbot on Ubuntu servers running Apache or Nginx.

## Features

- Automatically installs and configures Let's Encrypt SSL certificates
- Supports both Apache and Nginx web servers
- Sets up automatic certificate renewal
- Validates domain configuration before requesting certificates
- Supports multiple domains in a single certificate
- Includes dry-run mode for testing without making changes
- Provides staging mode for development without hitting rate limits
- Works with unattended mode for automated deployments

## Requirements

- Ubuntu (tested on 20.04 / 22.04)
- Apache2 or Nginx installed and running
- Domain name(s) pointing to your server's public IP
- Ports 80 and 443 open on your firewall

## Installation

Clone the repository:

```bash
git clone https://github.com/pa-ulander/lecbh.git
cd lecbh
```

Make the script executable:

```bash
chmod +x lecbh.sh
```

## Usage

### Basic Usage

Run the script with sudo:

```bash
sudo ./lecbh.sh
```

The script will prompt you for:
- Domain name(s) (comma-separated for multiple domains)
- Email address for Let's Encrypt registration
- Web server type (Apache or Nginx)

### Command Line Options

```
Usage: sudo ./lecbh.sh [OPTIONS]

Options:
  --dry-run      Test run without making actual changes
  --unattended   Run with default values without prompting
  --verbose      Show more detailed output
  --staging      Use Let's Encrypt staging environment (for testing)
  --help         Show this help message
```

### Examples

Test run without making changes:
```bash
sudo ./lecbh.sh --dry-run
```

Run with default values without prompting:
```bash
sudo ./lecbh.sh --unattended
```

Use staging environment for development:
```bash
sudo ./lecbh.sh --staging
```

Show detailed output:
```bash
sudo ./lecbh.sh --verbose
```

### Default Configuration

You can modify the default values at the top of the script:

```bash
# -------------------- CONFIG --------------------
DEFAULT_EMAIL="admin@example.com"
DEFAULT_DOMAINS="example.com"
DEFAULT_SERVER="apache" # Change to nginx if preferred
# -------------------------------------------------
```

## Certificate Renewal

Let's Encrypt certificates expire every 90 days. The script ensures your system is set up with a systemd timer to renew automatically.

You can test the renewal process with:

```bash
sudo certbot renew --dry-run
```

To check the status of the renewal timer:

```bash
systemctl status certbot.timer
```

## Development and Testing

For development and testing, use the `--staging` flag to avoid hitting Let's Encrypt rate limits. Staging certificates are not trusted by browsers but work identically for testing purposes.

Docker can be used for testing the script in an isolated environment. See the included Dockerfile and docker-compose.yml for details.

For detailed information about testing procedures and environments, see the [Testing documentation](Testing.md).

## Troubleshooting

### Common Issues

1. **Domain not reachable**: Ensure your domain's DNS records point to your server's IP address.

2. **Port 80/443 not accessible**: Check your firewall settings and ensure your web server is properly configured.

3. **Web server not running**: Make sure Apache or Nginx is installed and running.

4. **Rate limits**: If you hit Let's Encrypt rate limits, use the `--staging` flag for testing.

### Logs

Certbot logs can be found at:
- `/var/log/letsencrypt/letsencrypt.log`

## Unlicense

This project is licensed under the UNLICENCE License - see the UNLICENSE file for details.

## Acknowledgments

- [Let's Encrypt](https://letsencrypt.org/) for providing free SSL certificates
- [Certbot](https://certbot.eff.org/) for the excellent certificate management tool
