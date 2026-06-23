#!/usr/bin/env bash
# find-stale-forks.sh
#
# Classifies every (non-archived) fork on your account by analysing ALL of its
# branches against the upstream parent:
#
#   STALE   every branch was successfully compared AND is fully contained in
#           upstream (0 commits ahead) AND you opened no pull requests upstream.
#           Only this bucket is safe to delete.
#   KEEP    every branch is contained, but you DID open PR(s) upstream.
#   REVIEW  at least one branch has commit(s) not present in upstream, OR has an
#           unrelated history, OR the fork is private / detached, OR *anything
#           could not be determined* (branch list empty, compare errored). The
#           code might still be in upstream (e.g. squash-merged) -- so this is
#           the "unsure" bucket: point an LLM (or your eyes) at the repo.
#
# Each fork branch is compared against the upstream branch of the SAME name when
# one exists, otherwise against the upstream default branch. "ahead_by == 0"
# means every commit on that branch already exists in upstream.
#
# SAFETY: a fork is classified STALE only when *every* branch was compared
# without error and found contained. Any error/uncertainty -> REVIEW, never
# STALE, so an incomplete run can never feed a delete.
#
# Outputs (machine-readable, one "owner/repo" per line):
#   stale-forks.txt    -> fed to delete-stale-forks.sh
#   review-forks.txt   -> NEVER auto-deleted; inspect by hand / with an LLM
#   classified.tsv     -> full <verdict>\t<repo>\t<reason> table
#
# Verbose per-branch analysis is printed to stderr (on by default; -q silences).
#
# Requires: gh (authenticated), jq. Portable to bash 3.2 (macOS).
#
# Tuning via env:
#   JOBS=N      parallel forks (default 1 -- serial, to avoid GitHub's secondary
#               rate limit; raise cautiously, the retry/backoff below helps).
#   RETRIES=N   per-call retries on throttling (default 5).
set -uo pipefail

USER=krlmlr
VERBOSE=1
JOBS="${JOBS:-1}"
RETRIES="${RETRIES:-5}"
{ [ "${1:-}" = "-q" ] || [ "${1:-}" = "--quiet" ]; } && VERBOSE=0

# Never touch these: packages where you are the DESCRIPTION Maintainer.
KEEP='backends blob DBI DBItest dblog duckplyr here hms jointprof LoadMyData
pillar profile RKazam RMariaDB roxygen2md RSQLite tibble tic tkigraph travis'

# gh api with retry + exponential backoff on rate/secondary limits.
# Prints body to stdout. Returns: 0 ok, 1 non-throttle HTTP error (body is the
# error JSON), 2 throttled past RETRIES.
ghapi() {
  local out err rc attempt=0 delay=3
  err="$(mktemp)"
  while :; do
    out="$(gh api "$@" 2>"$err")"; rc=$?
    if [ "$rc" -eq 0 ]; then rm -f "$err"; printf '%s' "$out"; return 0; fi
    if grep -qiE 'rate limit|secondary rate|abuse detection|retry-after|HTTP 403|HTTP 429' "$err"; then
      attempt=$((attempt + 1))
      if [ "$attempt" -gt "$RETRIES" ]; then rm -f "$err"; return 2; fi
      sleep "$delay"; delay=$((delay * 2)); continue
    fi
    rm -f "$err"; printf '%s' "$out"; return 1   # genuine 404 etc.; body returned
  done
}

# Percent-encode the characters that break a compare ref in the URL path.
urlenc() { printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/#/%23/g' -e 's/ /%20/g' -e 's/?/%3F/g'; }

check() {
  local repo="$1" full meta priv parent base uptmp fbtmp b cmpbase resp ahead behind msg
  local unique=0 errors=0 nbranch=0 details=""
  full="$USER/$repo"
  v() { [ "${VERBOSE:-1}" = 1 ] && printf '[%s] %s\n' "$repo" "$*" >&2; }

  meta="$(ghapi "repos/$full" --jq '[.private, (.parent.full_name // ""), (.parent.default_branch // "")] | @tsv')" \
    || { v "metadata fetch failed -> REVIEW"; printf 'REVIEW\t%s\tmetadata-error\n' "$full"; return; }
  IFS=$'\t' read -r priv parent base <<<"$meta"

  if [ -z "$parent" ]; then v "no upstream parent (detached) -> REVIEW"; printf 'REVIEW\t%s\tno-parent\n' "$full"; return; fi
  if [ "$priv" = "true" ]; then v "private repo -> REVIEW (inspect manually)"; printf 'REVIEW\t%s\tprivate\n' "$full"; return; fi

  uptmp="$(mktemp)"; fbtmp="$(mktemp)"
  ghapi "repos/$parent/branches" --paginate --jq '.[].name' >"$uptmp" 2>/dev/null
  if ! ghapi "repos/$full/branches" --paginate --jq '.[].name' >"$fbtmp" 2>/dev/null; then
    v "could not list fork branches -> REVIEW"; rm -f "$uptmp" "$fbtmp"
    printf 'REVIEW\t%s\tbranch-list-error\n' "$full"; return
  fi

  v "upstream=$parent default=$base"
  while IFS= read -r b || [ -n "$b" ]; do
    [ -z "$b" ] && continue
    nbranch=$((nbranch + 1))
    if grep -qxF -- "$b" "$uptmp"; then cmpbase="$b"; else cmpbase="$base"; fi
    resp="$(ghapi "repos/$parent/compare/$(urlenc "$cmpbase")...$USER:$(urlenc "$b")")"
    ahead="$(printf '%s' "$resp" | jq -r 'if type=="object" then (.ahead_by // empty) else empty end' 2>/dev/null)"
    behind="$(printf '%s' "$resp" | jq -r 'if type=="object" then (.behind_by // empty) else empty end' 2>/dev/null)"
    if [ "$ahead" = "0" ]; then
      v "  branch '$b'  vs $parent:$cmpbase  -> contained (behind ${behind:-?})"
    elif printf '%s' "$resp" | grep -q 'No common ancestor'; then
      v "  branch '$b'  vs $parent:$cmpbase  -> UNRELATED history [review]"
      unique=$((unique + 1)); details="$details $b(unrelated)"
    elif [ -n "$ahead" ]; then
      v "  branch '$b'  vs $parent:$cmpbase  -> $ahead commit(s) NOT in upstream [review]"
      unique=$((unique + 1)); details="$details $b(+$ahead)"
    else
      msg="$(printf '%s' "$resp" | jq -r '.message? // "compare-failed"' 2>/dev/null | head -1)"
      v "  branch '$b'  vs $parent:$cmpbase  -> COMPARE ERROR: ${msg:-unknown} [review]"
      errors=$((errors + 1)); details="$details $b(err)"
    fi
  done <"$fbtmp"
  rm -f "$uptmp" "$fbtmp"

  local prs
  prs="$(gh pr list --repo "$parent" --author "$USER" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"

  details="$(echo "$details" | tr -s ' ' ',' | sed 's/^,//')"

  if [ "$nbranch" -eq 0 ]; then
    v "VERDICT: REVIEW  (no branches enumerated -- cannot conclude)"
    printf 'REVIEW\t%s\tno-branches-enumerated\n' "$full"
  elif [ "$errors" -gt 0 ] || ! [ "$prs" -ge 0 ] 2>/dev/null; then
    v "VERDICT: REVIEW  (incomplete: $errors/$nbranch compare error(s), $unique unique, prs=$prs)"
    printf 'REVIEW\t%s\tincomplete:%s\n' "$full" "$details"
  elif [ "$unique" -gt 0 ]; then
    v "VERDICT: REVIEW  ($unique/$nbranch branch(es) with unique commits: $details )"
    printf 'REVIEW\t%s\tunique:%s\n' "$full" "$details"
  elif [ "$prs" != "0" ]; then
    v "VERDICT: KEEP  (all $nbranch branch(es) contained, but $prs PR(s) authored upstream)"
    printf 'KEEP\t%s\t%s-prs\n' "$full" "$prs"
  else
    v "VERDICT: STALE  (all $nbranch branch(es) contained, no PRs)"
    printf 'STALE\t%s\t%s-branches\n' "$full" "$nbranch"
  fi
}
export -f check ghapi urlenc
export USER VERBOSE RETRIES

# Loop-free fan-out: gh lists the forks, grep drops the keepers, xargs runs the
# per-fork analysis. Default JOBS=1 (serial) to stay under the secondary limit.
gh repo list "$USER" --fork --no-archived --limit 1000 --json name --jq '.[].name' \
  | grep -vxF -f <(printf '%s\n' $KEEP) \
  | xargs -P "$JOBS" -I{} bash -c 'check "$@"' _ {} \
  | sort -u > classified.tsv

grep '^STALE'  classified.tsv | cut -f2 > stale-forks.txt
grep '^REVIEW' classified.tsv | cut -f2 > review-forks.txt

printf '\n=== summary ===\n' >&2
printf 'STALE  (deletable): %s -> stale-forks.txt\n'  "$(grep -c '^STALE'  classified.tsv)" >&2
printf 'REVIEW (unsure)   : %s -> review-forks.txt\n' "$(grep -c '^REVIEW' classified.tsv)" >&2
printf 'KEEP   (has PRs)  : %s\n'                      "$(grep -c '^KEEP'   classified.tsv)" >&2
