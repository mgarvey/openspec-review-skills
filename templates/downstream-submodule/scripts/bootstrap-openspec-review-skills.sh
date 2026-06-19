#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/mgarvey/openspec-review-skills.git"
vendor_dir=".agents/vendor/openspec-review-skills"
skills_dir=".agents/skills"
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

echo "OpenSpec review skills are linked under $skills_dir"
