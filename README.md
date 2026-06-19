# OpenSpec Review Skills

Portable `SKILL.md` review skills for repository review workflows.

This repository is intentionally public-safe. The skills are written for generic
software repositories and do not contain private company names, personal
information, credentials, server names, internal paths, customer data, or
business-specific operating procedures.

## What Is Included

Review skills:

- `review-pr`: default focused skill for ordinary PR, branch, patch, diff, and
  working-tree review.
- `review-proposal`: pre-implementation proposal review.
- `review-evidence`: review of proof for approval, merge, deploy, or release.
- `review-security`: defensive security review.
- `final-rereview`: narrow re-review after fixup commits.
- `review-code`: explicit-only multi-lens final readiness suite. Do not use it
  for ordinary PR/diff review; use `review-pr` instead.

## Repository Layout

```text
skills/
  <skill-name>/
    SKILL.md
    agents/openai.yaml
docs/
scripts/
templates/
tests/
```

`skills/` is the canonical source. Do not check copied activation mirrors such
as `.agents/skills` or `.codex/skills` into this public repository.

## Install

For Codex, install into exactly one repo-local skill directory for a given
project. Current Codex project activation uses `.agents/skills`:

```bash
./scripts/install-skills.sh --codex-current
```

Alias targets such as `--codex-current`, `--codex-legacy`, and `--claude` are
resolved relative to the current working directory. Run the installer from the
project that should receive the skills, or pass an explicit target path.

`.codex/skills` is a legacy Codex target. Do not install both `.agents/skills`
and `.codex/skills` in the same project unless you are intentionally migrating
between them; duplicate same-named skills may appear twice.

```bash
./scripts/install-skills.sh --codex-legacy
```

For Claude Code project skills:

```bash
./scripts/install-skills.sh --claude
```

Install selected skills:

```bash
./scripts/install-skills.sh --codex-current --skill review-pr,review-evidence
```

Preview changes before copying:

```bash
./scripts/install-skills.sh --dry-run --codex-current
```

## Downstream Rollout Options

1. Submodule + symlink + Dependabot:
   use `templates/downstream-submodule/` when downstream projects can keep this
   repo as a Git submodule under `.agents/vendor/openspec-review-skills`.
2. Scheduled copy-update PR:
   use `templates/downstream-copy-workflow/` when downstream projects prefer
   copied skill directories updated by a weekly PR.
3. User-scoped local install:
   copy selected skills into the personal skill directory used by your agent
   surface when project-scoped rollout is not appropriate.

Do not use Codex startup or resume `SessionStart` hooks to clone, fetch, copy,
delete, overwrite, or install these skills. Do not use hooks to keep
`.codex/skills` or `.agents/skills` silently current. Hooks may only be used for
read-only advisory checks. Skill updates should arrive through pull requests,
either by Dependabot submodule updates or scheduled copy-update PRs.

See [docs/compatibility.md](docs/compatibility.md) for current compatibility
notes and tradeoffs.

## Validation

```bash
python3 scripts/validate-skills.py
bash scripts/validate-install.sh
bash -n scripts/install-skills.sh
```

Regenerate release metadata after skill changes:

```bash
python3 scripts/validate-skills.py --write-manifest
```

## Release Safety

Before publishing, review [docs/public-safety.md](docs/public-safety.md) and run
your normal secret-scanning and repository review process outside this package.

## License

MIT. See [LICENSE](LICENSE).
