# Script to create the soil_function_groups dataset
#
# The five functions are Yuan and Shi (2026), after Li et al. (2023). The
# assignment of this package's indicator vocabulary to them is a curation
# decision, documented in R/function_groups.R along with the ambiguous cases.
#
# The vocabulary is fixed by what the shipped datasets measure:
#   Sand, Silt, Clay, BD, pH, OM, SOC, N, P, K, CEC, Ca, Mg, S, EC
#
# Soil biodiversity maintenance has NO indicator in that vocabulary -- it needs
# microbial biomass carbon, enzyme activity, respiration or a community
# measure. It ships EMPTY on purpose. Do not fill it with a proxy: a
# plausible-looking stand-in would misrepresent which functions the index
# actually covers.

soil_function_groups <- list(

  # The organic carbon pool. OM and SOC are two measurements of one thing
  # (SOC = OM / 1.724), which is exactly why they belong together and why only
  # one of them should reach the minimum data set.
  carbon_cycling = c("OM", "SOC"),

  # Plant-available nutrient supply. Ca and Mg are placed here because they are
  # measured as nutrients, though they are also exchangeable bases and
  # contribute to buffering -- see the documentation for that ambiguity.
  nutrient_cycling = c("N", "P", "K", "Ca", "Mg", "S"),

  # Texture and compaction: the physical arrangement that governs rooting,
  # aeration and water movement.
  physical_structure = c("Sand", "Silt", "Clay", "BD"),

  # The capacity to buffer reaction and to retain or transmit solutes.
  buffering_filtration = c("pH", "CEC", "EC"),

  # Deliberately empty. See the header.
  biodiversity = character(0)
)

stopifnot(
  length(soil_function_groups) == 5L,
  length(soil_function_groups$biodiversity) == 0L,
  !anyDuplicated(unlist(soil_function_groups, use.names = FALSE))
)

usethis::use_data(soil_function_groups, overwrite = TRUE)
