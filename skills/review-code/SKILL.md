---
name: review-code
description: Explicit-only multi-lens review suite for final readiness checks across proposal, diff, evidence, security, and re-review lenses. Do not use for ordinary PR/diff/branch review; use review-pr instead.
license: MIT
---

# Review Code

Run a read-only multi-lens review suite against the user's stated intent.
Use this skill only when the user explicitly asks for the full review suite,
an orchestrated final readiness review, multi-lens review, or `$review-code`.

Do not use this skill as the default for ordinary PR, diff, branch, patch, or
working-tree review. Use the focused skill that matches the request:

- `review-pr`: default for pull request, branch, patch, diff, or working-tree
  review.
- `review-proposal`: default for proposal or pre-implementation review.
- `review-evidence`: default for proof, evidence, approval-readiness, merge,
  deployment, or release evidence review.
- `review-security`: default for security-specific review.
- `final-rereview`: default for fixup or re-review after prior findings.

This skill is an orchestrator. Use the focused review skills as lenses when
they match the request:

- `review-proposal`: proposal or pre-implementation readiness.
- `review-pr`: pull request, branch, patch, diff, or working-tree review.
- `review-evidence`: proof for approval, merge, release, or deployment.
- `review-security`: defensive security review.
- `final-rereview`: narrow re-review after fixup commits.

Do not copy those skills wholesale into the response. Apply their posture and
focus areas as needed, then synthesize one review result.

## Read-only Boundary

Do not implement fixes, edit files, commit, push, merge, deploy, archive,
delete files, run destructive commands, mutate external systems, or broaden the
requested scope during the review.

You may run read-only discovery commands, inspect local files, inspect diffs,
and read repository documentation. If a mutating command or implementation fix
would be useful, label it as future human-approved work outside this review.

## Inputs

Identify these before reviewing:

- Review target: pull request, branch, patch, diff, commit range, working tree,
  proposal, or stated plan.
- Stated intent: user prompt, PR description, issue, ticket, OpenSpec change,
  design doc, commit message, or other planning artifact.
- Requested decision: feedback only, approval readiness, merge readiness,
  release readiness, deployment readiness, security review, evidence review, or
  final re-review.
- Constraints: local instructions, review scope, forbidden actions, and any
  user-specified non-goals.

If the target or intent is ambiguous and cannot be inferred from local context,
ask one concise clarification before proceeding.

## Context Discovery

Use local repository context as the authority for project-specific rules. Look
for, when present:

- `AGENTS.md`, `CLAUDE.md`, README, CONTRIBUTING, issue templates, and PR
  templates.
- OpenSpec proposals, specs, designs, tasks, and archived changes.
- ADRs, design docs, tickets, release notes, docs, and runbooks.
- Makefiles, scripts, command wrappers, test commands, and CI configuration.
- Dependency manifests and lockfiles when changed.
- Security, credential, release, deployment, migration, rollback, data, or
  production safety instructions.

OpenSpec is optional. If absent, continue with other available local context.

When shell access is available, `../../docs/read-only-discovery.md` provides
optional supporting discovery commands. Prefer repository-provided wrappers and
local instructions over invented commands.

## Review Lens Selection

Use the minimum set of lenses that answers the request:

- Proposal lens: use when reviewing an idea before implementation.
- Diff lens: use when reviewing code changes against stated intent.
- Evidence lens: use when deciding whether the change is proven.
- Security lens: use when requested or when the change touches trust
  boundaries, credentials, commands, files, network calls, dependencies, CI,
  release, deployment, or production behavior.
- Final re-review lens: use when prior findings were addressed and the task is
  to confirm fixups.

For an explicitly requested full-suite review over a code change, use diff,
evidence, and security lenses by default. For an ordinary "review this" request
over a code change, use `review-pr` instead of this skill.

## Review Focus

Prioritize actionable risks:

- Intent mismatch or incomplete implementation.
- Missing required behavior, tests, docs, migrations, rollback, or evidence.
- Bugs, edge cases, race conditions, lifecycle gaps, and data integrity risks.
- Scope creep and unintended file changes.
- Fragility that creates correctness, operability, maintainability, or
  reviewability risk.
- Security risks involving secrets, authorization, injection, unsafe command or
  file handling, dependencies, CI, release, deployment, and production
  boundaries.
- Evidence gaps where claims are implemented but not proven.

Avoid style-only comments unless style hides a real correctness, safety,
usability, maintainability, or reviewability risk.

## Output

Lead with findings. Group output exactly as:

```text
## Blocking Issues
## Non-blocking Issues
## Follow-up Suggestions
## Evaluation
## Verdict
```

For each finding, include:

- Severity group.
- File and line reference where possible.
- The observed gap or risk.
- Why it matters.
- An actionable remediation.

Use PASS / WARN / FAIL rows in `## Evaluation` when useful. Cover only the
checks relevant to the selected lenses, such as intent, scope, tests, evidence,
security, migration, rollback, docs, and release readiness.

If there are no findings in a group, write `None.`

The verdict must clearly state whether the change is ready for the requested
decision, ready with caveats, or not ready.

## Public-safe Behavior

Do not include private examples, credentials, customer data, internal hostnames,
personal data, or organization-specific operational details in reusable output.
When examples are needed, use placeholders such as `<change-name>`, `<repo>`,
`<service>`, `<environment>`, and `<artifact>`.
