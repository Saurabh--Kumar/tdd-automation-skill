# TDD Auto — MVP Design Document

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

**Purpose:** Read design docs, surface ambiguities, ask clarifying questions.

**Behavior:**
- Read all `.md` files in `.tdd-auto/design/`
- Read the user's request
- Produce `brainstorm-notes.md`:
  - What the request seems to ask for
  - Ambiguities in the request
  - Ambiguities found in the design
  - Clarifying questions
- Present to user, wait for response
- If design is sparse or self-contradictory, note that explicitly

**Advances to:** step-03 after user confirms understanding

### step-03-requirements

**Purpose:** Produce requirements from brainstorm exchange.

**Behavior:**
- Read `brainstorm-notes.md` and user's clarifying answers
- Fill `requirements.md` from template:
  - Feature overview
  - Functional requirements
  - Non-functional requirements
  - Dependencies
  - Out of scope
  - Open questions (if any remain)
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
- Present summary to user

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
step-02: Read design, produce brainstorm-notes.md
"From your design I see X. Your request mentions Y but the design doesn't cover Z. Clarifying questions: ..."
  ↓
User answers
  ↓
step-03: requirements.md (draft) → user approves
step-04: test-cases.md (draft) → user approves
step-05: sub-problems.md
step-06: sequential subagents implement
step-07: pytest (all green)
step-08: summary
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
```

## 11. Scope Boundary (MVP)

**In scope:**
- Single request, single feature slug
- Two human gates: requirements, test cases
- Sequential subagent implementation
- Auto-detected test framework
- Full resume/edit support
- Hidden `.tdd-auto/` runtime folder

**Out of scope (future):**
- Parallel subagents
- Multiple goals in one request
- Coverage thresholds
- CI integration
- Epic/chain workflows
- Plugin marketplace packaging

## 12. Key Risks

| Risk | Mitigation |
|---|---|
| Subagent produces code that doesn't compile | step-06 logs failures; step-07 catches test failures |
| User edits requirements without realizing it invalidates tests | step-01c detects checksum change, warns explicitly |
| Design docs are insufficient | step-02 surfaces this; user can supplement before requirements |
| Long runs exhaust context | State is written to disk after every step; resume is safe |
| Subagents drift out of scope | Each subagent receives only its sub-problem spec + relevant excerpts |
