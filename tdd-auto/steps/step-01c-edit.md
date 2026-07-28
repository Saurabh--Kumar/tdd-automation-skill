# Step 1c: Edit

## Purpose

Handle user edits to requirements or test cases.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts live in `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Load `progress.yaml`.** Read the routing document.

2. **Detect which artifact was edited.** Compare stored checksums (`requirements_checksum`, `test_cases_checksum`) against the current files:
   - `requirements.md`
   - `test-cases.md`

3. **If `requirements.md` checksum changed:**
   - Re-run requirements validation/edit logic.
   - Invalidate `test-cases.md` (mark as stale in `progress.yaml`).
   - Route user to approve updated requirements, then regenerate test cases.

4. **If `test-cases.md` checksum changed:**
   - Validate test cases against requirements.
   - Route user to approve updated tests.

5. **If both changed**, handle requirements first.

## Advances to

- Whatever step is appropriate after validation:
  - Requirements changed → step-03 (re-validate)
  - Test cases changed → step-04 (re-validate)
  - After re-approval → continue from step-06 onward
