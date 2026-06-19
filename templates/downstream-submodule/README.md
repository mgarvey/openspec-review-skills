# Downstream Submodule Rollout

Use this template when a downstream project can keep
`mgarvey/openspec-review-skills` as a Git submodule and expose the skills with
symlinks under `.agents/skills`.

## Files

- `.github/dependabot.yml`: opens update PRs for the submodule.
- `scripts/bootstrap-openspec-review-skills.sh`: adds the submodule and creates
  symlinks for each skill.

## Usage

Copy these files into the downstream repository, then run:

```bash
bash scripts/bootstrap-openspec-review-skills.sh
```

The script refuses to overwrite unrelated local skill directories unless
`--force` is passed.
