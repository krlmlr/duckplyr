# The duckplyr handbook

The single source of truth for everything this repository documents;
internal pages like this one navigate and state their area's principles,
leaves explain ([`meta/handbook/`](/handbook/meta/handbook/README.md)).

duckplyr is a long-running fork of dplyr's `data.frame` methods, executed by DuckDB where it can and by dplyr where it cannot.
The areas divide by what a question is about, not by who is asking it.
A maintainer pulling dplyr's latest changes in and a contributor adding the translation of one function
are served by the same tree, and the same question brings both to the same leaf.
An audience split would need the same fact in two places, and the tree holds every fact once.
What stays outside the tree, intent and evidence, and where each lives, is [`meta/local/`](/handbook/meta/local/README.md)'s.

* [`benchmarks/`](benchmarks/): the TPC-H queries and the benchmark scripts around them, and where their results land
* [`ci/`](ci/): what the GitHub Actions workflows check, and on which events
* [`dependencies/`](dependencies/): the dplyr and duckdb versions duckplyr supports, and how it moves to a new one
* [`dplyr-alignment/`](dplyr-alignment/): keeping duckplyr aligned with dplyr,
  from the helper clones through the sync pipeline, the patches that keep manual edits, and the vendored dplyr tests,
  to the rigged dplyr for reverse-dependency checks
* [`layout/`](layout/): what each top-level directory holds, and which files are generated and by what
* [`meta/`](meta/): the rules of this tree, its forms and growth moves, how prose is written here, the vocabulary,
  the evidence convention, and what this repository decides for itself
* [`releases/`](releases/): cutting a patch release from an earlier release tag, as done for 1.2.2
* [`testing/`](testing/): how the test suite is laid out, how to run it, and the environment variables that shape it
* [`translations/`](translations/): how R functions inside verbs are translated to DuckDB, and how a new one is added
* [`verbs/`](verbs/): how a dplyr verb is implemented, falls back, and gains support for more of its arguments

Everything this repository documents is reachable by walking down from this page:
internal nodes navigate, leaves explain, and every fact has exactly one leaf that owns it,
including the limits, the declined requests, and the reasons.
Start at the root and follow the scope sentences; searching the tree is the slower path.
