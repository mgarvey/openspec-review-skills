# OpenSpec Agent Skills

Portable agent skills for repository review workflows developed with OpenSpec.

This repository is intentionally public-safe. The skills are written for generic
software repositories and do not contain private company names, personal
information, credentials, server names, internal paths, customer data, or
business-specific operating procedures.

## What Is Included

Review skills:

- `review-code`: read-only orchestrated review of a branch, pull request,
  patch, diff, or working tree.
- `review-proposal`: read-only pre-implementation proposal review.
- `review-pr`: read-only review of a pull request, branch, or diff.
- `review-evidence`: read-only review of proof for approval, merge, or deploy.
- `review-security`: read-only defensive security review.
- `final-rereview`: narrow re-review after fixup commits.

OpenSpec workflow skills:

- `openspec-propose`: create a complete OpenSpec change proposal, design, specs,
  and tasks.
- `openspec-apply-change`: implement tasks from an active OpenSpec change.
- `openspec-archive-change`: archive a completed OpenSpec change.
- `openspec-explore`: exploratory thinking mode for clarifying requirements
  before or during a change.
- `openspec-sync-specs`: sync delta specs from an active change into main specs.

## Repository Layout

```text
skills/
  <skill-name>/
    SKILL.md
docs/
  compatibility.md
  public-safety.md
scripts/
  install-skills.sh
```

`skills/` is the canonical source. Copy or sync those skill directories into the
agent-specific location used by your environment.

## Install

For Codex, install into the skill directory your Codex surface loads. Existing
Codex projects may use `.codex/skills`; current public documentation also
describes `.agents/skills`.

For Claude Code, current public documentation describes project-scoped skills
under `.claude/skills` and personal skills under `$HOME/.claude/skills`.

Install all skills into a project with one of:

```bash
./scripts/install-skills.sh .codex/skills
./scripts/install-skills.sh .agents/skills
./scripts/install-skills.sh .claude/skills
```

Or copy a single skill manually:

```bash
mkdir -p .codex/skills
cp -R skills/review-code .codex/skills/
```

See [docs/compatibility.md](docs/compatibility.md) for current compatibility
notes and tradeoffs.

## Requirements

- Git and shell access for most review workflows.
- OpenSpec CLI for the `openspec-*` workflow skills.
- No required network access unless the reviewed repository workflow itself
  requires it.
- No bundled secrets or private configuration.

OpenSpec CLI is not required to install the skills or use the read-only review
skills.

## Release Safety

Before publishing, review [docs/public-safety.md](docs/public-safety.md) and run
your normal secret-scanning and repository review process outside this package.

## License

MIT. See [LICENSE](LICENSE).
