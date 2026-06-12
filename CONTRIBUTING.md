# Contributing

Thank you for helping keep these skills portable and public-safe.

## Principles

- Keep skills generic and reusable across repositories.
- Prefer repository-local context discovery over hardcoded project rules.
- Keep workflows read-only unless the skill explicitly exists to implement or
  archive work.
- Avoid agent-specific tool names unless there is no portable alternative.
- Do not include private organization details, personal data, credentials,
  internal paths, customer data, logs, screenshots, or production runbooks.

## Before Opening A Pull Request

Before opening a pull request, manually review changed `SKILL.md` files for:

- private nouns or examples copied from an internal repository
- commands that mutate state without clear human approval
- references to unavailable private tools
- examples that require credentials or production access
- instructions that are too broad or likely to trigger unintentionally

## Skill Style

- Put the trigger words in the `description`.
- Keep each skill focused on one job.
- Use imperative instructions.
- Make inputs, outputs, and guardrails explicit.
- Put long examples or references in supporting files only when needed.
