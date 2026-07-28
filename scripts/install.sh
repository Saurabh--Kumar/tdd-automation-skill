#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="tdd-auto"
SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/skills/${SKILL_NAME}"
TARGET="${1:-$(pwd)}"
TARGET_DIR="${TARGET}/.claude/skills/${SKILL_NAME}"
BACKUP_DIR="${TARGET}/.claude/skills/${SKILL_NAME}.bak"
VERSION_FILE="${SKILL_SRC}/../VERSION"

if [[ ! -d "$SKILL_SRC" ]]; then
  echo "Error: Skill source not found at ${SKILL_SRC}"
  exit 1
fi

VERSION="unknown"
if [[ -f "$VERSION_FILE" ]]; then
  VERSION=$(cat "$VERSION_FILE")
fi

echo "Installing ${SKILL_NAME} (v${VERSION})..."
echo "Source:  ${SKILL_SRC}"
echo "Target:  ${TARGET_DIR}"

mkdir -p "${TARGET}/.claude/skills/"

if [[ -d "${TARGET_DIR}" ]]; then
  echo "Existing install found. Backing up to ${BACKUP_DIR}..."
  rm -rf "${BACKUP_DIR}"
  mv "${TARGET_DIR}" "${BACKUP_DIR}"
fi

mkdir -p "${TARGET_DIR}"
cp -r "${SKILL_SRC}/"* "${TARGET_DIR}/"

if [[ -d "${TARGET}/.tdd-auto" ]]; then
  echo "Preserving existing .tdd-auto runtime directory."
fi

GITIGNORE="${TARGET}/.gitignore"
if ! grep -q ".tdd-auto/runs/" "$GITIGNORE" 2>/dev/null; then
  echo ".tdd-auto/runs/" >> "$GITIGNORE"
  echo "Added .tdd-auto/runs/ to .gitignore"
fi

echo "Installation complete."
echo "Next steps: Invoke with @${SKILL_NAME} and follow the workflow."
