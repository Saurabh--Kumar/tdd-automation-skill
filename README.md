# tdd-automation-skill

A Claude skill that automates the Test-Driven Development workflow while keeping the human in control at every gate.

## What it does

`tdd-auto` takes a feature request and a Low-Level Design (LLD), then walks through the full TDD cycle:

1. **Evaluate LLD** — Reads the project's design documents, surfaces ambiguities, detects architectural drift, and asks clarifying questions before any code is written.
2. **Requirements** — Produces a requirements document from the clarified intent. Human approves before proceeding.
3. **Test cases** — Derives Given/When/Then test cases from the approved requirements. Human approves before proceeding.
4. **Sub-problems** — Breaks the feature into sequential implementation sub-problems (no gate; human reviews via the final summary).
5. **Implement** — Dispatches sequential subagents to implement each sub-problem.
6. **Run tests** — Detects the project's test framework, runs the agreed test cases, and reports results.
7. **Design sync** — Updates the LLD in place to incorporate any approved architectural drift.
8. **HTML review page** — Generates a reviewer-facing HTML page and hosts it on GitHub Pages if available.

A companion skill, `tdd-auto-pr`, addresses PR review comments by reworking existing feature artifacts through the same workflow.

## Key principles

- **Human control at every gate.** Requirements and test cases are written to disk as editable markdown. The workflow does not advance until the human explicitly approves.
- **Disk is the source of truth.** All state is persisted to `.tdd-auto/runs/<feature-slug>/`. Runs may exceed 30 minutes; interruption is safe and the workflow is fully resumable.
- **Editable artifacts.** Humans can edit requirements, test cases, or design docs directly from their IDE. The skill re-reads these files on resume and honors edits.
- **Standalone.** No dependency on BMAD or any other framework. Drop the skill into `.claude/skills/tdd-auto/` and run.
- **Hidden runtime.** All runtime artifacts live in `.tdd-auto/` at the project root. Global artifacts (`design/`, `config.yaml`) are version controlled. Request-specific artifacts (`runs/`) are gitignored.
