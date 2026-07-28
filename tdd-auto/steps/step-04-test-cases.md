# Step 4: Test Cases

## Purpose

Derive test cases from approved requirements.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Read inputs.** Load the approved `requirements.md` and `progress.yaml`.

2. **Fill test-cases template.** Read `templates/test-cases-template.md`. Produce test cases:
   - One section per requirement
   - Given/When/Then format
   - Happy path, edge cases, error cases
   - Test IDs for traceability (e.g. `TC-{feature-slug}-001`)

3. **Write `test-cases.md`.** Write the filled template to:
   `{project-root}/.tdd-auto/runs/{feature-slug}/test-cases.md`
   with `status: draft` in the YAML frontmatter.

4. **Present to user.** Tell them:
   > "Test cases written to `.tdd-auto/runs/{feature-slug}/test-cases.md`. Edit if needed, then say `tests approved`."

5. **Wait for approval.** Do not advance until the user says "tests approved" or equivalent.

6. **Update `progress.yaml`**
   - `test_cases_checksum`: sha256 of the finalized `test-cases.md`
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-05-subproblems.md` after user approval.
