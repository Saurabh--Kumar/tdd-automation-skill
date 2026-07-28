# Step 7: Run Tests

## Purpose

Execute the agreed test suite.

## Failure Recovery

- If tests fail, attempt a recovery loop up to 2 times:
  1. Spawn a subagent to analyze the failures.
  2. Subagent proposes fixes to the affected code.
  3. Re-run the tests.
- If still failing after recovery attempts, surface to user with:
  - Failing test IDs
  - Error output
  - Options: retry again, skip failing tests, or halt

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/`.

## Instructions

1. **Read inputs.** Load `test-cases.md` to determine which tests to run. Load `progress.yaml` to get `test_command`.

2. **Run tests.** Execute `{test_command}` from `{project-root}/.tdd-auto/config.yaml` from `{project-root}`.

3. **Capture exit code and output.** Record results in `run-log.md`.

4. **If all green** → advance.

5. **If failures** → run recovery loop (up to 2 times). If failures persist, surface to user and HALT with status `blocked`.

6. **Update `progress.yaml`**
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-08-summarize.md` if all tests pass.
