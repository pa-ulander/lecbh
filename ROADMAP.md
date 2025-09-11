# lecbh Roadmap & TODOs

This document outlines the planned evolution of **lecbh** from a single Bash helper script into a lightweight, embeddable ACME (Let's Encrypt) automation layer suitable for hosting panels and automated environments.

## Guiding Principles
- Idempotent & deterministic execution
- Safe web server modifications with rollback
- Clear, stable machine interfaces (JSON & exit codes)
- Pluggable challenge & integration layers
- Minimal external dependencies; shell-native

## Milestones Overview
| Milestone | Focus               | Key Outcomes                                      |
| --------- | ------------------- | ------------------------------------------------- |
| M1        | Core & Subcommands  | Library split, JSON schema, `issue`/`list` basics |
| M2        | DNS & Plugins       | dns-01 providers, plugin loader, notifications    |
| M3        | Renewal & Packaging | Scheduler, metrics, deb/OCI packaging             |
| M4        | Security & Scale    | Rollback, privilege drop, parallel issuance       |
| M5        | Ecosystem           | Control panel SDK, distribution, optional UI      |

---
## M1 – Core Refactor & Interfaces
**Goal:** Establish a clean internal API and predictable output.
- [ ] Extract core logic into `lib/core.sh` (pure functions; no direct I/O)
- [ ] Introduce subcommand structure: `lecbh <command>` with:
  - [ ] `issue` (current default behavior)
  - [ ] `list` (placeholder; returns static or detected certs)
  - [ ] Legacy shim: running without subcommand maps to `issue`
- [ ] Add `--version` and `version` subcommand
- [ ] Define JSON result schema in `docs/json-schema.md`
- [ ] Optional JSON Lines mode: `--output=jsonl` (progress events)
- [ ] Implement `--log-format=json|text`
- [ ] Add basic Bats tests for: flag parsing, JSON schema validation, lock acquisition
- [ ] Add `shfmt` + CI formatting check
- [ ] Add CONTRIBUTING.md with development workflow

### Stretch (M1)
- [ ] Config file support `--config=/path` (KEY=VALUE)
- [ ] Deterministic field ordering in JSON (documented)

---
## M2 – Plugins & DNS-01 Support
**Goal:** Support wildcard issuance and integrations.
- [ ] Create `plugins/` directory and dynamic loader
- [ ] Define plugin contract documentation `docs/plugins.md`
- [ ] Implement server plugins (core): `apache`, `nginx`
- [ ] Add DNS plugin interface: `dns_present`, `dns_cleanup`
- [ ] Providers (env token based):
  - [ ] Cloudflare
  - [ ] DigitalOcean
  - [ ] Route53
  - [ ] Hetzner
- [ ] Generic RFC2136 plugin
- [ ] Add `--challenge=http-01|dns-01|auto` selection
- [ ] Automatic wildcard → force dns-01 path
- [ ] Notification plugin type + sample (webhook)
- [ ] Add sample notify plugin for Slack/Discord webhook

### Stretch (M2)
- [ ] GitHub Actions matrix: Ubuntu LTS, Debian stable, Alpine (pip path only)
- [ ] Mock DNS provider for CI test determinism

---
## M3 – Renewal & Packaging
**Goal:** First-class managed lifecycle + distribution.
- [ ] Renewal scheduler mode `lecbh daemon` (loop / sleep / backoff)
- [ ] Systemd unit & timer template generation command `lecbh install-timer`
- [ ] Certificate inventory index (`~/.lecbh/index.json`)
- [ ] `list` shows: domains, expiry, days_left, method, path
- [ ] Add `inspect <domain>` command (reads metadata)
- [ ] Metrics exporter: `--metrics-file=/path/metrics.prom`
- [ ] Deb packaging script (`packaging/deb/`)
- [ ] OCI image build workflow (`ghcr.io/.../lecbh:<version>`)
- [ ] Homebrew tap formula template
- [ ] Add CHANGELOG automation (Conventional Commits via script)

### Stretch (M3)
- [ ] JSON schema versioning + compatibility tests
- [ ] Cron fallback generator for non-systemd systems

---
## M4 – Security, Reliability & Scale
**Goal:** Harden operations & support larger deployments.
- [ ] Pre-change validation: `apachectl -t` / `nginx -t`
- [ ] Fail-safe rollback if validation fails post-injection
- [ ] Hash & store original vhost snippet (integrity file)
- [ ] Privilege drop post-cat of challenge (optional flag)
- [ ] Key permission enforcement (0600) + `umask 077`
- [ ] Support `--key-type=rsa|ecdsa` (ecc default experiment flag)
- [ ] OCSP must-staple flag `--must-staple`
- [ ] Parallel issuance: `--parallel=N` (queue + lock granularity by domain set)
- [ ] Multi-tenant namespace prefix: `--tenant=<id>` (isolated storage root)
- [ ] Structured error codes doc (`docs/error-codes.md`)

### Stretch (M4)
- [ ] Optional Redis advisory lock support
- [ ] ACME External Account Binding

---
## M5 – Ecosystem & Integration
**Goal:** Make embedding easy for control panels & clusters.
- [ ] Library mode: `LECBH_MODE=library` (silences UI, strict JSON only)
- [ ] Control panel example integration (`examples/controlpanel/`)
- [ ] Distribution plugin: rsync/scp sync to remote nodes
- [ ] Web UI (read-only) minimal (optional static site generator)
- [ ] gRPC or Unix socket micro-API (experimental)
- [ ] Policy engine: skip renew unless < X days or force
- [ ] Webhook events for lifecycle phases (issue_start, issue_success, issue_fail, renew_success)
- [ ] Documentation site (mkdocs or GitHub Pages)

### Stretch (M5)
- [ ] Cluster shared cache for ACME directory & rate-limit tracking
- [ ] Interactive TUI for terminal dashboards

---
## General Cross-Cutting TODOs
- [ ] Improve test isolation (temp dirs, fixture configs)
- [ ] Add shellcheck severity gating (treat certain SC codes as warnings only)
- [ ] Performance profiling script (measure time per phase)
- [ ] Caching: ACME directory endpoint + challenge reuse where safe
- [ ] Add `doctor` command (environment diagnostics)
- [ ] Enhanced troubleshooting guide (`docs/troubleshooting.md`)
- [ ] Add CODEOWNERS file
- [ ] Security review checklist (`docs/security-checklist.md`)

---
## JSON Output Contract (Draft Summary)
- Top-level fields: `status`, `command`, `domains`, `email`, `server`, `challenge`, `redirect`, `dry_run`, `staging`, `test_mode`, `install_method`, `started_at`, `finished_at`, `duration_ms`, `version`, `messages[]`, `errors[]`.
- Status enums: `success`, `partial`, `skipped`, `error`.

---
## Proposed Error Code Ranges (Draft)
| Range  | Purpose                   |
| ------ | ------------------------- |
| 0      | Success                   |
| 10–29  | Input / validation errors |
| 30–49  | Environment / dependency  |
| 50–69  | Network / DNS             |
| 70–89  | ACME / challenge          |
| 90–109 | Web server integration    |
| 120+   | Internal / unexpected     |

---
## Contribution Guidance (Snapshot)
1. Fork & branch: `feature/<short-desc>`
2. Run tests: `./test.sh` (add new ones for features)
3. Run shellcheck + shfmt
4. Update CHANGELOG (Unreleased section)
5. Provide docs updates with behavioral changes

---
## Open Questions / Design Decisions Pending
- Should plugin discovery fail hard or soft on errors? (default: soft + warn)
- Standard for secrets: environment only vs optional `.env` file
- ECDSA default timing (which curve: P-256 vs P-384?)
- Inventory storage format extensibility (JSON vs directory per cert with metadata file)

---
## Tracking & Labels
Recommended GitHub labels:
- `m1-core` `m2-dns` `m3-renewal` `m4-security` `m5-ecosystem`
- `plugin` `doc` `bug` `enhancement` `good-first-issue` `help-wanted`
- `breaking-change` `needs-design` `security` `testing`

---
## Quick Start for New Contributors
```bash
# Run style & static checks (future placeholder)
./scripts/dev/check.sh

# Issue a dry-run JSON plan (future subcommand form)
./lecbh.sh issue --dry-run --json --domains=example.com --email=admin@example.com
```

---
*This roadmap will evolve; propose updates via PRs to keep it living and accurate.*
