# gh-fork-cleanup

Helper scripts to find and delete GitHub forks that never contributed anything
upstream. Handy when a personal account has accumulated hundreds of one-off
forks over the years.

`find-stale-forks.sh` analyses **every branch** of each fork and compares it
against the upstream parent (against the upstream branch of the same name when
one exists, otherwise the upstream default branch). It sorts each fork into one
of three buckets:

| Verdict    | Meaning                                                                                   | Output             |
|------------|-------------------------------------------------------------------------------------------|--------------------|
| **STALE**  | every branch is fully contained in upstream (`ahead_by == 0`) **and** you opened no PRs   | `stale-forks.txt`  |
| **KEEP**   | every branch is contained, but you authored pull request(s) upstream                      | (none)             |
| **REVIEW** | ≥1 branch has commit(s) not in upstream, or the fork is private / detached / errored      | `review-forks.txt` |

A branch with commits that are *not* present in upstream lands the fork in
**REVIEW** rather than STALE. The code on such a branch might still be in
upstream (e.g. it was squash-merged, so the commits differ), which the
commit-level comparison can't tell — so REVIEW is the "unsure" bucket. Point an
LLM (or your own eyes) at those repos before deciding.

## Requirements

* [`gh`](https://cli.github.com/), authenticated (`gh auth login`)
* `jq`
* `delete_repo` scope for the deletion step:
  `gh auth refresh -h github.com -s delete_repo`

## Usage

```bash
# 1. Analyse all forks. Verbose per-branch output goes to stderr; pass -q to
#    silence it. Produces stale-forks.txt, review-forks.txt and classified.tsv.
./find-stale-forks.sh

# 2. REVIEW the candidate list (and the unsure pile) before deleting anything.
cat stale-forks.txt
cat review-forks.txt

# 3. Delete everything in stale-forks.txt (irreversible).
./delete-stale-forks.sh
```

Set `USER=` at the top of `find-stale-forks.sh` to target a different account
(defaults to `krlmlr`). The `KEEP` allow-list protects repositories where you
are the package maintainer so they are never flagged.

## Output files

* `stale-forks.txt` — deletable forks, one `owner/repo` per line; the only input
  to `delete-stale-forks.sh`.
* `review-forks.txt` — the "unsure" pile; **never** auto-deleted.
* `classified.tsv` — full `verdict <TAB> repo <TAB> reason` table for every fork.

## Caveats

* Branch work that was **squash-merged** upstream shows up as unique commits, so
  the fork is flagged **REVIEW**, not STALE — by design.
* **Private** forks are routed to REVIEW for manual inspection rather than
  compared automatically.
* Forks with many branches mean many API calls; runs against an authenticated
  `gh` (5000 requests/hour) but a huge account may still want to throttle.
* Deletion is permanent. There is no undo.
