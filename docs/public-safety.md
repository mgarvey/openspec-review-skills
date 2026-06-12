# Public Safety

This repository is intended for public release. Keep the skills generic and
portable.

## Do Not Include

- Personal names, email addresses, phone numbers, home paths, or account IDs.
- Company names, customer names, vendor account identifiers, internal hostnames,
  private IPs, bucket names, project-specific task names, or scheduler names.
- Credentials, tokens, passwords, API keys, private certificates, `.env` files,
  connection strings, or secret-looking examples.
- Internal runbooks, production procedures, account-specific rollback steps, or
  business-specific mutation boundaries.
- Screenshots, command output, logs, artifacts, or examples copied from a
  private repository.

## Prefer

- Generic placeholders such as `<change-name>`, `<repo>`, `<service>`,
  `<environment>`, and `<artifact>`.
- Read-only examples unless a mutation is central to the workflow.
- Explicit human approval language for destructive or production-changing
  actions.
- Repository-local context discovery rather than hardcoded project rules.
- Local verification commands that users can adapt to their own repository.

## Review Checklist

Before publishing:

- Review every `SKILL.md` for private nouns and environment-specific claims.
- Confirm examples do not reveal internal paths or operational details.
- Confirm no generated artifacts, logs, caches, or local config files are
  committed.
- Confirm the README and docs explain how to install skills without requiring
  private tools.
- Run your normal secret-scanning and repository review process outside this
  package.
