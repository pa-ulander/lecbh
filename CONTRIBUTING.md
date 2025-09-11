# Contributing to lecbh

Thanks for your interest in contributing! This guide explains how to get set up, propose changes, and keep quality high.

## Quick Start
```bash
git clone https://github.com/pa-ulander/lecbh.git
cd lecbh
./test.sh          # run integration tests (Docker required)
./lecbh.sh --help  # see current CLI
```

## Development Workflow
1. Fork repository & create a feature branch: `git checkout -b feature/short-desc`
2. Make changes (add tests & docs updates where needed)
3. Run checks:
   - `./test.sh`
   - `shellcheck lecbh.sh`
   - (future) `scripts/dev/check.sh`
4. Update `CHANGELOG.md` (Unreleased section) if user visible
5. Open a Pull Request (PR) early as draft for feedback
6. Ensure CI passes

## Commit Style
Use Conventional Commit prefixes when possible:
- `feat:` new user-facing feature
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` internal change (no behavior impact)
- `test:` tests only
- `chore:` tasks, tooling, maintenance

Example: `feat: add --version flag`

## Testing
- `test.sh` spins a container and exercises flows (dry-run, mock certbot, pip, snap)
- Keep tests fast & deterministic (prefer mock / staging / test-mode)
- Add new scenarios when adding flags or behavioral changes

## Style & Lint
- Follow existing Bash style; use functions & defensive checks
- Prefer arrays for command construction
- Avoid `eval`
- Keep `set -euo pipefail` at top
- Logging helpers must never exit non-zero

## Adding Features
Before large changes (new subcommands, plugin system), open an issue tagged `needs-design` to discuss interface & scope.

## Roadmap
See `ROADMAP.md` for milestone-aligned tasks. Issues labeled `good-first-issue` are ideal starting points.

## Reporting Bugs
Open an issue with:
- What happened vs expected
- Reproduction command(s)
- Environment (OS version, install method)
- Script output snippet (trim sensitive info)

## Security
Report vulnerabilities privately—see `SECURITY.md`.

## Code of Conduct
Participation requires following the `CODE_OF_CONDUCT.md`.

## Getting Help
Feel free to open an issue with the `question` label—even for early design questions.

Thanks for helping improve lecbh! 🙌
