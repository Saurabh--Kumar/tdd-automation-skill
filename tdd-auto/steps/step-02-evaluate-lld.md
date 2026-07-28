# Step 2: Evaluate LLD

## Purpose

Read design docs, surface ambiguities, detect architectural drift, and produce clarifying questions before writing requirements.

## Rules

- Read fully and execute completely before proceeding.
- All artifacts are written to `{project-root}/.tdd-auto/runs/{feature-slug}/`.

## Instructions

1. **Read design docs.** List all files in `{progress.yaml.lld_dir}` (usually `.tdd-auto/design/`). Read each one.

2. **Extract diagrams.** Scan LLD files for Mermaid diagram blocks (` ```mermaid ` ... ` ``` `). Store their content for later use in the HTML review page.

3. **Read the request.** Re-read `progress.yaml`'s `feature_request` field. Also consider any clarifying answers the user has already provided.

4. **Produce `brainstorm-notes.md`.** Based on what you read, produce a document with these sections:
   - **What the request seems to ask for** — one-paragraph summary.
   - **Ambiguities in the request** — things that are unclear or could be interpreted multiple ways.
   - **Ambiguities found in the design** — gaps, contradictions, or under-specified sections in the LLD.
   - **Clarifying questions** — numbered list of questions for the user, one per ambiguity.
   - **Relevant diagrams extracted from LLD** — list or embed any Mermaid blocks found.

5. **Produce `drift-report.md`.** For each significant divergence between the request and the LLD:
   - LLD says...
   - Request asks...
   - Drift type (`Architecture`, `Scope`, `Implementation`)
   - Severity (`High`, `Medium`, `Low`)
   - User decision: `Pending`

6. **Present both documents to the user.** Tell them:
   > "From your design I see X. Your request mentions Y but the design doesn't cover Z.
   > Clarifying questions: ...
   > Also, design drift detected: JWT vs session cookies. Approve?"

7. **Wait for user response.** The user must acknowledge each drift point before proceeding.

8. **Update `progress.yaml`**
   - `brainstorm_notes`: `runs/{feature-slug}/brainstorm-notes.md`
   - `drift_report`: `runs/{feature-slug}/drift-report.md`
   - `last_saved`: current ISO timestamp

9. **Validate exit.** If the design is sparse or self-contradictory, note it explicitly in your message. Do not advance until the user confirms understanding and acknowledges drift.

## Advances to

- `./step-03-requirements.md` after user confirms understanding and acknowledges drift.
