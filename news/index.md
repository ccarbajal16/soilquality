# Changelog

## soilquality 2.1.0 (development)

First piece of the SEM module, and the one that needed no SEM at all.

#### New features

- [`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md) -
  refuses to let you regress a soil quality index on the indicators that
  **built** it. An index is a weighted sum of its components, so a model
  predicting it from those components must fit well: the R-squared is
  arithmetic, not evidence about soil. Sarapatka et al.
  2026. report R-squared = 0.99 from exactly this arrangement and name
        the cause themselves; Wang et al. (2025) conclude that carbon
        “affects” an index carbon helped build.
- Two modes, and the function distinguishes them. **Explanation** uses
  predictors from outside the index; overlap is an error.
  **Decomposition** – “which of my components dominates this index?” –
  is a fair question with a real answer, available via
  `allow_components = TRUE`, and the result is labelled so that its fit
  statistic is not reported as a finding.
- **Renaming is not laundering.** Name matching alone would miss the
  commonest version: an index built on `OM` regressed against `SOC`, the
  same measurement times 1.724. Supply `data` and every predictor is
  also checked by correlation against every component. On
  `soil_structured`, `SOC` is flagged as a proxy for **both** `OM` (rho
  0.99) and `N` (rho 0.96, through the C:N ratio) – reporting only the
  first would understate the entanglement.
- [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
  gains `external_r_max` (default 0.9) and now warns when the “external”
  criterion is really one of the index’s own indicators. That vector
  arrives unnamed, so the check is numerical. It is the same trap
  wearing a different hat, and the validation layer was exposed to it.

No new dependencies: this needs
[`stats::cor()`](https://rdrr.io/r/stats/cor.html) and set arithmetic.

## soilquality 2.0.0 (development)

### Breaking change

**`soil_ucayali` has been removed.** Use `soil_data`, which is a strict
superset: the same 50 samples, the same `SampleID`s, and all fifteen
shared columns **identical value for value**, plus a sulfur (`S`)
measurement that `soil_ucayali` lacked. The dataset carried no
information of its own, and shipping both made the reference index look
like there were two example datasets to choose between when there was
one.

Migration is a rename:

``` r

# before
data(soil_ucayali)
compute_sqi_properties(soil_ucayali, properties = c("pH", "OM"))

# after
data(soil_data)
compute_sqi_properties(soil_data, properties = c("pH", "OM"))
```

One caveat worth stating: code that **auto-detects numeric columns**
rather than naming properties explicitly will now see sixteen columns
instead of fifteen, because `S` is present. The selected minimum data
set, and therefore the index, can change. Name your properties if that
matters to you. The package’s own vignettes were updated on this basis
and their results shift accordingly.

The major version is bumped because this removes an exported object.

### Documentation

- `soil_data` is retitled from “Extended Soil Data from Ucayali, Peru” —
  the “Extended” only meant “relative to `soil_ucayali`” and no longer
  parses. Its help page now says plainly what it is good for and what it
  is not: it has almost no covariance structure (largest off-diagonal
  Spearman rho 0.66, one pair above 0.6), which is fine for scoring,
  weighting and aggregation, and useless for anything that reads the
  structure *between* indicators. Use `soil_structured` for that.
- The two remaining datasets are now described in the reference index by
  the job each does, rather than as interchangeable alternatives.

## soilquality 1.7.0 (development)

Completes the upgrade begun in 1.1.0: adequacy testing, the main
vignette, and the documentation the earlier phases deferred.

#### New features

- [`pca_adequacy()`](https://ccarbajal16.github.io/soilquality/reference/pca_adequacy.md) -
  the two checks that a correlation matrix is worth factoring at all:
  the Kaiser-Meyer-Olkin measure of sampling adequacy, with Kaiser’s
  labels and a per-variable MSA, and Bartlett’s test of sphericity. Most
  published soil quality work skips both.
- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  gains `adequacy = c("report", "warn", "ignore")`, reporting by default
  and warning on request when KMO falls below 0.6 or sphericity is not
  rejected. It reports rather than gates, because erroring would break
  every existing call.

#### A limitation worth knowing about

KMO requires inverting the correlation matrix, and **soil data routinely
makes that impossible**: particle-size fractions sum to 100, so `Sand`,
`Silt` and `Clay` together are exactly collinear, and organic matter and
organic carbon are related by a fixed factor. When the matrix is
singular,
[`pca_adequacy()`](https://ccarbajal16.github.io/soilquality/reference/pca_adequacy.md)
returns `NA` with an explanation naming the offending pairs, rather than
erroring or quietly substituting a pseudo-inverse. Bartlett’s statistic
is reported as `NA` for the same reason.

Bartlett’s test is also close to a formality on real data: with a decent
sample size almost any set of soil properties rejects sphericity.
Passing it is weak evidence; failing it is strong evidence, and that is
what it is for.

#### Documentation

- New vignette,
  [`vignette("building-and-validating-an-sqi")`](https://ccarbajal16.github.io/soilquality/articles/building-and-validating-an-sqi.md),
  walking the full pipeline: adequacy, selection by variance or
  centrality, functional grouping, the five scoring routes, weighting or
  not weighting, aggregation, and validation.
- README gains the pipeline decision table and states why validation is
  the point rather than an optional extra.
- **Do not build an index from predicted properties.** Documented on
  [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  and in the README. Chaudhry et al. (2024): computing an SQI from
  spectrally predicted properties gave R² = 0.23, while predicting the
  index directly from the same spectra gave R² = 0.90, with individually
  acceptable property models.

#### Verification

`R CMD check --as-cran`: 0 errors, 0 warnings, 0 notes, including
`--run-donttest` and vignette rebuilding.

## soilquality 1.6.0 (development)

Adds reference-soil standardisation: scoring against an undisturbed soil
rather than against the sample’s own extremes.

#### New features

- [`standardize_to_reference()`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md) -
  scores an indicator relative to the same indicator in a non-degraded
  reference soil, which takes the value 1 while degraded samples fall
  toward 0. Three directions: `"higher"` gives `x / reference`;
  `"lower"` inverts to `reference / x`, because the undisturbed soil
  holds the **minimum** for bulk density and its like; and `"optimum"`
  uses the **distance from the optimum**, since a monotone scale would
  rank pH 8.0 above pH 6.5.
- [`reference_scoring()`](https://ccarbajal16.github.io/soilquality/reference/reference_scoring.md) -
  the matching `scoring_rule` constructor, so the route is reachable
  from
  [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md).
- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)
  gains a `"reference"` type.
- [`sensitivity_resistance()`](https://ccarbajal16.github.io/soilquality/reference/sensitivity_resistance.md) -
  Kuzyakov’s second and much less used approach: each indicator’s
  relative change divided by the change in soil organic carbon. Below 1
  the indicator degrades faster than carbon and is sensitive; above 1 it
  is resistant.

#### Why it matters, and what it costs

Every other scoring function normalises against the sample’s own
extremes, which guarantees the best site scores about 1 **by
construction** – whether it is pristine or merely the least ruined of a
bad set. Two studies can both report 0.8 and mean entirely different
soils.

The price is a defensible reference: same soil type, parent material and
climate, undisturbed. Kuzyakov et al. call this the approach’s key
disadvantage, and a fully converted landscape often has no such site
left. A badly chosen reference does not add noise, it silently rescales
every index built on it. The documentation says so rather than selling
the method.

Two honest touches: a sample that **beats** the reference is capped at 1
with a warning naming how many did, because that usually means the
reference is not the least disturbed soil available; and
[`sensitivity_resistance()`](https://ccarbajal16.github.io/soilquality/reference/sensitivity_resistance.md)
documents that Kuzyakov’s classification resolved cleanly on a Luvic
Phaeozem and **failed to separate on a Calcic Chernozem**, so an untidy
result is a fact about the soil rather than a failure of the analysis.

## soilquality 1.5.0 (development)

Adds functional (EMDS) grouping: selecting one indicator per soil
*function* rather than letting the whole pool compete on a single
criterion.

#### New features

- `soil_function_groups` - the five functions of Yuan and Shi (2026),
  after Li et al. (2023): carbon cycling, nutrient cycling, physical
  structure, buffering and filtration, and soil biodiversity. The
  biodiversity group ships **empty on purpose** – nothing in this
  package’s indicator vocabulary measures it, and a plausible-looking
  proxy would misrepresent which functions an index actually covers.
- [`assign_function_groups()`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md) -
  maps a set of property names onto those functions. Names that match
  nothing are reported in an `"unassigned"` element rather than silently
  dropped.
- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  and
  [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)
  gain `groups =`, running selection independently inside each function.
  Default `NULL` keeps pool-wide selection. In the network route a group
  too small for a graph (carbon cycling is two indicators) falls back to
  the most within-group correlated indicator, **with a warning**,
  recorded per group in `$group_results`.
- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  gains `selector = c("loading", "norm")`. The norm value is Yuan eq.
  (2), `N_i = sqrt(sum_k u_ik^2 * lambda_k)` over components with
  eigenvalue \>= 1, which judges an indicator across components instead
  of one at a time.

#### The relative loading rule, finally implemented

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  gains `within =`. The function has always taken the single
  highest-loading indicator per retained component; the rule stated in
  the literature keeps **every** indicator within 10% of that maximum,
  which generally yields a larger data set. `within = NULL` (the
  default) keeps the historical behaviour and the regression baseline;
  `within = 0.10` is the published rule. `loading_threshold` is an
  absolute floor and `within` a relative band – different mechanisms,
  combinable.
- Documented that Yuan and Shi (2026) section 2.3.1 states this rule
  **inverted**, which would select the least informative variables.
  Their own section 2.3.2 states it correctly.

#### Why this matters, measured on `soil_structured`

Offered all fifteen indicators, ungrouped selection leaves **entire
functions with no representative**:

| Route              | Selected           | Functions covered |
|--------------------|--------------------|-------------------|
| network, ungrouped | OM, CEC            | 2 of 4            |
| network, grouped   | OM, P, N, Clay, EC | **4 of 4**        |
| PCA, ungrouped     | pH, Silt           | 2 of 4            |
| PCA, grouped       | SOC, P, Sand, EC   | **4 of 4**        |

The base-status indicators `pH`, `Ca`, `Mg` and `EC` are dropped
wholesale by the ungrouped network route, because their module is
peripheral to the graph.

#### Documentation

- `soil_function_groups` documents why grouping should be functional
  rather than by the familiar physical/chemical split: Maaz et
  al. (2023) tested that split by confirmatory factor analysis and found
  it has **no statistical support**. `soil_property_sets$physical` and
  `$chemical` are unchanged and remain useful for choosing what to
  measure – they are simply not a basis for selecting a minimum data
  set.

## soilquality 1.4.0 (development)

#### New data

- `soil_structured` - 120 simulated soil samples whose properties are
  related to one another the way real soil properties are. Generated
  from three latent gradients (texture, organic status, base status) so
  that the standard pedological relationships hold: compositional
  texture summing to 100, `SOC = OM / 1.724` (van Bemmelen),
  `N = SOC / (C:N)`, CEC generated by clay and organic colloids,
  exchangeable bases tracking CEC and pH, bulk density falling with
  organic matter, conductivity carried by soluble bases. **Forty**
  indicator pairs reach `|rho| >= 0.6`, against **one** in `soil_data`.
- `soil_data` and `soil_ucayali` are unchanged. They draw every property
  independently, which is fine for demonstrating scoring and aggregation
  but cannot exercise any method that reads the structure *between*
  indicators. Use `soil_structured` for
  [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md),
  [`mds_consensus()`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md)
  and, in future, functional grouping.
- The dataset separates the two selection routes cleanly, which is worth
  seeing before choosing one: the network route selects the hubs (OM,
  CEC), the PCA route selects the high-variance and near-unique
  variables (pH, Silt), and their consensus is empty. That is the
  documented asymmetry made visible, not a defect in either method.

#### Bug fixes

- [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)
  now runs the redundancy screen **within each module** rather than
  across the whole selected set. Screening globally discarded every
  module’s representative as redundant with the single most central
  indicator, collapsing the partition that the module step had just
  built – on `soil_structured` it returned one indicator where it should
  return two.
- The disconnected-network warning no longer fires for a lone isolated
  indicator. A singleton component has no internal correlation to erase
  and is already reported in `$isolated`; the warning is now raised only
  when more than one component contains actual structure.

## soilquality 1.3.0 (development)

Adds correlation-network indicator selection, which chooses indicators
by their centrality in a correlation network rather than by their
contribution to variance.

#### New features

- [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md) -
  Minimum Data Set selection following Yuan and Shi (2026) section
  2.3.2: a Spearman correlation network, Louvain communities, an
  eigenvector-centrality module filter, within-10% retention,
  weighted-degree tie-breaking, an optional redundancy screen, and
  centrality-derived weights.
- [`mds_consensus()`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md) -
  runs the PCA and network routes over the same data and returns the
  indicators both agree on.
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  gains `select = "network"` and a `network_args` list, so the route
  reaches
  [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
  and
  [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
  too. The centrality weights are used unless a pairwise matrix is
  supplied.
- `igraph` is a **suggested** dependency, guarded by
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html). This
  package is MIT-licensed and igraph is GPL-2+; a hard dependency in
  Imports would pull the combined work into GPL territory on
  distribution. Everything in this section degrades gracefully when
  igraph is absent.

#### Two defects in the published procedure, and what was done about them

- **Louvain is randomised, so the method is not deterministic.** Six
  runs over identical input returned two different Minimum Data Sets
  during development.
  [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)
  therefore takes a `seed`, defaulting to 1 and applied in a local scope
  that leaves the caller’s random stream untouched. Vary it to find out
  whether a selection is genuinely robust; stability at one seed is not
  evidence.
- **On a disconnected network, eigenvector centrality goes to zero
  outside the dominant component** – exactly zero under the reference
  BLAS, around 1e-17 under macOS Accelerate; the distinction is
  immaterial, since neither passes a usable threshold. A clique of three
  indicators correlating at 0.98 was discarded entire, and no
  `centrality_min` could rescue it. The new `component = "all"` computes
  centrality within each connected component so each sub-network is
  judged on its own terms; the default reproduces the published
  behaviour, and a warning now states the consequence.

#### Note on the example data

`soil_data` is simulated from independent draws and carries almost no
correlation structure: the largest off-diagonal Spearman rho is 0.66 and
only one pair clears the default threshold. The network route collapses
to a single indicator on it. That is a property of the fixture, not the
method.

## soilquality 1.2.0 (development)

Adds index validation – the ability to ask whether an index actually
discriminates, rather than assuming it does.

#### New features

##### Validation

- [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md) -
  assesses a computed index on four diagnostics, in descending order of
  how much they should influence a judgement: the distribution across
  the five soil-health decision categories, the sensitivity index
  (max/min), fidelity to a total-data-set index, and correlation against
  an optional external criterion such as yield.
- The distribution is the headline, and it warns. Maaz et al. (2023)
  found an additive index and an SEM index correlating at r = 0.96 while
  placing 94% vs 61% of plots in the middle bands: correlation is the
  wrong diagnostic for an index, the spread across decision categories
  is the right one. A warning fires above `middle_band_threshold`
  (default 0.8) because a silent number gets ignored.
- [`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md) -
  runs the same samples through two or more recipes and reports whether
  the ranking survives: Spearman rho per pair, plus a flag when the best
  or worst sample changes. A high rank correlation does not rescue a
  changed extreme if the extreme is what you act on.
- [`plot_sqi_validation()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_validation.md) -
  the distribution plot, accepting an `sqi_validation`, an `sqi_result`
  or a bare numeric vector.
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  gains `select = c("pca", "none")`. With `"none"` the selection step is
  skipped and every numeric indicator is used, which is how the
  total-data-set index that
  [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
  measures fidelity against is built. PCA is still run and reported
  either way.

#### Note on the example data

Running
[`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
on the package’s own default recipe applied to `soil_data` fires the
middle-band warning: the resulting SQI spans roughly 0.36-0.70, so 100%
of samples land in the middle bands and the “very low” and “very high”
categories are empty. This is not a bug – it is the diagnostic working,
on exactly the pathology it was built to expose.

## soilquality 1.1.0 (development)

Broadens the package from a single SQI route (PCA-MDS, AHP/loading
weights, linear scoring, weighted additive aggregation) toward the
routes the soil quality literature actually uses. This release covers
non-linear scoring and weight-free aggregation. All additions are
opt-in; the default pipeline produces exactly the values it produced in
1.0.0, and a golden-output regression test now enforces that.

#### New features

##### Non-linear (sigmoidal) scoring

- [`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md) -
  scores an indicator with `S = 1 / (1 + (x/x0)^b)`, the dominant
  scoring form in the SQI literature. Both `x0` (the value scoring 0.5)
  and `b` (steepness) are parameters. The `b = 2.5` default is a
  convention inherited from the literature with empirical support for
  pH/TN/SOC/P only, not a general constant, and the documentation says
  so.
- [`sigmoid_scoring()`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md) -
  the matching `scoring_rule` constructor, so the new curve is reachable
  from
  [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md).
- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)
  gains a `"sigmoid"` scoring type alongside the existing
  `higher`/`lower`/`optimum`/`threshold`.
- [`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)
  gains `scoring = c("linear", "sigmoid")` and `b`. pH deliberately
  remains an optimum-range rule under `"sigmoid"`: the sigmoidal curve
  is monotonic and has no optimum form.

##### Area-based (weight-free) aggregation

- [`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md) -
  aggregates scored indicators as the area of the radar diagram they
  trace, `A = 0.5 * sum(s^2) * sin(2*pi/n)` (Kuzyakov et al. 2020, eq.
  2). This ignores weights entirely, sidestepping the most contested
  step in the pipeline. Supplying `reference` reports the result as a
  ratio against a non-degraded reference soil, which is what makes
  area-based values comparable across studies – the absolute value is
  not.
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  gains `method = c("weighted", "area")` and `reference`. Both flow
  through
  [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
  and
  [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
  via `...`. The returned `sqi_result` now carries a `method` element.

#### Documentation

- [`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
  documents that the literature contradicts itself on linear vs
  non-linear scoring (Yuan 2026 finds non-linear better; Bilgili et
  al. 2017, cited in Yuan’s own introduction, finds the opposite) and
  recommends computing both.
- [`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md)
  documents why the formula squares each score rather than multiplying
  adjacent radii: the square form is order-independent, whereas the true
  polygon area would depend on the arbitrary order of indicators around
  the diagram.

#### Internal

- Added a golden-output regression baseline pinning the MDS, PCA
  variance decomposition, weights and SQI values of the default pipeline
  against the shipped `soil_data`. Every change from here must leave it
  green or declare itself a break.
- Migrated the test suite to `testthat` edition 3
  (`Config/testthat/edition: 3`). No test changes were required.
  User-facing behaviour is unaffected.

## soilquality 1.0.0

*Release Date: 2025-12-07*

### Initial Release

This is the first public release of the soilquality package, providing
comprehensive tools for calculating Soil Quality Index (SQI) using
scientifically validated methods combining Principal Component Analysis
(PCA) and Analytic Hierarchy Process (AHP).

#### Major Features

##### Core Functionality

- **PCA-based MDS Selection**: Automated selection of Minimum Data Set
  indicators using Principal Component Analysis with configurable
  variance and loading thresholds
- **AHP Weighting System**: Expert-based indicator weighting with
  consistency ratio validation following Saaty’s methodology
- **Flexible Scoring Framework**: Multiple normalization methods to
  handle different soil property characteristics
- **Property Selection**: Pre-defined property sets (basic, standard,
  comprehensive, physical, chemical, fertility) and custom property
  selection
- **Standard Scoring Rules**: Automatic rule assignment based on
  property name patterns for common soil properties
- **Comprehensive Visualization**: Five plot types (distribution,
  indicators, weights, scree, biplot) plus multi-panel reports
- **Interactive Application**: Shiny-based GUI for non-programmers with
  file upload, configuration, and results download

##### Workflow Options

- **File-based workflow**:
  [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
  for CSV input/output
- **In-memory workflow**:
  [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  for data frame processing
- **Enhanced workflow**:
  [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
  with property selection and constructor-based scoring

#### Complete Function Reference

##### Data Handling Functions

- [`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md) -
  Import soil data from CSV files with encoding handling
- [`standardize_numeric()`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md) -
  Z-score standardization of numeric columns
- [`to_numeric()`](https://ccarbajal16.github.io/soilquality/reference/to_numeric.md) -
  Safe type conversion with NA for failures

##### PCA and MDS Selection

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md) -
  Perform PCA and select minimum data set based on variance and loading
  thresholds

##### AHP Weighting Functions

- [`ahp_weights()`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md) -
  Calculate indicator weights from pairwise comparison matrix using
  eigenvalue decomposition
- [`create_ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md) -
  Interactive or programmatic AHP matrix creation with validation
- [`ratio_to_saaty()`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md) -
  Convert importance ratios to Saaty scale (1-9)
- [`print.ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/print.ahp_matrix.md) -
  S3 print method for AHP matrix objects

##### Scoring Functions (Low-level)

- [`score_higher_better()`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md) -
  Normalize properties where higher values indicate better quality
- [`score_lower_better()`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md) -
  Normalize properties where lower values indicate better quality
- [`score_optimum()`](https://ccarbajal16.github.io/soilquality/reference/score_optimum.md) -
  Normalize properties with optimal range using linear or quadratic
  penalty
- [`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md) -
  Custom piecewise linear scoring based on threshold-score pairs
- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md) -
  Apply scoring functions to multiple indicators

##### Scoring Constructors (User-facing)

- [`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md) -
  Constructor for higher-is-better scoring rules
- [`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md) -
  Constructor for lower-is-better scoring rules
- [`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md) -
  Constructor for optimal range scoring with tolerance
- [`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md) -
  Constructor for custom threshold-based scoring
- [`print.scoring_rule()`](https://ccarbajal16.github.io/soilquality/reference/print.scoring_rule.md) -
  S3 print method for scoring rule objects

##### Property Sets and Standard Rules

- `soil_property_sets` - Pre-defined collections: basic (pH, OM, P, K),
  standard (9 properties), comprehensive (14 properties), physical,
  chemical, fertility
- [`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md) -
  Automatic scoring rule assignment based on property name patterns

##### SQI Computation Functions

- [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md) -
  File-based SQI computation with CSV input/output
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md) -
  In-memory SQI computation with data frame input
- [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md) -
  Enhanced SQI computation with property selection and constructor-based
  scoring

##### Visualization Functions

- [`plot.sqi_result()`](https://ccarbajal16.github.io/soilquality/reference/plot.sqi_result.md) -
  S3 plot method supporting five plot types:
  - “distribution”: Histogram of SQI values with mean line
  - “indicators”: Boxplots of indicator scores
  - “weights”: Bar chart of AHP weights with CR annotation
  - “scree”: Variance explained by principal components
  - “biplot”: PCA biplot of observations and variables
- [`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md) -
  Generate comprehensive 2x2 multi-panel visualization report

##### Interactive Tools

- [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md) -
  Launch interactive Shiny application with file upload, property
  selection, scoring configuration, AHP input, results display, and CSV
  download

#### Example Datasets

- `soil_ucayali` - Real soil property data from Ucayali, Peru (50
  samples, 14 properties)
  - Physical properties: Sand, Silt, Clay, BD (bulk density)
  - Chemical properties: pH, OM (organic matter), SOC (soil organic
    carbon)
  - Nutrients: N, P, K, CEC, Ca, Mg
  - Other: EC (electrical conductivity)

#### Documentation

##### Vignettes

- **Introduction to soilquality**: Basic workflow, installation, quick
  start examples, result interpretation
- **Advanced Usage**: Property selection strategies, custom scoring
  rules, AHP matrix creation, visualization options
- **AHP Matrices Guide**: AHP methodology explanation, creating pairwise
  comparisons, consistency ratio interpretation, tips for improving
  inconsistent matrices

##### Function Documentation

- Complete roxygen2 documentation for all 28 exported functions
- Parameter descriptions with types and defaults
- Return value specifications with structure details
- Working examples for each function
- Cross-references to related functions

##### Package Documentation

- Comprehensive README with installation instructions, quick start, main
  functions, citation information
- Package-level documentation with workflow overview and examples
- NEWS file with version history

#### Testing and Quality

##### Test Coverage

- Unit tests for all core modules (data handling, PCA/MDS, AHP, scoring,
  SQI computation, visualization)
- Integration tests for complete workflows
- Test coverage \>= 80% of core functions
- All tests pass with testthat framework

##### Package Quality

- Passes R CMD check with 0 errors, 0 warnings
- All examples run without errors
- Valid DESCRIPTION and NAMESPACE files
- MIT License included
- UTF-8 encoding properly declared
- All dependencies declared in DESCRIPTION

#### Dependencies

##### Required (Imports)

- `stats` - PCA (prcomp), eigenvalue calculations
- `utils` - CSV reading, data manipulation

##### Optional (Suggests)

- `shiny` - Interactive application
- `DT` - Data tables in Shiny app
- `testthat` (\>= 3.0.0) - Unit testing
- `knitr` - Vignette building
- `rmarkdown` - Vignette building
- `covr` - Test coverage analysis

##### R Version

- Requires R \>= 3.5.0

#### Known Limitations

##### Technical Constraints

- PCA requires at least 3 numeric variables for meaningful
  dimensionality reduction
- Sufficient observations recommended (n \>= p) for stable PCA results
- AHP consistency ratio should be \< 0.1 for reliable weights (warning
  issued if exceeded)
- Interactive AHP matrix creation requires interactive R session (not
  available in batch mode)

##### Scope Limitations

- Package focuses on PCA-based MDS selection; other selection methods
  not included
- AHP is the only weighting method implemented; other MCDA methods not
  included
- Visualization uses base R graphics only (no ggplot2 integration)
- Shiny app requires manual launch; no deployed web version included

#### Future Development

Potential enhancements for future versions: - Additional MDS selection
methods (correlation-based, expert selection) - Alternative weighting
methods (equal weights, data-driven weights) - ggplot2-based
visualization option - Additional scoring functions (membership
functions, fuzzy logic) - Spatial analysis integration - Time series
support for monitoring - Export to additional formats (PDF reports, GIS
layers)

#### Acknowledgments

This package implements methodologies from soil quality assessment
literature: - Andrews et al. (2004) - Soil Management Assessment
Framework - Saaty (1980) - Analytic Hierarchy Process - PCA-based MDS
selection approaches widely used in soil science research

#### Citation

To cite this package in publications:

    Carbajal, Carlos (2025). soilquality: Soil Quality Index Calculation with PCA and AHP. R package version 1.0.0. https://github.com/ccarbajal16/soilquality

#### Getting Help

- Function documentation: `?function_name` or `help(function_name)`
- Vignettes: `browseVignettes("soilquality")`
- Issues: <https://github.com/ccarbajal16/soilquality/issues>
