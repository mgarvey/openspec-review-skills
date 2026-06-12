---
name: review-proposal
description: Read-only review of a proposed change before implementation, using local repository context as the source of project-specific rules.
license: MIT
---

# Review Proposal

Review a proposed change before implementation. The source may be a user
prompt, issue, ticket, ADR, planning document, OpenSpec change, design doc, or
another local artifact.

This is a review skill only. Do not implement, edit files, commit, push, merge,
deploy, archive, run destructive commands, or broaden the requested scope.

## Context Discovery

Before reviewing, inspect available local context and treat it as the authority
for project-specific rules. Look for, when present:

- `AGENTS.md`, `CLAUDE.md`, README, CONTRIBUTING, and templates.
- OpenSpec artifacts, ADRs, design docs, specs, tickets, or task docs.
- Makefiles, scripts, command wrappers, and CI configuration.
- Docs, runbooks, release notes, and repository-specific safety instructions.

OpenSpec is optional. If absent, continue with other local context.

## Review Focus

Check whether the proposed change is ready to implement:

- The problem, goal, and intended outcome are clear.
- Scope is bounded and non-goals are explicit.
- Ownership and affected surfaces are identified.
- Acceptance criteria are testable.
- Evidence expectations are clear.
- Rollback or undo expectations are clear where relevant.
- Data, security, release, migration, cleanup, deletion, and configuration risks
  are identified.
- The proposal matches local repository instructions and architecture.
- The proposal does not smuggle unrelated work into the change.

Explicitly scan for unbounded phrases that often hide scope creep:

- "and related cleanup"
- "fix related bugs"
- "clean up the codebase"
- "while you are there"
- "make it better"
- "refactor as needed"

When one appears, report the exact phrase as a scope risk and ask for a bounded
replacement or explicit non-goal.

## Output

Lead with findings. Group them exactly as:

```text
## Blocking Issues
## Non-blocking Issues
## Follow-up Suggestions
## Evaluation
## Verdict
```

For each finding, include:

- Severity group.
- Exact file and line reference where possible.
- The risk or ambiguity.
- An actionable remediation.

Use PASS / WARN / FAIL rows in `## Evaluation` when they help summarize the
checks. These rows support the findings; they do not replace finding
classification.

If there are no findings in a group, write `None.`

The verdict must be one of:

- PROCEED
- PROCEED WITH WARNINGS
- REJECT

## Guardrails

- Stay read-only.
- Do not rewrite the proposal unless explicitly asked in a separate editing
  request.
- Do not invent project rules. Derive them from local context.
- Prefer read-only commands and evidence collection when recommending commands.
- Label any mutating command as human-approved future work outside this review.
- Avoid style-only comments unless style hides a real correctness, safety,
  usability, maintainability, or reviewability risk.
