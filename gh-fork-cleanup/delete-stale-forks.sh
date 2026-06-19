#!/usr/bin/env bash
# delete-stale-forks.sh
# Stupid + loop-free: deletes every repo listed in stale-forks.txt.
#
#   1. Run ./find-stale-forks.sh first.
#   2. REVIEW stale-forks.txt by hand.
#   3. Make sure gh has the delete scope:  gh auth refresh -h github.com -s delete_repo
#   4. Run this.
set -euo pipefail
xargs -r -I{} gh repo delete {} --yes < stale-forks.txt
