# Step 8: Summarize

## Purpose

Produce final summary.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/`.

## Instructions

1. **Read inputs.** Load `sub-problems.md` and `run-log.md`.

2. **Write summary to `run-log.md`.** Append a final summary section:
   ```markdown
   ## Summary

   - **Implemented:** list of sub-problems completed
   - **Test results:** pass/fail, count
   - **Files modified:** list
   - **Open issues:** any remaining issues
   ```

3. **Update `progress.yaml`**
   - `workflow_status: completed`
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-09-design-sync.md`
