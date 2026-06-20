# Downstream Vendored Skill Rollout

Use this template for downstream repositories that should commit real managed
skill files directly under `.agents/skills`.

This is the standard repo-scoped rollout path. Do not use Git submodules,
symlinks, `.agents/vendor/openspec-review-skills`, `.codex/skills`, or
startup/bootstrap hooks for OpenSpec review skill distribution.

## Files

- `.github/workflows/update-openspec-review-skills.yml`: weekly and manual
  workflow that clones this repository, installs the managed skills into
  `.agents/skills`, refreshes the managed `.agents/docs/read-only-discovery.md`
  support doc, and opens a pull request if files changed.
- `.github/workflows/validate-openspec-review-skills.yml`: validates the
  committed `.agents/skills` copies in pull requests and manual runs.
- `scripts/validate-openspec-review-skills.sh`: checks that managed skills and
  the read-only discovery support doc are real files, not symlinks or
  submodule-backed entries.

The workflow does not run `--prune`, so unrelated local skills are not touched.

## Initial Vendoring

Copy this template's files into the downstream repository, then install the
current managed skills from this upstream package. If `ensure-openspec-repo` is
on your `PATH`, use:

```bash
ensure-openspec-repo --apply
```

Otherwise run the installer directly:

```bash
tmp_dir="$(mktemp -d)"
git clone --depth 1 https://github.com/mgarvey/openspec-review-skills "$tmp_dir/openspec-review-skills"
"$tmp_dir/openspec-review-skills/scripts/install-skills.sh" --codex-current
bash scripts/validate-openspec-review-skills.sh
```

Commit the resulting `.agents/skills` files,
`.agents/docs/read-only-discovery.md`, the validator script, and the workflow
files. Do not add a Git submodule and do not commit symlinks under
`.agents/skills` or `.agents/docs`.

## Refreshing Vendored Skills

Use the scheduled/manual `Update OpenSpec Review Skills` workflow to refresh the
committed `.agents/skills` copies by pull request.

For a local refresh, run the same install command from the downstream repository
root:

```bash
tmp_dir="$(mktemp -d)"
git clone --depth 1 https://github.com/mgarvey/openspec-review-skills "$tmp_dir/openspec-review-skills"
"$tmp_dir/openspec-review-skills/scripts/install-skills.sh" --codex-current
bash scripts/validate-openspec-review-skills.sh
git add .agents/skills .agents/docs/read-only-discovery.md
```

Review refresh pull requests as prompt/instruction supply-chain updates, the
same way you would review code changes.

## Repairing Existing Repos

From inside a downstream Git repo, run:

```bash
ensure-openspec-repo --check
ensure-openspec-repo --print-plan
ensure-openspec-repo --apply
```

The bootstrapper refuses to overwrite unknown files. It only removes known
managed legacy rollout paths, including the old
`.agents/vendor/openspec-review-skills` checkout, old managed symlinks under
`.agents/skills`, the matching old `.gitmodules` submodule section, and managed
duplicate `.codex/skills` review-skill copies.
