---
name: tdd-auto
description: 'Automated Test-Driven Development workflow with human gates. Use when invoked by name to implement a feature from Low-Level Design through requirements, tests, sub-problems, sequential implementation, and verification.'
---

# TDD Auto — Automated TDD Workflow

**Goal:** Automate the Test-Driven Development workflow while keeping the human in control at every gate.

**CRITICAL:** If a step says "read fully and follow step-XX", you read and follow step-XX. No exceptions.

## HALT

To HALT with a final status and optional blocking condition:
1. Update `{project-root}/.tdd-auto/runs/{feature-slug}/progress.yaml` with the final status and blocking condition.
2. Stop the workflow.

## Subagents

Invoke every subagent **synchronously**: launch it, wait for it to return within the same turn, then continue with its result. Never run a subagent in the background / detached / async. This workflow includes human gates and resumable state — a backgrounded subagent never hands control back and the run stalls.

## Conventions

- Bare paths (e.g. `step-01-init.md`) resolve from the skill root.
- `{skill-root}` resolves to this skill's installed directory.
- `{project-root}` resolves to the project working directory.
- Runtime artifacts live in `{project-root}/.tdd-auto/`.
- Only `.tdd-auto/design/` and `.tdd-auto/config.yaml` are version-controlled. `.tdd-auto/runs/` is in `.gitignore`.

## On Activation

### Step 1: Ensure Runtime Directory

Check if `{project-root}/.tdd-auto/` exists. If not:
1. Create `{project-root}/.tdd-auto/design/` and `{project-root}/.tdd-auto/runs/`
2. Add `.tdd-auto/runs/` to `.gitignore`
3. Ask user: "No design found. Provide a path to your LLD documents."
4. Copy ALL files (any format: `.md`, `.txt`, `.drawio`, images, etc.) from the provided path into `.tdd-auto/design/`
5. Run `scripts/detect-test-framework.sh` and write `.tdd-auto/config.yaml`

## First workflow step

Read fully and follow: `./steps/step-01-init.md` to begin the workflow.
