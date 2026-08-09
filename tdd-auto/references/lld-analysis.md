# LLD Analysis Guide

## Purpose

This reference guides the agent through reading and evaluating Low-Level Design (LLD) documents during step-02.

## Reading LLDs

1. Read EVERY file in `.tdd-auto/design/` — design docs may be in any format: `.md`, `.txt`, `.adoc`, `.drawio`, images (PNG/SVG), etc.
2. Note the document structure: sections, diagrams, API contracts, data models.
3. Inventory every diagram you find (see "Diagram Handling" below) so it can be referenced in the brainstorm notes and the final review package.

## Diagram Handling

Design diagrams are NOT limited to Mermaid. The skill must understand and preserve all of them:

- **Text-based diagram DSLs** — Mermaid, PlantUML, Graphviz/DOT, nomnoml, etc. These appear in fenced code blocks. Capture the raw block verbatim (including its language tag) so it can be re-embedded in markdown.
- **UML / formal notation** — class diagrams, sequence diagrams, activity diagrams authored as text or images. Understand the relationships they express (inheritance, calls, flows).
- **ASCII / box-drawing diagrams** — hand-drawn-in-text flows and tables. Interpret the directional/relationship meaning.
- **Embedded images** — PNG/SVG/other raster or vector files. Inspect them visually and describe what they depict (components, flows, boundaries). Reference the file path so a human reviewer can open the original.

**Golden rule:** never rewrite or "convert" an existing diagram into Mermaid (or any other format) unless the user explicitly asks. Preserve diagrams exactly as the author intended. The only time the skill authors a Mermaid diagram is when it generates a NEW one (e.g. inside `sub-problems.md`), because Mermaid renders natively on GitHub and in common markdown viewers.

## Ambiguity Checklist

When evaluating the design, check:
- **Incomplete API specs**: missing request/response schemas
- **Undefined data models**: tables, schemas, or entities without full structure
- **Unspecified error handling**: what happens when things fail?
- **Missing edge cases**: boundary conditions not covered
- **Contradictory diagrams**: when two diagrams (or a diagram and prose) disagree about the same thing
- **Assumed infrastructure**: external services, databases, queues mentioned but not documented

## Drift Types

- **Architecture**: fundamental architectural pattern mismatch (e.g. REST vs GraphQL, JWT vs session cookies)
- **Scope**: feature boundary changes (e.g. "add search" when design only covers CRUD)
- **Implementation**: specific implementation approach changes (e.g. bcrypt vs sha256)

## Severity Guide

- **High**: Affects system architecture, security, or data integrity. Cannot proceed without explicit approval.
- **Medium**: Affects implementation approach or scope. Can proceed with user awareness.
- **Low**: Minor detail (linting rules, naming conventions). Inform but do not block.
