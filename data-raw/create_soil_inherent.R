# Script to create the soil_inherent example dataset
#
# WHY THIS EXISTS
# Neither soil_data nor soil_structured carries the columns an
# inherent-property adjustment needs: soil type, land-use history, or a plot
# identifier. Every column in both is a measured property. That makes
# adjust_inherent() undemonstrable, untestable and unexampleable on anything
# the package ships.
#
# This dataset is built for that job, and for two others it enables: the
# intraclass correlation check (it is nested, five samples per plot) and any
# future multilevel work.
#
# THE DESIGN, AND WHY IT IS SHAPED THIS WAY
# Three sources of variation, deliberately separated so that an adjustment can
# be shown to remove one and preserve another:
#
#   soil_type          INHERENT  - parent material. Sets clay, CEC and pH.
#                                  A manager cannot change it, and a soil
#                                  should not be scored down for it.
#   land_use_history   INHERENT  - what the site was before. Sets the legacy
#                                  carbon and nitrogen baseline. Also outside
#                                  present-day control.
#   management         NOT       - current practice. This is the thing an
#                                  index is actually meant to assess, and it
#                                  MUST survive the adjustment or the
#                                  adjustment is useless.
#
# The test that matters is therefore two-sided: after adjusting for the two
# inherent factors, the soil_type difference should be gone AND the management
# difference should still be there.
#
# Nesting: 3 soil types x 3 land-use histories x 2 management levels = 18
# combinations, 2 plots each = 36 plots, 5 samples per plot = 180 samples.
# The plot random effect is deliberately larger than the residual, because
# Maaz et al. (2023) found ICC above 75% for every indicator -- samples within
# a plot are not independent, and most soil campaigns never check.
#
# Values stay in ranges plausible for acidic tropical soils of the Ucayali
# region, matching the other datasets.

set.seed(2027)

soil_types <- c("Acrisol", "Cambisol", "Fluvisol")
histories  <- c("primary_forest", "secondary_forest", "long_pasture")
managements <- c("conventional", "improved")

plots_per_cell <- 2
samples_per_plot <- 5

design <- expand.grid(
  soil_type = soil_types,
  land_use_history = histories,
  management = managements,
  replicate = seq_len(plots_per_cell),
  stringsAsFactors = FALSE
)
design$PlotID <- sprintf("P%02d", seq_len(nrow(design)))

n_plots <- nrow(design)

# ---- effects ----------------------------------------------------------------
# Stated as named vectors so the injected truth is inspectable, and so the
# tests can assert against the same numbers the generator used.

# Parent material: clay content, exchange capacity, reaction.
clay_by_soil <- c(Acrisol = 38, Cambisol = 26, Fluvisol = 16)
cec_by_soil  <- c(Acrisol = 9.5, Cambisol = 12.5, Fluvisol = 15.5)
ph_by_soil   <- c(Acrisol = 4.6, Cambisol = 5.4, Fluvisol = 6.3)

# Legacy carbon and nitrogen from what the site used to be.
om_by_history <- c(primary_forest = 4.4, secondary_forest = 3.2,
                   long_pasture = 2.4)

# Present-day management: the signal an index exists to detect. Deliberately
# smaller than the inherent effects, which is what makes the adjustment worth
# doing -- unadjusted, parent material drowns it out.
om_by_management <- c(conventional = 0, improved = 0.55)
p_by_management  <- c(conventional = 0, improved = 3.2)
bd_by_management <- c(conventional = 0, improved = -0.08)

# ---- plot-level draws -------------------------------------------------------
# One value per plot, shared by its samples. This is what creates the high
# intraclass correlation.

plot_effect <- function(sd) stats::rnorm(n_plots, 0, sd)

plot_clay <- clay_by_soil[design$soil_type] + plot_effect(2.5)
plot_cec  <- cec_by_soil[design$soil_type] + plot_effect(0.9)
plot_ph   <- ph_by_soil[design$soil_type] + plot_effect(0.18)
plot_om   <- om_by_history[design$land_use_history] +
  om_by_management[design$management] + plot_effect(0.30)
plot_p    <- 6.5 + p_by_management[design$management] + plot_effect(0.9)
plot_bd   <- 1.42 + bd_by_management[design$management] + plot_effect(0.05)

# ---- expand to samples ------------------------------------------------------
# Residual sd is small relative to the plot sd on purpose: ICC = between /
# (between + within), and Maaz's soils sat above 0.75.

idx <- rep(seq_len(n_plots), each = samples_per_plot)
n <- length(idx)

within <- function(sd) stats::rnorm(n, 0, sd)

Clay <- plot_clay[idx] + within(1.2)
Clay <- pmin(pmax(Clay, 6), 55)

Sand <- 92 - 1.35 * Clay + within(2.5)
Sand <- pmin(pmax(Sand, 15), 75)

Silt <- 100 - Sand - Clay
too_low <- Silt < 6
Sand[too_low] <- Sand[too_low] - (6 - Silt[too_low])
Silt[too_low] <- 6

OM <- pmax(plot_om[idx] + within(0.22), 0.5)
SOC <- OM / 1.724 * (1 + within(0.03) / 1)
N <- SOC / stats::rnorm(n, 11, 0.9)

pH <- pmin(pmax(plot_ph[idx] + within(0.12), 3.8), 7.6)
CEC <- pmax(plot_cec[idx] + 0.9 * (OM - mean(OM)) + within(0.5), 3)

BD <- pmin(pmax(plot_bd[idx] - 0.05 * (OM - mean(OM)) + within(0.035),
                0.95), 1.75)

P <- pmax(plot_p[idx] + 0.9 * (OM - mean(OM)) + within(0.8), 1)
K <- pmax(58 + 4.2 * CEC + 3.0 * OM + within(7), 20)

soil_inherent <- data.frame(
  SampleID = sprintf("INH%03d", seq_len(n)),
  PlotID = design$PlotID[idx],
  soil_type = factor(design$soil_type[idx], levels = soil_types),
  land_use_history = factor(design$land_use_history[idx], levels = histories),
  management = factor(design$management[idx], levels = managements),
  Sand = round(Sand, 1),
  Silt = round(Silt, 1),
  Clay = round(Clay, 1),
  BD = round(BD, 2),
  pH = round(pH, 1),
  OM = round(OM, 2),
  SOC = round(SOC, 2),
  N = round(N, 3),
  P = round(P, 1),
  K = round(K, 0),
  CEC = round(CEC, 1),
  stringsAsFactors = FALSE
)

# Re-close texture after rounding.
soil_inherent$Silt <- round(100 - soil_inherent$Sand - soil_inherent$Clay, 1)

stopifnot(
  nrow(soil_inherent) == 180,
  nlevels(soil_inherent$soil_type) == 3,
  nlevels(soil_inherent$land_use_history) == 3,
  nlevels(soil_inherent$management) == 2,
  length(unique(soil_inherent$PlotID)) == 36,
  all(table(soil_inherent$PlotID) == samples_per_plot),
  all(abs(soil_inherent$Sand + soil_inherent$Silt +
            soil_inherent$Clay - 100) < 1e-8),
  !anyNA(soil_inherent)
)

usethis::use_data(soil_inherent, overwrite = TRUE)
