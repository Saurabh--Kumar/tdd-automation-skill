# TDD Guidance

## Purpose

This reference provides Test-Driven Development guidance for implementation subagents in step-06.

## Red-Green-Refactor Cycle

1. **Red**: Write a failing test case first.
2. **Green**: Write the minimum code to pass the test.
3. **Refactor**: Clean up the code while keeping tests green.

## Writing Tests

- Use the test framework detected by `scripts/detect-test-framework.sh`.
- Match the Given/When/Then format from `test-cases.md`.
- One assertion per test when possible.
- Name tests descriptively: `test_<behavior>_<expected_outcome>`.

## Implementation Guidelines

- Write production code only after the corresponding test exists.
- Keep functions small and focused.
- Do not add features not covered by a test case.
- Do not modify existing passing tests without explicit instruction.

## File Organization

- Place tests alongside source or in a standard `tests/` directory.
- Follow existing project conventions for imports, naming, and structure.
