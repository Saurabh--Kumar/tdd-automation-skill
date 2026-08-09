# Step 10: Review Package

## Purpose

Produce a single Markdown review package that the user can paste directly into a GitHub PR description so reviewers understand what changed and what to expect — without leaving the PR page.

## Rules

- Read fully and execute completely before proceeding.
- The workflow ends after this step.
- The output is a plain Markdown file the user pastes into the PR.
- Do NOT simply concatenate the earlier artifacts. Combine them into one coherent narrative.

## How to combine (not append)

The package must read as a single story a reviewer can skim top-to-bottom. Structure it as:

1. **Title + one-line summary** — what feature this PR delivers.
2. **TL;DR for reviewers** — 3–6 bullets: what changed at a high level, the test outcome, any design drift that was approved, and anything they must look closely at.
3. **Agreed requirements** — the approved `requirements.md`, trimmed to the essentials (drop boilerplate; keep functional + non-functional + scope).
4. **Design drift (if any)** — the approved drift points from `drift-report.md`, framed as "what the design said vs what we built and why it was approved."
5. **Test coverage** — the `test-cases.md` Given/When/Then cases, grouped by requirement, so a reviewer can map intent → tests.
6. **Test results** — pass/fail counts and the command used, from `run-log.md`.
7. **Open issues / follow-ups** — anything intentionally left out or deferred.

Embed any text-based diagrams (Mermaid/PlantUML/ASCII) found in the LLD or authored in `sub-problems.md` inline so they render on GitHub. For image diagrams, link to their path in `.tdd-auto/design/` and note what they show.

## Instructions

1. **Read inputs.** Load `requirements.md`, `test-cases.md`, `drift-report.md`, `sub-problems.md`, and `run-log.md`.
2. **Compose `review-package.md`** following the structure above — coherent, reviewer-facing, paste-ready.
3. **Write `review-package.md`** to `{project-root}/.tdd-auto/runs/{feature-slug}/review-package.md`.
4. **Tell the user:**
   > "Review package ready at `.tdd-auto/runs/{feature-slug}/review-package.md`. Paste its contents into the PR description."

The user can copy the Markdown into GitHub directly.

## Workflow Ends
