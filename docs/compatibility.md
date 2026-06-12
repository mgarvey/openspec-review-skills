# Compatibility

These skills use the open agent skill shape: each skill is a directory with a
`SKILL.md` entrypoint and YAML frontmatter. The instructions avoid
environment-specific tool names whenever possible so the same skill content can
run in Codex, Claude Code, and other agents that follow the `SKILL.md` pattern.

## Codex

Codex environments may expose repo-local skills through more than one directory
name. The existing source repository for these extensions used `.codex/skills`.
Current public Codex documentation also describes `.agents/skills` as the
repo-scoped skill location.

Current Codex documentation says:

- Skills are directories with a required `SKILL.md`.
- `SKILL.md` must include `name` and `description`.
- Repo-scoped skills are discovered from `.agents/skills` directories from the
  current working directory up to the repository root.
- User-scoped skills may live under `$HOME/.agents/skills`.
- Codex supports explicit and implicit skill invocation.
- Plugins are the preferred distribution unit for sharing reusable skills
  beyond a single repository.

Source: <https://developers.openai.com/codex/skills>

Recommended project install:

```bash
./scripts/install-skills.sh .codex/skills
./scripts/install-skills.sh .agents/skills
```

The `review-code` skill is installed the same way as the other skills. Its
canonical source is `skills/review-code`; `.codex/skills/review-code` and
`.agents/skills/review-code` are activation copies.

Recommended personal install:

```bash
./scripts/install-skills.sh "$HOME/.agents/skills"
```

## Claude Code

Current Claude Code documentation says:

- Skills are directories with a required `SKILL.md`.
- Project skills live under `.claude/skills/<skill-name>/SKILL.md`.
- Personal skills live under `$HOME/.claude/skills/<skill-name>/SKILL.md`.
- Claude Code skills follow the Agent Skills open standard and add optional
  Claude-specific frontmatter fields.
- Existing `.claude/commands` continue to work, but skills are recommended for
  reusable instructions and supporting files.

Source: <https://code.claude.com/docs/en/skills>

Recommended project install:

```bash
./scripts/install-skills.sh .claude/skills
```

The `review-code` skill is installed the same way as the other skills. Its
canonical source is `skills/review-code`; `.claude/skills/review-code` is
only an activation copy.

Recommended personal install:

```bash
./scripts/install-skills.sh "$HOME/.claude/skills"
```

## Why There Is No Checked-in Activation Mirror

This repository keeps `skills/` as the only canonical copy and documents
activation targets instead of checking in mirrored copies. If your environment
reads `.codex/skills`, install there explicitly:

```bash
./scripts/install-skills.sh .codex/skills
```

Treat `.codex/skills`, `.agents/skills`, and `.claude/skills` as install
targets, not source-of-truth directories.

## Frontmatter Policy

The skills include portable fields:

- `name`
- `description`
- `license`
- `compatibility`

They avoid Claude-only fields such as `allowed-tools`, `context`, and dynamic
command injection, and avoid Codex-only metadata files. Add those in a local
fork if your team wants tighter invocation policy or preapproved tools.
