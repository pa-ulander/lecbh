#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[check] ShellCheck"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck lecbh.sh || { echo "ShellCheck failed"; exit 1; }
else
  echo "ShellCheck not installed (skipping)"
fi

echo "[check] Formatting (shfmt)"
if command -v shfmt >/dev/null 2>&1; then
  shfmt -d . || { echo "Run: shfmt -w ."; exit 1; }
else
  echo "shfmt not installed (skipping)"
fi

echo "[check] Integration tests"
if [[ -f test.sh ]]; then
  ./test.sh || { echo "Tests failed"; exit 1; }
fi

echo "All checks passed"
