#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="tdd-auto"
TARGET="${1:-$(pwd)}"
TARGET_DIR="${TARGET}/.claude/skills/${SKILL_NAME}"

echo "Uninstalling ${SKILL_NAME}..."
echo "Target:  ${TARGET_DIR}"

if [[ -d "${TARGET_DIR}" ]]; then
  rm -rf "${TARGET_DIR}"
  echo "Skill removed. Runtime directory .tdd-auto preserved."
else
  echo "Skill not found at ${TARGET_DIR}. Nothing to do."
fi
