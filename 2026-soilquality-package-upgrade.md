---
type: project
title: soilquality R package — upgrade to cover the full SQI corpus
domains: [soil-quality, vnv, ml]
based_on_skills: ["[[skills-forge/soil-quality-index/SKILL]]"]
study_area: n/a — software (github.com/ccarbajal16/soilquality)
status: in-progress
created: 2026-08-08
updated: 2026-08-08
audited_against: bc1838e
---
# soilquality R package — upgrade to cover the full SQI corpus

> **Executes:** [[skills-forge/soil-quality-index/SKILL]] · **Repo:** `github.com/ccarbajal16/soilquality` · **Status:** in-progress
> ✅ **Audited against the real repo (`bc1838e`, 2026-08-08).** Sections marked ❌ were assumptions
> that turned out false — read those before implementing the phase they belong to.
> Bridges the vault from *knowledge* (wiki) and *operability* (skill) to *execution* (running code).

## Objective

Extend `soilquality` from **one** SQI route (PCA-MDS → AHP/loading weights → scoring → weighted
additive) to **the routes the literature actually uses**, so that a user can reproduce published
SQIs, choose a weight-free aggregation, select indicators by network centrality, and — the biggest
gap — **prove their index discriminates**. Every addition below is grounded in a specific paper and
a specific equation.

## Scope

- **In scope:** new scoring, aggregation, MDS-selection and validation functions; functional
  grouping; reference-soil standardisation; docs and tests for all of it.
- **Out of scope (non-goals):** spatial prediction (that is [[skills-forge/soil-fertility-mapping/SKILL|soil-fertility-mapping]]'s
  job), uncertainty propagation into the index (own project), ~~a Shiny app~~ **building a new Shiny
  app** — ⚠️ corrected: one already exists (`run_sqi_app()`, `inst/shiny`). The non-goal is *new* app
  work; but every phase that adds a route must decide explicitly whether the app exposes it, and say
  so, or the app silently drifts out of sync with the package. Also out of scope: breaking changes to
  the existing API.
- **First slice:** Phase 1 + Phase 2 (`score_sigmoid()` and `sqi_area()`). Both are small, both are
  independently useful, and together they let the package reproduce the two most common published
  recipes. Ship that, then continue.

## ⚠️ Strategic context, added 2026-08-08 — read before picking a phase

### Two SQI packages already exist on CRAN
| Package | Date | What it covers |
|---|---|---|
| **[`SQIpro`](https://cran.r-project.org/web/packages/SQIpro/index.html)** (Islam & Kaushal, v0.1.0) | 2026-04-20 | Six methods: **Linear Scoring, Regression-based, PCA-based, Fuzzy Logic, Entropy Weighting, TOPSIS**; four scoring functions; automated **MDS via PCA + VIF filtering**; one-way ANOVA + Tukey HSD; **leave-one-out sensitivity analysis**; ggplot2 output |
| **[`SQI`](https://cran.r-project.org/package=SQI)** (Wani et al., v0.1.0) | 2023-04-10 | Linear scoring, regression-based, PCA-based |

### ✅ `SQIpro`'s actual function index (verified 2026-08-08 via rdrr.io — Task 0.4, first pass)
```
scoring    score_more · score_less · score_optimum (bell curve) · score_trapezoid · score_custom · score_all
MDS        select_mds                          (PCA + VIF only)
indices    sqi_linear · sqi_regression · sqi_pca · sqi_fuzzy · sqi_entropy · sqi_topsis · sqi_compare
checks     sqi_anova (ANOVA+Tukey) · sqi_sensitivity (leave-one-out) · validate_data
plots      plot_sqi · plot_radar · plot_scores · plot_scoring_curves · plot_sensitivity · plot_pca_biplot
config     make_config · soil_data
```
**What is absent from that list:** any **area** computation, any **reference-soil ratio**, any
**network-analysis** MDS, any **functional/EMDS grouping**, any **AHP** weighting, any
**quantile-distribution** validation, and anything touching **SEM / path modelling / inherent-property
adjustment**.

⚠️ **Striking gap to exploit:** `plot_radar` **draws** the radar diagram but nothing **measures** it.
The Kuzyakov area is the natural completion of a chart they already render.

✅ **NAME COLLISION — RESOLVED 2026-08-08.** `SQIpro::sqi_compare()` (*"Compare All SQI Methods"*)
occupies that name. **Ours is `sqi_stability()`** (Phase 3.3). The names must differ because the
*questions* differ:

| | `SQIpro::sqi_compare()` | **`soilquality::sqi_stability()`** |
|---|---|---|
| Asks | what index value does each method give? | **does my conclusion survive a change of recipe?** |
| Unit of comparison | the index values | **the ranking of samples/groups** |
| Output | a table of methods × values | rank correlation + a flag when the top/bottom group changes |

Never name a function after a competitor's — and here the rename is not cosmetic, it names a
genuinely different test.

### The decision: differentiate, do not chase parity
The human's call (2026-08-08): `soilquality` is to be **the sharp research tool for the methods the
corpus showed are missing**, not a general-purpose competitor to `SQIpro`. Racing `SQIpro` method-by-method
is a losing race — it shipped first in that direction. The corpus gives a real edge instead: it read
**Kuzyakov, Maaz and Yuan**, and those methods are absent from both CRAN packages.

### Which phases are differentiators, and which are parity
| Phase | Overlaps `SQIpro`? | Priority |
|---|---|---|
| **1 — sigmoidal scoring** | ✅ **confirmed parity-ish** — `score_more`/`score_less`/`score_optimum`(bell)/`score_trapezoid`/**`score_custom`** cover the space; a user can supply the ±2.5 sigmoid via `score_custom` | **demote** — build only for convenience/reproducibility |
| **2 — area aggregation + reference-soil ratio** | ❌ **confirmed absent** — it has `plot_radar` but no area computation | ⭐⭐ **strongest differentiator** |
| **3 — validation by quantile distribution** | ❌ **confirmed absent** — it has `sqi_sensitivity` (leave-one-out) + `sqi_anova`, not the distribution test | ⭐ **differentiator** (ours is `sqi_stability()`, name collision resolved) |
| **4 — network-analysis MDS** | ❌ **confirmed** — `select_mds` is PCA + VIF only | ⭐ **differentiator** |
| **5 — EMDS functional grouping** | ❌ **confirmed absent** from the function index | ⭐ **differentiator** |
| **6 — reference-soil standardisation** | ❌ **confirmed absent** from the function index | ⭐ **differentiator** |
| **7 — docs** | neutral | keep |

Plus one `soilquality` already has that neither competitor advertises: **AHP weighting with a
consistency ratio**. Lead with it.

### ⚠️ This changes the first slice
The original plan opened with Phases 1 + 2. **Revised: open with Phase 2 + Phase 3** — the two
strongest differentiators, and the two that make the package's positioning true rather than aspirational.
Phase 1 moves to "do it when convenient".

## Scope
- **In scope:** new scoring, aggregation, MDS-selection and validation functions; functional
  grouping; reference-soil standardisation; docs and tests for all of it.
- **Out of scope (non-goals):** spatial prediction (that is [[skills-forge/soil-fertility-mapping/SKILL|soil-fertility-mapping]]'s
  job), uncertainty propagation into the index (own project), a Shiny app, breaking changes to the
  existing API.
- **First slice (revised 2026-08-08):** **Phase 2 + Phase 3** (`sqi_area()` with the reference-soil
  ratio, and `sqi_validate()`). These are the two strongest **differentiators** against the existing
  CRAN packages — see the strategic section above. Phase 1 (`score_sigmoid()`) is likely parity with
  `SQIpro` and drops to "when convenient".

## ⚠️ Read this before starting — the implementing agent has no wiki
This plan is written to be **self-contained**. Every formula, threshold and selection rule is stated
inline with its source, because the agent working inside the `soilquality` repo will not have access
to this vault. Do not paraphrase the equations from memory — copy them from this page.

### Carry-over kit (copy these into the package repo, e.g. `inst/refs/` or just have them open)
| File in `Soil_skill/raw/papers/` | What it grounds |
|---|---|
| `Yuan_2026.pdf` | scoring equations, area/weighted formulas, PCA & network MDS rules, EMDS grouping, validation (SI, fit to TDS) |
| `Kuzyakov_2020.pdf` | the area formula (eq. 2) and its **ratio** design; reference-soil standardisation; sensitivity/resistance |
| `Chaudhry_2024.pdf` | non-linear scoring with published expert weights; the `SQI_p` vs `SQI_dp` warning |
| `Maaz_2023.pdf` | validation by **distribution**; inherent-property adjustment; ICC/clustering |
| `Huera-Lucero_2025.pdf` | clean PCA-MDS reference implementation with every rule stated numerically |
| `Theresa_2026.pdf` | PCA adequacy testing (KMO/Bartlett); yield as external validator |

---

## Data & assumptions
- ⚠️ **Assumed current API** (from `entities/soilquality`): `read_soil_csv()`, `standardize_numeric()`,
  `pca_select_mds(data, var_threshold, loading_threshold)`, `ratio_to_saaty()`,
  `create_ahp_matrix()`, `ahp_weights()`, `score_higher_better()`, `score_lower_better()`,
  `score_optimum()`, `score_threshold()`, `score_indicators()`, `compute_sqi_properties()`,
  `soil_property_sets$fertility`, `standard_scoring_rules()`, `plot_sqi_report()`.
  **Task 0.1 verifies this before anything is written.**
- ⚠️ Assumed tooling: `roxygen2` docs, `testthat` (3rd edition) tests, `pkgdown` optional.
  Confirm in `DESCRIPTION`.
- ⚠️ Assumed licence GPL-3, so `igraph` (GPL-2+) is compatible as a dependency.

---

## Task breakdown

### Phase 0 — Baseline and guardrails
- [ ] **0.1 Audit the current API.** List every exported function, its signature and its return
  shape. Reconcile against the assumed list above and **correct this plan** where it differs.
- [ ] **0.2 Establish a regression baseline.** Run the existing test suite; record pass/fail. If
  coverage of `compute_sqi_properties()` is thin, add a golden-output test on a small fixture
  dataset **before** touching anything — every phase below must leave it green.
- [ ] **0.3 Create a shared fixture.** A small, documented example dataset (~30 samples × ~10
  indicators, mixed directions incl. a bulk-density-like less-is-better and a pH-like optimum) used
  by all new tests. Ship as `inst/extdata/` or `data/`.

- [x] **0.4a ⭐ Verify the competitive overlap — FIRST PASS DONE 2026-08-08.** `SQIpro`'s function
  index is transcribed above and the differentiator table is updated with confirmed verdicts. Two
  findings: `plot_radar` draws the polygon but nothing measures it, and a **name collision on
  `sqi_compare()`** — resolved by naming ours **`sqi_stability()`** (Phase 3.3).
- [ ] **0.4b Finish the verification by running the code.** Install `SQIpro` and check the *behaviour*
  the index cannot show: does `score_optimum`'s "bell curve" coincide with `1/(1+(x/x0)^±2.5)`? What
  exactly does `sqi_sensitivity` report? Does `select_mds` expose the "within 10% of max loading"
  rule? Read their **function reference**, not just the CRAN description. For each phase below, record whether the function
  already exists, and how it differs. Specifically check: do `SQIpro`'s "four variable scoring
  functions" include the **sigmoidal** `1/(1+(x/x0)^±2.5)` form? Does anything implement the
  **Kuzyakov area** method or a **reference-soil ratio**? Does its leave-one-out sensitivity report a
  **quantile distribution** of scores? Update the priority table above with what you find. **Do this
  before writing code** — it decides what is worth building.
- [ ] **0.5 Decide the positioning line in the README/DESCRIPTION.** The package is *"the sharp
  research tool for the methods the corpus showed are missing"*, not a general SQI calculator. Name
  the differentiators explicitly: AHP + consistency ratio, Kuzyakov area/ratio, network-analysis MDS,
  functional (EMDS) grouping, reference-soil standardisation, and distribution-based validation.
### Phase 1 — Non-linear (sigmoidal) scoring ⭐ start here
**Why:** this is the **dominant scoring form in the SQI literature**. Without it the package cannot
reproduce Chaudhry, Huera-Lucero, or Yuan's non-linear arm.

- [ ] **1.1 Implement `score_sigmoid()`.**
  ```
  S = 1 / (1 + (x / x0)^b)        b = -2.5  "more is better"
                                  b = +2.5  "less is better"
                                  x0 = mean of the indicator (default)
  ```
  Source: **Yuan 2026 eq. (5)**; **Chaudhry 2024 eq. (1)**; **Huera-Lucero 2025** (writes it as
  `S = a/(1 + (x/x0)^b)` with `a = 1`).
  ```r
  score_sigmoid <- function(x, direction = c("higher", "lower"),
                            x0 = mean(x, na.rm = TRUE), b = 2.5) { ... }
  ```
  - `b` **must be a user-facing parameter with a documented default of 2.5**, not a constant. The
    2.5 is inherited from Yu et al. via Chaudhry — it is a convention with empirical support for
    pH/TN/SOC/P, **not** a constant of nature. Say so in the roxygen block.
  - `x0` defaults to the sample mean but must be overridable, so a user can centre on an external
    reference value instead (see Phase 6).
  - Handle `NA` (`na.rm`), zero and negative `x` (a negative base with a fractional exponent is
    `NaN` in R — document and guard; suggest shifting or using `score_threshold()` instead).
- [ ] **1.2 Sanity tests.** `direction="higher"` → S increases monotonically with x, S→1 as x≫x0,
  S→0 as x→0; `direction="lower"` → the mirror; `S(x0) == 0.5` exactly for both directions;
  output always in [0,1].
- [ ] **1.3 Wire into `score_indicators()`** as a selectable method, without changing existing
  behaviour (default must stay whatever it is today).
- [ ] **1.4 Document the linear/non-linear choice honestly.** The literature **contradicts itself**:
  Yuan 2026 finds NL > L (fit R² 0.65 vs 0.56); Bilgili et al. 2017 — cited *inside Yuan's own
  introduction* — finds L > NL. Add a vignette note recommending **computing both** and reporting
  whether conclusions change.

### Phase 2 — Area aggregation, with the reference-soil ratio ⭐
**Why:** gives the package a **weight-free** aggregation route, sidestepping the most contested step
in the pipeline. See Phase 3's rationale for why weights are contested.

- [ ] **2.1 Implement `sqi_area()`.**
  ```
  Area = 0.5 * sum(stP_i^2) * sin(2*pi / n)
  ```
  Source: **Kuzyakov et al. 2020, eq. (2)** (Front. Agr. Sci. Eng. 7(3):282–288,
  doi 10.15302/J-FASE-2020338). Verified against the original PDF.
  ```r
  sqi_area <- function(s, reference = NULL) {
    a <- 0.5 * sum(s^2) * sin(2 * pi / length(s))
    if (is.null(reference)) return(a)
    a / (0.5 * sum(reference^2) * sin(2 * pi / length(reference)))
  }
  ```
  - ⚠️ **It is the SQUARE of each parameter, not the product of adjacent radii.** The true polygon
    area would be `sum(s_i * s_{i+1})`, which makes the result depend on the arbitrary **order** of
    indicators around the diagram. Kuzyakov's square form is an approximation of "the sum of
    individual triangles" that is **order-independent**. Implement the square. Document this note —
    a reviewer will ask.
  - ⚠️ **As designed it is a RATIO.** Kuzyakov standardises against a **non-degraded reference soil**
    (reference = 1.0) and reports `Area_degraded / Area_non_degraded`; the worked figure gives
    **0.47** = "half the function lost". *"Comparison with non-degraded soil is required."*
- [ ] **2.2 Document the two uses and their consequence.** The weight-independence people cite is a
  consequence of **taking a ratio**, not a property of the formula.

  | Use | Standardised against | Comparable across studies? |
  |---|---|---|
  | Absolute (`reference = NULL`) | your own sample | **no** |
  | Ratio (`reference = <ref soil>`) | a non-degraded reference soil | **claimed yes** |

- [ ] **2.3 Tests.** Area is invariant to the order of `s` (this is the point of the square form);
  all-1.0 scores give the maximum area for that `n`; ratio of a vector with itself is exactly 1;
  ratio < 1 for a uniformly degraded vector.
- [ ] **2.4 Add `n`-dependence warning.** Kuzyakov notes total area depends slightly on `n`, but the
  *ratio* does not. Warn if `length(s) != length(reference)`.
- [ ] **2.5 Wire into `compute_sqi_properties()`** as `method = c("weighted", "area")`, default
  unchanged.

### Phase 3 — Validation ⭐ the biggest gap in the package *and* the field
**Why:** an SQI has **no ground truth**. Nothing in `soilquality` — or in most of the literature —
answers "does this index actually work?". This is where the package can lead rather than follow.

- [ ] **3.1 Implement `sqi_validate()`** returning a structured object with:
  - **Sensitivity index** `SI = max(SQI) / min(SQI)`. Source: **Yuan 2026**, after Rezaee et al.
    Yuan's observed ranges: Area 1.12–2.92, weighted 1.14–1.82, NL 1.21–2.92, L 1.14–2.49,
    NA 1.30–2.92, PCA 1.14–2.72.
  - **Fidelity to the total data set**: R² of `lm(sqi_mds ~ sqi_tds)`. Source: **Yuan 2026**.
    ⚠️ Document that the TDS index is **not ground truth** — it is just the index with everything in
    it. High fidelity means *faithful to your full measurement set*, not *correct*.
  - ⭐ **Quantile distribution** — the count of samples falling in each of the
    **0–20 / 20–40 / 40–60 / 60–80 / 80–100 %** bands of the empirical CDF (`ecdf()` then `cut()`).
    These are the conventional "very low → very high" soil-health categories (CSHT convention, used
    by **Maaz 2023**).
  - **External criterion** (optional): correlation with a supplied vector (yield, a known contrast).
    Source: **Theresa 2026** validates against four seasons of rice yield.
- [ ] **3.2 Make the distribution the headline.** This is the corpus's strongest methodological
  finding and it must not be buried. **Maaz 2023**: an SEM index and an additive index correlated at
  **r = 0.96** — apparent agreement — yet the additive index put **94 %** of plots in the middle
  20–80 % band versus **61 %** for SEM. **Correlation is the wrong diagnostic for an index; the
  distribution across decision categories is the right one.** An index that calls everything
  "medium" cannot inform a decision.
  - The print/summary method should surface the middle-band share prominently and **warn above a
    documented threshold** (suggest > 80 %).
- [ ] **3.3 Implement `sqi_stability()`** ⚠️ *(named to avoid `SQIpro::sqi_compare()`; see the
  collision note above — and the test is genuinely different, not just the name)* — run the same data
  through ≥ 2 recipes (e.g. linear vs
  sigmoid, weighted vs area) and report whether the **ranking of samples/groups** survives
  (Spearman rank correlation + a flag when the top/bottom group changes). Source: **Yuan 2026**
  found EMDS achieved fit R² 0.74–0.77 with *no p > 0.05 across any scoring/aggregation
  combination* — i.e. it was **stable**, not merely accurate.
- [ ] **3.4 Extend `plot_sqi_report()`** with the quantile-distribution plot, or add
  `plot_sqi_validation()`.

### Phase 4 — Network-analysis MDS selection
**Why:** **Yuan 2026** measured that it **beats PCA** — better fidelity (R² 0.63 vs 0.58), higher
sensitivity (SI 1.30–2.92 vs 1.14–2.72), selects **fewer** indicators, and makes **no normality
assumption**. It also selects on a different principle: PCA favours **variance**, network analysis
favours **centrality** (ecological hubs).

- [ ] **4.1 Add `igraph` to `Imports`** in `DESCRIPTION` (GPL-2+, compatible with GPL-3).
- [ ] **4.2 Implement `na_select_mds()`** following Yuan 2026 §2.3.2 **exactly**:
  1. Correlation network: nodes = indicators; edge where **Spearman |r| ≥ 0.60 and p < 0.01**.
  2. Communities by **Louvain/Blondel** modularity — `igraph::cluster_louvain()`
     (Blondel et al. 2008).
  3. Keep only modules whose **maximum eigenvector centrality > 0.6** —
     `igraph::eigen_centrality()`. (Yuan states this is the analogue of retaining PCs that explain
     ≥ 5 % of variance.)
  4. Within each kept module, retain indicators **within 10 % of the maximum centrality**
     (i.e. `centrality >= 0.9 * max(centrality)`).
  5. Break ties by highest **weighted degree** — `igraph::strength()`.
  6. Screen surviving correlated indicators as in the PCA route.
  7. **Weights** = eigenvector centrality / sum of centralities within the module.
  ```r
  na_select_mds <- function(data, r_min = 0.60, p_max = 0.01,
                            centrality_min = 0.6, within = 0.10) { ... }
  ```
  All four thresholds must be parameters with these defaults.
- [ ] **4.3 Return the same shape as `pca_select_mds()`** so the two are drop-in interchangeable
  downstream.
- [ ] **4.4 Implement `mds_consensus()`** — run both routes and return the **intersection**. Cheap,
  underused robustness check: on Yuan's 40-year tillage data, **SOC, dissolved organic carbon and
  soil compaction** were selected by **all six** MDS variants.
- [ ] **4.5 Document the caveat.** Correlation networks **cannot establish causality**, and shared
  environmental drivers create **spurious edges** (Yuan cites Connor et al. 2017; Deutschmann et al.
  2021). Yuan recommends verifying with random forest or SEM.

### Phase 5 — Functional (EMDS) grouping
**Why:** **Yuan 2026** found fidelity improved monotonically with grouping detail —
**EMDS (R² 0.77 / 0.74) > RMDS > ungrouped MDS** — and EMDS was the most **stable** choice. And
**Maaz 2023** found by confirmatory factor analysis that the physical/chemical/biological split has
**no statistical support**. Two methods, two continents, same verdict: group by **function**.

- [ ] **5.1 Add a `groups =` argument** to `pca_select_mds()` and `na_select_mds()` — select within
  each group rather than across the whole pool. Must default to `NULL` (current behaviour).
- [ ] **5.2 Ship the five-function default grouping** as exported data, per Yuan (after Li et al. 2023):
  **carbon cycling · nutrient cycling · physical structure stability · buffering and filtration
  capacity · soil biodiversity maintenance**. Provide a mapping helper for the common indicator names
  already in `soil_property_sets`.
- [ ] **5.3 Implement the norm-value selector** for the grouped PCA route — pick the indicator with
  the highest **norm value** per group:
  ```
  N_ik = sqrt( sum( u_ik^2 * lambda_k ) )
  ```
  where `u_ik` is the loading of indicator *i* on PC *k* and `lambda_k` the eigenvalue of PC *k*,
  summed over the PCs with eigenvalue ≥ 1. Source: **Yuan 2026 eq. (2)**.
- [ ] **5.4 Document why not to group by physical/chemical/biological**, citing Maaz's CFA result.

### Phase 6 — Reference-soil standardisation
**Why:** it is the **only documented escape from SQI incomparability**. Scoring against your own
sample extremes makes the best site score ≈ 1.0 by construction, which is why published SQI values
cannot be compared across studies.

- [ ] **6.1 Implement `standardize_to_reference()`.** Standardise each indicator against the same
  indicator measured in a **non-degraded reference soil** (reference = 1.0, values decrease toward
  0). Source: **Kuzyakov 2020**.
  - **more is better** (default) → reference gets the maximum
  - **less is better** (e.g. bulk density) → the **minimum** is assigned to the undisturbed soil
  - **optimum** (pH, water/air permeability, hydrophobicity) → use the **difference from the
    optimum**, not a monotone scale
- [ ] **6.2 Wire it as an option throughout** the scoring functions (an alternative to sample-relative
  `X/X_max`), and document the trade-off: comparability in exchange for **needing a defensible
  non-degraded reference soil** — which Kuzyakov calls the approach's key disadvantage, and which a
  fully converted landscape often lacks.
- [ ] **6.3 (Optional) Implement `sensitivity_resistance()`.** Kuzyakov's under-used second approach:
  plot each parameter's standardised change against the **SOC** change. On the 1:1 identity line the
  parameter degrades at SOC's rate; **faster = sensitive**, **slower = resistant**. Generally
  (micro)biological properties are sensitive, physical properties resistant. ⚠️ Kuzyakov reports it
  separated cleanly on a Luvic Phaeozem but **not** on a Calcic Chernozem — document the limitation.

### Phase 7 — Documentation, vignette, correctness fixes
- [ ] **7.1 ⚠️ Document the `loading_threshold` rule explicitly** in `pca_select_mds()`: it implements
  **"within 10 % of the maximum loading"**, i.e. `|loading| >= 0.9 * max(|loading|)`.
  **Yuan 2026 §2.3.1 states this rule INVERTED** (`"< 10 % of the highest loading"`), which would
  select the *least* informative variables; Yuan's own §2.3.2 and every other paper state it
  correctly. Anyone implementing from that paper alone will get it backwards. This doc note is
  five minutes and prevents a real error.
- [ ] **7.2 Add PCA adequacy testing** to `pca_select_mds()` — **KMO** and **Bartlett's sphericity**,
  reported (and optionally enforced). Most papers skip it; **Theresa 2026** does not
  (KMO 0.81, Bartlett χ² 425.37, df 136, p < 0.001).
- [ ] **7.3 Write the main vignette** — "Building and validating a Soil Quality Index" — walking the
  full pipeline: select (PCA | network | expert) → group by function → score (linear | sigmoid |
  optimum) → weight (AHP | loading | centrality | none) → aggregate (weighted | area) → **validate**.
- [ ] **7.4 Add the "don't chain predictions" warning** wherever the docs touch predicted inputs.
  **Chaudhry 2024**: computing an SQI from *predicted* properties gave **R² = 0.23**; predicting the
  index *directly* gave **R² = 0.90** — on the same spectra, with individually acceptable property
  models (Cubist R² 0.35–0.93). If a user feeds predicted properties into `compute_sqi_properties()`,
  the resulting index is far less reliable than its inputs.
- [ ] **7.5 Update README** with the new routes and a decision table.
- [ ] **7.6 `R CMD check --as-cran`** clean; bump version; NEWS.md entry per phase.

---

## Open decisions (these tailor the tasks)
0. ⭐ **What does Task 0.4 find?** Every priority in this plan is provisional until the overlap with
   `SQIpro` is verified against its function reference. If it turns out to implement the area method
   or reference-soil standardisation, this plan needs re-cutting.
1. **Does `soil_property_sets` already carry indicator→function mappings?** If not, Task 5.2 needs a
   curation pass — decide whether to ship an opinionated default or require the user to supply it.
2. **`igraph` as `Imports` or `Suggests`?** `Imports` is simpler; `Suggests` keeps the dependency
   footprint light and makes Phase 4 optional at load time. Recommend **Imports** unless CRAN
   footprint is a concern.
3. **Should `sqi_validate()` hard-warn or just report** when the middle-band share exceeds the
   threshold? Recommend a **warning** — a silent number will be ignored.
4. **Scope of Phase 6.3** (`sensitivity_resistance()`) — genuinely useful but the least-used method
   in the corpus. Defer if time is short.

## Risks & mitigations
| Risk | Mitigation |
|---|---|
| Breaking the existing API | Task 0.2's regression baseline; every new behaviour behind a new argument with the current default |
| Implementing a formula from memory | The carry-over kit; every equation stated inline with paper + equation number |
| The `s²` vs `sᵢ·sᵢ₊₁` area trap | Settled against the original PDF: **use the square**. Test for order-invariance (2.3) |
| Inverting the "within 10 %" loading rule | Task 7.1 documents it; add a unit test asserting the selected set on a fixture |
| Validation functions that nobody uses | Make the quantile distribution the headline of the print method (3.2), not an optional extra |
| **Rebuilding what `SQIpro` already ships** | Task 0.4 verifies overlap **before** code is written; the priority table demotes parity work |
| **Positioning drifting back to "general SQI calculator"** | Task 0.5 fixes the line in README/DESCRIPTION; differentiators named explicitly |
| Over-claiming comparability | Task 2.2's table states plainly which mode is comparable and which is not |

## Progress log
- **2026-08-08** — Plan created from [[skills-forge/soil-quality-index/SKILL]] after ingesting the
  11-paper SQI corpus plus [[sources/2020-kuzyakov-sqi-area-degradation|Kuzyakov 2020]]. Not started.

## Provenance
Executes [[skills-forge/soil-quality-index/SKILL]]. Key sources — full citations in the wiki:
[[sources/2026-yuan-shi-mds-methods-comparison|Yuan 2026]] (scoring, aggregation, MDS routes, EMDS,
validation), [[sources/2020-kuzyakov-sqi-area-degradation|Kuzyakov 2020]] (area formula + ratio
design + reference standardisation + sensitivity/resistance),
[[sources/2023-maaz-sem-soil-health|Maaz 2023]] (validation by distribution; functional grouping),
[[sources/2024-chaudhry-sqi-three-methods|Chaudhry 2024]] (non-linear scoring; the chaining trap),
[[sources/2025-huera-lucero-land-use-sqi-amazon|Huera-Lucero 2025]] (PCA-MDS reference implementation),
[[sources/2026-theresa-rice-fertilization-sqi|Theresa 2026]] (KMO/Bartlett; yield validation).
Method pages: [[methods/minimum-dataset-construction]], [[methods/soil-indicator-scoring]],
[[methods/sqi-aggregation]], [[methods/sqi-validation]]. Tool page: [[entities/soilquality]].
