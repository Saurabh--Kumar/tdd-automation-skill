---
feature_slug: ''
status: in-progress
current_step: step-01-init
steps_completed: []
next_step: step-02-evaluate-lld
last_saved: ''
requirements_checksum: ''
test_cases_checksum: ''
brainstorm_notes: ''
drift_report: ''
test_command: ''
workflow_status: in-progress
feature_request: ''
lld_dir: ''
---

# Step 1: Initialize

## Purpose

Route to new run, resume, or edit. Ensure `.tdd-auto/` exists.

## Rules

- Read fully and execute completely before proceeding to the next step.
- All artifacts are written to `{project-root}/.tdd-auto/runs/{feature-slug}/`.
- `progress.yaml` is the routing document. Update it before advancing.

## Instructions

1. **Check runtime directory.** Does `{project-root}/.tdd-auto/` exist?
   - If not: create `design/`, `runs/`, and add `runs/` to `.gitignore`. Inform the user and ask for the LLD documents path (any format: `.md`, `.txt`, `.drawio`, images, etc.).
   - If yes: continue.

2. **Resolve `feature_slug`.** Derive a kebab-case slug from the user's request. If the request references an existing `progress.yaml`, use that slug. Otherwise generate a new one.

3. **Determine route.**
   - If `progress.yaml` exists for this slug and `workflow_status` is `in-progress` → set `next_step: step-01b-resume` and **EARLY EXIT** to `./step-01b-resume.md`.
   - If the user says "edit requirements" or "edit tests" → set `next_step: step-01c-edit` and **EARLY EXIT** to `./step-01c-edit.md`.
   - Otherwise → new run mode.

4. **New run setup.**
   - Derive `feature_request` from the user's intent.
   - Confirm `lld_dir` (default: `.tdd-auto/design/`).
   - Write `progress.yaml` with current state.
   - Set `next_step: step-02-evaluate-lld`.

## Advances to

- `./step-02-evaluate-lld.md` (new run)
- `./step-01b-resume.md` (resume)
- `./step-01c-edit.md` (edit)
