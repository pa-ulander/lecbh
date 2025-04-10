#!/bin/bash

# lecbh - Let's Encrypt Certbot Helper for Apache/Nginx on Ubuntu
# https://github.com/pa-ulander/lecbh
# Version: 1.1.0

set -e

# -------------------- CONFIG --------------------
DEFAULT_EMAIL="admin@example.com"
DEFAULT_DOMAINS="example.com"
DEFAULT_SERVER="apache" # Change to nginx if preferred
# -------------------------------------------------

DRY_RUN=false
UNATTENDED=false
VERBOSE=false
STAGING=false

# ---------- Parse Flags ----------
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --dry-run) DRY_RUN=true ;;
    --unattended) UNATTENDED=true ;;
    --verbose) VERBOSE=true ;;
    --staging) STAGING=true ;;
    --help)
        echo "Usage: sudo ./lecbh.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --dry-run      Test run without making actual changes"
        echo "  --unattended   Run with default values without prompting"
        echo "  --verbose      Show more detailed output"
        echo "  --staging      Use Let's Encrypt staging environment (for testing)"
        echo "  --help         Show this help message"
        exit 0
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo "Run with --help for usage information"
        exit 1
        ;;
    esac
    shift
done

# Function for verbose logging
log() {
    if $VERBOSE; then
        echo "🔍 $1"
    fi
}

echo "🔐 lecbh - Let's Encrypt Certbot Helper"
echo "----------------------------------------"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root (sudo)."
    exit 1
fi

# Check Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo "⚠️ This script is designed for Ubuntu. You're running: $PRETTY_NAME"
        read -p "Continue anyway? (y/n): " choice
        [[ "$choice" != "y" ]] && exit 1
    else
        log "Running on $PRETTY_NAME"
    fi
fi

# Check for required tools
if ! command -v nc >/dev/null 2>&1; then
    echo "📦 Installing netcat for network checks..."
    apt-get update && apt-get install -y netcat-openbsd
fi

# Install Certbot if needed
if ! command -v certbot >/dev/null 2>&1; then
    echo "📦 Installing Certbot via Snap..."
    snap install core
    snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
else
    echo "✅ Certbot is already installed."
fi

# Collect input
if $UNATTENDED; then
    DOMAIN_INPUT=$DEFAULT_DOMAINS
    EMAIL=$DEFAULT_EMAIL
    SERVER=$DEFAULT_SERVER
    echo "🤖 Running in unattended mode with default values:"
    echo "   Domains: $DOMAIN_INPUT"
    echo "   Email: $EMAIL"
    echo "   Server: $SERVER"
else
    read -p "🌐 Enter domain(s), comma-separated (e.g., example.com,www.example.com): " DOMAIN_INPUT
    DOMAIN_INPUT=${DOMAIN_INPUT:-$DEFAULT_DOMAINS}

    read -p "📧 Enter email for Let's Encrypt registration: " EMAIL
    EMAIL=${EMAIL:-$DEFAULT_EMAIL}

    read -p "🖥️ Which web server are you using? (apache/nginx) [default: $DEFAULT_SERVER]: " SERVER
    SERVER=${SERVER:-$DEFAULT_SERVER}
fi

# Prepare domain flags
IFS=',' read -ra DOMAINS <<<"$DOMAIN_INPUT"
DOMAIN_ARGS=""
for domain in "${DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs) # Trim whitespace
    DOMAIN_ARGS+=" -d $domain"
    log "Added domain: $domain"
done

# Optional DNS reachability check
MAIN_DOMAIN="${DOMAINS[0]}"
echo "🔍 Checking if domain $MAIN_DOMAIN is reachable..."
if ! ping -c 1 "$MAIN_DOMAIN" &>/dev/null; then
    echo "⚠️ Warning: Domain $MAIN_DOMAIN doesn't seem reachable."
    echo "   This could indicate DNS is not properly configured."
    echo "   Make sure the domain points to this server's IP address."

    if ! $UNATTENDED; then
        read -p "Continue anyway? (y/n): " choice
        [[ "$choice" != "y" ]] && exit 1
    else
        echo "   Continuing anyway (unattended mode)."
    fi
else
    echo "✅ Domain $MAIN_DOMAIN is reachable."
fi

# Web server check
if [[ "$SERVER" == "apache" ]]; then
    if ! systemctl is-active --quiet apache2; then
        echo "❌ Apache is not running or not installed."
        echo "   Please install and start Apache first:"
        echo "   sudo apt update && sudo apt install apache2 && sudo systemctl start apache2"
        exit 1
    fi
    CERTBOT_PLUGIN="--apache"
    echo "✅ Apache is running."
elif [[ "$SERVER" == "nginx" ]]; then
    if ! systemctl is-active --quiet nginx; then
        echo "❌ Nginx is not running or not installed."
        echo "   Please install and start Nginx first:"
        echo "   sudo apt update && sudo apt install nginx && sudo systemctl start nginx"
        exit 1
    fi
    CERTBOT_PLUGIN="--nginx"
    echo "✅ Nginx is running."
else
    echo "❌ Unsupported server: $SERVER"
    echo "   This script supports 'apache' or 'nginx'."
    exit 1
fi

# Check if port 80 is open
echo "🔍 Checking if port 80 is accessible..."
if ! nc -z localhost 80 >/dev/null 2>&1; then
    echo "⚠️ Warning: Port 80 doesn't seem to be accessible locally."
    echo "   Let's Encrypt requires port 80 for domain validation."

    if ! $UNATTENDED; then
        read -p "Continue anyway? (y/n): " choice
        [[ "$choice" != "y" ]] && exit 1
    else
        echo "   Continuing anyway (unattended mode)."
    fi
else
    echo "✅ Port 80 is accessible."
fi

# Check if port 443 is open (for HTTPS after setup)
echo "🔍 Checking if port 443 is accessible..."
if ! nc -z localhost 443 >/dev/null 2>&1; then
    echo "⚠️ Warning: Port 443 doesn't seem to be accessible locally."
    echo "   HTTPS requires port 443 to be open."

    if ! $UNATTENDED; then
        read -p "Continue anyway? (y/n): " choice
        [[ "$choice" != "y" ]] && exit 1
    else
        echo "   Continuing anyway (unattended mode)."
    fi
else
    echo "✅ Port 443 is accessible."
fi

# Check for existing certificates
if ! $DRY_RUN && ! $STAGING; then
    for domain in "${DOMAINS[@]}"; do
        if certbot certificates | grep -q "$domain"; then
            echo "⚠️ Certificate for $domain already exists."
            if ! $UNATTENDED; then
                read -p "Do you want to renew/replace it? (y/n): " choice
                [[ "$choice" != "y" ]] && exit 0
            else
                echo "   Continuing with renewal/replacement (unattended mode)."
            fi
        fi
    done
fi

# Build certbot command
if $DRY_RUN; then
    echo "🧪 Running in dry-run mode (no changes will be made)."
    CERTBOT_CMD="certbot certonly $CERTBOT_PLUGIN $DOMAIN_ARGS --email $EMAIL --agree-tos --redirect --non-interactive --dry-run"
else
    CERTBOT_CMD="certbot $CERTBOT_PLUGIN $DOMAIN_ARGS --email $EMAIL --agree-tos --redirect --non-interactive"
fi

# Add staging flag if enabled
if $STAGING; then
    echo "🧪 Using Let's Encrypt staging environment."
    CERTBOT_CMD+=" --staging"
fi

# Execute certbot
echo "🚀 Running: $CERTBOT_CMD"
if $VERBOSE; then
    eval $CERTBOT_CMD
else
    eval $CERTBOT_CMD >/dev/null 2>&1 && echo "✅ Certificate request successful!" || {
        echo "❌ Certificate request failed!"
        exit 1
    }
fi

# Renewal test
if ! $DRY_RUN; then
    echo "🔄 Testing auto-renewal..."
    if $VERBOSE; then
        certbot renew --dry-run
    else
        certbot renew --dry-run >/dev/null 2>&1 && echo "✅ Renewal test successful!" || {
            echo "❌ Renewal test failed!"
            exit 1
        }
    fi

    # Check renewal service
    if systemctl is-active --quiet certbot.timer; then
        echo "✅ Automatic renewal service is active."
    else
        echo "⚠️ Warning: Automatic renewal service doesn't seem to be active."
        echo "   Setting up systemd timer for automatic renewal..."
        systemctl enable certbot.timer
        systemctl start certbot.timer
    fi
fi

# Display certificate information
if ! $DRY_RUN && ! $STAGING; then
    echo ""
    echo "📊 Certificate Information:"
    if $VERBOSE; then
        certbot certificates
    else
        certbot certificates | grep -E "Certificate Name:|Expiry Date:" | sed 's/^/   /'
    fi
fi

# Final success message
echo ""
echo "✅ SSL setup complete!"
if $DRY_RUN; then
    echo "🧪 Dry run completed successfully — no certificates were issued."
elif $STAGING; then
    echo "🧪 Staging certificates issued — these are NOT trusted by browsers."
    echo "   Run without --staging to get real certificates."
else
    echo "🔒 Your site should now be accessible via HTTPS."
    echo "   Certificates will automatically renew when needed."
fi

# Security recommendations
echo ""
echo "📝 Recommended next steps:"
echo "   1. Test your site's SSL configuration: https://www.ssllabs.com/ssltest/"
echo "   2. Consider setting up HTTP Strict Transport Security (HSTS)"
echo "   3. Verify that automatic redirects from HTTP to HTTPS are working"

exit 0
