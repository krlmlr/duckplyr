#!/usr/bin/env bash
# find-stale-forks.sh
# Lists your forks that contribute NOTHING upstream:
#   * their default branch is NOT ahead of the parent (ahead_by == 0), AND
#   * you have opened NO pull requests in the parent repo.
# Output: one "krlmlr/<repo>" per line, on stdout and into stale-forks.txt
#
# Requires: gh (authenticated), jq
# Caveat: only the DEFAULT branch is compared. A fork that carries work on a
#         non-default branch (but never PR'd it) is treated as "stale". Eyeball
#         stale-forks.txt before deleting.
set -euo pipefail

USER=krlmlr

# Never touch these: packages where you are the DESCRIPTION Maintainer.
KEEP='backends blob DBI DBItest dblog duckplyr here hms jointprof LoadMyData
pillar profile RKazam RMariaDB roxygen2md RSQLite tibble tic tkigraph travis'

check() {
  local repo="$1" full parent base head ahead prs
  full="krlmlr/$repo"
  read -r parent base head < <(
    gh api "repos/$full" --jq '[.parent.full_name, .parent.default_branch, .default_branch] | @tsv'
  ) || return 0
  [ -z "$parent" ] && return 0                                  # not a fork
  ahead=$(gh api "repos/$parent/compare/$base...krlmlr:$head" --jq '.ahead_by' 2>/dev/null || echo '?')
  prs=$(gh pr list --repo "$parent" --author "$USER" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo 0)
  [ "$ahead" = "0" ] && [ "$prs" = "0" ] && echo "$full"
}
export -f check
export USER

# Loop-free pipeline: gh enumerates the forks, grep drops the keepers,
# xargs fans the per-fork check out across 8 workers.
gh repo list "$USER" --fork --no-archived --limit 1000 --json name --jq '.[].name' \
  | grep -vxF -f <(printf '%s\n' $KEEP) \
  | xargs -P 8 -I{} bash -c 'check "$@"' _ {} \
  | sort | tee stale-forks.txt
