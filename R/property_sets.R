#' Pre-defined soil property sets
#'
#' A list containing pre-defined sets of soil properties commonly used in
#' soil quality assessments. These sets can be used with the
#' \code{\link{standard_scoring_rules}} function to quickly configure
#' analyses for different scenarios.
#'
#' @format A named list with the following property sets:
#' \describe{
#'   \item{basic}{A minimal set of 4 fundamental soil properties: pH,
#'     organic matter (OM), phosphorus (P), and potassium (K). Suitable
#'     for quick assessments with limited data.}
#'   \item{standard}{A comprehensive set of 9 commonly measured properties:
#'     Sand, Silt, Clay, pH, OM, nitrogen (N), P, K, and cation exchange
#'     capacity (CEC). Recommended for most soil quality assessments.}
#'   \item{comprehensive}{An extensive set of 15 properties including all
#'     standard properties plus bulk density (BD), electrical conductivity
#'     (EC), calcium (Ca), magnesium (Mg), sodium (Na), and sulfur (S).
#'     Suitable for detailed soil characterization.}
#'   \item{physical}{Physical properties only: Sand, Silt, Clay, and BD.
#'     Focuses on soil structure and texture characteristics.}
#'   \item{chemical}{Chemical properties only: pH, EC, CEC, Ca, Mg, K, Na.
#'     Focuses on soil chemistry and nutrient availability.}
#'   \item{fertility}{Fertility-related properties: OM, N, P, K, Ca, Mg, S,
#'     CEC. Focuses on nutrient supply and retention capacity.}
#' }
#'
#' @examples
#' # View available property sets
#' names(soil_property_sets)
#'
#' # View properties in the basic set
#' soil_property_sets$basic
#'
#' # View properties in the standard set
#' soil_property_sets$standard
#'
#' # Use with standard_scoring_rules()
#' rules <- standard_scoring_rules(soil_property_sets$basic)
#'
#' @seealso \code{\link{standard_scoring_rules}}
#'
#' @export
soil_property_sets <- list(
  basic = c("pH", "OM", "P", "K"),

  standard = c("Sand", "Silt", "Clay", "pH", "OM", "N", "P", "K", "CEC"),

  comprehensive = c("Sand", "Silt", "Clay", "pH", "OM", "N", "P", "K",
                    "CEC", "BD", "EC", "Ca", "Mg", "Na", "S"),

  physical = c("Sand", "Silt", "Clay", "BD"),

  chemical = c("pH", "EC", "CEC", "Ca", "Mg", "K", "Na"),

  fertility = c("OM", "N", "P", "K", "Ca", "Mg", "S", "CEC")
)


#' Generate standard scoring rules for soil properties
#'
#' Automatically assigns appropriate scoring rules to soil properties based
#' on pattern matching of property names. This function provides sensible
#' defaults for common soil properties, reducing the need to manually
#' specify scoring rules for each property.
#'
#' @param properties Character vector of property names, or a single string
#'   naming a pre-defined property set from \code{\link{soil_property_sets}}.
#'   If a property set name is provided (e.g., "basic", "standard"), the
#'   corresponding properties from \code{soil_property_sets} will be used.
#'
#' @return A named list of \code{\link{scoring_rule}} objects, one for each
#'   property. The names of the list correspond to the property names.
#'
#' @details
#' The function applies the following pattern matching rules (case-insensitive):
#' \itemize{
#'   \item Properties containing "ph": \code{\link{optimum_range}}(7, 1)
#'   \item Properties containing "ec" or "electrical": \code{\link{lower_better}}()
#'   \item Properties containing "bd" or "bulk": \code{\link{lower_better}}()
#'   \item Properties containing "om", "soc", or "organic": \code{\link{higher_better}}()
#'   \item Properties containing "n", "nitrogen", "p", "phosph", "k", or "potass":
#'     \code{\link{higher_better}}()
#'   \item Properties containing "cec", "ca", or "mg": \code{\link{higher_better}}()
#'   \item All other properties: \code{\link{higher_better}}() (default)
#' }
#'
#' @examples
#' # Generate rules for basic property set
#' rules <- standard_scoring_rules("basic")
#' names(rules)
#'
#' # Generate rules for custom properties
#' custom_props <- c("pH", "BD", "OM", "Sand")
#' rules <- standard_scoring_rules(custom_props)
#'
#' # View a specific rule
#' rules$pH
#'
#' # Use with standard property sets
#' rules <- standard_scoring_rules(soil_property_sets$standard)
#'
#' @seealso \code{\link{soil_property_sets}}, \code{\link{higher_better}},
#'   \code{\link{lower_better}}, \code{\link{optimum_range}}
#'
#' @export
standard_scoring_rules <- function(properties) {
  # If properties is a single string matching a property set name, use that set
  if (length(properties) == 1 && properties %in% names(soil_property_sets)) {
    properties <- soil_property_sets[[properties]]
  }

  # Validate input
  if (!is.character(properties) || length(properties) == 0) {
    stop("properties must be a character vector or a property set name")
  }

  # Initialize list to store rules
  rules <- vector("list", length(properties))
  names(rules) <- properties

  # Apply pattern matching for each property
  for (prop in properties) {
    # Convert to lowercase for case-insensitive matching
    prop_lower <- tolower(prop)

    # Pattern matching logic - order matters, check more specific patterns first
    if (grepl("^ph$|^ph_|_ph$|\\bph\\b", prop_lower)) {
      # pH: optimum around 7
      # Match: pH, pH_water, soil_pH, but not phosphorus
      rules[[prop]] <- optimum_range(optimal = 7, tolerance = 1)

    } else if (grepl("^ec$|^ec_|_ec$|electrical", prop_lower)) {
      # Electrical conductivity: lower is better
      # Match: EC, EC_dS, electrical_conductivity
      rules[[prop]] <- lower_better()

    } else if (grepl("^bd$|^bd_|_bd$|bulk", prop_lower)) {
      # Bulk density: lower is better
      # Match: BD, BD_gcm3, bulk_density
      rules[[prop]] <- lower_better()

    } else if (grepl("\\bom\\b|soc|organic", prop_lower)) {
      # Organic matter/carbon: higher is better
      rules[[prop]] <- higher_better()

    } else if (grepl("\\bn\\b|nitrogen|\\bp\\b|phosph|\\bk\\b|potass", prop_lower)) {
      # Nutrients (N, P, K): higher is better
      # Using word boundaries for single letters to avoid false matches
      rules[[prop]] <- higher_better()

    } else if (grepl("\\bcec\\b|\\bca\\b|calcium|\\bmg\\b|magnesium", prop_lower)) {
      # CEC, Calcium, Magnesium: higher is better
      # Using word boundaries to avoid false matches
      rules[[prop]] <- higher_better()

    } else {
      # Default: higher is better
      rules[[prop]] <- higher_better()
    }
  }

  return(rules)
}
