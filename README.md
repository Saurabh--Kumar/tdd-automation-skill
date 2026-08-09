# tdd-automation-skill

A Claude skill that automates the Test-Driven Development workflow while keeping the human in control at every gate.

## The problem with prompt-driven implementation

Giving an agent a design doc and a feature prompt is a one-shot attempt with no structured feedback loop. The table below contrasts that approach with what this skill provides.

| Without this skill | With this skill |
|---|---|
| Agent silently invents or omits requirements based on ambiguous design docs | LLD is evaluated for ambiguities and drift before any code is written; clarifying questions are surfaced up front |
| No editable artifact to review before implementation begins | Requirements and Given/When/Then test cases are written to disk as markdown; workflow halts until human explicitly approves each |
| Architectural drift discovered only after code is written, requiring costly rewrites | Design sync step updates the LLD in place after implementation, keeping the design and code aligned |
| Context window exhaustion mid-run loses all progress | All state persisted to `.tdd-auto/runs/<feature-slug>/`; interrupted runs resume from the last approved gate |
| PR review feedback requires re-reading the full diff and re-implementing from scratch | Companion `tdd-auto-pr` workflow reworks only affected artifacts through the same TDD cycle and produces a PR-ready summary |

## Installation

The repository contains the skill source under `tdd-auto/`. Install it by copying that folder into your project's (or user-level) Claude skills directory:

```bash
# Project-scoped (only this project)
cp -r tdd-auto/ .claude/skills/tdd-auto/

# Or user-scoped (all projects)
cp -r tdd-auto/ ~/.claude/skills/tdd-auto/
```

### Requirements

- A Claude Code (or compatible) environment that loads skills from `.claude/skills/`.
- `bash` available on your `PATH` (used by `scripts/detect-test-framework.sh` to auto-detect your test runner).
- Git initialized in the target project (the workflow persists state to `.tdd-auto/` at the project root).

No other dependencies are required — the skill is standalone and does not rely on BMAD or any other framework.

## Usage

1. **Prepare your design.** Have a Low-Level Design (LLD) ready. On first run, the skill asks for the path to your LLD documents and copies them into `.tdd-auto/design/`.

2. **Invoke the skill.** Start a Claude session in your project and run:

   ```
   /tdd-auto
   ```

   Provide the feature request (a short description of what to build). The skill reads your LLD, surfaces ambiguities, and asks clarifying questions before any code is written.

3. **Approve each gate.** The workflow writes editable artifacts to disk and halts at each gate:
   - Requirements (`requirements.md`)
   - Test cases (`test-cases.md`)

   Review them in your IDE, edit if needed, and explicitly approve to continue.

4. **Implement & verify.** The skill breaks the feature into sub-problems, dispatches sequential subagents to implement them, then auto-detects and runs your test framework.

5. **Review the output.** A reviewer-facing HTML page is generated and (if available) hosted on GitHub Pages. The LLD is synced in place to reflect any approved drift.

### Resuming an interrupted run

All state is persisted to `.tdd-auto/runs/<feature-slug>/`. If a run is interrupted, simply invoke `/tdd-auto` again — the skill detects the existing run and resumes from the last approved gate. To edit artifacts mid-run, make your changes on disk and resume; the skill re-reads them.


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

## `tdd-auto-pr`

`tdd-auto-pr` takes an existing feature run folder and PR review comments, then resolves them through the same TDD workflow:

1. **Load baseline** — Loads the existing requirements, test cases, sub-problems, and implementation from the run folder.
2. **Categorize comments** — Classifies each review comment as nit/style, bug, requirement clarification, or new requirement. Produces a change manifest for user approval.
3. **Requirements** — If requirements changed, updates `requirements.md` and re-validates against the LLD. User partially approves changed requirements only.
4. **Test cases** — If requirements changed, updates `test-cases.md` to match. User partially approves changed tests only.
5. **Sub-problems** — Regenerates `sub-problems.md` for affected sub-problems only.
6. **Implement** — Re-implements only the affected sub-problems via sequential subagents.
7. **Run tests** — Runs the full test suite with recovery on failures.
8. **Summarize** — Produces a PR-ready summary of what changed and test results.
9. **HTML review page** — Updates the existing reviewer-facing HTML page with the delta and re-hosts if GitHub Pages is available.

## Key principles

- **Human control at every gate.** Requirements and test cases are written to disk as editable markdown. The workflow does not advance until the human explicitly approves.
- **Disk is the source of truth.** All state is persisted to `.tdd-auto/runs/<feature-slug>/`. Runs may exceed 30 minutes; interruption is safe and the workflow is fully resumable.
- **Editable artifacts.** Humans can edit requirements, test cases, or design docs directly from their IDE. The skill re-reads these files on resume and honors edits.
- **Standalone.** No dependency on BMAD or any other framework. Drop the skill into `.claude/skills/tdd-auto/` and run.
- **Hidden runtime.** All runtime artifacts live in `.tdd-auto/` at the project root. Global artifacts (`design/`, `config.yaml`) are version controlled. Request-specific artifacts (`runs/`) are gitignored.
