#!/usr/bin/env bash
set -euo pipefail

# Detect the test framework used by the project.
#
# Strategy (most confident first):
#   1. Look for existing test files in the repo and map them to a framework.
#      This is the most reliable signal — it reflects what the project already runs.
#   2. If no test files exist, fall back to the project's primary language
#      (by manifest file or dominant source extension) and pick a sensible default.
#
# Outputs one of: pytest | npm test | go test ./... | cargo test | mvn test | gradle test | UNKNOWN

PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

# Helper: does `find` match anything (ignoring noisy dirs)?
_has() {
  [[ -n "$(find . \( -path ./node_modules -o -path ./target -o -path ./venv -o -path ./.venv -o -path ./__pycache__ \) -prune -o "$@" -print 2>/dev/null | head -n1)" ]]
}

detect_from_existing_tests() {
  # Python
  if _has \( -name 'test_*.py' -o -name '*_test.py' \); then
    echo "pytest"; return 0
  fi
  # JS / TS (jest, mocha, vitest all run via npm test)
  if _has \( -name '*.test.js' -o -name '*.spec.js' -o -name '*.test.ts' -o -name '*.spec.ts' \); then
    echo "npm test"; return 0
  fi
  # Go
  if _has -name '*_test.go'; then
    echo "go test ./..."; return 0
  fi
  # Rust
  if _has -name '*.rs' && [[ -f Cargo.toml ]]; then
    echo "cargo test"; return 0
  fi
  # Java (detect build tool too)
  if _has \( -name '*Test.java' -o -name '*Tests.java' \); then
    if [[ -f pom.xml ]]; then echo "mvn test"; return 0
    elif [[ -f build.gradle ]] || [[ -f build.gradle.kts ]]; then echo "gradle test"; return 0
    else echo "mvn test"; return 0; fi
  fi
  return 1
}

detect_from_language_default() {
  # Existing manifests first.
  if [[ -f pyproject.toml ]] || [[ -f setup.cfg ]] || [[ -f requirements.txt ]] || [[ -f Pipfile ]]; then
    echo "pytest"; return 0
  fi
  if [[ -f package.json ]]; then echo "npm test"; return 0; fi
  if [[ -f go.mod ]]; then echo "go test ./..."; return 0; fi
  if [[ -f Cargo.toml ]]; then echo "cargo test"; return 0; fi
  if [[ -f pom.xml ]]; then echo "mvn test"; return 0; fi
  if [[ -f build.gradle ]] || [[ -f build.gradle.kts ]]; then echo "gradle test"; return 0; fi

  # Still nothing: pick by dominant source extension.
  py=$(find . -name '*.py' 2>/dev/null | wc -l)
  js=$(find . \( -name '*.js' -o -name '*.ts' \) 2>/dev/null | wc -l)
  go=$(find . -name '*.go' 2>/dev/null | wc -l)
  if [[ "$py" -gt "$js" ]] && [[ "$py" -gt "$go" ]] && [[ "$py" -gt 0 ]]; then
    echo "pytest"; return 0
  fi
  if [[ "$js" -gt "$go" ]] && [[ "$js" -gt 0 ]]; then echo "npm test"; return 0; fi
  if [[ "$go" -gt 0 ]]; then echo "go test ./..."; return 0; fi
  return 1
}

if DETECTED=$(detect_from_existing_tests); then
  echo "$DETECTED"; exit 0
fi
if DETECTED=$(detect_from_language_default); then
  echo "$DETECTED"; exit 0
fi

echo "UNKNOWN"
exit 1
