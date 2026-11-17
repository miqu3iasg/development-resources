#!/usr/bin/env bash
# bootstrap: creates and verifies the ~/dev workspace.
# arcanum/ is out of scope: it has its own versioning.
#
#   bootstrap.sh apply [--dry-run]   create missing dirs, seed missing files
#   bootstrap.sh check               verify layout; exit 1 if anything is missing
#   bootstrap.sh sync                copy live READMEs from ~/dev back into skeleton/
#
# Idempotent: never overwrites, never deletes. Content lives as real files in
# ./skeleton (mirroring ~/dev); this script only distributes it. After the
# first apply the READMEs in ~/dev are the working copies: run `sync` and
# commit to keep this repo a valid fresh-machine fallback.
set -euo pipefail

DEV_ROOT="${DEV_ROOT:-$HOME/dev}"
SKELETON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skeleton"

# Layout contract: skeleton/README.md ("Layout") and each domain README.
DIRS=(
  repos/{personal,lab,studies,university,work}
  repos/studies/{templates,materials,attachments}
  repos/university/{attachments,materials/templates}
  resources/{licenses,templates,config/gitignore}
  scripts/{development,skills}
  work/{cv,applications,certificates,documents}
)

dry=0
log() { printf '%-9s %s\n' "$1" "$2"; }
skeleton_files() { find "$SKELETON" -type f -print0 | sort -z; }

apply() {
  local d f rel dest
  for d in "${DIRS[@]}"; do
    [[ -d $DEV_ROOT/$d ]] && continue
    log mkdir "$d"
    (( dry )) || mkdir -p "$DEV_ROOT/$d"
  done

  if [[ -d $SKELETON ]]; then
    while IFS= read -r -d '' f; do
      rel=${f#"$SKELETON"/}
      dest=$DEV_ROOT/$rel
      [[ -e $dest ]] && continue
      log seed "$rel"
      if (( ! dry )); then
        mkdir -p "$(dirname "$dest")"
        cp "$f" "$dest"
      fi
    done < <(skeleton_files)
  else
    echo "note: no skeleton/ next to the script; directories only" >&2
  fi

  # repos/lab is a single git repository for all experiments (dev README).
  if [[ ! -d $DEV_ROOT/repos/lab/.git ]]; then
    if command -v git >/dev/null; then
      log git-init repos/lab
      (( dry )) || git init -q "$DEV_ROOT/repos/lab"
    else
      echo "note: git not found; repos/lab not initialised" >&2
    fi
  fi
}

check() {
  local d f rel bad=0
  for d in "${DIRS[@]}"; do
    [[ -d $DEV_ROOT/$d ]] || { log missing "$d/"; bad=1; }
  done
  [[ -d $DEV_ROOT/repos/lab/.git ]] || { log missing "repos/lab/.git"; bad=1; }
  while IFS= read -r -d '' f; do
    rel=${f#"$SKELETON"/}
    if [[ ! -e $DEV_ROOT/$rel ]]; then
      log missing "$rel"; bad=1
    elif ! cmp -s "$f" "$DEV_ROOT/$rel"; then
      log changed "$rel (live differs from skeleton; run sync)"
    fi
  done < <(skeleton_files)
  (( bad == 0 )) && echo ok || return 1
}

sync() {
  local f rel
  while IFS= read -r -d '' f; do
    rel=${f#"$SKELETON"/}
    [[ -e $DEV_ROOT/$rel ]] || continue
    cmp -s "$f" "$DEV_ROOT/$rel" && continue
    log sync "$rel"
    cp "$DEV_ROOT/$rel" "$f"
  done < <(skeleton_files)
}

case "${1:-}" in
  apply) [[ ${2:-} == --dry-run ]] && dry=1; apply ;;
  check) check ;;
  sync)  sync ;;
  *)     sed -n '2,8p' "$0"; exit 2 ;;
esac
