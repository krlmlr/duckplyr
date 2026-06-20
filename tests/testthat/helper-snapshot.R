# Snapshot transform that scrubs volatile hash values from snapshots.
#
# vctrs abbreviates factor types as `factor<xxxxx>`, where `xxxxx` is the
# first few characters of `rlang::hash()` of the factor levels. The hash
# algorithm is an implementation detail of rlang and changes between releases
# (e.g. the development version of rlang uses a different walking strategy and
# therefore produces different hashes). Scrubbing the hash keeps these
# snapshots stable across rlang versions while still capturing the structure
# of the message.
scrub_hash <- function(x) {
  gsub("factor<[0-9a-f]+>", "factor<...>", x)
}
