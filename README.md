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

For Codex, install into exactly one repo-local skill directory for a given
project. Current public documentation describes `.agents/skills`; older or
existing projects may still load `.codex/skills`. Do not install the same skills
into both `.agents/skills` and `.codex/skills` in one project, or the skills may
appear twice.

For Claude Code, current public documentation describes project-scoped skills
under `.claude/skills` and personal skills under `$HOME/.claude/skills`.

Install all skills into a project with one target appropriate for your agent:

```bash
# Current Codex project target
./scripts/install-skills.sh .agents/skills

# Legacy Codex project target, if your environment still loads it
./scripts/install-skills.sh .codex/skills

# Claude Code project target
./scripts/install-skills.sh .claude/skills
```

Or copy a single skill manually:

```bash
mkdir -p .agents/skills
cp -R skills/review-code .agents/skills/
```

See [docs/compatibility.md](docs/compatibility.md) for current compatibility
notes and tradeoffs.

## Requirements

- Git and shell access for most review workflows.
- No required network access.
- No bundled secrets or private configuration.

OpenSpec CLI is only needed for maintainers who work on this repository's
proposal artifacts under `openspec/`.

## Release Safety

Before publishing, review [docs/public-safety.md](docs/public-safety.md) and run
your normal secret-scanning and repository review process outside this package.

## License

MIT. See [LICENSE](LICENSE).
