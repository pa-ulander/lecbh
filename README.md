[![Test Status](https://github.com/pa-ulander/lecbh/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/pa-ulander/lecbh/actions/workflows/test.yml)
![](https://ghvc.kabelkultur.se?username=pa-ulander&label=Repository%20visits&color=brightgreen&style=flat&repository=lecbh)

# Let's Encrypt Certbot Helper

**Let's Encrypt Certbot Helper** (lecbh) is a lightweight bash script that automates SSL certificate setup using Certbot on Ubuntu servers running Apache or Nginx.

## Table of Contents

- [Let's Encrypt Certbot Helper](#lets-encrypt-certbot-helper)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Basic Usage](#basic-usage)
    - [Command Line Options](#command-line-options)
    - [Examples](#examples)
    - [Default Configuration](#default-configuration)
  - [JSON Output Mode](#json-output-mode)
  - [Concurrency Lock](#concurrency-lock)
  - [Certificate Renewal](#certificate-renewal)
  - [Development and Testing](#development-and-testing)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
    - [Logs](#logs)
  - [Contributing](#contributing)
    - [Looking to contribute?](#looking-to-contribute)
  - [Unlicense](#unlicense)
  - [Acknowledgments](#acknowledgments)


## Features

*   Automatically installs and configures Let's Encrypt SSL certificates
*   Supports both Apache and Nginx web servers
*   Sets up automatic certificate renewal
*   Validates domain configuration before requesting certificates
*   Supports multiple domains in a single certificate
*   Includes dry-run mode for testing without making changes
*   Provides staging mode for development without hitting rate limits
*   Works with unattended mode for automated deployments
*   Supports installation via Snap (default) or pip
*   Includes test mode for Docker/container environments
*   JSON output mode for automation (`--json`)
*   Concurrency lock to prevent overlapping runs

## Requirements

*   Ubuntu (tested on 20.04 / 22.04)
*   Apache2 or Nginx installed and running
*   Domain name(s) pointing to your server's public IP
*   Ports 80 and 443 open on your firewall

## Installation

Clone the repository:

```
git clone https://github.com/pa-ulander/lecbh.git
cd lecbh
```

Make the script executable:

```
chmod +x lecbh.sh
```

## Usage

### Basic Usage

Run the script with sudo:

```
sudo ./lecbh.sh
```

The script will prompt you for:

*   Domain name(s) (comma-separated for multiple domains)
*   Email address for Let's Encrypt registration
*   Web server type (Apache or Nginx)
*   Installation method (snap or pip)

### Command Line Options

```
Usage: sudo ./lecbh.sh [OPTIONS]

Options:
  --dry-run                Test run (no real certs issued)
  --unattended             Non-interactive (use defaults / flags)
  --verbose                Extra logging
  --quiet                  Minimal output
  --staging                Use Let's Encrypt staging API
  --test-mode              Mock certbot (for CI / containers)
  --pip / --snap           Select install method (default: snap)
  --server=apache|nginx    Web server type
  --email=ADDR             Account email
  --domains=a.com,b.com    Comma separated domains list
  --no-redirect            Disable HTTP→HTTPS redirect
  --json                   Emit JSON summary (implies --quiet)
  --help                   Show help
```

### Examples

Test run without making changes:

```
sudo ./lecbh.sh --dry-run
```

Run with default values without prompting:

```
sudo ./lecbh.sh --unattended
```

Use staging environment for development:

```
sudo ./lecbh.sh --staging
```

Show detailed output:

```
sudo ./lecbh.sh --verbose
```

Use pip installation method instead of snap:

```
sudo ./lecbh.sh --pip
```

Testing in container environments:

```
sudo ./lecbh.sh --test-mode
```

### Default Configuration

Defaults can be overridden via environment variables or flags. Examples:

```
export DEFAULT_EMAIL="admin@example.com"
export DEFAULT_DOMAINS="example.com,www.example.com"
export DEFAULT_SERVER="nginx"
export DEFAULT_INSTALL_METHOD="pip"
sudo ./lecbh.sh --unattended
```

Inline override:

```
DEFAULT_EMAIL=ops@example.org DEFAULT_DOMAINS="example.org,www.example.org" \
  sudo ./lecbh.sh --unattended --server=nginx
```
## JSON Output Mode

Use `--json` to produce a machine-readable summary. Helpful for pipelines or provisioning systems:

```
sudo ./lecbh.sh --unattended --server=nginx \
  --domains=example.org,www.example.org --email=admin@example.org --json
```

Sample (values illustrative):

```json
{
  "domains": ["example.org","www.example.org"],
  "email": "admin@example.org",
  "server": "nginx",
  "install_method": "snap",
  "dry_run": false,
  "staging": false,
  "test_mode": false,
  "redirect": true,
  "timestamp": "2025-01-01T00:00:00Z",
  "version": "1.1.0"
}
```

Parse with `jq`:

```
sudo ./lecbh.sh --unattended --json | jq -r '.domains[]'
```

## Concurrency Lock

The script uses a lock file (`/var/run/lecbh.lock` by default) to prevent overlapping runs. Override with `LECBH_LOCK_FILE` if needed. Stale locks are removed automatically if the owning process no longer exists.


## Certificate Renewal

Let's Encrypt certificates expire every 90 days. The script ensures your system is set up for automatic renewal:

*   With snap installation: Sets up systemd timer for automatic renewal
*   With pip installation: Configures a cron job to run every 12 hours

You can test the renewal process with:

```
sudo certbot renew --dry-run
```

To check the status of the renewal timer (snap installation):

```
systemctl status certbot.timer
```

To check the cron job (pip installation):

```
crontab -l | grep certbot
```

## Development and Testing

For development and testing, use the `--staging` flag to avoid rate limits, and `--test-mode` to mock certbot operations inside CI or container environments.

Docker can be used for testing the script in an isolated environment. See the included Dockerfile and docker-compose.yml for details.

For detailed information about testing procedures and environments, see the [Testing documentation](Testing.md).

## Troubleshooting

### Common Issues

**Domain not reachable**: Ensure your domain's DNS records point to your server's IP address.

**Port 80/443 not accessible**: Check your firewall settings and ensure your web server is properly configured.

**Web server not running**: Make sure Apache or Nginx is installed and running.

**Rate limits**: If you hit Let's Encrypt rate limits, use the `--staging` flag for testing.

**Snap not available**: If snap is not available or preferred, use `--pip` to install via pip instead.

### Logs

Certbot logs can be found at:

*   `/var/log/letsencrypt/letsencrypt.log`

## Contributing
If you find any problems or have suggestions about this script, please submit an issue. Moreover, any pull request, code review and feedback are welcome.

### Looking to contribute? 

Start with:

- Read the [Roadmap](ROADMAP.md) for upcoming milestones
- See [Contributing Guide](CONTRIBUTING.md) for workflow & standards
- Pick an issue labeled `good-first-issue` or `m1-core`
- Open draft PRs early - questions welcome

## Unlicense

This project is licensed under the UNLICENSE License - see the UNLICENSE file for details.

## Acknowledgments

*   [Let's Encrypt](https://letsencrypt.org/) for providing free SSL certificates
*   [Certbot](https://certbot.eff.org/) for the excellent certificate management tool