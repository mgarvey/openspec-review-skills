#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/mgarvey/openspec-review-skills.git"
vendor_dir=".agents/vendor/openspec-review-skills"
skills_dir=".agents/skills"
skills_readme="$skills_dir/README.md"
skills_readme_marker="Managed by mgarvey/openspec-review-skills downstream-submodule bootstrap."
force=0
dry_run=0

usage() {
  cat <<'EOF'
Usage: bootstrap-openspec-review-skills.sh [options]

Options:
  --force    Replace unrelated local skill directories or links.
  --dry-run  Print actions without changing files.
  -h, --help Show this help.
EOF
}

run() {
  echo "+ $*"
  if [ "$dry_run" -eq 0 ]; then
    "$@"
  fi
}

ensure_skills_readme_writable() {
  if [ -e "$skills_readme" ] && ! grep -Fq "$skills_readme_marker" "$skills_readme"; then
    if [ "$force" -ne 1 ]; then
      echo "error: refusing to overwrite unrelated $skills_readme; pass --force to replace it" >&2
      exit 1
    fi
  fi
}

write_skills_readme() {
  ensure_skills_readme_writable
  echo "+ write $skills_readme"
  if [ "$dry_run" -ne 0 ]; then
    return
  fi

  cat > "$skills_readme" <<'EOF'
# Managed OpenSpec Review Skills

<!-- Managed by mgarvey/openspec-review-skills downstream-submodule bootstrap. -->

The review skills in this directory are symlinked from
`.agents/vendor/openspec-review-skills`.

The public `mgarvey/openspec-review-skills` repository is the source of truth
for these managed skills. Do not edit symlinked skill files locally; update
`mgarvey/openspec-review-skills` instead.

## Fresh Checkout

A normal clone without recursive submodules leaves
`.agents/vendor/openspec-review-skills` uninitialized, which also leaves the
managed skill symlinks unresolved.

Initialize the submodule before using or validating the skills:

```bash
git submodule update --init --recursive
```

Then validate the managed skill wiring:

```bash
bash scripts/validate-openspec-review-skills.sh
```

## Maintenance

Do not edit symlinked skill files in this repo. Update
`mgarvey/openspec-review-skills` instead, then update this submodule pointer.

Dependabot opens pull requests when the submodule can be updated. Treat those
pull requests as prompt/instruction supply-chain updates and review them as
code, not as routine metadata bumps.

`.codex/skills` is legacy and should not contain duplicate managed review
skills.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=1
      ;;
    --dry-run)
      dry_run=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      exit 64
      ;;
  esac
  shift
done

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ]; then
  echo "error: run this script inside a Git repository" >&2
  exit 64
fi
cd "$repo_root"
ensure_skills_readme_writable

if [ -e "$vendor_dir" ]; then
  if [ -d "$vendor_dir/.git" ] || git config --file .gitmodules --get-regexp "submodule\\..*\\.path" 2>/dev/null | grep -Fq "$vendor_dir"; then
    run git submodule update --init -- "$vendor_dir"
  else
    echo "error: $vendor_dir exists and is not this submodule" >&2
    exit 1
  fi
else
  run git submodule add "$repo_url" "$vendor_dir"
fi

run mkdir -p "$skills_dir"

for skill in "$vendor_dir"/skills/*; do
  [ -d "$skill" ] || continue
  [ -f "$skill/SKILL.md" ] || continue
  name="$(basename "$skill")"
  dest="$skills_dir/$name"
  rel_target="../vendor/openspec-review-skills/skills/$name"

  if [ -L "$dest" ]; then
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$rel_target" ]; then
      echo "skip $dest (already linked)"
    elif [ "$force" -eq 1 ]; then
      run rm -f "$dest"
      run ln -s "$rel_target" "$dest"
    else
      echo "error: $dest is a symlink to $current_target; pass --force to replace it" >&2
      exit 1
    fi
  elif [ -e "$dest" ]; then
    if [ "$force" -eq 1 ]; then
      run rm -rf "$dest"
      run ln -s "$rel_target" "$dest"
    else
      echo "error: refusing to overwrite unrelated local skill: $dest" >&2
      exit 1
    fi
  else
    run ln -s "$rel_target" "$dest"
  fi

  legacy=".codex/skills/$name"
  if [ -e "$legacy" ]; then
    echo "warning: legacy copy exists at $legacy; remove it after verifying .agents/skills is active" >&2
  fi
done

write_skills_readme

echo "OpenSpec review skills are linked under $skills_dir"
