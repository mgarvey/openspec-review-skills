# Deprecated Downstream Submodule Rollout

Do not use this rollout pattern.

The OpenSpec review skills downstream standard is now vendored real files
committed directly under `.agents/skills`. Git submodules under
`.agents/vendor/openspec-review-skills` and symlinks under `.agents/skills` are
retired because they break fresh clones and new Git worktrees when the submodule
is not initialized.

Use `../downstream-copy-workflow/` instead.

This directory intentionally no longer contains a submodule bootstrap script,
submodule Dependabot config, or submodule/symlink validator.

Downstream repositories should not use:

- Git submodules for this package.
- Symlinked `.agents/skills` entries.
- `.codex/skills` duplicates.
- Startup/bootstrap hooks that install or refresh skills.
