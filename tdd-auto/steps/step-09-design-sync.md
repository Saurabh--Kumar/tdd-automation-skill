# Step 9: Design Sync

## Purpose

Update LLD to incorporate approved drift.

## Failure Recovery

- If LLD update fails (file not found, permission error), surface to user with:
  - Which file failed
  - Error message
  - Options: retry, skip LLD update, or halt

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/design/`.

## Instructions

1. **Read inputs.** Load `drift-report.md` and `requirements.md`.

2. **For each approved drift:**
   - Find the relevant section in `.tdd-auto/design/`.
   - Update inline, preserving surrounding context.
   - If a diagram needs updating (Mermaid, sequence), update it in place.

3. **Write updated LLD files** back to `.tdd-auto/design/`.

4. **Record changes in `run-log.md`** with `<!-- DESIGN SYNC -->` marker.

5. **Present diff to user:** "Updated N sections in `<file>`. Review the changes."

6. **Update `progress.yaml`**
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-10-html-review.md`
