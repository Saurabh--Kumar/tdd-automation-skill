# Step 10: HTML Review Page

## Purpose

Generate and host reviewer-facing HTML page.

## Failure Recovery

- If GitHub Pages hosting fails due to auth, prompt user to refresh `gh` auth login.
- If Pages not enabled or `gh` unavailable, provide HTML as local artifact without blocking.

## Rules

- Read fully and execute completely before proceeding.
- The workflow ends after this step.

## Instructions

1. **Read inputs.** Load `requirements.md`, `test-cases.md`, `drift-report.md`, `sub-problems.md`, and `run-log.md`.

2. **Generate `review.html`.** Create a single-page HTML artifact with:
   - Embedded CSS
   - Mermaid.js CDN
   - Sections: requirements, test cases, design drift, implementation summary
   - Mermaid diagrams from LLD and sub-problems

3. **Write `review.html`** to `{project-root}/.tdd-auto/runs/{feature-slug}/review.html`.

4. **Attempt GitHub Pages hosting:**
   - Check `gh` CLI availability and auth status
   - If auth fails, prompt user to refresh token
   - If Pages enabled, commit and push HTML, construct URL
   - If Pages not enabled or `gh` unavailable, provide as local artifact

5. **Present URL to user:**
   > "Review page: <url>"

6. **If local only:**
   > "Could not host on GitHub Pages: <reason>. HTML is available at `<local-path>`. You can view it locally or host it manually."

## Workflow Ends
