#!/usr/bin/env bash
set -euo pipefail

# Detect the test framework used by the project.
# Outputs one of: pytest, npm test, go test, cargo test, or asks user.

PROJECT_ROOT="${1:-$(pwd)}"

detect() {
  if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    if grep -E '"jest"|"mocha"|"vitest"' "$PROJECT_ROOT/package.json" >/dev/null 2>&1; then
      echo "npm test"
      return 0
    fi
  fi

  if [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/setup.cfg" ]]; then
    if grep -qi 'pytest' "$PROJECT_ROOT/pyproject.toml" 2>/dev/null || grep -qi 'pytest' "$PROJECT_ROOT/setup.cfg" 2>/dev/null; then
      echo "pytest"
      return 0
    fi
  fi

  if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
    echo "go test ./..."
    return 0
  fi

  if [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
    echo "cargo test"
    return 0
  fi

  return 1
}

DETECTED=$(detect) || DETECTED=""

if [[ -n "$DETECTED" ]]; then
  echo "$DETECTED"
  exit 0
fi

echo "UNKNOWN"
exit 1
