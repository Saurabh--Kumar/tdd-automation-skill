# Step 5: Sub-Problems

## Purpose

Break the feature into implementation sub-problems.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Read inputs.** Load `requirements.md` and `test-cases.md`.

2. **Produce `sub-problems.md`.** Create an ordered list of sub-problems:
   - ID (e.g. `sp-01`, `sp-02`)
   - Description
   - Files to touch
   - Acceptance criteria
   - Relevant test IDs (from `test-cases.md`)
   - For sub-problems with multi-step interactions, include a Mermaid sequence or flow diagram

3. **Write `sub-problems.md`.** Write the result to:
   `{project-root}/.tdd-auto/runs/{feature-slug}/sub-problems.md`

4. **Update `progress.yaml`**
   - `last_saved`: current ISO timestamp

No human gate — the human reviews via the final summary.

## Advances to

- `./step-06-implement.md`
