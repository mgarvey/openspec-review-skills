# Read-only Discovery

Use repository-provided wrappers and local instructions first. These commands
are optional starting points when shell access is available and the repository
does not provide a clearer review command.

## Common Commands

```bash
git status --short
git branch --show-current
git log --oneline --decorate -n 20
git diff --stat main...HEAD
git diff --name-only main...HEAD
git diff main...HEAD
find . -name AGENTS.md -o -name CLAUDE.md -o -name README.md -o -name CONTRIBUTING.md
```

If the default branch is not `main`, infer it with Git where possible and
substitute that branch in the diff commands.

```bash
git symbolic-ref --quiet --short refs/remotes/origin/HEAD
```

## Boundaries

- Prefer repo-provided wrappers over invented commands.
- Do not run destructive commands.
- Do not run deployment, migration, archive, delete, or cleanup commands during
  review.
- Keep command output tied to the review target and requested decision.
