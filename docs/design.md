# TDD Auto — Design Document

## 1. Goal

Automate the Test-Driven Development workflow while keeping the human in control at every gate. The skill takes a user request and a Low-Level Design (LLD), walks through brainstorming/requirements/test-cases/sub-problems, dispatches subagents to implement, runs tests, and summarizes the result. Runs may exceed 30 minutes; state is persisted to disk so the workflow is resumable.

## 2. Non-Negotiable Constraints

- The skill is standalone and self contained.
- All state lives on disk. A killed session can be resumed exactly where it left off.
- Human approval is required at the requirements gate and the test-cases gate.
- Sub-problem breakdown is AI-generated; no human gate at that step.
- Subagents run sequentially to avoid merge conflicts (parallel can be revisited later).
- "Tests pass" means all agreed test cases are green. No coverage threshold.
- Global artifacts are version controlled. Request-specific artifacts are not.

## 3. Invocation

Only `SKILL.md` has skill frontmatter (`name`, `description`). Step files are plain markdown loaded by explicit file reads — they never appear in any skill menu. For example, Step-04 cannot fire unintentionally; it only routes forward from step-03's approved output via `progress.yaml`.

## 4. Directory Layout

### Skill source (installed into `.claude/skills/tdd-auto/`)

```
tdd-auto/
├── SKILL.md
├── customize.toml
├── steps/
│   ├── step-01-init.md
│   ├── step-02-evaluate-lld.md
│   ├── step-03-requirements.md
│   ├── step-04-test-cases.md
│   ├── step-05-subproblems.md
│   ├── step-06-implement.md
│   ├── step-07-run-tests.md
│   ├── step-08-summarize.md
│   ├── step-01b-resume.md
│   └── step-01c-edit.md
├── templates/
│   ├── requirements-template.md
│   ├── test-cases-template.md
│   ├── sub-problems-template.md
│   └── progress-template.yaml
├── references/
│   ├── lld-analysis.md
│   └── tdd-guidance.md
└── scripts/
    └── detect-test-framework.sh
```

### Project runtime (created by the skill on first use)

```
project-root/
├── .tdd-auto/
│   ├── design/                    # Global — version controlled
│   │   ├── lld.md
│   │   ├── sequence-diagram.md
│   │   └── ... (user-supplied design docs)
│   ├── config.yaml                # Global — version controlled
│   │   ├── test_command: "pytest"
│   │   ├── lld_dir: "design"
│   │   └── languages: ["python"]
│   └── runs/                      # Request-specific — NOT version controlled
│       └── <feature-slug>/
│           ├── progress.yaml
│           ├── brainstorm-notes.md
│           ├── requirements.md
│           ├── test-cases.md
│           ├── sub-problems.md
│           └── run-log.md
```

`.tdd-auto/runs/` is added to `.gitignore`. `design/` and `config.yaml` are committed.

## 5. State Machine

```
step-01-init
    │
    ├── new run ──────────────────────────────────────┐
    │                                                  │
    ├── resume ──────────────────────────────┐        │
    │                                        │        │
    └── edit ─────────────────────────────┐   │        │
                                          │   │        │
                                          ▼   ▼        ▼
                                   step-02-evaluate-lld
                                          │
                                          ▼
                                   step-03-requirements  (status: draft)
                                          │
                                          ▼ [human approves]
                                   step-04-test-cases    (status: draft)
                                          │
                                          ▼ [human approves]
                                   step-05-subproblems   (no gate)
                                          │
                                          ▼
                                   step-06-implement
                                          │
                                          ▼
                                   step-07-run-tests
                                          │
                                          ▼
                                   step-08-summarize
                                          │
                                          ▼
                                   step-09-design-sync   (in-place LLD update)
                                          │
                                          ▼
                                   step-10-html-review   (generate + host page)
```

`progress.yaml` is the routing document. Fields:

```yaml
workflowStatus: in-progress | completed | blocked
featureSlug: <kebab-case-id>
currentStep: step-02-evaluate-lld
stepsCompleted: [step-01-init]
nextStep: step-03-requirements
lastSaved: <ISO timestamp>
requirementsChecksum: <sha256 of requirements.md>
testCasesChecksum: <sha256 of test-cases.md>
brainstormNotes: <path to brainstorm-notes.md>
driftReport: <path to drift-report.md>
testCommand: pytest
```

## 6. Step Contracts

### step-01-init

**Purpose:** Route to new, resume, or edit. Ensure `.tdd-auto/` exists.

**Behavior:**
- If `.tdd-auto/` does not exist → first-run setup:
  - Create `.tdd-auto/design/`, `.tdd-auto/runs/`
  - Add `.tdd-auto/runs/` to `.gitignore`
  - Ask user for design directory path. Copy all `.md` files into `.tdd-auto/design/`
  - Run `scripts/detect-test-framework.sh`, write `config.yaml`
- If `.tdd-auto/` exists and user references an existing `progress.yaml` → resume mode
- If user says "edit requirements" or "edit tests" → edit mode
- Otherwise → new run mode

**Advances to:** step-02 (new), step-01b (resume), or step-01c (edit)

### step-02-evaluate-lld

**Purpose:** Read design docs, surface ambiguities, detect architectural drift, ask clarifying questions.

**Behavior:**
- Read all `.md` files in `.tdd-auto/design/`
- Read the user's request
- Extract any Mermaid diagram blocks from the LLD files and store them for later use in the HTML review page
- Produce `brainstorm-notes.md`:
  - What the request seems to ask for
  - Ambiguities in the request
  - Ambiguities found in the design
  - Clarifying questions
  - Relevant diagrams extracted from LLD
- Produce `drift-report.md`:
  - For each significant divergence between request and LLD
  - LLD says vs Request asks, drift type, severity
- Present both to user, wait for response
- If design is sparse or self-contradictory, note that explicitly
- If drift is detected, user must acknowledge each drift point before proceeding

**Advances to:** step-03 after user confirms understanding and acknowledges drift

### step-03-requirements

**Purpose:** Produce requirements from brainstorm exchange and approved drift.

**Behavior:**
- Read `brainstorm-notes.md`, `drift-report.md`, and user's clarifying answers
- Fill `requirements.md` from template:
  - Feature overview
  - Functional requirements
  - Non-functional requirements
  - Dependencies
  - Out of scope
  - Open questions (if any remain)
  - Design drift section (approved drift points from `drift-report.md`)
- Write to `.tdd-auto/runs/<feature-slug>/requirements.md` with `status: draft`
- Tell user: "Requirements written to `<path>`. Edit if needed, then say `requirements approved`."
- Do not advance until user says "requirements approved" (or equivalent)
- If user edits the file externally, detect via checksum change on next interaction

**Advances to:** step-04 after approval

### step-04-test-cases

**Purpose:** Derive test cases from approved requirements.

**Behavior:**
- Read approved `requirements.md`
- Produce `test-cases.md` from template:
  - One section per requirement
  - Given/When/Then format
  - Happy path, edge cases, error cases
  - Test IDs for traceability
- Write to `.tdd-auto/runs/<feature-slug>/test-cases.md` with `status: draft`
- Tell user: "Test cases written to `<path>`. Edit if needed, then say `tests approved`."
- Do not advance until user says "tests approved"

**Advances to:** step-05 after approval

### step-05-subproblems

**Purpose:** Break feature into implementation sub-problems.

**Behavior:**
- Read `requirements.md` and `test-cases.md`
- Produce `sub-problems.md`:
  - Ordered list of sub-problems
  - Each with: ID, description, files to touch, acceptance criteria, relevant test IDs
  - For sub-problems that involve multi-step interactions, include a Mermaid sequence or flow diagram
- AI-generated. No human gate — the human reviews via the final summary.
- Write to `.tdd-auto/runs/<feature-slug>/sub-problems.md`

**Advances to:** step-06

### step-06-implement

**Purpose:** Implement each sub-problem via sequential subagents.

**Behavior:**
- Read `sub-problems.md`
- For each sub-problem:
  - Spawn a synchronous subagent with:
    - The sub-problem spec
    - Relevant excerpt from `requirements.md` and `test-cases.md`
    - File paths to create/modify
    - TDD guidance from `references/tdd-guidance.md`
  - Await completion before starting the next
  - Log result to `run-log.md`
- If a subagent fails, HALT with status `blocked` and blocking condition from subagent output

**Advances to:** step-07

### step-07-run-tests

**Purpose:** Execute the agreed test suite.

**Behavior:**
- Read `test-cases.md` to determine which tests to run
- Run `{test_command}` from `config.yaml` from `{project-root}`
- Capture exit code and output
- If all green → advance
- If failures → report failures, offer to fix or halt

**Advances to:** step-08

### step-08-summarize

**Purpose:** Produce final summary.

**Behavior:**
- Write `run-log.md` summary:
  - What was implemented (sub-problems completed)
  - Test results (pass/fail, count)
  - Files modified
  - Any open issues
- Set `progress.yaml` status to `completed`

**Advances to:** step-09-design-sync

### step-09-design-sync

**Purpose:** Update LLD to incorporate approved drift.

**Behavior:**
- Read `drift-report.md` and `requirements.md`
- For each approved drift:
  - Find the relevant section in `.tdd-auto/design/`
  - Update inline, preserving surrounding context
  - If a diagram needs updating (Mermaid, sequence), update it in place
- Write updated LLD files back to `.tdd-auto/design/`
- Record changes in `run-log.md` with `<!-- DESIGN SYNC -->` marker
- Present diff to user: "Updated 2 sections in `lld.md`. Review the changes."

**Advances to:** step-10-html-review

### step-10-html-review

**Purpose:** Generate and host reviewer-facing HTML page.

**Behavior:**
- Read `requirements.md`, `test-cases.md`, `drift-report.md`, `sub-problems.md`, `run-log.md`
- Generate `review.html` with embedded CSS and Mermaid.js CDN
- Sections: requirements, test cases, design drift, implementation summary
- Attempt to host on GitHub Pages:
  - Check `gh` CLI availability and auth status
  - If auth fails, prompt user to refresh token
  - If Pages enabled, commit and push HTML, construct URL
  - If Pages not enabled or `gh` unavailable, provide as local artifact
- Present URL to user: "Review page: <url>"

**Ends workflow.**

### step-01b-resume

**Purpose:** Resume an interrupted workflow.

**Behavior:**
- Load `progress.yaml`
- Validate all referenced artifact files exist
- Display progress dashboard (workflowStatus, lastStep, nextStep, stepsCompleted)
- Route to `nextStep`
- If `nextStep` is empty or unknown, halt and ask user to start fresh

### step-01c-edit

**Purpose:** Handle user edits to requirements or test cases.

**Behavior:**
- Load `progress.yaml`
- Detect which artifact was edited via checksum comparison
- If `requirements.md` checksum changed:
  - Re-run step-03 logic to validate/edit requirements
  - Invalidate `test-cases.md` (mark as stale)
  - Route user to approve updated requirements, then regenerate test cases
- If `test-cases.md` checksum changed:
  - Validate test cases against requirements
  - Route user to approve updated tests
- If both changed, handle requirements first

## 7. Test Framework Detection

`scripts/detect-test-framework.sh` inspects the project root:

| Signal | Detected command |
|---|---|
| `package.json` with `jest`/`mocha`/`vitest` | `npm test` |
| `pyproject.toml` or `setup.cfg` with `pytest` | `pytest` |
| `go.mod` present | `go test ./...` |
| `Cargo.toml` present | `cargo test` |
| None of the above | Prompt user for test command |

Result is written to `.tdd-auto/config.yaml`. User can override manually.

## 8. First-Run Flow

```
User: @tdd-auto implement user authentication flow
  ↓
step-01-init: .tdd-auto/ not found
  ↓
Create .tdd-auto/design/ and .tdd-auto/runs/
Add .tdd-auto/runs/ to .gitignore
Ask: "No design found. Provide a path to your LLD documents."
User: ./docs/design/
  ↓
Copy all .md files to .tdd-auto/design/
Detect test framework → write config.yaml
  ↓
step-02: Read design, produce brainstorm-notes.md and drift-report.md
"From your design I see X. Your request mentions Y but the design doesn't cover Z. 
Clarifying questions: ...
Also, design drift detected: JWT vs session cookies. Approve?"
  ↓
User answers, acknowledges drift
  ↓
step-03: requirements.md (draft, includes drift section) → user approves
step-04: test-cases.md (draft) → user approves
step-05: sub-problems.md
step-06: sequential subagents implement
step-07: pytest (all green)
step-08: summary
step-09: design sync — update LLD inline
step-10: generate review.html, attempt to host on GitHub Pages
```

## 9. Resume Flow

```
User: @tdd-auto resume
  ↓
step-01-init: finds .tdd-auto/runs/<feature-slug>/progress.yaml
  ↓
step-01b-resume: load progress.yaml, validate artifacts, route to nextStep
  ↓
Resume at the exact step that was interrupted
```

## 10. Edit Flow

```
User: @tdd-auto edit requirements
  ↓
step-01-init: edit mode detected
  ↓
step-01c-edit: checksum mismatch on requirements.md
  ↓
Re-validate requirements, mark test-cases.md as stale
User approves updated requirements
  ↓
Regenerate test-cases.md
User approves updated tests
  ↓
Continue from step-06
  ↓
step-07: run tests
step-08: summarize
step-09: design sync (if drift changed)
step-10: update HTML review page
```

## 11. Scope Boundary (MVP)

**In scope:**
- Single request, single feature slug
- Two human gates: requirements, test cases
- Sequential subagent implementation
- Auto-detected test framework
- Full resume/edit support
- Hidden `.tdd-auto/` runtime folder
- Architectural drift detection at requirements gate
- In-place LLD sync after tests pass
- HTML review page generation and GitHub Pages hosting
- Plugin packaging and installer script for distribution

**Out of scope (future):**
- Parallel subagents
- Multiple goals in one request
- Coverage thresholds
- CI integration
- Epic/chain workflows

## 12. Failure Recovery

The skill should attempt to recover from failures before surfacing to the user.

### Subagent failure recovery

- If a subagent for example, fails during step-06, retry the same sub-problem once with the failure context attached.
- If the retry also fails, surface the failure to the user with:
  - Which sub-problem failed
  - What the subagent reported
  - The current state of the code
  - Options: retry again, skip this sub-problem, or halt

### Test failure recovery

- If tests fail in step-07, attempt a recovery loop up to 2 times:
  - Spawn a subagent to analyze the failures
  - Subagent proposes fixes to the affected code
  - Re-run the tests
- If still failing after recovery attempts, surface to the user with:
  - Failing test IDs
  - Error output
  - Options: retry again, skip failing tests, or halt

The recovery loop is bounded to prevent infinite retry cycles.

### Design sync failure recovery

- If LLD update fails (file not found, permission error), surface to user with:
  - Which file failed
  - Error message
  - Options: retry, skip LLD update, or halt

### HTML hosting failure recovery

- If GitHub Pages hosting fails due to auth, prompt user to refresh `gh` token
- If Pages not enabled or `gh` unavailable, provide HTML as local artifact without blocking

## 13. Key Risks

| Risk | Mitigation |
|---|---|
| Subagent produces code that doesn't compile | step-06 logs failures; step-07 catches test failures |
| User edits requirements without realizing it invalidates tests | step-01c detects checksum change, warns explicitly |
| Design docs are insufficient | step-02 surfaces this; user can supplement before requirements |
| Long runs exhaust context | State is written to disk after every step; resume is safe |
| Subagents drift out of scope | Each subagent receives only its sub-problem spec + relevant excerpts |
| LLD update fails due to file permissions | step-09 surfaces error, offers retry/skip/halt |
| GitHub Pages auth token expired | step-10 prompts user to refresh `gh auth login` |
| HTML page becomes stale | step-10 updates existing page in review mode; generates fresh in greenfield |

## 14. PR Review Workflow (`tdd-auto-pr`)

### Purpose

Address PR review comments by reworking the existing feature artifacts. This is a delta workflow: it starts from an approved baseline and asks "what changed, and what needs to change in response?"

### Invocation

Separate skill, separate invocation. Invoked as:

```
@tdd-auto-pr <run-folder-path> <review comments>
```

For example:

```
@tdd-auto-pr .tdd-auto/runs/user-auth-flow/ "Reviewer comments: ..."
```

The user provides:
1. The path to the existing run folder (e.g. `.tdd-auto/runs/user-auth-flow/`)
2. Review comments as pasted text or a file path

### Comment Categorization

For each review comment, the skill classifies it before touching anything:

| Category | Meaning | Action |
|---|---|---|
| Nit / style | No semantic change needed | Fix code only |
| Bug / implementation gap | Existing requirement is unmet | Fix code, possibly update tests |
| Requirement clarification | Existing requirement is wrong or incomplete | Update requirements.md → user approval gate |
| New requirement | Comment asks for something outside original scope | Update requirements.md → user approval gate |

The skill produces a **change manifest** before executing:

```markdown
## Change Manifest

| # | Comment | Category | Affects |
|---|---|---|---|
| 1 | "Use bcrypt instead of sha256" | Requirement clarification | requirements.md, sp-02 |
| 2 | "Missing test for null input" | Bug / implementation gap | test-cases.md, sp-02 |
| 3 | "Add type hints to all functions" | Nit / style | code only |
```

The user approves the manifest before any artifacts are modified.

### Requirements Change Path (with LLD Re-validation)

```
Requirements change detected
    ↓
Re-validate updated requirements against LLD
    ↓
Update requirements.md (status: draft)
User partially approves changed requirements
    ↓
Re-evaluate tests: do existing test-cases still hold?
    ↓
If tests need updating → update test-cases.md → user partially approves
    ↓
Regenerate sub-problems.md
    ↓
Re-implement only affected sub-problems
    ↓
Run full test suite
    ↓
Summarize delta
```

Partial re-approval means the human only reviews the changed requirements and changed tests — not the full set.

### Test Change Path

If only test-cases change: update tests, user approves, re-implement affected sub-problems, run tests.

### Implementation-Only Path

If no artifacts change: fix code in affected sub-problems, run tests.

### Sub-problem Impact Mapping

The skill maps each review comment to the sub-problem(s) it touches. Only those sub-problems are re-implemented. This is the efficiency win — the skill doesn't redo work that wasn't challenged.

### Conflicting Comments

If two comments contradict each other, surface the contradiction to the user with both comments quoted. The skill never picks a winner silently.

### Summary Output

Structured for PR consumption:

```markdown
## PR Review Resolution Summary

**Baseline run:** `user-auth-flow`
**Review comments addressed:** 5
**Requirements changed:** Yes (2 requirements updated)
**Test cases changed:** Yes (3 test cases added)
**Sub-problems reworked:** sp-02, sp-03
**Test results:** All green (12/12)
**Files modified:** src/auth/service.py, tests/test_auth.py
```

### State Model Additions

`progress.yaml` gains review-specific fields:

```yaml
reviewMode: true
baselineRun: .tdd-auto/runs/user-auth-flow/
reviewComments: <path or embedded text>
changeManifest: <path to change manifest>
reworkedSubProblems: [sp-02, sp-03]
```

### Recovery in Review Mode

Same recovery behavior as greenfield:
- Subagent failure: retry once with failure context, then surface to user
- Test failure: recovery loop up to 2 times with fix suggestions, then surface to user

### Out of Scope (for now)

- Requirements that need LLD changes (flagged explicitly, not auto-handled)
- Parallel rework of sub-problems (sequential for now)

## 15. `tdd-auto-pr` — Directory, Artifact, and Step Design

### 15.1 Skill Source Structure

Installed into `.claude/skills/tdd-auto-pr/`:

```
tdd-auto-pr/
├── SKILL.md
├── customize.toml
├── steps/
│   ├── step-01-init.md           # Route: new review / resume review
│   ├── step-02-load-baseline.md  # Load existing run folder, validate artifacts
│   ├── step-03-categorize.md     # Categorize review comments, produce change manifest
│   ├── step-04-requirements.md   # Re-validate requirements against LLD if changed
│   ├── step-05-test-cases.md     # Re-evaluate tests if requirements changed
│   ├── step-06-subproblems.md    # Regenerate sub-problems if artifacts changed
│   ├── step-07-implement.md      # Re-implement affected sub-problems
│   ├── step-08-run-tests.md      # Run full test suite
│   ├── step-09-summarize.md      # PR-ready summary
│   └── step-01b-resume.md        # Resume interrupted review
├── templates/
│   ├── change-manifest-template.md
│   ├── requirements-delta-template.md
│   ├── test-cases-delta-template.md
│   └── review-progress-template.yaml
└── references/
    └── comment-categorization.md
```

### 15.2 Project Runtime Artifacts

Reuses the existing run folder. No new top-level directory:

```
project-root/
├── .tdd-auto/
│   ├── design/                        # Global — unchanged from MVP
│   ├── config.yaml                    # Global — unchanged from MVP
│   └── runs/
│       └── <feature-slug>/
│           ├── progress.yaml          # Existing + new review fields
│           ├── brainstorm-notes.md    # Existing — not modified in review mode
│           ├── requirements.md        # May be updated
│           ├── test-cases.md          # May be updated
│           ├── sub-problems.md        # May be regenerated
│           ├── run-log.md             # Existing + review delta entries
│           ├── change-manifest.md     # NEW — produced in step-03
│           └── review-comments.md     # NEW — raw comments for traceability
```

`review-comments.md` and `change-manifest.md` are ephemeral. `requirements.md`, `test-cases.md`, and `sub-problems.md` are mutated in place — the baseline is the pre-review version, the current version is the post-review version.

### 15.3 Progress YAML Additions

`progress.yaml` gains review-specific fields:

```yaml
# Existing fields retained:
workflowStatus: in-progress | completed | blocked
featureSlug: user-auth-flow
currentStep: step-03-categorize
stepsCompleted: [step-01-init, step-02-load-baseline]
nextStep: step-04-requirements
lastSaved: 2026-07-25T20:00:00+05:30
requirementsChecksum: <sha256>
testCasesChecksum: <sha256>

# New review fields:
reviewMode: true
baselineRun: .tdd-auto/runs/user-auth-flow/
reviewCommentsPath: .tdd-auto/runs/user-auth-flow/review-comments.md
changeManifestPath: .tdd-auto/runs/user-auth-flow/change-manifest.md
reworkedSubProblems: [sp-02, sp-03]
requirementsDelta: true
testCasesDelta: true
```

`reviewMode: true` is the flag that distinguishes a review run from a greenfield run. When `true`, the skill operates in delta mode: it loads the baseline, categorizes comments, and reworks only what changed.

### 15.4 Step Contracts

#### step-01-init

**Purpose:** Route to new review or resume review.

**Behavior:**
- If user provides a path to an existing run folder → new review mode
- If user references an existing review `progress.yaml` with `reviewMode: true` → resume review mode
- Validate the run folder contains `progress.yaml`, `requirements.md`, `test-cases.md`, `sub-problems.md`
- If any artifact is missing, halt with blocking condition

**Advances to:** step-02 (new), step-01b (resume)

#### step-02-load-baseline

**Purpose:** Load the existing artifacts as the baseline.

**Behavior:**
- Read `progress.yaml` from the run folder
- Read `requirements.md`, `test-cases.md`, `sub-problems.md`, `run-log.md`
- Record checksums of `requirements.md` and `test-cases.md` as `baselineRequirementsChecksum` and `baselineTestCasesChecksum`
- Load review comments (pasted text or file path), write to `review-comments.md`
- Display baseline summary to user: "Loaded run `user-auth-flow`. Baseline has 5 requirements, 12 test cases, 3 sub-problems."

**Advances to:** step-03

#### step-03-categorize

**Purpose:** Classify each review comment and produce a change manifest.

**Behavior:**
- Read `review-comments.md`
- For each comment:
  - Classify as: nit/style, bug/implementation-gap, requirement-clarification, new-requirement
  - Map to affected sub-problem(s)
  - Determine if requirements.md or test-cases.md need updating
- Produce `change-manifest.md`:
  ```markdown
  ## Change Manifest

  | # | Comment | Category | Affects Artifacts | Affects Sub-Problems |
  |---|---|---|---|---|
  | 1 | "Use bcrypt instead of sha256" | requirement-clarification | requirements.md | sp-02 |
  | 2 | "Missing test for null input" | bug/implementation-gap | test-cases.md | sp-02 |
  | 3 | "Add type hints" | nit/style | — | — |
  ```
- Detect contradictions between comments, surface to user
- Present manifest to user, wait for approval: "Approve this change manifest? (yes / no / edit)"
- Do not advance until user approves

**Advances to:** step-04 if requirements changed, step-06 if implementation-only, step-07 if tests changed

#### step-04-requirements

**Purpose:** Update requirements.md if the change manifest indicates requirements changes.

**Behavior:**
- Read baseline `requirements.md` and `change-manifest.md`
- Identify which comments require requirements changes
- For each changed requirement:
  - Re-validate against LLD (`.tdd-auto/design/`)
  - If contradiction with LLD, surface to user: "Updated requirement X contradicts the LLD section Y. Proceed anyway or adjust?"
- Update `requirements.md` in place, marking changed requirements with `<!-- UPDATED IN REVIEW -->`
- Write to `requirements.md` with `status: draft`
- Tell user: "Requirements updated. Review the changes at `<path>`. Say `requirements approved` to proceed."
- Do not advance until user says "requirements approved"
- Set `requirementsDelta: true` in `progress.yaml`

**Advances to:** step-05

#### step-05-test-cases

**Purpose:** Re-evaluate and update test-cases.md if requirements changed.

**Behavior:**
- Read updated `requirements.md` and baseline `test-cases.md`
- Determine which existing test cases are still valid
- Determine which new test cases are needed for changed requirements
- Update `test-cases.md` in place, marking new/changed tests with `<!-- UPDATED IN REVIEW -->`
- Write to `test-cases.md` with `status: draft`
- Tell user: "Test cases updated. Review at `<path>`. Say `tests approved` to proceed."
- Do not advance until user says "tests approved"
- Set `testCasesDelta: true` in `progress.yaml`

**Advances to:** step-06

#### step-06-subproblems

**Purpose:** Regenerate sub-problems.md if artifacts changed.

**Behavior:**
- Read updated `requirements.md` and `test-cases.md` and `change-manifest.md`
- Determine which sub-problems are affected by the review comments
- If artifacts changed:
  - Regenerate `sub-problems.md` with updated sub-problem specs
  - Mark affected sub-problems with `<!-- REWORKED IN REVIEW -->`
  - Write to `sub-problems.md`
- If no artifacts changed (implementation-only path):
  - Read existing `sub-problems.md`, identify affected sub-problems from change manifest
  - No regeneration needed
- Set `reworkedSubProblems` in `progress.yaml`

**Advances to:** step-07

#### step-07-implement

**Purpose:** Re-implement affected sub-problems via sequential subagents.

**Behavior:**
- Read `sub-problems.md` and `reworkedSubProblems` from `progress.yaml`
- For each affected sub-problem:
  - Spawn a synchronous subagent with:
    - The sub-problem spec
    - Relevant excerpt from updated `requirements.md` and `test-cases.md`
    - File paths to create/modify
    - TDD guidance from `references/tdd-guidance.md`
    - What changed and why (from change manifest)
  - Await completion before starting the next
  - Log result to `run-log.md` with `<!-- REVIEW REWORK -->` marker
- If a subagent fails, retry once with failure context attached
- If retry fails, surface to user with options: retry, skip, or halt

**Advances to:** step-08

#### step-08-run-tests

**Purpose:** Execute the full test suite.

**Behavior:**
- Read `test-cases.md` to determine which tests to run
- Run `{test_command}` from `.tdd-auto/config.yaml` from `{project-root}`
- Capture exit code and output
- If all green → advance
- If failures → recovery loop up to 2 times:
  - Spawn subagent to analyze failures
  - Propose fixes to affected code
  - Re-run tests
- If still failing after recovery, surface to user with options: retry, skip failing tests, or halt

**Advances to:** step-09

#### step-09-summarize

**Purpose:** Produce PR-ready summary.

**Behavior:**
- Write `run-log.md` delta summary:
  - Baseline run name
  - Review comments addressed
  - Requirements changed (yes/no, count)
  - Test cases changed (yes/no, count)
  - Sub-problems reworked
  - Test results
  - Files modified
  - Recovery attempts taken (if any)
- Set `progress.yaml` status to `completed`
- Present summary to user in PR-ready format

**Ends workflow.**

#### step-01b-resume

**Purpose:** Resume an interrupted review workflow.

**Behavior:**
- Load `progress.yaml`
- Verify `reviewMode: true`
- Validate all referenced artifact files exist
- Display progress dashboard (workflowStatus, lastStep, nextStep, stepsCompleted, reworkedSubProblems)
- Route to `nextStep`
- If `nextStep` is empty or unknown, halt and ask user to start fresh review

### 15.5 Change Manifest Template

`templates/change-manifest-template.md`:

```markdown
---
status: draft
featureSlug: <feature-slug>
baselineRequirementsChecksum: <sha256>
baselineTestCasesChecksum: <sha256>
---

## Change Manifest

**Generated:** <timestamp>
**Review comments:** <count>

| # | Comment | Category | Affects Artifacts | Affects Sub-Problems |
|---|---|---|---|---|
```

### 15.6 State Transitions

```
step-01-init
    │
    ├── new review ──────────────────────────────┐
    │                                            │
    └── resume review ─────────────────────┐    │
                                           │    │
                                           ▼    ▼
                                    step-02-load-baseline
                                           │
                                           ▼
                                    step-03-categorize
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
             requirements changed    test-cases changed    implementation-only
                    │                      │                      │
                    ▼                      │                      ▼
             step-04-requirements          │             step-07-implement
                    │                      │                      │
                    ▼                      │                      ▼
             step-05-test-cases           │             step-08-run-tests
                    │                      │                      │
                    ▼                      │                      ▼
             step-06-subproblems ─────────┘                      │
                    │                                              │
                    └──────────────┬──────────────────────────────┘
                                   ▼
                            step-08-run-tests
                                   │
                                   ▼
                            step-09-summarize
```

### 15.7 Partial Re-approval Behavior

When `requirementsDelta: true`, the human reviews only the changed requirements. Unchanged requirements are not re-presented. The same applies to test cases.

Implementation:
- `requirements.md` marks changed sections with `<!-- UPDATED IN REVIEW -->`
- The skill extracts only the marked sections for human review
- Unchanged sections are carried forward without re-approval

### 15.8 Recovery in Review Mode

Same bounded recovery as greenfield:

- **Subagent failure:** retry once with failure context + change manifest context attached
- **Test failure:** recovery loop up to 2 times with fix suggestions scoped to affected sub-problems only
- **LLD contradiction:** surface immediately, no auto-recovery — this requires human decision

### 15.9 First Review Flow

```
User: @tdd-auto-pr .tdd-auto/runs/user-auth-flow/ "Reviewer comments: ..."
  ↓
step-01-init: review mode, load baseline run
  ↓
step-02-load-baseline: load artifacts, write review-comments.md
"Loaded baseline: 5 requirements, 12 test cases, 3 sub-problems."
  ↓
step-03-categorize: produce change-manifest.md
"3 comments categorized. 1 requires requirements change. 2 are code fixes. Approve?"
User: yes
  ↓
step-04-requirements: update requirements.md (1 requirement changed)
User: requirements approved
  ↓
step-05-test-cases: update test-cases.md (2 tests added)
User: tests approved
  ↓
step-06-subproblems: regenerate sub-problems.md
sp-02 marked as reworked
  ↓
step-07-implement: re-implement sp-02
  ↓
step-08-run-tests: pytest (all green)
  ↓
step-09-summarize: PR-ready summary
```

## 16. Architectural Drift Detection and LLD Sync

### 16.1 Purpose

Detect when the user's request or the resulting implementation diverges from the documented LLD, and keep the LLD in sync with reality.

### 16.2 Drift Detection Points

Drift is detected in two places:

**A. At the requirements gate (step-03 / step-04)**

When the skill analyzes the user's request against the LLD, it produces a `drift-report.md`:

```markdown
## Design Drift Report

**Feature:** user-auth-flow
**Date:** 2026-07-25

| # | LLD Says | Request Asks | Drift Type | Severity | User Decision |
|---|---|---|---|---|---|
| 1 | Auth uses JWT tokens (session: 24h) | Request asks for session cookies with 7-day expiry | Architecture | High | Approve / Reject |
| 2 | API is REST (OpenAPI spec) | Request implies GraphQL mutations | Scope | Medium | Approve / Reject |
| 3 | Password hashing: bcrypt | Request mentions SHA-256 | Implementation | Low | Approve / Reject |
```

The user must acknowledge each drift point before `requirements.md` is finalized:
- **Approve drift** → proceed with the new direction, update requirements accordingly
- **Reject drift** → adjust the request to align with the LLD, or update the LLD first

**B. At the end of the workflow (design sync step)**

After tests pass, the skill performs an in-place LLD update. This is a separate step that runs after step-08 in greenfield mode and after step-09 in review mode.

### 16.3 In-Place LLD Update (Not "Last Updated" Section)

The skill updates the relevant LLD files **at the exact location where the concept is described**, not by appending a "last updated" section. This prevents confusion where a reader sees contradictory statements in the same document.

For example, if the LLD says "authentication uses JWT tokens" and the approved drift changes it to session cookies, the skill:
1. Locates the "authentication" section in the relevant LLD file
2. Replaces the JWT description with the session cookie description
3. Updates any related diagrams or API contracts in the same file
4. Records the change in `run-log.md` for traceability

The skill should be surgical: update only the sections that changed, leave everything else untouched.

### 16.4 Design Sync Step Contract

**Purpose:** Update LLD to incorporate approved drift.

**Behavior:**
- Read `drift-report.md` and `requirements.md`
- For each approved drift:
  - Find the relevant section in `.tdd-auto/design/`
  - Update inline, preserving surrounding context
  - If a diagram needs updating (Mermaid, sequence), update it in place
- Write updated LLD files back to `.tdd-auto/design/`
- Record changes in `run-log.md` with `<!-- DESIGN SYNC -->` marker
- Present diff to user: "Updated 2 sections in `lld.md`. Review the changes."

**Advances to:** End of workflow (after step-08 in greenfield, after step-09 in review)

### 16.5 Drift Report in Review Mode

In review mode, if a review comment changes a requirement that was already a drift from the original LLD, the drift report should note the **cumulative drift**:

```markdown
| # | Original LLD | Current State | Change |
|---|---|---|---|
| 1 | Auth uses JWT tokens | Auth uses session cookies (approved in run user-auth-flow) | No change needed |
| 2 | API is REST | API is GraphQL (new drift from review comment) | Requires approval |
```

This helps the user see the evolution of the design over time.

## 17. HTML Review Page

### 17.1 Purpose

Generate a single-page HTML artifact that renders the agreed requirements, test cases, design drift, and implementation summary in a reviewer-friendly format. Host it on GitHub Pages if available, otherwise provide it as a local artifact.

### 17.2 Page Structure

The HTML is a single file (`review.html`) with embedded CSS, JS, and Mermaid.js loaded from CDN. It contains:

```html
<!DOCTYPE html>
<html>
<head>
  <title>PR Review: user-auth-flow</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <style>/* embedded CSS */</style>
</head>
<body>
  <header>
    <h1>PR Review: user-auth-flow</h1>
    <p>Baseline: 2026-07-25 | Review: 2026-07-26</p>
  </header>

  <section id="requirements">
    <h2>Agreed Requirements</h2>
    <!-- Rendered requirements.md -->
  </section>

  <section id="test-cases">
    <h2>Agreed Test Cases</h2>
    <!-- Rendered test-cases.md, Given/When/Then formatted -->
  </section>

  <section id="drift">
    <h2>Design Drift</h2>
    <!-- Drift report if any -->
  </section>

  <section id="implementation">
    <h2>What Was Implemented</h2>
    <!-- Sub-problems with completion status -->
    <!-- Mermaid diagrams if present in sub-problems.md -->
  </section>

  <section id="delta" class="review-mode-only">
    <h2>What Changed in This Review</h2>
    <!-- In review mode: diff-like view of changes -->
  </section>
</body>
</html>
```

### 17.3 Diagram Support

Mermaid.js is embedded via CDN. Diagrams are authored as part of the sub-problem specs or the LLD. The skill does **not** auto-generate diagrams from code — that's a future enhancement.

For MVP, diagrams come from:
- Existing Mermaid blocks in `.tdd-auto/design/` files
- Mermaid blocks authored in `sub-problems.md` by the skill

The HTML page renders all Mermaid blocks automatically.

### 17.4 GitHub Pages Hosting

**Detection:**
1. Check if `gh` CLI is available: `which gh`
2. Check if authenticated: `gh auth status`
3. If authenticated, check if Pages is enabled: `gh api repos/{owner}/{repo}/pages`
4. If Pages is enabled, determine the Pages URL and base path

**Auth failure handling:**
If `gh auth status` fails with an auth error, prompt the user:
```
GitHub CLI authentication expired. Run `gh auth login` to refresh your token, then retry.
```

If Pages is not enabled or `gh` is unavailable, skip hosting and provide the HTML as a local artifact.

**Hosting flow:**
1. Determine the target directory for Pages (e.g. `.tdd-auto/pages/` or `docs/` depending on Pages config)
2. Copy `review.html` and any assets to the target directory
3. Commit and push: `git add`, `git commit`, `git push`
4. Construct the Pages URL from the repo configuration
5. Present the URL to the user

**URL pattern:**
- User Pages: `https://<username>.github.io/<repo>/runs/<feature-slug>/`
- Org Pages: `https://<org>.github.io/<repo>/runs/<feature-slug>/`
- Project Pages with custom domain: use the configured domain

The skill detects the correct pattern from the Pages API response.

### 17.5 Review Mode HTML Updates

In review mode, the HTML page is **updated**, not regenerated from scratch. The skill:

1. Loads the existing `review.html` from the Pages directory (or from the run folder if not hosted)
2. Updates the relevant sections:
   - Append new requirements / mark updated ones
   - Append new test cases / mark updated ones
   - Add delta section showing what changed
3. Re-host if Pages is available

This preserves the reviewer's context — they can see the full history, not just the latest state.

### 17.6 HTML Step Placement

**Greenfield mode:** Added as step-09 (after summarize, after design sync). The step generates the HTML, attempts to host, and presents the URL.

**Review mode:** Added as step-10 (after summarize). Same behavior, but updates the existing HTML instead of creating from scratch.

### 17.7 Fallback Behavior

If GitHub Pages hosting fails for any reason other than auth:
1. Write `review.html` to the run folder
2. Tell the user: "Could not host on GitHub Pages: <reason>. HTML is available at `<local-path>`. You can view it locally or host it manually."
3. Do not block the workflow — the HTML is still a useful artifact

## 18. Future Diagram Generation Challenges

Auto-generating interaction diagrams, sequence diagrams, and other visuals from code or sub-problem specs is a future enhancement. The challenges include:

- **Accuracy:** Diagrams generated from code can become stale as the code evolves. Maintaining them requires either regenerating on every run (expensive) or accepting that they may drift from reality.
- **Scope selection:** Not every code path deserves a diagram. Deciding what to visualize requires judgment about what helps reviewers understand the PR.
- **Tooling:** There are libraries that can generate Mermaid/PlantUML from code (e.g. `mermaid-cli`, `pyreverse` for Python), but they produce verbose, noisy output that needs curation.
- **Sub-problem granularity:** Sub-problems are implementation-level, not design-level. A sub-problem might touch 10 files and 20 functions — generating a meaningful diagram from that requires abstraction, not just raw code analysis.

For now, the approach is to **author diagrams as part of the workflow** (in LLD files or sub-problem specs) rather than generate them from code. This keeps diagrams intentional and accurate. Auto-generation can be revisited once the core workflow is stable.

## 19. Post-MVP Roadmap

| Feature | Notes |
|---|---|
| `tdd-auto-pr` skill | PR review comment resolution workflow |
| Parallel subagents | Run independent sub-problems concurrently |
| LLD change detection | Handle review comments that require design doc changes |
| Auto-generated diagrams | Generate Mermaid/sequence diagrams from sub-problem specs (future) |

## 20. Installer Script

### 20.1 Purpose

Provide a simple bash installer that copies the skill into a project's `.claude/skills/` directory and performs first-time setup.

### 20.2 Script Location

`scripts/install.sh` at the repo root.

### 20.3 Behavior

1. Accept a target project path as argument (default: current directory)
2. Copy `tdd-auto/` and `tdd-auto-pr/` into `<target>/.claude/skills/`
3. If an existing install is found, back it up to `.claude/skills/<skill-name>.bak/` before overwriting
4. Preserve `.tdd-auto/` runtime directory if it exists — do not overwrite it
5. Add `.tdd-auto/runs/` to the target project's `.gitignore` if not already present
6. Print installation summary: skill paths, next steps (first invocation instructions)

### 20.4 Uninstall

`scripts/uninstall.sh` removes the skill directories from `.claude/skills/` but preserves `.tdd-auto/` runtime state. The user can delete `.tdd-auto/` manually if they want a clean removal.

### 20.5 Version Tracking

A `VERSION` file at the repo root. The installer reads it and writes it into `customize.toml` during install. Future upgrades can compare versions and prompt the user if a major version change is detected.
