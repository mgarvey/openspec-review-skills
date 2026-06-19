# Downstream Submodule Rollout

Use this template when a downstream project can keep
`mgarvey/openspec-review-skills` as a Git submodule and expose the skills with
symlinks under `.agents/skills`.

## Files

- `.github/dependabot.yml`: opens update PRs for the submodule.
- `.github/workflows/validate-openspec-review-skills.yml`: validates the
  submodule checkout and managed skill symlinks in pull requests.
- `scripts/bootstrap-openspec-review-skills.sh`: adds the submodule and creates
  symlinks for each skill.
- `scripts/validate-openspec-review-skills.sh`: validates that the submodule is
  initialized and `.agents/skills` points at the manifest-defined skills.

## Usage

Copy these files into the downstream repository, then run:

```bash
bash scripts/bootstrap-openspec-review-skills.sh
```

## Fresh Checkouts

A normal clone without recursive submodules leaves
`.agents/vendor/openspec-review-skills` uninitialized, which also leaves
`.agents/skills/*` symlinks dangling.

After cloning a downstream repository that uses this template, initialize the
submodule before using or validating the skills:

```bash
git submodule update --init --recursive
```

Then validate the wiring:

```bash
bash scripts/validate-openspec-review-skills.sh
```

The script refuses to overwrite unrelated local skill directories unless
`--force` is passed.

Dependabot submodule pull requests update prompt and instruction content. Review
them like code, not as routine metadata bumps.

`.codex/skills` is a legacy Codex target and should not contain duplicate
managed skills when `.agents/skills` is active.
