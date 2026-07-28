# Step 6: Implement

## Purpose

Implement each sub-problem via sequential subagents.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/`.
- Subagents run **sequentially** to avoid merge conflicts.

## Failure Recovery

- If a subagent fails, retry the same sub-problem once with the failure context attached.
- If the retry also fails, halt with status `blocked` and report:
  - Which sub-problem failed
  - What the subagent reported
  - The current state of the code
  - Options: retry again, skip this sub-problem, or halt

## Instructions

1. **Read inputs.** Load `sub-problems.md`, `requirements.md`, `test-cases.md`, and `references/tdd-guidance.md`.

2. **Initialize `run-log.md`.** If it doesn't exist, create it at:
   `{project-root}/.tdd-auto/runs/{feature-slug}/run-log.md`

3. **For each sub-problem (in order):**
   - Spawn a synchronous subagent with:
     - The sub-problem spec
     - Relevant excerpts from `requirements.md` and `test-cases.md`
     - File paths to create/modify
     - TDD guidance from `references/tdd-guidance.md`
   - Await completion before starting the next.
   - Log the result to `run-log.md`.

4. **On failure.** HALT with status `blocked` and blocking condition from subagent output.

5. **Update `progress.yaml`**
   - `last_saved`: current ISO timestamp

## Advances to

- `./step-07-run-tests.md`
