# Changelog

All notable changes to this project will be documented in this file.

Format: Keep a Changelog (https://keepachangelog.com/en/1.0.0/)  
Versioning: Semantic Versioning (https://semver.org/)

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