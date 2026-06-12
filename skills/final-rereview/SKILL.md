---
name: final-rereview
description: Read-only narrow re-review after fixup commits, focused on prior findings, fixup deltas, final evidence, and human approval readiness.
license: MIT
---

# Final Re-review

Use this skill after review findings have been addressed with fixup commits or
small follow-up changes. Do not redo the whole review unless the fixup expands
scope or invalidates prior assumptions.

This is a review skill only. Do not implement, edit files, commit, push, merge,
deploy, archive, run destructive commands, or broaden the requested scope.

## Context Discovery

Gather:

- Prior Blocking, Non-blocking, and Follow-up findings.
- Fixup commits, patch range, or updated diff.
- PR description or change intent.
- Evidence added since the previous review.
- `AGENTS.md`, `CLAUDE.md`, README, CONTRIBUTING, templates, docs, runbooks,
  and local instructions as needed.
- OpenSpec artifacts, when present.

OpenSpec is optional. If absent, continue with other local context.

## Review Focus

Keep the re-review narrow:

- Track each prior Blocking finding to resolved, still blocking, or explicitly
  superseded.
- Check whether prior Non-blocking findings were resolved or consciously
  accepted.
- Review only fixup commits or the delta since prior review.
- Reopen the broader review only if the fixup changes design, materially
  expands the diff, or invalidates prior assumptions.
- Check whether fixups introduced new correctness, safety, maintainability,
  reviewability, release, data, security, migration, cleanup, deletion, or
  configuration risks.
- Check whether final evidence is sufficient for the requested human decision.

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
- Prior finding reference or exact file and line reference where possible.
- What changed in the fixup.
- Remaining risk, if any.
- An actionable remediation.

Use PASS / WARN / FAIL rows in `## Evaluation` when useful. If there are no
findings in a group, write `None.`

The terminal verdict must be one of:

- READY FOR HUMAN APPROVAL
- RE-REVIEW FAILED

Use READY FOR HUMAN APPROVAL only when prior blockers are resolved or
explicitly superseded, no new blocking risks were introduced, and final evidence
is sufficient for the requested human decision.

Use RE-REVIEW FAILED when any prior blocker remains unresolved, a new blocker
appears, the fixup cannot be tied to the prior finding, or final evidence is
insufficient.

## Guardrails

- Stay read-only.
- Do not fix remaining issues.
- Do not run destructive commands.
- Prefer read-only commands and evidence collection when recommending commands.
- Label any mutating command as human-approved future work outside this review.
- Avoid style-only comments unless style hides a real risk.
