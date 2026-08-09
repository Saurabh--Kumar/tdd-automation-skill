# Step 7: Run Tests

## Purpose

Execute the agreed test suite and actively drive it green.

## Failure Recovery (fix, don't just retry)

Tests failing is normal during a first run. The recovery loop must **analyze and fix** the failing code — not blindly re-run and hope:

1. Spawn a subagent with the failing test output, the relevant sub-problem spec, and the affected source files.
2. The subagent **applies fixes** to the affected code (and, if the test itself was wrong, corrects the test) while keeping every other agreed test case intact.
3. Re-run the suite.
4. Repeat up to 3 times. Only surface to the user if it still fails after real fix attempts.

If still failing after recovery attempts, surface to user with:
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

5. **If failures** → run the fix-focused recovery loop above (up to 3 times). If failures persist, surface to user and HALT with status `blocked`.

6. **Update `progress.yaml`**
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-08-summarize.md` if all tests pass.
