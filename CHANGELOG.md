# Changelog

All notable changes to this project will be documented in this file.

Format: Keep a Changelog (https://keepachangelog.com/en/1.0.0/)  
Versioning: Semantic Versioning (https://semver.org/)

## [1.1.0] - 2025-09-07
### Added
- JSON output mode (`--json`) producing a machine-readable operation summary.
- Quiet mode (`--quiet`) for reduced logging (implicitly enabled by `--json`).
- Flag-based overrides for server, email, and domains: `--server=`, `--email=`, `--domains=`.
- Concurrency lock mechanism (default `/var/run/lecbh.lock`, override with `LECBH_LOCK_FILE`).
- `--no-redirect` flag to skip automatic HTTP→HTTPS redirect.
- Environment variable overrides for defaults (`DEFAULT_EMAIL`, `DEFAULT_DOMAINS`, `DEFAULT_SERVER`, `DEFAULT_INSTALL_METHOD`).
- Mock certbot enhancements in `--test-mode` with optional one-time real install path via `LECBH_TEST_INSTALL=1`.
- Email & domain validation logic with clear failure messages.
- Color/emoji suppression via `LECBH_NO_COLOR=1`.
- New ShellCheck lint workflow (`.github/workflows/shellcheck.yml`).

### Changed
- Script now uses `#!/usr/bin/env bash` and enforces `set -euo pipefail` with a stricter `IFS`.
- Refactored into modular functions (parsing, validation, install, execution, reporting).
- Help/usage text reorganized and expanded.
- Default configuration expressed via environment overrides instead of editing static lines.
- Certbot installation logic installs only relevant plugins for the chosen server.

### Improved
- Logging clarity (separation of verbose vs quiet, structured progress messages).
- Port 80/443 and domain resolution checks now produce actionable warnings.
- More robust error handling and exit codes with contextual messages.
- Renewal setup feedback and mock behavior in test mode.
- Test script coverage (JSON, invalid inputs, concurrency, pip/snap paths, no-redirect scenarios).

### Fixed
- Prevented overlapping executions through PID-based lock file.
- Eliminated potential quoting/whitespace pitfalls in argument handling.
- Normalized behavior / exit codes on invalid domain/email input.
- Reduced risk of silent failures during certbot or dependency installation.
- (Pre-release note) Version mismatch identified between header (1.1.0) and JSON output ("1.2.0")—to be aligned.

### Documentation
- README: Added JSON Output Mode & Concurrency Lock sections; updated options table; examples for env overrides.
- Testing.md: Refreshed scenarios list (JSON mode, concurrency, invalid input tests), streamlined manual test examples.
- Clarified development/testing usage of `--staging`, `--test-mode`, and domain/server flags.

### CI / Internal
- Added ShellCheck workflow for static analysis.
- Simplified test workflow (removed complex caching; explicit Apache/Nginx dry-run phases; JSON & concurrency tests).
- Expanded `test.sh` with new numbered tests (invalid inputs, JSON, concurrency, no-redirect, staging combinations).
- Safer mock certbot injection with controlled PATH and optional real install pass.

### Notes
- No breaking changes; previous invocation patterns continue to work.
- Recommend switching from editing defaults in the script to env/flag overrides for automation.

[1.1.0]: https://github.com/pa-ulander/lecbh/compare/v1.0.0...v1.1.0


## [1.0.0] - 2025-09-06
### Added
- Initial stable release of lecbh.
- Automated end-to-end Let's Encrypt certificate acquisition for Apache and Nginx.
- Multiple domain (SAN) support via comma-separated input.
- Support for both snap (default) and pip installation methods for Certbot.
- Automatic renewal setup:
  - systemd timer integration for snap installations.
  - Cron-based renewal scheduling for pip installations.
- Dry-run mode (`--dry-run`) for non-invasive execution tests.
- Staging environment option (`--staging`) to prevent hitting production rate limits.
- Unattended mode (`--unattended`) with configurable default values (email, domains, server type, install method).
- Verbose output mode (`--verbose`) for detailed operational insight.
- Test mode (`--test-mode`) tailored for container or CI environments (skips actual installation steps).
- Dockerfile and docker-compose.yml for isolated/local testing scenarios.
- GitHub Actions workflow (test.yml) for automated testing.
- Testing documentation (Testing.md) describing test strategies and environments.
- Troubleshooting guidance and log path references in README.
- Licensing under UNLICENSE.

### Files Introduced / Key Artifacts
- `lecbh.sh` (primary automation script)
- `test.sh`, `test.yml` (testing harness and CI workflow)
- `Dockerfile`, `docker-compose.yml` (containerized test environment)
- `Testing.md` (testing procedures)
- `README.md` (feature overview, usage, troubleshooting)
- `UNLICENSE` (public domain dedication)

[1.0.0]: https://github.com/pa-ulander/lecbh/releases/tag/v1.0.0