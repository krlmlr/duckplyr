#!/usr/bin/env bash
# find-stale-forks.sh
#
# Classifies every (non-archived) fork on your account by analysing ALL of its
# branches against the upstream parent:
#
#   STALE   every branch is fully contained in upstream (0 commits ahead) AND
#           you opened no pull requests upstream  -> safe to delete.
#   KEEP    every branch is contained, but you DID open PR(s) upstream.
#   REVIEW  at least one branch has commit(s) not present in upstream, OR the
#           fork is private / detached / errored. The code *might* still be in
#           upstream (e.g. squash-merged), so this is the "unsure" bucket --
#           point an LLM (or your eyes) at the repo before deciding.
#
# Each fork branch is compared against the upstream branch of the SAME name when
# one exists, otherwise against the upstream default branch. "ahead_by == 0"
# means every commit on that branch already exists in upstream.
#
# Outputs (machine-readable, one "owner/repo" per line):
#   stale-forks.txt    -> fed to delete-stale-forks.sh
#   review-forks.txt   -> NEVER auto-deleted; inspect by hand / with an LLM
#   classified.tsv     -> full <verdict>\t<repo>\t<reason> table
#
# Verbose per-branch analysis is printed to stderr (on by default; -q silences).
#
# Requires: gh (authenticated), jq. Portable to bash 3.2 (macOS).
set -uo pipefail

USER=krlmlr
VERBOSE=1
{ [ "${1:-}" = "-q" ] || [ "${1:-}" = "--quiet" ]; } && VERBOSE=0

# Never touch these: packages where you are the DESCRIPTION Maintainer.
KEEP='backends blob DBI DBItest dblog duckplyr here hms jointprof LoadMyData
pillar profile RKazam RMariaDB roxygen2md RSQLite tibble tic tkigraph travis'

check() {
  local repo="$1" full meta priv parent base uptmp b cmpbase ahead behind status
  local unique=0 nbranch=0 details="" prs
  full="$USER/$repo"
  v() { [ "${VERBOSE:-1}" = 1 ] && printf '[%s] %s\n' "$repo" "$*" >&2; }

  meta=$(gh api "repos/$full" --jq '[.private, (.parent.full_name // ""), (.parent.default_branch // "")] | @tsv' 2>/dev/null) \
    || { v "metadata fetch failed -> REVIEW"; printf 'REVIEW\t%s\tmetadata-error\n' "$full"; return; }
  IFS=$'\t' read -r priv parent base <<<"$meta"

  if [ -z "$parent" ]; then v "no upstream parent (detached) -> REVIEW"; printf 'REVIEW\t%s\tno-parent\n' "$full"; return; fi
  if [ "$priv" = "true" ]; then v "private repo -> REVIEW (inspect manually)"; printf 'REVIEW\t%s\tprivate\n' "$full"; return; fi

  uptmp=$(mktemp)
  gh api "repos/$parent/branches" --paginate --jq '.[].name' >"$uptmp" 2>/dev/null

  v "upstream=$parent default=$base"
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    nbranch=$((nbranch + 1))
    if grep -qxF -- "$b" "$uptmp"; then cmpbase="$b"; else cmpbase="$base"; fi
    IFS=$'\t' read -r ahead behind status < <(
      gh api "repos/$parent/compare/$cmpbase...$USER:$b" --jq '[.ahead_by, .behind_by, .status] | @tsv' 2>/dev/null \
      || printf '?\t?\terror\n'
    )
    if [ "$ahead" = "0" ]; then
      v "  branch '$b'  vs $parent:$cmpbase  -> contained (behind ${behind:-?})"
    elif [ "$ahead" = "?" ] || [ -z "$ahead" ]; then
      v "  branch '$b'  vs $parent:$cmpbase  -> COMPARE FAILED [review]"
      unique=$((unique + 1)); details="$details $b(?)"
    else
      v "  branch '$b'  vs $parent:$cmpbase  -> $ahead commit(s) NOT in upstream [review]"
      unique=$((unique + 1)); details="$details $b(+$ahead)"
    fi
  done < <(gh api "repos/$full/branches" --paginate --jq '.[].name' 2>/dev/null)
  rm -f "$uptmp"

  prs=$(gh pr list --repo "$parent" --author "$USER" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo 0)

  if [ "$unique" -gt 0 ]; then
    v "VERDICT: REVIEW  ($unique/$nbranch branch(es) with unique commits:$details )"
    printf 'REVIEW\t%s\tunique:%s\n' "$full" "$(echo "$details" | tr -s ' ' ',' | sed 's/^,//')"
  elif [ "$prs" != "0" ]; then
    v "VERDICT: KEEP  (all $nbranch branch(es) contained, but $prs PR(s) authored upstream)"
    printf 'KEEP\t%s\t%s-prs\n' "$full" "$prs"
  else
    v "VERDICT: STALE  (all $nbranch branch(es) contained, no PRs)"
    printf 'STALE\t%s\t%s-branches\n' "$full" "$nbranch"
  fi
}
export -f check
export USER VERBOSE

# Loop-free fan-out: gh lists the forks, grep drops the keepers, xargs runs the
# per-fork analysis across workers. Verdicts -> classified.tsv.
gh repo list "$USER" --fork --no-archived --limit 1000 --json name --jq '.[].name' \
  | grep -vxF -f <(printf '%s\n' $KEEP) \
  | xargs -P 6 -I{} bash -c 'check "$@"' _ {} \
  | sort -u > classified.tsv

grep '^STALE'  classified.tsv | cut -f2 > stale-forks.txt
grep '^REVIEW' classified.tsv | cut -f2 > review-forks.txt

printf '\n=== summary ===\n' >&2
printf 'STALE  (deletable): %s -> stale-forks.txt\n'  "$(grep -c '^STALE'  classified.tsv)" >&2
printf 'REVIEW (unsure)   : %s -> review-forks.txt\n' "$(grep -c '^REVIEW' classified.tsv)" >&2
printf 'KEEP   (has PRs)  : %s\n'                      "$(grep -c '^KEEP'   classified.tsv)" >&2
