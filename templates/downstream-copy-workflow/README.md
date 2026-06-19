# Downstream Vendored Skill Rollout

Use this template for downstream repositories that should commit real managed
skill files directly under `.agents/skills`.

This is the standard repo-scoped rollout path. Do not use Git submodules,
symlinks, `.agents/vendor/openspec-review-skills`, `.codex/skills`, or
startup/bootstrap hooks for OpenSpec review skill distribution.

## Files

- `.github/workflows/update-openspec-review-skills.yml`: weekly and manual
  workflow that clones this repository, installs the managed skills into
  `.agents/skills`, and opens a pull request if files changed.
- `.github/workflows/validate-openspec-review-skills.yml`: validates the
  committed `.agents/skills` copies in pull requests and manual runs.
- `scripts/validate-openspec-review-skills.sh`: checks that managed skills are
  real files, not symlinks or submodule-backed entries.

The workflow does not run `--prune`, so unrelated local skills are not touched.

## Initial Vendoring

Copy this template's files into the downstream repository, then install the
current managed skills from this upstream package:

```bash
tmp_dir="$(mktemp -d)"
git clone --depth 1 https://github.com/mgarvey/openspec-review-skills "$tmp_dir/openspec-review-skills"
"$tmp_dir/openspec-review-skills/scripts/install-skills.sh" --codex-current
bash scripts/validate-openspec-review-skills.sh
```

Commit the resulting `.agents/skills` files, the validator script, and the
workflow files. Do not add a Git submodule and do not commit symlinks under
`.agents/skills`.

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
git add .agents/skills
```

Review refresh pull requests as prompt/instruction supply-chain updates, the
same way you would review code changes.
