# Compatibility

These skills use the open agent skill shape: each skill is a directory with a
`SKILL.md` entrypoint and YAML frontmatter. The instructions avoid
environment-specific tool names whenever possible so the same skill content can
run in Codex, Claude Code, and other agents that follow the `SKILL.md` pattern.

## Codex

Codex environments may expose repo-local skills through more than one directory
name. Current Codex project activation uses `.agents/skills`; older or existing
projects may still load `.codex/skills`.

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

Preferred project install:

```bash
./scripts/install-skills.sh --codex-current
```

`--codex-current` installs into `.agents/skills`. Treat `.codex/skills` as a
legacy target:

```bash
./scripts/install-skills.sh --codex-legacy
```

Installer aliases are resolved relative to the current working directory. Run
the installer from the project that should receive the skills, or pass an
explicit target path.

Do not install both `.agents/skills` and `.codex/skills` in the same project
unless you are intentionally migrating between them. The installer warns when it
sees both paths.

Codex supports symlinked skill folders, so downstream projects can keep this
repository as a submodule and symlink `.agents/skills/<skill-name>` to
`.agents/vendor/openspec-review-skills/skills/<skill-name>`.

The `review-code` skill is installed the same way as the other skills. Its
canonical source is `skills/review-code`; `.agents/skills/review-code` or
`.codex/skills/review-code` is only an activation copy.

## OpenAI Metadata

Each skill includes optional Codex UI metadata at `agents/openai.yaml`.

```yaml
interface:
  display_name: "Review PR"
  short_description: "Focused PR, diff, branch, patch, or working-tree review"
```

`review-code` also sets:

```yaml
policy:
  allow_implicit_invocation: false
```

That makes `review-code` explicit-only while the focused skills remain
available for implicit routing.

## Claude Code

Project install:

```bash
./scripts/install-skills.sh --claude
```

`--claude` installs into `.claude/skills`. The skill instructions avoid
Codex-only tool names, so the same canonical skill content can be copied into
Claude Code projects.

## Distribution

`skills/` is the canonical source for this package. Recommended downstream
rollout options are:

- submodule + symlink + Dependabot
- scheduled copy-update pull request
- user-scoped local install

This repository keeps `skills/` as the only canonical copy and documents
activation targets instead of checking in mirrored copies. Treat
`.codex/skills`, `.agents/skills`, and `.claude/skills` as install targets, not
source-of-truth directories. For Codex repo-local installs, use only one of
`.agents/skills` or `.codex/skills` in the same project.

Plugins may become a useful future distribution path, but they are optional and
are not the primary repo-scoped rollout path for this package.

## Frontmatter Policy

Required fields:

- `name`
- `description`

Optional portable field:

- `license`

This package does not claim a required `compatibility` frontmatter field.
