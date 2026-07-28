# Step 3: Requirements

## Purpose

Produce requirements from the brainstorm exchange and approved drift.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Read inputs.** Load `brainstorm-notes.md`, `drift-report.md`, and the user's clarifying answers from this step's conversation.

2. **Fill requirements template.** Read `templates/requirements-template.md`. Fill it out using the brainstorm exchange and approved drift. Include:
   - Feature overview
   - Functional requirements
   - Non-functional requirements
   - Dependencies
   - Out of scope
   - Open questions (if any remain)
   - Design drift section (only approved drift points from `drift-report.md`)

3. **Write `requirements.md`.** Write the filled template to:
   `{project-root}/.tdd-auto/runs/{feature-slug}/requirements.md`
   with `status: draft` in the YAML frontmatter.

4. **Detect edits.** If the file is later edited externally, detect via checksum change against `progress.yaml.requirements_checksum`.

5. **Present to user.** Tell them:
   > "Requirements written to `.tdd-auto/runs/{feature-slug}/requirements.md`. Edit if needed, then say `requirements approved`."

6. **Wait for approval.** Do not advance until the user says "requirements approved" or equivalent.

7. **Update `progress.yaml`**
   - `requirements_checksum`: sha256 of the finalized `requirements.md`
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-04-test-cases.md` after user approval.
