# Keeping duckplyr aligned with dplyr

How duckplyr follows dplyr: the checkouts the work needs, the scripts that regenerate everything taken from dplyr,
how manual edits survive that regeneration, how dplyr's own tests are carried over and skipped,
and how dplyr's reverse dependencies are checked against duckplyr.

**dplyr is upstream, and what is taken from it is regenerated rather than edited.**
Every file derived from dplyr's source or tests is rewritten from scratch by a script,
so a change made by hand survives only where the regeneration knows to replay it,
and a difference from dplyr is recorded where the next sync will see it.

**A sync is reviewed as a diff.**
The scripts write into the working tree and commit nothing in this repository,
so what dplyr changed reaches duckplyr as a diff that a maintainer reads, adjusts, and commits.

* [`patches/`](patches/): how manual edits to generated methods and vendored tests are kept across regeneration
* [`rigged-dplyr/`](rigged-dplyr/): the dplyr fork with duckplyr's methods injected, for checking dplyr's reverse dependencies
* [`setup/`](setup/): the helper clones and the tools a sync needs, set up once per checkout
* [`sync/`](sync/): running the sync pipeline, and reviewing what it changed
* [`vendored-tests/`](vendored-tests/): how dplyr's tests are copied into duckplyr's suite, and how one is skipped
