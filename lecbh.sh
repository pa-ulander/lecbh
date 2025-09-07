#!/usr/bin/env bash

# lecbh - Let's Encrypt Certbot Helper for Apache/Nginx on Ubuntu
# https://github.com/pa-ulander/lecbh
# Version: 1.1.0

set -euo pipefail
IFS=$'\n\t'
LOCK_FILE="${LECBH_LOCK_FILE:-/var/run/lecbh.lock}"
JSON_MODE=false

cleanup() {
    local ec=$?
    # Remove lock if owned by this PID
    if [[ -f "$LOCK_FILE" ]] && grep -q "^PID=$$" "$LOCK_FILE" 2>/dev/null; then
        rm -f "$LOCK_FILE" || true
    fi
    if [[ $ec -ne 0 ]]; then
        echo "❌ Error at line $LINENO (exit $ec)" >&2
    fi
}

trap cleanup EXIT ERR INT TERM

# -------------------- DEFAULT CONFIG (env overrides allowed) --------------------
: "${DEFAULT_EMAIL:=admin@example.com}"
: "${DEFAULT_DOMAINS:=example.com}"
: "${DEFAULT_SERVER:=apache}"
: "${DEFAULT_INSTALL_METHOD:=snap}" # snap | pip
: "${LECBH_NO_COLOR:=0}" # set to 1 to disable emojis/colors
# --------------------------------------------------------------------------------

DRY_RUN=false
UNATTENDED=false
VERBOSE=false
STAGING=false
TEST_MODE=false
QUIET=false
NO_REDIRECT=false
INSTALL_METHOD="$DEFAULT_INSTALL_METHOD"

SERVER=""
EMAIL_OVERRIDE=""
DOMAINS_OVERRIDE=""

COLOR_OK="✅"; COLOR_WARN="⚠️"; COLOR_ERR="❌"; COLOR_INFO="🔍"; COLOR_KEY="🔐"
if [[ "$LECBH_NO_COLOR" == "1" ]]; then
    COLOR_OK="[OK]"; COLOR_WARN="[WARN]"; COLOR_ERR="[ERR]"; COLOR_INFO="[INFO]"; COLOR_KEY="[LECBH]"
fi

usage() {
    cat <<EOF
Usage: sudo ./lecbh.sh [OPTIONS]

Options:
    --dry-run                Use certbot --dry-run (no real certs)
    --unattended             Non-interactive: use defaults or provided flags
    --verbose                Verbose logging
    --quiet                  Minimal output (overrides verbose)
    --staging                Use Let's Encrypt staging environment
    --test-mode              Do not install real certbot; use mock (CI/testing)
    --pip                    Force pip install method
    --snap                   Force snap install method (default)
    --server=apache|nginx    Web server type (overrides DEFAULT_SERVER)
    --email=ADDR             Email address (overrides DEFAULT_EMAIL)
    --domains=a.com,b.com    Comma separated domain list
    --no-redirect            Do not force HTTP->HTTPS redirect
    --json                   Output machine-readable JSON summary (implies quiet except errors)
    --help                   Show this help and exit

Examples:
    sudo ./lecbh.sh --unattended --server=nginx \\
             --domains=example.org,www.example.org --email=admin@example.org
    sudo ./lecbh.sh --dry-run --staging --unattended
EOF
}

log() { if $VERBOSE && ! $QUIET; then echo "${COLOR_INFO} $*" >&2; fi; return 0; }
info() { if ! $QUIET; then echo "$*" >&2; fi; return 0; }
warn() { echo "${COLOR_WARN} $*" >&2; return 0; }
die() { echo "${COLOR_ERR} $*" >&2; exit 1; }

parse_flags() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run) DRY_RUN=true ;;
            --unattended) UNATTENDED=true ;;
            --verbose) VERBOSE=true ;;
            --quiet) QUIET=true ; VERBOSE=false ;;
            --staging) STAGING=true ;;
            --test-mode) TEST_MODE=true ;;
            --pip) INSTALL_METHOD="pip" ;;
            --snap) INSTALL_METHOD="snap" ;;
            --server=*) SERVER="${1#*=}" ;;
            --email=*) EMAIL_OVERRIDE="${1#*=}" ;;
            --domains=*) DOMAINS_OVERRIDE="${1#*=}" ;;
            --no-redirect) NO_REDIRECT=true ;;
            --json) JSON_MODE=true ; QUIET=true ; VERBOSE=false ;;
            --help) usage; exit 0 ;;
            *) die "Unknown option: $1 (use --help)" ;;
        esac
        shift
    done
}

validate_email() { [[ $1 =~ ^[^@]+@[^@]+\.[^@]+$ ]] || die "Invalid email: $1"; }
validate_domain() { [[ $1 =~ ^([A-Za-z0-9*-]+\.)+[A-Za-z]{2,}$ ]] || die "Invalid domain: $1"; }

resolve_domain() {
    local d=$1
    if getent ahosts "$d" >/dev/null 2>&1; then
        log "Resolved $d"
        return 0
    else
        warn "Could not resolve domain $d"
        return 1
    fi
}

ensure_root() { [[ $EUID -eq 0 ]] || die "Please run as root (sudo)."; }

ensure_prereqs() {
    command -v nc >/dev/null 2>&1 || { info "Installing netcat-openbsd"; apt-get update -y && apt-get install -y netcat-openbsd >/dev/null 2>&1; }
}

prepare_mock_certbot() {
    local mock_dir="/tmp/lecbh-mock"
    mkdir -p "$mock_dir"
    cat >"$mock_dir/certbot" <<'MOCK'
#!/usr/bin/env bash
echo "[lecbh mock certbot] $*"
if [[ "$*" == *"certificates"* ]]; then
    echo "No certificates found (mock)."
fi
exit 0
MOCK
    chmod +x "$mock_dir/certbot"
    export PATH="$mock_dir:$PATH"
    log "Using mock certbot in test mode"
}

install_certbot() {
    if $TEST_MODE; then
        if [[ "${LECBH_TEST_INSTALL:-0}" == "1" ]]; then
            # Perform real install only once per method to exercise installer path
            local marker="/var/lib/lecbh_real_install_${INSTALL_METHOD}"
            if [[ ! -f $marker ]]; then
                log "Test mode (install): performing one-time real install for method=${INSTALL_METHOD}"
                command -v certbot >/dev/null 2>&1 || {
                    case $INSTALL_METHOD in
                        snap)
                            command -v snap >/dev/null 2>&1 || die "snap command not found; install snapd or use --pip"
                            info "📦 Installing certbot via snap..."
                            snap install core >/dev/null 2>&1 || true
                            snap refresh core >/dev/null 2>&1 || true
                            snap install --classic certbot >/dev/null 2>&1 || die "Failed snap install of certbot"
                            ln -sf /snap/bin/certbot /usr/bin/certbot
                            ;;
                        pip)
                            info "📦 Installing certbot via pip..."
                            command -v pip3 >/dev/null 2>&1 || { apt-get update -y && apt-get install -y python3-pip >/dev/null 2>&1; }
                            if [[ ! -f /var/lib/lecbh_pip_deps_installed ]]; then
                                mkdir -p /var/lib || true
                                (apt-get update -y && apt-get install -y --no-install-recommends \
                                    build-essential gcc python3-dev libssl-dev libffi-dev \
                                    libaugeas0 libaugeas-dev augeas-tools >/dev/null 2>&1 && \
                                    touch /var/lib/lecbh_pip_deps_installed) || warn "Failed to install some build dependencies for pip method"
                            fi
                            pip3 install --quiet certbot || die "Failed to install certbot via pip"
                            pip3 install --quiet certbot-apache certbot-nginx || warn "Failed to install one or more certbot plugins"
                            ln -sf /usr/local/bin/certbot /usr/bin/certbot || true
                            ;;
                        *) die "Unknown INSTALL_METHOD: $INSTALL_METHOD" ;;
                    esac
                }
                touch "$marker" || true
            else
                log "Test mode (install): real install already performed (${INSTALL_METHOD})"
            fi
            # Always overlay mock after ensuring real install once
            prepare_mock_certbot
            return 0
        else
            info "${COLOR_INFO} Test mode: forcing mock certbot"
            prepare_mock_certbot
            return 0
        fi
    fi
    # Normal (non-test) path
    if command -v certbot >/dev/null 2>&1; then
        log "Certbot already present"
        return 0
    fi
    case $INSTALL_METHOD in
        snap)
            command -v snap >/dev/null 2>&1 || die "snap command not found; install snapd or use --pip"
            info "📦 Installing certbot via snap..."
            snap install core >/dev/null 2>&1 || true
            snap refresh core >/dev/null 2>&1 || true
            snap install --classic certbot >/dev/null 2>&1 || die "Failed snap install of certbot"
            ln -sf /snap/bin/certbot /usr/bin/certbot
            ;;
        pip)
            info "📦 Installing certbot via pip..."
            command -v pip3 >/dev/null 2>&1 || { apt-get update -y && apt-get install -y python3-pip >/dev/null 2>&1; }
            if [[ ! -f /var/lib/lecbh_pip_deps_installed ]]; then
                mkdir -p /var/lib || true
                (apt-get update -y && apt-get install -y --no-install-recommends \
                    build-essential gcc python3-dev libssl-dev libffi-dev \
                    libaugeas0 libaugeas-dev augeas-tools >/dev/null 2>&1 && \
                    touch /var/lib/lecbh_pip_deps_installed) || warn "Failed to install some build dependencies for pip method"
            fi
            pip3 install --quiet certbot || die "Failed to install certbot via pip"
            if [[ $SERVER == apache ]]; then
                pip3 install --quiet certbot-apache || warn "Failed to install certbot-apache plugin"
            elif [[ $SERVER == nginx ]]; then
                pip3 install --quiet certbot-nginx || warn "Failed to install certbot-nginx plugin"
            fi
            ln -sf /usr/local/bin/certbot /usr/bin/certbot || true
            ;;
        *) die "Unknown INSTALL_METHOD: $INSTALL_METHOD" ;;
    esac
}

ensure_server_running() {
    local server=$1
    case $server in
        apache)
            command -v apache2 >/dev/null 2>&1 || die "Apache not installed"
            if ! pgrep -x apache2 >/dev/null 2>&1; then
                service apache2 start >/dev/null 2>&1 || true
            fi
            pgrep -x apache2 >/dev/null 2>&1 || warn "Apache process not detected (continuing)"
            CERTBOT_PLUGIN="--apache"
            ;;
        nginx)
            command -v nginx >/dev/null 2>&1 || die "Nginx not installed"
            if ! pgrep -x nginx >/dev/null 2>&1; then
                service nginx start >/dev/null 2>&1 || true
            fi
            pgrep -x nginx >/dev/null 2>&1 || warn "Nginx process not detected (continuing)"
            CERTBOT_PLUGIN="--nginx"
            ;;
        *) die "Unsupported server: $server" ;;
    esac
}

check_ports() {
    local missing=false
    # Temporarily disable errexit for port probing
    set +e
    nc -z localhost 80 >/dev/null 2>&1
    local p80=$?
    nc -z localhost 443 >/dev/null 2>&1
    local p443=$?
    set -e
    if [[ $p80 -ne 0 ]]; then
        warn "Port 80 not open"; missing=true
    fi
    if [[ $p443 -ne 0 ]]; then
        warn "Port 443 not open (expected after issuance)"
    fi
    if $missing && ! $UNATTENDED; then
        read -r -p "Continue despite port 80 closed? (y/N): " c
        [[ ${c:-n} == y ]] || die "Aborted by user"
    fi
    return 0
}

check_existing_certs() {
    $DRY_RUN || $STAGING || $TEST_MODE || return 0
    return 0 # logic skipped in dry-run/staging/test modes intentionally
}

build_certbot_args() {
    CERTBOT_ARGS=(certbot certonly)
    CERTBOT_ARGS+=("$CERTBOT_PLUGIN")
    for d in "${DOMAINS[@]}"; do CERTBOT_ARGS+=( -d "$d" ); done
    CERTBOT_ARGS+=( --email "$EMAIL" --agree-tos --non-interactive )
    if $DRY_RUN; then CERTBOT_ARGS+=( --dry-run ); fi
    if $STAGING; then CERTBOT_ARGS+=( --staging ); fi
    if ! $NO_REDIRECT; then CERTBOT_ARGS+=( --redirect ); fi
}

run_certbot() {
    info "🚀 Running: ${CERTBOT_ARGS[*]}"
    ${CERTBOT_ARGS[@]} || die "Certbot command failed"
    $DRY_RUN && info "${COLOR_OK} Dry run completed" || info "${COLOR_OK} Certificate request successful"
}

test_renewal() {
    ($DRY_RUN || $TEST_MODE) && return 0
    info "🔄 Testing renewal (dry-run)"
    certbot renew --dry-run >/dev/null 2>&1 || warn "Renewal dry-run failed"
    if [[ $INSTALL_METHOD == snap ]]; then
        systemctl is-active --quiet certbot.timer 2>/dev/null && log "certbot.timer active" || warn "certbot.timer not active"
    elif [[ $INSTALL_METHOD == pip ]]; then
        crontab -l 2>/dev/null | grep -q 'certbot renew' || {
            (crontab -l 2>/dev/null; echo "0 */12 * * * /usr/bin/certbot renew --quiet") | crontab -
            log "Installed cron renewal"
        }
    fi
}

final_report() {
    if $TEST_MODE; then
        info "🧪 Test mode complete (no real certificates)"; return
    fi
    if $DRY_RUN; then
        info "🧪 Dry-run finished (no real certificates)"; return
    fi
    if $STAGING; then
        info "🧪 Staging certificates issued (not browser-trusted)"; return
    fi
    info "🔒 Your site should now be accessible via HTTPS."
}

main() {
    parse_flags "$@"
    ensure_root
    info "${COLOR_KEY} lecbh - Let's Encrypt Certbot Helper"
    info "----------------------------------------"

    # Concurrency lock
    if [[ -f "$LOCK_FILE" ]]; then
        if grep -q '^PID=' "$LOCK_FILE"; then
            existing_pid=$(grep '^PID=' "$LOCK_FILE" | cut -d'=' -f2)
            if [[ -n "$existing_pid" && -d "/proc/$existing_pid" ]]; then
                die "Another lecbh instance is running (PID $existing_pid). Use LECBH_LOCK_FILE to override."
            fi
        fi
        warn "Stale lock file found; removing"
        rm -f "$LOCK_FILE" || true
    fi
    echo "PID=$$" > "$LOCK_FILE" 2>/dev/null || warn "Cannot create lock file ($LOCK_FILE). Continuing without lock."

    # Determine interactive inputs
    DOMAIN_INPUT=${DOMAINS_OVERRIDE:-$DEFAULT_DOMAINS}
    EMAIL=${EMAIL_OVERRIDE:-$DEFAULT_EMAIL}
    SERVER=${SERVER:-$DEFAULT_SERVER}

    if ! $UNATTENDED; then
        read -r -p "🌐 Domains [$DOMAIN_INPUT]: " inp || true; DOMAIN_INPUT=${inp:-$DOMAIN_INPUT}
        read -r -p "📧 Email [$EMAIL]: " inp || true; EMAIL=${inp:-$EMAIL}
        read -r -p "🖥️ Server (apache/nginx) [$SERVER]: " inp || true; SERVER=${inp:-$SERVER}
        read -r -p "🔧 Install method (snap/pip) [$INSTALL_METHOD]: " inp || true; INSTALL_METHOD=${inp:-$INSTALL_METHOD}
    else
        log "Unattended mode values: domains=$DOMAIN_INPUT email=$EMAIL server=$SERVER method=$INSTALL_METHOD"
    fi

    validate_email "$EMAIL"
    IFS=',' read -r -a DOMAINS <<<"$DOMAIN_INPUT"
    local cleaned=()
    for d in "${DOMAINS[@]}"; do
        d=$(echo "$d" | xargs)
        [[ -z $d ]] && continue
        validate_domain "$d"
        cleaned+=("$d")
    done
    DOMAINS=(${cleaned[@]})
    [[ ${#DOMAINS[@]} -gt 0 ]] || die "No valid domains provided"

    resolve_domain "${DOMAINS[0]}" || warn "Primary domain not resolvable"

    ensure_prereqs
    install_certbot
    ensure_server_running "$SERVER"
    check_ports
    check_existing_certs
    build_certbot_args
    run_certbot
    test_renewal
    final_report

    if $JSON_MODE; then
        # Build JSON object
        # Build proper JSON array of domains
        if ((${#DOMAINS[@]})); then
            domains_json="["
            for i in "${!DOMAINS[@]}"; do
                d=${DOMAINS[$i]}
                if [[ $i -gt 0 ]]; then domains_json+=","; fi
                domains_json+="\"$d\""
            done
            domains_json+="]"
        else
            domains_json="[]"
        fi
        cat <<JEOF
{
  "domains": $domains_json,
  "email": "${EMAIL}",
  "server": "${SERVER}",
  "install_method": "${INSTALL_METHOD}",
  "dry_run": ${DRY_RUN},
  "staging": ${STAGING},
  "test_mode": ${TEST_MODE},
  "redirect": $(! $NO_REDIRECT && echo true || echo false),
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "1.1.0"
}
JEOF
    else
        info "\n📝 Next steps:"
        info "   1. Test SSL: https://www.ssllabs.com/ssltest/"
        info "   2. Consider enabling HSTS"
        info "   3. Verify HTTP->HTTPS redirect (if enabled)"
    fi
    # Optional delay (for testing lock behavior)
    if [[ -n "${LECBH_SLEEP_BEFORE_EXIT:-}" ]]; then
        sleep "$LECBH_SLEEP_BEFORE_EXIT"
    fi
}

main "$@"
