---
status: draft
---

# Function translations

How an R expression inside a verb becomes a DuckDB expression, where the translations live, and what keeps their user-facing list current.
Which verbs run through DuckDB at all is [`verbs/`](/handbook/verbs/README.md)'s.

**Adding a translation is the contributing guide's.**
Its section [New translations for functions](https://github.com/tidyverse/duckplyr/blob/main/.github/CONTRIBUTING.md#new-translations-for-functions)
owns the steps, because contributors from outside the project read it on the website.
This leaf holds what the guide does not say.

**[`R/translate.R`](/R/translate.R) holds the translations.**

* `rel_find_packages()` maps each translatable function name to the package it must come from,
  and a call whose function resolves elsewhere, such as a user's own `n()`, is refused rather than translated.
* `rel_translate_lang()` builds the DuckDB expression,
  with special cases for functions whose arguments need checking or rewriting and aliases for functions DuckDB names differently.
* `duckplyr_macros` defines in SQL the functions DuckDB lacks or defines with different semantics;
  `R/relational-duckdb.R` registers them as macros on every new connection.
  The guide places the macros in `R/relational-duckdb.R`, which is where they are registered rather than defined.

**A function without a translation falls back.**
Translation raises an error, which `rel_try()` turns into a fallback to dplyr for the whole verb call.
`dd$<fun>()` and `dd::<fun>()` skip translation and call the DuckDB function of that name,
which `vignette("duckdb")` documents for users.

**The user-facing list is [`vignettes/limits.Rmd`](/vignettes/limits.Rmd), and it is kept by hand.**
Nothing generates it from `R/translate.R`, so a translation added there is added to the vignette in the same change,
as the comments in `rel_find_packages()` remind.

**A translation is tested through the generated tests.**
The guide's step adds an expression to the `mutate` entry of `test_extra_arg_map` in [`tools/00-funs.R`](/tools/00-funs.R),
and `tools/03-tests.R` turns each entry into a test in `tests/testthat/test-as_duckplyr_df.R`;
[`tests/testthat/test-translate.R`](/tests/testthat/test-translate.R) tests the translation layer directly.

*To deepen: fix the guide's statement about where the macros live,
and say how the window-function aliases in `rel_translate_lang()` are extended.*
