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
.codex-plugin/
```

`skills/` is the canonical source. Do not check copied activation mirrors such
as `.agents/skills` or `.codex/skills` into this public repository.

## Install

### Codex Plugin

For personal or cross-repository Codex use, install this repository as a Codex
plugin. The plugin manifest is `.codex-plugin/plugin.json`, and it exposes the
canonical `skills/` directory directly. Install it once from a personal or team
marketplace rather than copying the skills into every repository.

This repository also includes a local marketplace catalog at
`.agents/plugins/marketplace.json`. To test or install this local checkout:

```bash
codex plugin marketplace add /path/to/openspec-review-skills
codex plugin add openspec-review-skills@openspec-review-skills
```

Start a new Codex thread after installation so the skill list is refreshed.

Use this plugin path when the goal is:

- the skills are available in new Codex threads;
- the skills are available in any repository you open;
- no application repository needs committed `.agents/skills` or `.codex/skills`
  copies;
- no startup/bootstrap hook is needed to copy files.

### Repo-local Copy

Use repo-local copying only when a downstream repository intentionally needs to
carry its own managed skill files for all contributors. Current Codex project
activation uses `.agents/skills`:

```bash
./scripts/install-skills.sh --codex-current
```

Alias targets such as `--codex-current`, `--codex-legacy`, and `--claude` are
resolved relative to the current working directory. Run the installer from the
project that should receive the skills, or pass an explicit target path.

`.codex/skills` is a legacy Codex target. It is not part of the downstream
rollout standard for this package; downstream repositories should use
`.agents/skills` only. The installer retains `--codex-legacy` only for older
local migrations.

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

1. Vendored repo-local skill files:
   use `templates/downstream-copy-workflow/` when downstream projects should
   commit managed copies directly under `.agents/skills`. This is the standard
   rollout path for repo-scoped Codex skills.
2. User-scoped local install:
   copy selected skills into the personal skill directory used by your agent
   surface when project-scoped rollout is not appropriate.

For personal cross-repository availability, prefer the Codex plugin package over
repo-local copies.

Downstream repositories should not use Git submodules, symlinks, `.codex/skills`,
or startup/bootstrap hooks for this package. Fresh clones and new Git worktrees
must work without `git submodule update`.

Do not use Codex startup or resume `SessionStart` hooks to clone, fetch, copy,
delete, overwrite, or install these skills. Do not use hooks to keep
`.agents/skills` silently current. Hooks may only be used for read-only advisory
checks. Skill updates should arrive through pull requests that update the
vendored files.

## Repo Bootstrapper

Starting with `v0.2.0`, `scripts/ensure-openspec-repo` is the supported safe
repo bootstrapper for downstream Git repositories. Put this repository's
`scripts/` directory on your `PATH`, or run it by absolute path from inside the
target repo:

```bash
ensure-openspec-repo --check
ensure-openspec-repo --print-plan
ensure-openspec-repo --apply
```

The command refuses to run outside a Git worktree, and refuses to run outside
`~/Code` unless `--force` is passed. `--apply` initializes OpenSpec when
`openspec/` is missing, installs committed real files under `.agents/skills`,
installs the downstream validator, writes managed `.agents/skills/README.md` and
`.agents/skills/UPSTREAM.md`, installs the managed
`.agents/docs/read-only-discovery.md` support doc, removes only known managed
legacy rollout paths, cleans the matching legacy `.gitmodules` submodule
section, and then runs validation.

Do not use `ensure-openspec-repo` to make these skills available everywhere in
your personal Codex environment. Use the plugin package for that.

See [docs/compatibility.md](docs/compatibility.md) for current compatibility
notes and tradeoffs.

## Validation

```bash
python3 scripts/validate-skills.py
python3 scripts/validate-plugin.py
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
bash scripts/validate-install.sh
bash -n scripts/install-skills.sh
bash -n scripts/ensure-openspec-repo
bash -n templates/downstream-copy-workflow/scripts/validate-openspec-review-skills.sh
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
