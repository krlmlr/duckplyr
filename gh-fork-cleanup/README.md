# gh-fork-cleanup

Helper scripts to find and delete GitHub forks that never contributed anything
upstream. Handy when a personal account has accumulated hundreds of one-off
forks over the years.

A fork is considered **stale** (contributes nothing) when **both** hold:

* its default branch is **not ahead** of the parent (`ahead_by == 0`), and
* you have opened **no pull requests** in the parent repository.

## Requirements

* [`gh`](https://cli.github.com/), authenticated (`gh auth login`)
* `jq`
* `delete_repo` scope for the deletion step:
  `gh auth refresh -h github.com -s delete_repo`

## Usage

```bash
# 1. Produce the candidate list -> stale-forks.txt
./find-stale-forks.sh

# 2. REVIEW the list by hand before deleting anything.
cat stale-forks.txt

# 3. Delete everything in the list (irreversible).
./delete-stale-forks.sh
```

Set `USER=` at the top of `find-stale-forks.sh` to target a different account
(defaults to `krlmlr`). The `KEEP` allow-list protects repositories where you
are the package maintainer so they are never flagged.

## Caveats

* Only the **default branch** is compared against the parent. A fork that
  carries work on a non-default branch but never opened a PR for it is reported
  as stale — review the list before deleting.
* **Private** forks are intentionally excluded from the automated comparison;
  audit those manually.
* Deletion is permanent. There is no undo.
