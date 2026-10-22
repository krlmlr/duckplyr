# `experiments/`: measured evidence

*Handbook: [`meta/experiments/`](/handbook/meta/experiments/README.md) owns this directory's conventions.*

One directory per experiment, holding everything it needs:
a `README.md` that says what was measured, when, on what, and which handbook leaf relies on it,
plus whatever the run took: scripts, inputs, recorded output.

This file is what names the contents, so nothing here is an orphan.
The change that adds a directory adds its line below: the name, what it measured, and the leaf it supports.

<!-- One bullet per directory, newest last:
     * [`YYYY-MM-DD-topic/`](YYYY-MM-DD-topic/): what it measured, in one clause;
       supports [`area/leaf/`](/handbook/area/leaf/README.md). -->
* [`2026-10-22-dplyr-tests-revendoring/`](2026-10-22-dplyr-tests-revendoring/): vendored dplyr test failures after re-vendoring from dplyr 1.2.1;
  supports [`dplyr-alignment/vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md).
