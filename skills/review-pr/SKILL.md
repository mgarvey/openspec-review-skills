---
name: review-pr
description: Read-only hostile review of a pull request, branch, patch, or diff against its stated intent, bounded to actionable risk.
license: MIT
---

# Review PR

Review a pull request, branch, patch, or diff against its stated intent. The
posture is hostile in the review sense: assume defects can hide in the gap
between intent, diff, tests, and evidence. Keep the review bounded, risk-based,
and actionable.

This is a review skill only. Do not implement, edit files, commit, push, merge,
deploy, archive, run destructive commands, or broaden the requested scope.

## Context Discovery

Before reviewing, identify the stated intent and local rules. Use available
context such as:

- PR description, linked issue, ticket, design doc, ADR, or user prompt.
- `AGENTS.md`, `CLAUDE.md`, README, CONTRIBUTING, and templates.
- OpenSpec artifacts, specs, task docs, docs, and runbooks.
- Makefiles, scripts, command wrappers, and CI configuration.
- Repository-specific safety or release instructions.

OpenSpec is optional. If absent, review against other intent and context
sources.

## Review Focus

Compare the diff against the stated intent. Explicitly check:

- Intent alignment.
- Omissions in behavior, tests, docs, migration, rollback, or evidence.
- Fragility that creates concrete correctness, safety, operability, or
  maintainability risk.
- Scope creep.
- Unintended file changes.
- Missing tests or evidence.
- Docs/code mismatch.
- Data, security, lifecycle, configuration, migration, cleanup, or deletion
  risks.
- Local instructions or command wrappers bypassed without justification.
- Generated files, lockfiles, or artifacts changed unexpectedly.

Do not turn hostile review into noise. Prefer findings that could affect
correctness, safety, maintainability, reviewability, or approval confidence.

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
- The gap between stated intent and observed change.
- The risk.
- An actionable remediation.

Use PASS / WARN / FAIL rows in `## Evaluation` when they help summarize the
intent, scope, test, evidence, data, security, lifecycle, configuration,
migration, cleanup, and deletion checks.

If there are no findings in a group, write `None.`

The verdict should state whether the change is ready for approval, ready with
non-blocking caveats, or not ready.

## Guardrails

- Stay read-only.
- Do not fix the diff.
- Do not run destructive commands.
- Prefer read-only commands and evidence collection when recommending commands.
- Label any mutating command as human-approved future work outside this review.
- Avoid style-only comments unless style hides a real risk.
