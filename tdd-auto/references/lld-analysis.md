# LLD Analysis Guide

## Purpose

This reference guides the agent through reading and evaluating Low-Level Design (LLD) documents during step-02.

## Reading LLDs

1. Read every file in `.tdd-auto/design/`.
2. Note the document structure: sections, diagrams, API contracts, data models.
3. Extract all Mermaid blocks for later use in the HTML review page.

## Extracting Diagrams

Scan for code blocks marked as `mermaid`:
```markdown
```mermaid
graph TD
    A --> B
```
```

Store the inner content (between the fences) for later Mermaid.js rendering.

## Ambiguity Checklist

When evaluating the design, check:
- **Incomplete API specs**: missing request/response schemas
- **Undefined data models**: tables, schemas, or entities without full structure
- **Unspecified error handling**: what happens when things fail?
- **Missing edge cases**: boundary conditions not covered
- **Contradictory diagrams**: when a text diagram and a Mermaid diagram disagree
- **Assumed infrastructure**: external services, databases, queues mentioned but not documented

## Drift Types

- **Architecture**: fundamental architectural pattern mismatch (e.g. REST vs GraphQL, JWT vs session cookies)
- **Scope**: feature boundary changes (e.g. "add search" when design only covers CRUD)
- **Implementation**: specific implementation approach changes (e.g. bcrypt vs sha256)

## Severity Guide

- **High**: Affects system architecture, security, or data integrity. Cannot proceed without explicit approval.
- **Medium**: Affects implementation approach or scope. Can proceed with user awareness.
- **Low**: Minor detail (linting rules, naming conventions). Inform but do not block.
