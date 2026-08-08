# soilquality R package — upgrade to cover the full SQI corpus

> **Executes:** \[\[skills-forge/soil-quality-index/SKILL\]\] ·
> **Repo:** `github.com/ccarbajal16/soilquality` · **Status:**
> in-progress ✅ **Audited against the real repo (`bc1838e`,
> 2026-08-08).** Sections marked ❌ were assumptions that turned out
> false — read those before implementing the phase they belong to.
> Bridges the vault from *knowledge* (wiki) and *operability* (skill) to
> *execution* (running code).

## Objective

Extend `soilquality` from **one** SQI route (PCA-MDS → AHP/loading
weights → scoring → weighted additive) to **the routes the literature
actually uses**, so that a user can reproduce published SQIs, choose a
weight-free aggregation, select indicators by network centrality, and —
the biggest gap — **prove their index discriminates**. Every addition
below is grounded in a specific paper and a specific equation.

## Scope

- **In scope:** new scoring, aggregation, MDS-selection and validation
  functions; functional grouping; reference-soil standardisation; docs
  and tests for all of it.
- **Out of scope (non-goals):** spatial prediction (that is
  \[\[skills-forge/soil-fertility-mapping/SKILL\|soil-fertility-mapping\]\]’s
  job), uncertainty propagation into the index (own project), ~~a Shiny
  app~~ **building a new Shiny app** — ⚠️ corrected: one already exists
  ([`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md),
  `inst/shiny`). The non-goal is *new* app work; but every phase that
  adds a route must decide explicitly whether the app exposes it, and
  say so, or the app silently drifts out of sync with the package. Also
  out of scope: breaking changes to the existing API.
- **First slice:** Phase 1 + Phase 2
  ([`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
  and
  [`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md)).
  Both are small, both are independently useful, and together they let
  the package reproduce the two most common published recipes. Ship
  that, then continue.

## ⚠️ Read this before starting — the implementing agent has no wiki

This plan is written to be **self-contained**. Every formula, threshold
and selection rule is stated inline with its source, because the agent
working inside the `soilquality` repo will not have access to this
vault. Do not paraphrase the equations from memory — copy them from this
page.

### Carry-over kit (copy these into the package repo, e.g. `inst/refs/` or just have them open)

| File in `Soil_skill/raw/papers/` | What it grounds |
|----|----|
| `Yuan_2026.pdf` | scoring equations, area/weighted formulas, PCA & network MDS rules, EMDS grouping, validation (SI, fit to TDS) |
| `Kuzyakov_2020.pdf` | the area formula (eq. 2) and its **ratio** design; reference-soil standardisation; sensitivity/resistance |
| `Chaudhry_2024.pdf` | non-linear scoring with published expert weights; the `SQI_p` vs `SQI_dp` warning |
| `Maaz_2023.pdf` | validation by **distribution**; inherent-property adjustment; ICC/clustering |
| `Huera-Lucero_2025.pdf` | clean PCA-MDS reference implementation with every rule stated numerically |
| `Theresa_2026.pdf` | PCA adequacy testing (KMO/Bartlett); yield as external validator |

------------------------------------------------------------------------

## Data & assumptions

✅ **Task 0.1 was executed on 2026-08-08.** The section below is no
longer assumption — it is the verified state of the repository at commit
`bc1838e`. Three original assumptions were wrong; they are marked ❌ and
the affected tasks have been rewritten in place.

### Verified exported API (from `NAMESPACE`)

All functions the plan assumed exist, **do** exist, with the assumed
signatures:
[`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md),
[`standardize_numeric()`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md),
`pca_select_mds(data, var_threshold, loading_threshold)`,
[`ratio_to_saaty()`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md),
[`create_ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md),
[`ahp_weights()`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md),
[`score_higher_better()`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md),
[`score_lower_better()`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md),
[`score_optimum()`](https://ccarbajal16.github.io/soilquality/reference/score_optimum.md),
[`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md),
`score_indicators(data, mds, directions)`,
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md),
`soil_property_sets`,
[`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md),
[`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md).

**The plan under-counted the surface.** These are also exported and must
be considered by every phase: \| Function \| Note for this plan \|
\|—\|—\| \|
[`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
\| CSV-in entry point \| \|
[`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
\| **The real engine.**
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
is a thin wrapper that delegates to it (`R/sqi_compute.R:440`). New
aggregation methods must be wired here, not only in the wrapper. \| \|
[`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)
\| `scoring_rule` constructor objects — the user-facing way to specify
scoring. A new
[`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
needs a matching constructor to be reachable idiomatically. \| \|
[`to_numeric()`](https://ccarbajal16.github.io/soilquality/reference/to_numeric.md)
\| coercion helper \| \|
[`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md)
\| ⚠️ **A Shiny app already ships** in `inst/shiny`. See the revised
non-goal below. \| \| `plot.sqi_result` (S3) \| the `type =` dispatcher
behind
[`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md)
\|

### Verified tooling

- ✅ `roxygen2` 7.3.3 (`RoxygenNote`), `pkgdown` present
  (`_pkgdown.yml`, `docs/`).
- ❌ **`testthat` is NOT on edition 3.** `testthat (>= 3.0.0)` is in
  `Suggests`, but `DESCRIPTION` has **no `Config/testthat/edition: 3`**
  field, so the suite runs on edition 2. Deciding whether to migrate is
  now **Task 0.4**. Do not write 3e-only idioms until that is settled.

### ❌ Verified licence — this invalidates the `igraph` recommendation

`DESCRIPTION:14` reads **`License: MIT + file LICENSE`**, not GPL-3.

The plan’s reasoning (“licence is GPL-3, therefore igraph’s GPL-2+ is
compatible, therefore use `Imports`”) does not hold. Putting a GPL
package in `Imports` makes it a hard load-time dependency of a combined
work, which pulls a permissively-licensed package into GPL territory on
distribution. **Resolution: `igraph` goes in `Suggests`, guarded by
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).** See
revised Task 4.1 and Open decision 2.

### Verified example data — Task 0.3 is already satisfied

`data/soil_data.rda` (50 × 16) and `data/soil_ucayali.rda` (50 × 15)
already ship, documented in `R/data.R`. `soil_data` meets every
requirement Task 0.3 asked for: ~50 samples, 15 indicators, `BD` as a
less-is-better, `pH` as an optimum, plus `SOC`, `OM`, `N`, `P`, `K`,
`CEC`, `EC`. **Do not create a new fixture.** Task 0.3 is rewritten as a
verification step.

------------------------------------------------------------------------

## Task breakdown

### Phase 0 — Baseline and guardrails

**0.1 Audit the current API.** ✅ Done 2026-08-08. Findings folded into
*Data & assumptions* above; three wrong assumptions corrected (licence,
`testthat` edition, the `loading_threshold` rule) and the exported
surface expanded.

**0.2 Establish a regression baseline.** Run the existing test suite;
record pass/fail per file. Nine test files already exist (~2 070 lines)
covering ahp, data-handling, interactive, pca-mds, property-sets,
scoring, scoring-constructors, sqi-compute, visualization. If coverage
of
[`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
(the engine, not just the wrapper) is thin, add a golden-output test on
`soil_data` **before** touching anything — every phase below must leave
it green.

**0.3 ~~Create~~ Verify the shared fixture.** ✅ No new fixture needed —
`soil_data` (50 × 16) already satisfies every stated requirement. All
new tests use it. See *Data & assumptions*.

**0.4 ⚠️ NEW — decide the `testthat` edition.** ✅ **Migrated to edition
3.** Added `Config/testthat/edition: 3` to `DESCRIPTION`. The migration
cost exactly one line: the suite used none of the idioms edition 3
removes (`context()`, `expect_that()`, `expect_is()`,
`expect_equivalent()`, `expect_less_than()`/`expect_more_than()`,
`setup()`/`teardown()`, `with_mock()`, `expect_known_*()`), and the
Phase 1–2 tests were already written in 3e style. All 12 test files pass
and `R CMD check` is clean under the new edition. ⚠️ **Verification note
for anyone repeating this:** `testthat::test_dir("tests/testthat")` does
**not** pick up the edition from `DESCRIPTION` — it has no idea which
package the directory belongs to, so it silently runs on edition 2 and
reports a **false green**. Confirm with
[`testthat::edition_get()`](https://testthat.r-lib.org/reference/local_edition.html)
and run via `devtools::test()` or `R CMD check`, which do read the
field.

**0.5 ⚠️ NEW — record the Shiny sync policy.**
[`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md)
exists. Decide once, here, whether new routes surface in the app or the
app is explicitly frozen at the current feature set, and note it in
`NEWS.md`. Deciding per-phase guarantees drift.

### Phase 1 — Non-linear (sigmoidal) scoring ⭐ start here

**Why:** this is the **dominant scoring form in the SQI literature**.
Without it the package cannot reproduce Chaudhry, Huera-Lucero, or
Yuan’s non-linear arm.

**1.1 Implement
[`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md).**

    S = 1 / (1 + (x / x0)^b)        b = -2.5  "more is better"
                                    b = +2.5  "less is better"
                                    x0 = mean of the indicator (default)

Source: **Yuan 2026 eq. (5)**; **Chaudhry 2024 eq. (1)**; **Huera-Lucero
2025** (writes it as `S = a/(1 + (x/x0)^b)` with `a = 1`).

``` r

score_sigmoid <- function(x, direction = c("higher", "lower"),
                          x0 = mean(x, na.rm = TRUE), b = 2.5) { ... }
```

- `b` **must be a user-facing parameter with a documented default of
  2.5**, not a constant. The 2.5 is inherited from Yu et al. via
  Chaudhry — it is a convention with empirical support for pH/TN/SOC/P,
  **not** a constant of nature. Say so in the roxygen block.
- `x0` defaults to the sample mean but must be overridable, so a user
  can centre on an external reference value instead (see Phase 6).
- Handle `NA` (`na.rm`), zero and negative `x` (a negative base with a
  fractional exponent is `NaN` in R — document and guard; suggest
  shifting or using
  [`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md)
  instead).

**1.2 Sanity tests.** `direction="higher"` → S increases monotonically
with x, S→1 as x≫x0, S→0 as x→0; `direction="lower"` → the mirror;
`S(x0) == 0.5` exactly for both directions; output always in \[0,1\].

**1.3 Wire into
[`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)**
as a selectable method, without changing existing behaviour. ⚠️
**Verified mechanics** (`R/scoring.R:199-259`):
[`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)
dispatches on `direction$type` through an if/else chain over
`"higher" | "lower" | "optimum" | "threshold"`, writing
`paste0(indicator, "_scored")` columns, and
[`stop()`](https://rdrr.io/r/base/stop.html)s on an unknown type. Add a
`"sigmoid"` branch — this is purely additive, no existing default moves.

**1.3b ⚠️ NEW — add the
[`sigmoid_scoring()`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
constructor.** Verified in Task 0.1: users specify scoring through
exported `scoring_rule` constructor objects
([`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)
in `R/scoring_constructors.R`), which
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
converts to `directions` via `as.list(rule)`
(`R/sqi_compute.R:428-436`). Without a matching constructor,
[`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
is unreachable from the documented entry point. Also extend
[`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)
with an opt-in argument to emit sigmoid rules instead of linear ones —
that is what makes Task 1.4’s “compute both and compare” a one-line
change for a user.

**1.4 Document the linear/non-linear choice honestly.** The literature
**contradicts itself**: Yuan 2026 finds NL \> L (fit R² 0.65 vs 0.56);
Bilgili et al. 2017 — cited *inside Yuan’s own introduction* — finds L
\> NL. Add a vignette note recommending **computing both** and reporting
whether conclusions change.

### Phase 2 — Area aggregation, with the reference-soil ratio ⭐

**Why:** gives the package a **weight-free** aggregation route,
sidestepping the most contested step in the pipeline. See Phase 3’s
rationale for why weights are contested.

**2.1 Implement
[`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md).**

    Area = 0.5 * sum(stP_i^2) * sin(2*pi / n)

Source: **Kuzyakov et al. 2020, eq. (2)** (Front. Agr. Sci. Eng.
7(3):282–288, doi 10.15302/J-FASE-2020338). Verified against the
original PDF.

``` r

sqi_area <- function(s, reference = NULL) {
  a <- 0.5 * sum(s^2) * sin(2 * pi / length(s))
  if (is.null(reference)) return(a)
  a / (0.5 * sum(reference^2) * sin(2 * pi / length(reference)))
}
```

- ⚠️ **It is the SQUARE of each parameter, not the product of adjacent
  radii.** The true polygon area would be `sum(s_i * s_{i+1})`, which
  makes the result depend on the arbitrary **order** of indicators
  around the diagram. Kuzyakov’s square form is an approximation of “the
  sum of individual triangles” that is **order-independent**. Implement
  the square. Document this note — a reviewer will ask.
- ⚠️ **As designed it is a RATIO.** Kuzyakov standardises against a
  **non-degraded reference soil** (reference = 1.0) and reports
  `Area_degraded / Area_non_degraded`; the worked figure gives **0.47**
  = “half the function lost”. *“Comparison with non-degraded soil is
  required.”*

**2.2 Document the two uses and their consequence.** The
weight-independence people cite is a consequence of **taking a ratio**,
not a property of the formula.

| Use | Standardised against | Comparable across studies? |
|----|----|----|
| Absolute (`reference = NULL`) | your own sample | **no** |
| Ratio (`reference = <ref soil>`) | a non-degraded reference soil | **claimed yes** |

**2.3 Tests.** Area is invariant to the order of `s` (this is the point
of the square form); all-1.0 scores give the maximum area for that `n`;
ratio of a vector with itself is exactly 1; ratio \< 1 for a uniformly
degraded vector.

**2.4 Add `n`-dependence warning.** Kuzyakov notes total area depends
slightly on `n`, but the *ratio* does not. Warn if
`length(s) != length(reference)`.

**2.5 Wire into
[`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)**
as `method = c("weighted", "area")`, default unchanged. ⚠️ Corrected
target: the plan said
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md),
but Task 0.1 verified that function is a wrapper that forwards to
[`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
(`R/sqi_compute.R:440-448`). Add the argument to the engine and let it
flow through the wrapper’s `...`; wiring only the wrapper would leave
[`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
and
[`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
without the new route.

### Phase 3 — Validation ⭐ the biggest gap in the package *and* the field

**Why:** an SQI has **no ground truth**. Nothing in `soilquality` — or
in most of the literature — answers “does this index actually work?”.
This is where the package can lead rather than follow.

**3.1 Implement `sqi_validate()`** returning a structured object with:

- **Sensitivity index** `SI = max(SQI) / min(SQI)`. Source: **Yuan
  2026**, after Rezaee et al. Yuan’s observed ranges: Area 1.12–2.92,
  weighted 1.14–1.82, NL 1.21–2.92, L 1.14–2.49, NA 1.30–2.92, PCA
  1.14–2.72.
- **Fidelity to the total data set**: R² of `lm(sqi_mds ~ sqi_tds)`.
  Source: **Yuan 2026**. ⚠️ Document that the TDS index is **not ground
  truth** — it is just the index with everything in it. High fidelity
  means *faithful to your full measurement set*, not *correct*.
- ⭐ **Quantile distribution** — the count of samples falling in each of
  the **0–20 / 20–40 / 40–60 / 60–80 / 80–100 %** bands of the empirical
  CDF ([`ecdf()`](https://rdrr.io/r/stats/ecdf.html) then
  [`cut()`](https://rdrr.io/r/base/cut.html)). These are the
  conventional “very low → very high” soil-health categories (CSHT
  convention, used by **Maaz 2023**).
- **External criterion** (optional): correlation with a supplied vector
  (yield, a known contrast). Source: **Theresa 2026** validates against
  four seasons of rice yield.

**3.2 Make the distribution the headline.** This is the corpus’s
strongest methodological finding and it must not be buried. **Maaz
2023**: an SEM index and an additive index correlated at **r = 0.96** —
apparent agreement — yet the additive index put **94 %** of plots in the
middle 20–80 % band versus **61 %** for SEM. **Correlation is the wrong
diagnostic for an index; the distribution across decision categories is
the right one.** An index that calls everything “medium” cannot inform a
decision.

- The print/summary method should surface the middle-band share
  prominently and **warn above a documented threshold** (suggest \> 80
  %).

**3.3 Implement `sqi_compare()`** — run the same data through ≥ 2
recipes (e.g. linear vs sigmoid, weighted vs area) and report whether
the **ranking of samples/groups** survives (Spearman rank correlation +
a flag when the top/bottom group changes). Source: **Yuan 2026** found
EMDS achieved fit R² 0.74–0.77 with *no p \> 0.05 across any
scoring/aggregation combination* — i.e. it was **stable**, not merely
accurate.

**3.4 Extend
[`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md)**
with the quantile-distribution plot, or add `plot_sqi_validation()`.

### Phase 4 — Network-analysis MDS selection

**Why:** **Yuan 2026** measured that it **beats PCA** — better fidelity
(R² 0.63 vs 0.58), higher sensitivity (SI 1.30–2.92 vs 1.14–2.72),
selects **fewer** indicators, and makes **no normality assumption**. It
also selects on a different principle: PCA favours **variance**, network
analysis favours **centrality** (ecological hubs).

**4.1 ❌ CORRECTED — add `igraph` to `Suggests`, not `Imports`.** The
original instruction (“`Imports`, GPL-2+ is compatible with GPL-3”)
rested on a false premise: **this package is MIT** (`DESCRIPTION:14`),
not GPL-3. A GPL package in `Imports` is a mandatory load-time
dependency of a combined work and drags an MIT package into GPL
obligations on distribution. Put `igraph` in `Suggests` and guard every
use:

``` r

if (!requireNamespace("igraph", quietly = TRUE)) {
  stop("Package 'igraph' is required for network-based MDS selection. ",
       "Install it with install.packages('igraph').", call. = FALSE)
}
```

Consequences to honour: all `igraph` calls stay `igraph::`-qualified;
every example and test in Phase 4 is wrapped in a
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guard (or
`testthat::skip_if_not_installed("igraph")`) so `R CMD check` passes on
a machine without it; Phase 4 becomes optional at load time, which is
the desired outcome anyway.

**4.2 Implement `na_select_mds()`** following Yuan 2026 §2.3.2
**exactly**:

1.  Correlation network: nodes = indicators; edge where **Spearman \|r\|
    ≥ 0.60 and p \< 0.01**.
2.  Communities by **Louvain/Blondel** modularity —
    `igraph::cluster_louvain()` (Blondel et al. 2008).
3.  Keep only modules whose **maximum eigenvector centrality \> 0.6** —
    `igraph::eigen_centrality()`. (Yuan states this is the analogue of
    retaining PCs that explain ≥ 5 % of variance.)
4.  Within each kept module, retain indicators **within 10 % of the
    maximum centrality** (i.e. `centrality >= 0.9 * max(centrality)`).
5.  Break ties by highest **weighted degree** — `igraph::strength()`.
6.  Screen surviving correlated indicators as in the PCA route.
7.  **Weights** = eigenvector centrality / sum of centralities within
    the module.

``` r

na_select_mds <- function(data, r_min = 0.60, p_max = 0.01,
                          centrality_min = 0.6, within = 0.10) { ... }
```

All four thresholds must be parameters with these defaults.

**4.3 Return the same shape as
[`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)**
so the two are drop-in interchangeable downstream.

**4.4 Implement `mds_consensus()`** — run both routes and return the
**intersection**. Cheap, underused robustness check: on Yuan’s 40-year
tillage data, **SOC, dissolved organic carbon and soil compaction** were
selected by **all six** MDS variants.

**4.5 Document the caveat.** Correlation networks **cannot establish
causality**, and shared environmental drivers create **spurious edges**
(Yuan cites Connor et al. 2017; Deutschmann et al. 2021). Yuan
recommends verifying with random forest or SEM.

### Phase 5 — Functional (EMDS) grouping

**Why:** **Yuan 2026** found fidelity improved monotonically with
grouping detail — **EMDS (R² 0.77 / 0.74) \> RMDS \> ungrouped MDS** —
and EMDS was the most **stable** choice. And **Maaz 2023** found by
confirmatory factor analysis that the physical/chemical/biological split
has **no statistical support**. Two methods, two continents, same
verdict: group by **function**.

**5.1 Add a `groups =` argument** to
[`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
and `na_select_mds()` — select within each group rather than across the
whole pool. Must default to `NULL` (current behaviour).

**5.2 Ship the five-function default grouping** as exported data, per
Yuan (after Li et al. 2023): **carbon cycling · nutrient cycling ·
physical structure stability · buffering and filtration capacity · soil
biodiversity maintenance**. Provide a mapping helper for the common
indicator names already in `soil_property_sets`. ⚠️ **Verified in Task
0.1 — this answers Open decision 1, and the answer is worse than “no”.**
`soil_property_sets` (`R/property_sets.R:44-57`) carries **no**
indicator→function mapping. Its six sets are `basic`, `standard`,
`comprehensive`, `physical`, `chemical`, `fertility` — i.e. the
package’s only existing grouping vocabulary is exactly the
**physical/chemical split that Maaz 2023 shows has no statistical
support** (Task 5.4). So Task 5.2 is a full curation pass, and it lands
next to a contradicting default that ships today.

- Do **not** delete or repurpose `physical`/`chemical` — they are
  exported, documented and tested
  (`tests/testthat/test-property-sets.R`); removing them is the breaking
  change this plan forbids.
- Add the functional grouping as a **new** exported object
  (e.g. `soil_function_groups`), and use Task 5.4’s documentation to
  state plainly why the new one is preferred for MDS selection.
- The available indicator vocabulary to map against is fixed by
  `soil_data`: Sand, Silt, Clay, BD, pH, OM, SOC, N, P, K, CEC, Ca, Mg,
  EC, S. Note that **soil biodiversity maintenance has no measured
  indicator in this vocabulary** — ship the group, document that it is
  unpopulated by the example data, and do not fabricate a proxy.

**5.3 Implement the norm-value selector** for the grouped PCA route —
pick the indicator with the highest **norm value** per group:

    N_ik = sqrt( sum( u_ik^2 * lambda_k ) )

where `u_ik` is the loading of indicator *i* on PC *k* and `lambda_k`
the eigenvalue of PC *k*, summed over the PCs with eigenvalue ≥ 1.
Source: **Yuan 2026 eq. (2)**.

**5.4 Document why not to group by physical/chemical/biological**,
citing Maaz’s CFA result.

### Phase 6 — Reference-soil standardisation

**Why:** it is the **only documented escape from SQI incomparability**.
Scoring against your own sample extremes makes the best site score ≈ 1.0
by construction, which is why published SQI values cannot be compared
across studies.

**6.1 Implement `standardize_to_reference()`.** Standardise each
indicator against the same indicator measured in a **non-degraded
reference soil** (reference = 1.0, values decrease toward 0). Source:
**Kuzyakov 2020**.

- **more is better** (default) → reference gets the maximum
- **less is better** (e.g. bulk density) → the **minimum** is assigned
  to the undisturbed soil
- **optimum** (pH, water/air permeability, hydrophobicity) → use the
  **difference from the optimum**, not a monotone scale

**6.2 Wire it as an option throughout** the scoring functions (an
alternative to sample-relative `X/X_max`), and document the trade-off:
comparability in exchange for **needing a defensible non-degraded
reference soil** — which Kuzyakov calls the approach’s key disadvantage,
and which a fully converted landscape often lacks.

**6.3 (Optional) Implement `sensitivity_resistance()`.** Kuzyakov’s
under-used second approach: plot each parameter’s standardised change
against the **SOC** change. On the 1:1 identity line the parameter
degrades at SOC’s rate; **faster = sensitive**, **slower = resistant**.
Generally (micro)biological properties are sensitive, physical
properties resistant. ⚠️ Kuzyakov reports it separated cleanly on a
Luvic Phaeozem but **not** on a Calcic Chernozem — document the
limitation.

### Phase 7 — Documentation, vignette, correctness fixes

**7.1 ❌ CORRECTED — the “within 10 %” rule is NOT implemented. This is
a code task, not a doc task, and it does not belong in Phase 7.** The
original task said “document that
[`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
implements *within 10 % of the maximum loading*”. Task 0.1 read the
source: **it does not.** `R/pca_mds.R:152-171` does this instead:

``` r

for (pc_idx in retained_pcs) {
  pc_loadings  <- loadings[, pc_idx]
  abs_loadings <- abs(pc_loadings)
  max_idx      <- which.max(abs_loadings)          # ONE variable per PC
  max_loading  <- abs_loadings[max_idx]
  if (max_loading > loading_threshold) { ... }      # absolute cut-off, not relative
}
```

Two divergences from the literature, not one:

1.  It keeps **only the single highest-loading variable per retained
    PC** (`which.max`). The published rule keeps **every** variable
    within 10 % of that maximum —
    `abs_loadings >= 0.9 * max(abs_loadings)` — so the real MDS is
    generally **larger** than what this package returns.
2.  `loading_threshold = 0.5` is an **absolute** floor on the loading, a
    different mechanism from the **relative** 10 % band. Both can
    coexist, but they are not the same rule and the current argument
    name suggests otherwise. **Revised work:**

- Implement the relative band behind a **new** argument,
  e.g. `within = NULL` (current behaviour) / `within = 0.10` (published
  rule). Default must not move — widening the MDS changes every
  downstream weight and SQI value, and Task 0.2’s baseline must stay
  green.
- Document `loading_threshold` for what it actually is (an absolute
  floor), and document `within` for the relative rule.
- Keep the Yuan warning: **Yuan 2026 §2.3.1 states the rule INVERTED**
  (`"< 10 % of the highest loading"`), which would select the *least*
  informative variables; Yuan’s own §2.3.2 and every other paper state
  it correctly. Anyone implementing from that paper alone gets it
  backwards.
- Unit-test the selected set on `soil_data` for both `within = NULL` and
  `within = 0.10`. **Sequencing:** Phase 5.1 adds `groups =` to this
  same function and Phase 5.3 adds the norm-value selector — all three
  touch the same selection loop. **Move this task into Phase 5** and do
  the three together, rather than reopening
  [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  in Phase 7 after Phase 5 already rewrote it.

**7.2 Add PCA adequacy testing** to
[`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
— **KMO** and **Bartlett’s sphericity**, reported (and optionally
enforced). Most papers skip it; **Theresa 2026** does not (KMO 0.81,
Bartlett χ² 425.37, df 136, p \< 0.001).

**7.3 Write the main vignette** — “Building and validating a Soil
Quality Index” — walking the full pipeline: select (PCA \| network \|
expert) → group by function → score (linear \| sigmoid \| optimum) →
weight (AHP \| loading \| centrality \| none) → aggregate (weighted \|
area) → **validate**.

**7.4 Add the “don’t chain predictions” warning** wherever the docs
touch predicted inputs. **Chaudhry 2024**: computing an SQI from
*predicted* properties gave **R² = 0.23**; predicting the index
*directly* gave **R² = 0.90** — on the same spectra, with individually
acceptable property models (Cubist R² 0.35–0.93). If a user feeds
predicted properties into
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md),
the resulting index is far less reliable than its inputs.

**7.5 Update README** with the new routes and a decision table.

**7.6 `R CMD check --as-cran`** clean; bump version; NEWS.md entry per
phase.

------------------------------------------------------------------------

## Open decisions (these tailor the tasks)

1.  ✅ **RESOLVED by Task 0.1 — `soil_property_sets` carries no
    indicator→function mapping.** Its sets are
    `basic`/`standard`/`comprehensive`/`physical`/`chemical`/`fertility`.
    Task 5.2 therefore needs a full curation pass, and must ship the
    functional grouping as a **new** exported object beside the existing
    (contradicting) physical/chemical sets rather than replacing them.
    Details in 5.2.
2.  ✅ **RESOLVED by Task 0.1 — `Suggests`.** The premise of the
    original recommendation was wrong: the package is **MIT**, not
    GPL-3, so `Imports` is not merely a convenience question, it is a
    licensing one. See revised Task 4.1.
3.  **Should `sqi_validate()` hard-warn or just report** when the
    middle-band share exceeds the threshold? Recommend a **warning** — a
    silent number will be ignored. *(still open)*
4.  **Scope of Phase 6.3** (`sensitivity_resistance()`) — genuinely
    useful but the least-used method in the corpus. Defer if time is
    short. *(still open)*
5.  ✅ **RESOLVED — `testthat` edition 3.** Migrated in Phase 0; cost
    one line in `DESCRIPTION` because the suite used no removed idioms.
    Write every new test to 3e. See Task 0.4.
6.  ⚠️ **NEW — does
    [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md)
    expose the new routes?** See Task 0.5. Decide once, not per phase.

## Risks & mitigations

| Risk | Mitigation |
|----|----|
| Breaking the existing API | Task 0.2’s regression baseline; every new behaviour behind a new argument with the current default |
| Implementing a formula from memory | The carry-over kit; every equation stated inline with paper + equation number |
| The `s²` vs `sᵢ·sᵢ₊₁` area trap | Settled against the original PDF: **use the square**. Test for order-invariance (2.3) |
| Inverting the “within 10 %” loading rule | Revised Task 7.1 (moved to Phase 5) implements it behind a new `within` argument and unit-tests the selected set on `soil_data` |
| ⚠️ **Assuming the plan’s own assumptions** | Task 0.1 found 3 of them wrong (licence, testthat edition, the loading rule) by reading source, not docs. Verify against `R/` before implementing any phase — the wiki page describing this package was also stale |
| ⚠️ **MIT package acquiring GPL obligations** | Revised Task 4.1: `igraph` in `Suggests` behind [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html), never `Imports` |
| ⚠️ **Shiny app drifting from the package** | Task 0.5 sets the policy once, up front |
| Validation functions that nobody uses | Make the quantile distribution the headline of the print method (3.2), not an optional extra |
| Over-claiming comparability | Task 2.2’s table states plainly which mode is comparable and which is not |

## Progress log

- **2026-08-08** — Plan created from
  \[\[skills-forge/soil-quality-index/SKILL\]\] after ingesting the
  11-paper SQI corpus plus
  \[\[sources/2020-kuzyakov-sqi-area-degradation\|Kuzyakov 2020\]\]. Not
  started.
- **2026-08-08** — **Task 0.1 executed against the repo at `bc1838e`.**
  Three assumptions falsified by reading source:
  1.  **Licence is MIT, not GPL-3** → Task 4.1 reversed, `igraph` moves
      to `Suggests`.
  2.  **[`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
      does not implement the “within 10 %” rule** — it takes
      [`which.max()`](https://rdrr.io/r/base/which.min.html), one
      variable per PC → Task 7.1 turns from a five-minute doc note into
      an implementation task and moves to Phase 5.
  3.  **`testthat` runs on edition 2**, not 3 → new Task 0.4. Also
      found: the exported surface is larger than listed
      ([`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
      is the real engine, and scoring is reached through `scoring_rule`
      constructors → new Task 1.3b); a **Shiny app already ships** →
      non-goal reworded, new Task 0.5; `soil_data` already satisfies the
      fixture requirement → **Task 0.3 closed without work**;
      `soil_property_sets` has no functional mapping and encodes the
      physical/chemical split Maaz disproves → Open decision 1 resolved,
      Task 5.2 expanded. Phases 0.1 and 0.3 complete. Next: Task 0.2
      (regression baseline) on branch `feat/sqi-scoring-aggregation`,
      then Phases 1–2.

## Provenance

Executes \[\[skills-forge/soil-quality-index/SKILL\]\]. Key sources —
full citations in the wiki:
\[\[sources/2026-yuan-shi-mds-methods-comparison\|Yuan 2026\]\]
(scoring, aggregation, MDS routes, EMDS, validation),
\[\[sources/2020-kuzyakov-sqi-area-degradation\|Kuzyakov 2020\]\] (area
formula + ratio design + reference standardisation +
sensitivity/resistance), \[\[sources/2023-maaz-sem-soil-health\|Maaz
2023\]\] (validation by distribution; functional grouping),
\[\[sources/2024-chaudhry-sqi-three-methods\|Chaudhry 2024\]\]
(non-linear scoring; the chaining trap),
\[\[sources/2025-huera-lucero-land-use-sqi-amazon\|Huera-Lucero 2025\]\]
(PCA-MDS reference implementation),
\[\[sources/2026-theresa-rice-fertilization-sqi\|Theresa 2026\]\]
(KMO/Bartlett; yield validation). Method pages:
\[\[methods/minimum-dataset-construction\]\],
\[\[methods/soil-indicator-scoring\]\], \[\[methods/sqi-aggregation\]\],
\[\[methods/sqi-validation\]\]. Tool page: \[\[entities/soilquality\]\].
