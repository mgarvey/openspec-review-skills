# Downstream Copy Workflow

Use this template when a downstream project wants copied skill directories under
`.agents/skills` and update PRs instead of a Git submodule.

## Files

- `.github/workflows/update-openspec-review-skills.yml`: weekly and manual
  workflow that clones this repository, installs the managed skills into
  `.agents/skills`, and opens a pull request if files changed.

The workflow does not run `--prune`, so unrelated local skills are not touched.
