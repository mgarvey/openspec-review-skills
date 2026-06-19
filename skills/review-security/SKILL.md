---
name: review-security
description: Defensive security review for proposals or code changes that touch secrets, auth, input handling, commands, files, network calls, dependencies, CI, deployment, or production boundaries.
license: MIT
---

# Review Security

Perform a focused defensive security review of a proposal, pull request,
branch, patch, or diff.

This is a review skill only. Do not implement, edit files, commit, push, merge,
deploy, archive, run destructive commands, access secrets, exfiltrate data,
probe external systems, or broaden the requested scope.

## Context Discovery

Before reviewing, identify the stated intent and local security rules. Use
available context such as:

- PR description, linked issue, ticket, design doc, ADR, or user prompt.
- `AGENTS.md`, `CLAUDE.md`, README, CONTRIBUTING, and templates.
- OpenSpec artifacts, specs, task docs, docs, and runbooks.
- Makefiles, scripts, command wrappers, CI configuration, and deployment docs.
- Repository-specific safety, credential, release, or production instructions.

OpenSpec is optional. If absent, review against other local intent and context.

When shell access is available, `../../docs/read-only-discovery.md` provides
optional supporting discovery commands. Prefer repository-provided wrappers and
local instructions over invented commands.

## Security Review Focus

Check for concrete security risk in these categories:

Do not report a security category unless it is tied to a changed file, changed
behavior, changed dependency, changed configuration, missing control, or stated
intent that creates a concrete security, data, credential, CI, deployment, or
production risk.

- Secrets and credentials:
  - hardcoded secrets, tokens, passwords, connection strings, or API keys
  - secrets written to logs, artifacts, reports, screenshots, or PR text
  - unsafe `.env`, config, credential, or sample-file handling
  - credential scope expansion or new long-lived credentials

- Authentication and authorization:
  - missing authorization checks
  - privilege escalation
  - account, tenant, profile, channel, or environment confusion
  - unsafe production vs development defaults

- Input and command safety:
  - command injection
  - shell quoting bugs
  - unsafe subprocess calls
  - SQL injection or unsafe dynamic SQL
  - path traversal
  - unsafe globbing or overly broad file matching
  - unsafe deserialization or dynamic code execution

- File, log, and artifact safety:
  - deletion paths that are too broad
  - writes outside intended directories
  - symlink or traversal issues
  - logs containing sensitive data
  - artifacts that reveal secrets, internal paths, customer data, or credentials
  - retention or cleanup changes that destroy audit evidence too aggressively

- Network and API behavior:
  - unexpected outbound network calls
  - SSRF-style risks
  - unbounded retries or rate-limit abuse
  - unsafe webhook handling
  - insufficient TLS or certificate verification
  - wrong account, store, channel, tenant, or environment targeting

- Database and data safety:
  - destructive migrations or routine changes
  - missing backups or rollback
  - overly broad updates or deletes
  - sensitive data exposure
  - weak audit trail for production data mutation

- Dependency and supply-chain risk:
  - new dependencies
  - changed lockfiles
  - unpinned versions
  - install scripts or postinstall behavior
  - abandoned or suspicious packages
  - expanded CI permissions

- CI, release, and deployment risk:
  - secrets exposed to untrusted pull requests
  - unsafe workflow permissions
  - untrusted code running with privileged tokens
  - deployment from unintended branches
  - production deploy steps mixed with review or implementation steps
  - missing environment separation

- Organization-specific production boundaries:
  - new writes to systems that should be read-only
  - cross-account or cross-environment confusion
  - scheduler, queue, or background job mutation
  - database routine or migration mutation
  - log cleanup or retention behavior
  - server update or deployment behavior
  - public storage exposure
  - evidence artifacts that may leak sensitive operational details

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
- The security risk.
- The affected trust boundary or asset.
- An actionable remediation.

Use PASS / WARN / FAIL rows in `## Evaluation` when useful. If there are no
findings in a group, write `None.`

The verdict should state whether the proposal or change is acceptable from a
security perspective, acceptable with caveats, or not acceptable.

## Guardrails

- Stay read-only.
- Do not attempt exploitation.
- Do not access, print, decode, or validate real secrets.
- Do not call external systems unless explicitly authorized as a safe read-only
  check.
- Prefer static review of the diff, configs, docs, tests, and local scripts.
- Label any mutating command as human-approved future work outside this review.
- Do not fix the diff.
- Avoid theoretical noise. Report findings that affect real security, data
  safety, production safety, credential exposure, or approval confidence.
