#!/usr/bin/env bash
# Lint box's shell sources. Run locally (`bash scripts/lint.sh`) or in CI.
set -euo pipefail
cd "$(dirname "$0")/.."

files=(box scripts/lint.sh lib/*.sh tests/run.sh tests/lib/*.sh tests/unit/*.sh)

echo "== shellcheck"
shellcheck "${files[@]}"

if command -v shfmt >/dev/null 2>&1; then
  echo "== shfmt (diff; informational)"
  shfmt -d "${files[@]}" || echo "shfmt: formatting differences above (not enforced)"
fi

echo "lint OK"
