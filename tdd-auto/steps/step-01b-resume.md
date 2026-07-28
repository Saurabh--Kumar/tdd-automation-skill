# Step 1b: Resume

## Purpose

Resume an interrupted workflow.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts live in `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Load `progress.yaml`.** Read the routing document for this feature slug.

2. **Validate artifacts.** Ensure all referenced artifact files exist:
   - `brainstorm-notes.md`
   - `requirements.md`
   - `test-cases.md`
   - `sub-problems.md`
   - `drift-report.md`

3. **Display progress dashboard.**
   ```
   Feature: {feature_slug}
   Status: {workflow_status}
   Last saved: {last_saved}
   Completed: {steps_completed}
   Next: {next_step}
   ```

4. **Route to `next_step`.**
   - If `next_step` is empty or unknown, halt and ask the user to start fresh.
   - Otherwise, read and follow the target step file.

## Advances to

- Whatever `next_step` is set to in `progress.yaml`.
