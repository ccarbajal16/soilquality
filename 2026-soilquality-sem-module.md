# soilquality — SEM module for SQI construction and explanation

> **Executes:** \[\[skills-forge/soil-quality-index/SKILL\]\] §6 ·
> **Repo:** `github.com/ccarbajal16/soilquality` · **Status:** planning
> Companion to \[\[projects/2026-soilquality-package-upgrade\]\]. **Do
> that one first** — this module depends on its Phase 3
> ([`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md))
> and Phase 5 (functional grouping).

------------------------------------------------------------------------

## ⚠️ SECOND REVISION, 2026-08-08 — the scoping rule that overrides the task list below

**A survey of CRAN found no package doing SQI + SEM — but `lavaan`,
`piecewiseSEM` and `plspm` are mature, maintained by statisticians, and
generic. Wrapping them buys nothing and costs maintenance plus version
coupling.** After the human’s decision to position `soilquality` as *the
sharp research tool for the methods the corpus showed are missing* (see
\[\[projects/2026-soilquality-package-upgrade\]\]), the scope narrows
sharply.

### The rule

> **Does the function need to know what an SQI is?** **Yes → build it in
> `soilquality`. No → it is a vignette, not a function.**

### ✅ Non-overlap verified 2026-08-08

Checked against `SQIpro`’s **actual function index** (25 exported
functions, via rdrr.io): `score_*`, `select_mds`,
`sqi_linear/regression/pca/fuzzy/entropy/topsis/compare`, `sqi_anova`,
`sqi_sensitivity`, `validate_data`, six `plot_*`, `make_config`,
`soil_data`.

**It contains no path modelling, no SEM, no CFA, and no
inherent-property adjustment of any kind.** The `SQI` package (Wani et
al.) is a strict subset of that. `soilassessment` is a different scope
(crop suitability, erosion, salinization, groundwater recharge).

So all three surviving functions are **genuinely novel** in the R
ecosystem:

| Function | Overlap found | Why nothing else has it |
|----|----|----|
| **[`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)** | **none** ⭐ | sits exactly in the gap: SEM packages don’t know what an SQI is; SQI packages don’t do path models |
| **`adjust_inherent()`** | **none** | it is [`lm()`](https://rdrr.io/r/stats/lm.html) residuals — the novelty is the *framing* (adjust for soil type × land-use history **before** scoring), not the arithmetic |
| **`weights_from_cfa()`** | **none** | nobody connects `lavaan` loadings to SQI weights, because nobody has both halves |

⚠️ Honest caveat on `adjust_inherent()`: a reviewer can fairly say
*“that’s just residuals”*. Its value is being an opinionated,
documented, correctly-defaulted step in an SQI pipeline
(`method = "none"` by default, so adjusting is deliberate). Do not
oversell it as a new method — sell it as the step
\[\[sources/2023-maaz-sem-soil-health\|Maaz\]\] showed matters and that
**no additive-index paper in the corpus performs**.

Applied to the task list below:

| Task | Needs SQI knowledge? | Verdict |
|----|----|----|
| **C2 [`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)** | **yes** — needs the indicators that *constructed* the index | ✅ **BUILD** ⭐ |
| **B `adjust_inherent()`** | **yes** — a pre-scoring step of the SQI pipeline | ✅ **BUILD** ⭐ |
| **D3 `weights_from_cfa()`** | **yes** — the loadings → SQI-weights bridge | ✅ **BUILD** |
| **A `sqi_diagnose()` / `sqi_icc()`** | partly — aggregates `psych::KMO()`, `cortest.bartlett()`, `performance::icc()` into one SQI-context verdict | 🟡 **build thin**, or fold into the vignette |
| **C0 route selector** | no — a decision table | 🟡 **vignette** (or a tiny helper) |
| **C1 `sqi_paths()`** (piecewiseSEM) | no | ❌ **VIGNETTE — do not wrap** |
| **C3 `effect_decomposition()`** | no — `piecewiseSEM` does it | ❌ **VIGNETTE** |
| **C6 `sqi_plspm()`** | no | ❌ **VIGNETTE — do not wrap** |
| **D1/D2 `sqi_cfa()` + fit table** | no | ❌ **VIGNETTE — do not wrap** |

**Net effect: ~15 tasks collapse to 3 functions plus one vignette.**
Those three are the ones no SEM package can ever have, because no SEM
package knows what a soil quality index is.

⚠️ **The detailed tasks below are retained as the specification for the
vignette** — the equations, thresholds and pitfalls are all still
correct and still worth documenting. **Read them as “what the vignette
must teach”, not “what to implement”, except for B, C2 and D3.**

------------------------------------------------------------------------

## Feasibility verdict (first pass — superseded in scope by the rule above, retained for its analysis)

**Yes — but only three of the four things people mean by “SEM for SQI”
are worth building, and one of them must be built as a *guard rail*, not
a feature.**

| Candidate | Feasible? | Verdict |
|----|----|----|
| **A. Pre-flight diagnostics** (is SEM even applicable to this dataset?) | trivial | ✅**Build first.** Highest value, lowest risk. Protects every user from the failure modes below. |
| **B. Inherent-property adjustment** (Maaz’s score correction) | trivial — it is[`lm()`](https://rdrr.io/r/stats/lm.html) residuals, **no SEM needed** | ✅**Build.** Comes from the SEM paper but needs none of the machinery. Best value/effort ratio in the whole module. |
| **C. Path models to *explain* an index** (what drives SQI?) | moderate | ✅**Build, with a circularity guard.** Three corpus papers do it, across three sample-size regimes. |
| **D. SEM *as* the index** (CFA → latent factors → second-order score) | moderate | ⚠️**Build, but gate it hard on sample size.** Only a minority of users will qualify. |
| **D′. PLS-PM path models** (`plspm`) | moderate | ✅**Build — this is the route most of your users can actually run.** Added 2026-08-08; see below. |
| **E. Reimplementing SEM estimation** | — | ❌**Never.** `lavaan`, `piecewiseSEM` and `plspm` are mature. Wrap thin; add the *soil workflow*, not the statistics. |

### ⚠️ Revision, 2026-08-08 — “SEM” names three estimators, not one

The first version of this evaluation treated SEM as a single method and
concluded that small-n users were largely excluded. **That was wrong**,
and checking what \[\[sources/2025-wang-loess-vegetation-sqi-sem\|Wang
2025\]\] actually ran exposed it: Wang’s methods section states *“SEM
was performed via R 4.4.2. The R package was constructed with the PLS-PM
package”* (citing Tenenhaus et al. 2005; Lohmöller 1989). **PLS-PM is
variance-based path modelling built for small samples** — for eight
plots it is arguably the *correct* choice, not a compromise.

The corpus therefore spans **three** estimators covering three
sample-size regimes:

|  | **CB-SEM** (`lavaan`) | **Piecewise SEM** (`piecewiseSEM`) | **PLS-PM** (`plspm`) |
|----|----|----|----|
| Paper | Maaz (n = 567) | Sarapatka (n = 60) | Wang (8 plots) |
| Latent variables | yes, reflective | no — observed only | composites, reflective**or formative** |
| Random effects | limited | **native, per equation** | no |
| Sample size | **hundreds** | modest | **small** |
| Fit statistic | CFI, RMSEA, SRMR | **Fisher’s C** (p \> 0.05 = good) | **GoF, R², AVE, composite reliability** |

⚠️ **Never report CFI/RMSEA/SRMR for PLS-PM** — they do not exist for
it. Report GoF, R² per endogenous construct, composite reliability/AVE
for reflective blocks, and **bootstrap CIs** on the path coefficients.
(Wang reports none of these; that is the fair criticism of the paper,
not the absence of covariance-fit indices.)

**Consequence for this module:** Task C is no longer a single wrapper.
It becomes a **route-selection layer** (Task C0) plus two backends, so a
user with 30 samples gets PLS-PM instead of a refusal.

### The three obstacles that shape everything below

**1. Sample size — the binding constraint.**
\[\[sources/2023-maaz-sem-soil-health\|Maaz\]\] used **n = 567** across
145 plots to fit a 10-indicator CFA with a second-order factor. Typical
`soilquality` users are nowhere near that:
\[\[sources/2025-supriyadi-sfi-community-forest\|Supriyadi\]\] n = 25,
\[\[sources/2026-sarapatka-erosion-sqi-sem\|Sarapatka\]\] n = 60,
\[\[sources/2025-huera-lucero-land-use-sqi-amazon\|Huera-Lucero\]\]
small plot design. Standard SEM practice puts CFA out of reach below
roughly n = 200, or an N : free-parameter ratio under ~10:1. **A package
that lets a user run CFA on 30 samples is shipping a footgun.** Hence
Task A.

⚠️ **But this constrains CB-SEM specifically, not path modelling in
general** — see the revision above. At small n the answer is **PLS-PM**,
not refusal. What \[\[sources/2025-wang-loess-vegetation-sqi-sem\|Wang
2025\]\] genuinely illustrates is a *reporting* failure, not a method
failure: it ran an appropriate estimator for its n and then published
**no PLS-PM diagnostics at all** — no GoF, no R² per construct, no AVE,
no bootstrap CIs. Do not let the package produce that (Task C6).

**2. Circularity — the trap that will otherwise be shipped as a
feature.** If the SQI is a weighted sum of SOC, TN, HA/FA and enzymes,
then regressing SQI on SOC, TN, HA/FA and enzymes **must** fit well.
\[\[sources/2026-sarapatka-erosion-sqi-sem\|Sarapatka’s\]\] SQI equation
reached **R² = 0.99**, which is largely structural — the authors
themselves flag “the methodological dependence of SQI on its own
components”. \[\[sources/2025-wang-loess-vegetation-sqi-sem\|Wang’s\]\]
“SOC positively affects soil quality in every vegetation pattern” has
the same problem: SOC is an input to the index.

A naive `sqi_sem()` that accepts any predictors would let users publish
this by accident. **The package must detect the overlap and refuse or
loudly warn.** That guard (Task C2) is arguably the single most valuable
thing in this module, because no other tool does it.

**3. Scope — this is an SQI package, not an SEM package.** The value
added is the **soil-specific workflow**: which model to specify, which
fit indices to report, how to turn loadings into weights, how to avoid
circularity. Not estimation. Every function below is a thin wrapper that
returns the underlying `lavaan` / `piecewiseSEM` / `plspm` object so
users can go deeper.

------------------------------------------------------------------------

## Objective

Add a **thin, guarded path-modelling layer** to `soilquality` that (a)
tells the user which estimator — if any — their data can support, (b)
corrects indicator scores for inherent soil properties, (c) explains
what drives an SQI without falling into circularity, using the estimator
that fits their sample size, and (d) derives weights from a latent
measurement model when — and only when — sample size permits.

## Scope

- **In scope:** feasibility diagnostics; inherent-property adjustment; a
  **route selector** across the three path-modelling estimators; driver
  wrappers for **piecewise SEM** and **PLS-PM**, both behind a
  circularity guard; a CFA wrapper that emits loadings-as-weights and a
  fit table.
- **Out of scope (non-goals):** implementing estimators; automatic model
  specification/search (dangerous and indefensible); Bayesian SEM;
  spatial SEM; teaching SEM in the docs beyond what is needed to use the
  functions safely.
- **First slice (revised):** **Task B (`adjust_inherent()`) + Task C2
  ([`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)).**
  These two pass the scoping rule most cleanly, need no SEM dependency
  at all, and exist nowhere else. Task A follows only if it earns its
  place. Neither requires `lavaan` or `plspm`. Together they deliver
  most of the practical value of
  \[\[sources/2023-maaz-sem-soil-health\|Maaz\]\] to users with ordinary
  sample sizes, and they make the later tasks safe.

## ⚠️ The implementing agent has no wiki

As in the companion project, every threshold, formula and citation is
stated **inline**. Do not paraphrase from memory.

### Carry-over kit

| File in`Soil_skill/raw/papers/` | What it grounds |
|----|----|
| `Maaz_2023.pdf` | CFA → second-order factor; fit thresholds; omega reliability; ICC/clustering; inherent-property adjustment;`ecdf` scoring |
| `Sarapatka_2026.pdf` | piecewise SEM; d-separation; Fisher’s C; direct/indirect decomposition;**the circularity admission** |
| `Wang_2025.pdf` | **PLS-PM** as the small-n route (§Methods names the package); and what PLS-PM diagnostics look like when they are *missing* |
| `Yuan_2026.pdf` | why RF/SEM are recommended to verify correlation-network structure |

------------------------------------------------------------------------

## Data & assumptions

- ⚠️ Assumes \[\[projects/2026-soilquality-package-upgrade\]\] Phase 3
  ([`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md))
  exists — Task D4 reuses its quantile-distribution reporting.
- ⚠️ Assumes the package can add `lavaan` (GPL ≥ 2), `piecewiseSEM`
  (GPL-3) and **`plspm` (GPL-3)** — all CRAN, all licence-compatible
  with GPL-3. `semTools` (GPL ≥ 2) for reliability; `lme4` for ICC.
- ⚠️ Assumes users can supply **cluster/plot identifiers** and
  **inherent factors** (soil type, land-use history) as columns. If
  typical input data lacks them, Tasks A3 and B degrade to warnings.

------------------------------------------------------------------------

## Task breakdown

### Task A — Pre-flight diagnostics ⭐ build first

**Why:** stops the two failure modes above before they happen, and is
useful even to users who never run SEM.

**A1 Implement `sqi_diagnose()`** returning a structured feasibility
report:

- **n**, number of indicators, and the **N : indicator ratio**. Flag
  against documented heuristics (CFA generally unstable below ~n = 200;
  N:free-parameter ratio ≥ 10:1). State these as *heuristics*, not hard
  law, and cite that \[\[sources/2023-maaz-sem-soil-health\|Maaz\]\]
  used n = 567 for 10 indicators.
- **Factorability**: **Kaiser–Meyer–Olkin** and **Bartlett’s test of
  sphericity**. Both are used by Maaz and by
  \[\[sources/2026-theresa-rice-fertilization-sqi\|Theresa\]\] (KMO
  0.81; Bartlett χ² = 425.37, df = 136, p \< 0.001). Conventional KMO
  reading: \< 0.5 unacceptable, ≥ 0.8 meritorious.
- **Normality** per indicator (Shapiro–Wilk), with a note that Box–Cox
  is the corpus’s remedy (Maaz Box–Cox-transformed everything, then
  mean-centred and standardised).
- **A verdict object** with three levels: `ok` / `marginal` /
  `not-recommended`, plus the reasons.

**A2 Gate the SEM functions on it.** `sqi_cfa()` (Task D) must call
`sqi_diagnose()` and **refuse by default** on `not-recommended`,
overridable with an explicit `force = TRUE` that emits a warning naming
the reason.

**A3 Implement `sqi_icc()`** — intraclass correlation per indicator
given a cluster column (`lme4::lmer(indicator ~ 1 + (1|cluster))`, ICC =
between / (between + within)). **Why it matters:**
\[\[sources/2023-maaz-sem-soil-health\|Maaz\]\] found **ICC \> 75 % for
every indicator** — samples within a plot were not independent. Most
soil campaigns composite or sub-sample within plots and never check.
High ICC invalidates ordinary standard errors.

- Report a plain-language recommendation: high ICC → use cluster-robust
  SEs or a multilevel model (both routes agreed at r = 0.96 in Maaz),
  and report the **plot-level average**.

**A4 Tests + vignette section** “Is my dataset suitable for SEM?”.

### Task B — Inherent-property adjustment ⭐ best value/effort in the module

**Why:** a soil should not be scored down for being what its parent
material made it. This is
\[\[sources/2023-maaz-sem-soil-health\|Maaz’s\]\] most stealable idea
and **it needs no SEM at all** — it is a regression residual. None of
the additive-index papers in the corpus do it.

**B1 Implement `adjust_inherent()`.**

``` r

adjust_inherent(data, indicators,
                inherent = ~ soil_type * land_use_history,
                method = c("residual", "none"))
```

Regress each indicator on the inherent factors and return the
**residuals** (recentred on the indicator mean so scoring functions
still behave), plus the fitted models for inspection. Source: **Maaz
2023** — *“we developed scoring health functions that account for these
factors to prevent their bias on the overall score”*; land-use history
and soil type were the two most influential inherent drivers in their
region (Crow et al. 2022).

**B2 Report what the adjustment cost.** For each indicator, the R² of
the inherent model — i.e. how much of its variation was inheritance
rather than management. This is genuinely informative output, not
diagnostics padding.

**B3 Document the judgement call.** Adjusting removes inherent variation
*by design*. If the user’s question **is** “which soils are inherently
better?”, they must not adjust. Make the default `method = "none"` so
adjustment is always a deliberate act.

**B4 Wire as an optional pre-scoring step** in the main pipeline; tests
on a fixture with a synthetic soil-type effect (adjustment should remove
a known injected group difference).

### Task C — Path models to explain an index + the circularity guard

**Why:** three corpus papers do this, it works across the whole
sample-size range once the right estimator is chosen, and it answers the
question an index alone cannot: *what is driving this?*

**C0 Implement `sqi_path_route()` — the route selector.** Given n, the
number of constructs, whether the design is nested (a cluster column),
and whether the user wants latent variables, recommend one of
**`plspm`** / **`piecewiseSEM`** / **`lavaan`** and say why. This is the
function that keeps a small-n user from being turned away, and keeps a
nested design from being fitted without random effects. Reuse
`sqi_diagnose()` (Task A) for the n verdict.

**C1 Implement `sqi_paths()`** — a thin wrapper over
`piecewiseSEM::psem()`.

``` r

sqi_paths(data, sqi_col, model_list, random = NULL)
```

- Fit each structural equation (allowing `lme4` random effects per
  equation — this is *the* reason to use piecewiseSEM over lavaan for
  nested field designs).
- Return **Fisher’s C** with its p-value and the explicit reminder that
  **p \> 0.05 indicates good fit** (the opposite convention to a
  significance test — a *non*-significant C is what you want).
- Return **standardised path coefficients (β)**, marginal and
  conditional R² per equation.
- Report **d-separation** results so the user can see which missing
  paths are implied. Source: **Sarapatka 2026** (after Lefcheck 2016),
  whose five-equation model with a shared random site effect is the
  template.

**C2 ✅ DONE —
[`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)
shipped in v2.1.0, exported, no dependencies.** Given the indicator set
that **built** the SQI and the predictors of the SQI in the path model,
detect any overlap.

- **Default behaviour: refuse**, with a message naming the offending
  variables and explaining why (regressing an index on its own
  components must fit well; the R² is structural, not predictive).
- Allow `allow_components = TRUE` for the legitimate use —
  **decomposition**, i.e. “which component dominates this index?” — but
  then force the output to be **labelled as a decomposition** and
  **suppress the R²** from the summary.
- Source: **Sarapatka 2026** reached **R² = 0.99** this way; the authors
  flag “the methodological dependence of SQI on its own components” as
  the cause of their initial model’s poor global fit. ⚠️ **This is the
  highest-value item in the module.** No other tool checks it, and both
  corpus papers that use SEM this way fell into it.

**C3 Implement `effect_decomposition()`** — multiply standardised
coefficients along each path to split **total = direct + indirect**.
Sarapatka’s headline (**95 % of erosion’s effect on SQI was indirect**,
mediated by the HA/FA ratio) is only obtainable this way.

**C4 Guidance in docs:** paths from variables **outside** the index
carry real information; component→index paths are decomposition. Start
with fewer paths than you want — Sarapatka’s initial five-block model
was over-parameterised and failed Fisher’s C (p \< 0.001).

**C5 Transformation helpers.** Standardise (z-score) before interpreting
β; log-transform right-skewed drivers first (Sarapatka used `log(g + 1)`
on USLE erosion loss).

**C6 ⭐ Implement `sqi_plspm()` — the small-n backend.** Thin wrapper
over `plspm::plspm()`. Source: **Wang 2025** (via Tenenhaus et al. 2005;
Lohmöller 1989). **This is the route most `soilquality` users can
actually run.**

- Accept an inner path matrix, an outer block list, and **`modes`**
  (`"A"` reflective / `"B"` formative) — the reflective-vs-formative
  choice is the one PLS-PM decision that most changes the answer, so
  surface it rather than defaulting silently.
- Return, and require reporting of, the **PLS-PM-appropriate
  diagnostics**: **GoF**, **R² per endogenous construct**, **composite
  reliability (Dillon–Goldstein ρ) and AVE** for reflective blocks,
  cross-loadings, and **bootstrap confidence intervals** on the path
  coefficients (`plspm(..., boot.val = TRUE, br = 500)` or higher).
- ⚠️ **The summary method must NOT print CFI/RMSEA/SRMR** and should say
  plainly that those do not exist for PLS-PM. Wang’s paper reports no
  PLS-PM diagnostics at all — the package should make that omission
  impossible.
- [`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)
  (C2) applies here **unchanged, and matters more**: PLS-PM is *more*
  permissive than CB-SEM and will happily fit a composite against its
  own constituents.
- ⚠️ PLS-PM has **no random effects**. If `sqi_icc()` (A3) flags
  clustering, warn that PLS-PM cannot absorb it and point to
  `piecewiseSEM` instead.

### Task D — SEM as the index (CFA measurement model), gated

**Why:** it produces weights **from the data** rather than from
assertion, and it discriminates about twice as well as an additive
index. But it is the highest-data, highest-expertise route.

**D1 Implement `sqi_cfa()`** — wrapper over `lavaan::cfa()`.

- Default estimator **`"MLR"`** (maximum likelihood with robust
  Huber–White SEs), as Maaz used.
- Support a `cluster =` argument (cluster-robust) and a `level =` route
  (multilevel), matching the two options Maaz presents; they agreed at
  **r = 0.96**.
- Support a **second-order factor** for “overall soil quality” — this is
  what yields a single score.
- **Must call `sqi_diagnose()` first** (Task A2).

**D2 Return a fit table with the thresholds pre-applied** (Hu & Bentler
1999, as used by Maaz):

| Statistic | Threshold | Maaz achieved |
|----|----|----|
| CFI | \> 0.95 | 0.998 |
| SRMR | \< 0.08 | 0.007 |
| RMSEA | \< 0.06 | 0.035 |
| coefficient omega ω | \> 0.7 | 0.91 (2nd order); 0.92 / 0.77 / 0.90 (factors) |
| χ²/df (supplementary, complex models) | \< 4–5 | 3.7 (multilevel) |

⚠️ **Report omega, not Cronbach’s α** — omega is unbiased for congeneric
items with uncorrelated errors (Maaz cites Hancock & An 2020; Raykov
1997; Yang & Green 2011). Use `semTools::reliability()`.

**D3 Implement `weights_from_cfa()`** — extract standardised loadings as
indicator weights and return them in the shape
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
already accepts. This is the bridge that makes the module pay off:
**latent weights feeding the existing pipeline**. → resolves part of the
open question on weighting objectivity.

**D4 Score to an index** — convert factor scores with
[`ecdf()`](https://rdrr.io/r/stats/ecdf.html), then cut at the
conventional **0–20 / 20–40 / 40–60 / 60–80 / 80–100 %** quantiles (very
low → very high). Reuse the quantile-distribution reporting from
[`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
(\[\[projects/2026-soilquality-package-upgrade\]\] Phase 3).

**D5 Surface the practical warnings** in the summary method:

- Latent variables are hostage to the indicators chosen — “soil health”
  here means whatever these measurements jointly capture.
- Post-hoc modifications (freeing covariances at **MI \> 20**, variance
  constraints to avoid **Heywood cases** — Maaz needed one for
  β-glucosidase) make the final model **partly exploratory**. The
  summary should state whether any were applied.
- Reverse-score negatively loading indicators into an interpretable
  variable (Maaz turned pH into “acidity”).
- The factor structure is **regionally fitted** and should not be
  assumed transferable.

**D6 Document the corpus’s structural finding.** Maaz’s CFA found **no
statistical support** for grouping indicators into
physical/chemical/biological classes; a three-factor structure cutting
across the disciplines fitted far better, and
\[\[sources/2026-yuan-shi-mds-methods-comparison\|Yuan\]\] independently
found functional (EMDS) grouping beat the three-class split. Link to the
functional-grouping work in
\[\[projects/2026-soilquality-package-upgrade\]\] Phase 5.

### Task E — Integration, docs, release

**E1 Vignette** — “Explaining and constructing an SQI with SEM”, built
around the decision: *do you want SEM to BE the index, or to EXPLAIN
it?* Lead with that fork; most confusion in the literature comes from
conflating them.

**E2 Dependency hygiene.** `lavaan`, `piecewiseSEM`, **`plspm`**,
`semTools`, `lme4` in **`Suggests`** with
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards, so
the core SQI pipeline stays installable without the SEM stack. (Differs
from the `igraph` recommendation in the companion project, because this
stack is heavier and used by fewer users.)

**E3 `R CMD check --as-cran`** clean; NEWS.md; version bump.

------------------------------------------------------------------------

## Open decisions (these tailor the tasks)

1.  **Do typical `soilquality` input tables carry cluster and
    inherent-factor columns?** If not, Tasks A3 and B need a documented
    convention for supplying them, and both degrade to warnings.
2.  **Should `sqi_cfa()` refuse or warn on `not-recommended`?**
    Recommend **refuse with `force = TRUE`** available — a warning will
    be ignored, and an under-powered CFA is worse than none.
3.  **[`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)
    default — refuse or warn?** Recommend **refuse**, with
    `allow_components = TRUE` for the legitimate decomposition use.
4.  **Is Task D (CB-SEM/CFA) worth it for your user base?** If most
    users have n \< 100, Tasks A–C — **now including the PLS-PM backend
    C6** — deliver nearly all the value and D serves a minority.
    Recommend shipping A, B, C0, C2, C6 first, then C1/C3, and deciding
    D on demand.
5.  **Default `modes` for `sqi_plspm()`** — reflective (`"A"`) or
    formative (`"B"`)? Soil indicator blocks are arguably **formative**
    (indicators *constitute* soil quality rather than reflecting a
    latent cause), which would also make composite reliability/AVE
    inapplicable. Genuinely contested; decide deliberately and document.

## Risks & mitigations

| Risk | Mitigation |
|----|----|
| Users run CFA on 30 samples | Task A2 gate; refuse by default —**and Task C0 routes them to PLS-PM instead** |
| Treating “SEM” as one method | The three-estimator table in the feasibility verdict; Task C0 makes the choice explicit |
| Shipping the circularity trap as a feature | Task C2 — refuse by default, decomposition mode suppresses R² |
| Reimplementing SEM badly | Thin wrappers only; always return the underlying`lavaan`/`psem` object |
| Fisher’s C misread as a significance test | Task C1 returns it with the “p \> 0.05 = good fit” note attached |
| Reporting CFI/RMSEA/SRMR for a PLS-PM fit | The vignette states it explicitly — C6 is no longer a function |
| **Wrapping mature packages for no gain** | The scoping rule at the top: build only what needs SQI knowledge |
| **Maintenance burden from version coupling** | Three thin functions instead of ~15 wrappers; no `lavaan`/`plspm` API surface to track |
| Turning small-n users away entirely | Task C0 routes them to PLS-PM instead of refusing |
| Dependency bloat blocking core installs | Task E2 —`Suggests` + [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards |
| Over-claiming causality from cross-sectional data | Docs: these are**path models on observational data**; Yuan’s own caution that correlation networks cannot establish causality applies equally here |

## Progress log

- **2026-08-09** — ✅
  **[`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)
  (Task C2) BUILT AND SHIPPED**, v2.1.0, no dependencies. The companion
  project’s seven phases are all merged, so its Phase 3 and Phase 5
  prerequisites are satisfied.
  - Extended beyond the spec: **name matching alone is not enough.** An
    index built on `OM` regressed against `SOC` is circularity through a
    rename. Supplying `data` also checks every predictor by correlation
    against every component. On `soil_structured`, `SOC` is flagged as a
    proxy for **both** `OM` (ρ 0.99) and `N` (ρ 0.96, via the C:N
    ratio).
  - Also wired into **`sqi_validate(external = )`**, which the plan does
    not mention but which is exposed to exactly the same trap: an
    “external” criterion that is one of the index’s own indicators. The
    vector arrives unnamed, so that check is numerical
    (`external_r_max`, default 0.9).
- **2026-08-09** — ⚠️ **Three corrections from reviewing this plan
  against the built package.**
  1.  ❌ **The licence premise is wrong, as it was in the companion
      project.** This page says `lavaan`/`piecewiseSEM`/`plspm` are
      “licence-compatible with GPL-3”. The package is **MIT**
      (`DESCRIPTION:14`). The conclusion it draws — `Suggests` — is
      right, but for the wrong reason, and someone reading “compatible”
      could move them to `Imports`.
  2.  ✅ **Task A1’s KMO + Bartlett already exist** as
      [`pca_adequacy()`](https://ccarbajal16.github.io/soilquality/reference/pca_adequacy.md),
      shipped in the companion project’s Phase 7. ⚠️ And building it
      exposed something `sqi_diagnose()` must handle: **KMO is usually
      not computable on a soil data set.** Particle-size fractions sum
      to 100, so the correlation matrix is singular and KMO returns
      `NA`. A diagnostic that assumes a number will mislead.
  3.  ⚠️ **Task D4’s “[`ecdf()`](https://rdrr.io/r/stats/ecdf.html) then
      cut at 0–20/…/80–100” needs disambiguating before anyone builds
      it.** Applying [`ecdf()`](https://rdrr.io/r/stats/ecdf.html) per
      *indicator* as a scoring transform is legitimate. Applying it to
      the finished index and then cutting quantile bands is
      **degenerate** — it returns n/5 per band for every possible index.
      The companion project hit this exact trap in its Phase 3 and the
      spec had to be corrected. Establish which one Maaz did before
      implementing.
- **2026-08-09** — ⚠️ **Task B (`adjust_inherent()`) is blocked on data,
  not on code.** Neither `soil_data` nor `soil_structured` carries
  `soil_type`, `land_use_history` or a plot identifier — every column is
  a measured property. That answers Open decision 1 in the negative: the
  function cannot be demonstrated, tested against an injected group
  effect, or given a runnable example on anything the package ships. ✅
  **RESOLVED 2026-08-09 — `soil_inherent` added** (180 samples, 36
  plots, 5 per plot; `soil_type`, `land_use_history`, `management`,
  `PlotID`). Verified two-sided: residualising on the inherent factors
  removes the soil-type effect (p → 1.00) AND sharpens the management
  effect (OM: 2e-04 → 6e-23). ICC 0.81–0.99, matching Maaz’s field
  finding. **Task B is now unblocked.** This was the same failure the
  companion project hit when `soil_data` could not exercise network
  selection, and which was fixed by adding `soil_structured`.
- **2026-08-09** — ⚠️ **The CRAN non-overlap survey is unverified by the
  implementing agent.** No web access; the `SQIpro` function index and
  the “no package does SQI + SEM” claim are taken from this document,
  not confirmed independently.
- **2026-08-08** — Feasibility evaluated and plan created. Verdict:
  build A, B, C (with the guard) and gate D. Do **not** reimplement SEM.
  Not started.
- **2026-08-08 (second revision)** — ⚠️ **Scope cut after a CRAN
  survey.** No package does SQI + SEM, but
  `lavaan`/`piecewiseSEM`/`plspm` are mature and generic, so wrapping
  them is pure cost. Added the scoping rule *“does the function need to
  know what an SQI is?”*, collapsing ~15 tasks to **3 functions (B, C2,
  D3) + 1 vignette**. Detailed tasks retained as the vignette
  specification. Aligned with the decision to position the package as
  the sharp research tool for the corpus’s missing methods — see
  \[\[projects/2026-soilquality-package-upgrade\]\].
- **2026-08-08 (revised, same day)** — ⚠️ **Corrected after the human
  pointed out that Wang used SEM to explore key factors.** Checking the
  paper revealed Wang ran **PLS-PM**, not covariance-based SEM. The
  original evaluation had treated “SEM” as one method and concluded
  small-n users were largely excluded — wrong. Added the three-estimator
  comparison, a route-selection task (C0) and a **PLS-PM backend (C6)**,
  and revised the recommended shipping order so small-n users are
  routed, not refused.

## Provenance

Executes \[\[skills-forge/soil-quality-index/SKILL\]\] §6. Method page:
\[\[methods/structural-equation-modelling\]\]. Sources — full citations
in the wiki: \[\[sources/2023-maaz-sem-soil-health\|Maaz 2023\]\] (CFA,
second-order factor, fit thresholds, omega, ICC, inherent adjustment),
\[\[sources/2026-sarapatka-erosion-sqi-sem\|Sarapatka 2026\]\]
(piecewise SEM, Fisher’s C, d-separation, effect decomposition, **the
circularity admission**),
\[\[sources/2025-wang-loess-vegetation-sqi-sem\|Wang 2025\]\] (the
under-powered counter-example),
\[\[sources/2026-theresa-rice-fertilization-sqi\|Theresa 2026\]\]
(KMO/Bartlett values). Entities: \[\[entities/lavaan\]\],
\[\[entities/piecewisesem\]\]. Companion project:
\[\[projects/2026-soilquality-package-upgrade\]\].
