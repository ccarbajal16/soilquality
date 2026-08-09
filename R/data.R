#' Soil Data from Ucayali, Peru
#'
#' Soil physical, chemical and fertility properties from 50 samples in the
#' Ucayali region of Peru. This is the package's general-purpose example
#' dataset, used throughout the documentation and vignettes.
#'
#' @format A data frame with 50 rows and 16 columns:
#' \describe{
#'   \item{SampleID}{Character. Unique identifier for each soil sample (UCY001-UCY050)}
#'   \item{Sand}{Numeric. Sand content as percentage of soil texture (0-100)}
#'   \item{Silt}{Numeric. Silt content as percentage of soil texture (0-100)}
#'   \item{Clay}{Numeric. Clay content as percentage of soil texture (0-100)}
#'   \item{BD}{Numeric. Bulk density in g/cm³}
#'   \item{pH}{Numeric. Soil pH measured in water (1:1)}
#'   \item{OM}{Numeric. Organic matter content as percentage}
#'   \item{SOC}{Numeric. Soil organic carbon content as percentage}
#'   \item{N}{Numeric. Total nitrogen content as percentage}
#'   \item{P}{Numeric. Available phosphorus in mg/kg (Olsen method)}
#'   \item{K}{Numeric. Exchangeable potassium in mg/kg}
#'   \item{CEC}{Numeric. Cation exchange capacity in cmol/kg}
#'   \item{Ca}{Numeric. Exchangeable calcium in cmol/kg}
#'   \item{Mg}{Numeric. Exchangeable magnesium in cmol/kg}
#'   \item{EC}{Numeric. Electrical conductivity in dS/m}
#'   \item{S}{Numeric. Sulfur content in mg/kg}
#' }
#'
#' @details
#' The soils are generally acidic (pH 4-7.5), with moderate organic matter and
#' variable nutrient levels typical of tropical agricultural soils in the
#' Ucayali region.
#'
#' \strong{Choosing between the two example datasets.} The values here are
#' simulated with each property drawn independently, so the dataset has almost
#' no covariance structure: the largest off-diagonal Spearman correlation is
#' 0.66 and exactly one pair of indicators clears a 0.6 threshold. That is
#' fine, and realistic enough, for demonstrating scoring, weighting and
#' aggregation, which treat indicators one at a time.
#'
#' It is \strong{not} suitable for any method that reads the structure
#' \emph{between} indicators -- correlation-network selection, functional
#' grouping, redundancy screening. Use \code{\link{soil_structured}} for those.
#'
#' @section A note on this dataset's own soil quality index:
#' Running \code{\link{sqi_validate}} on the default recipe applied to this
#' data fires the middle-band warning: the resulting index spans roughly
#' 0.36 to 0.70, so every sample lands in the middle bands and both extreme
#' categories are empty. That is the diagnostic working, not a defect, and it
#' is a useful thing to see before trusting an index built the same way on
#' real data.
#'
#' @source Simulated data based on typical soil properties from the Ucayali
#'   region of Peru.
#'
#' @examples
#' # Load the dataset
#' data(soil_data)
#'
#' # View structure
#' str(soil_data)
#'
#' # Summary statistics
#' summary(soil_data)
#'
#' # Basic SQI calculation with extended properties
#' \dontrun{
#' result <- compute_sqi_properties(
#'   data = soil_data,
#'   properties = c("pH", "OM", "N", "P", "K", "S", "CEC"),
#'   id_column = "SampleID"
#' )
#' print(result)
#' }
#'
#' @seealso \code{\link{soil_structured}}, which carries realistic covariance
#'   and is the one to use for indicator-selection methods
"soil_data"

#' Simulated Soil Data with Realistic Covariance Structure
#'
#' A dataset of 120 simulated soil samples in which the properties are
#' \strong{related to one another the way real soil properties are}. It exists
#' because \code{\link{soil_data}} does not: it draws every property
#' independently, so it carries almost no covariance and cannot exercise any
#' method that works on the relationships \emph{between} indicators.
#'
#' @format A data frame with 120 rows and 16 columns:
#' \describe{
#'   \item{SampleID}{Character. Unique identifier (STR001-STR120)}
#'   \item{Sand}{Numeric. Sand content (\%)}
#'   \item{Silt}{Numeric. Silt content (\%)}
#'   \item{Clay}{Numeric. Clay content (\%)}
#'   \item{BD}{Numeric. Bulk density (g/cm3)}
#'   \item{pH}{Numeric. Soil pH in water}
#'   \item{OM}{Numeric. Organic matter (\%)}
#'   \item{SOC}{Numeric. Soil organic carbon (\%)}
#'   \item{N}{Numeric. Total nitrogen (\%)}
#'   \item{P}{Numeric. Available phosphorus (mg/kg)}
#'   \item{K}{Numeric. Exchangeable potassium (mg/kg)}
#'   \item{CEC}{Numeric. Cation exchange capacity (cmol/kg)}
#'   \item{Ca}{Numeric. Exchangeable calcium (cmol/kg)}
#'   \item{Mg}{Numeric. Exchangeable magnesium (cmol/kg)}
#'   \item{S}{Numeric. Sulfur (mg/kg)}
#'   \item{EC}{Numeric. Electrical conductivity (dS/m)}
#' }
#'
#' @details
#' The values are simulated, but from three latent gradients -- texture,
#' organic status and base status -- so that the standard pedological
#' relationships hold rather than being absent:
#'
#' \itemize{
#'   \item \code{Sand + Silt + Clay = 100} exactly (compositional closure)
#'   \item \code{SOC = OM / 1.724} (van Bemmelen factor), giving
#'     \eqn{\rho \approx 0.99}
#'   \item \code{N = SOC / (C:N)} with a C:N ratio near 11
#'   \item \code{CEC} generated by clay surfaces and organic colloids together,
#'     which makes it the hub of the correlation network
#'   \item \code{Ca} and \code{Mg} occupying exchange sites, so both track
#'     \code{CEC} and \code{pH}
#'   \item \code{BD} falling with organic matter and rising with sand
#'     (\eqn{\rho \approx -0.85} against \code{OM})
#'   \item \code{EC} carried by soluble bases
#' }
#'
#' \strong{Forty pairs} of indicators reach \eqn{|\rho| \ge 0.6}, against
#' \strong{one} in \code{soil_data}.
#'
#' \strong{What it is useful for.} Any method that reads the structure between
#' indicators: \code{\link{na_select_mds}}, \code{\link{mds_consensus}}, and
#' redundancy screening. It also separates the two selection routes cleanly, in
#' a way that is worth seeing before choosing one:
#'
#' \itemize{
#'   \item \code{\link{na_select_mds}} selects \strong{OM} and \strong{CEC} --
#'     the hubs.
#'   \item \code{\link{pca_select_mds}} selects \strong{pH} and \strong{Silt}
#'     -- high-variance and, in Silt's case, nearly uncorrelated with anything.
#'   \item Their consensus is \strong{empty}. That is not a defect in either
#'     method; it is the asymmetry the two documents warn about, made visible.
#'     PCA rewards variance and uniqueness, network analysis rewards centrality.
#' }
#'
#' The base-status module (\code{pH}, \code{Ca}, \code{Mg}, \code{EC}) is
#' internally coherent but peripheral to the network, so the centrality filter
#' discards it -- an illustration of why selecting within functional groups,
#' rather than across the whole pool, is worth doing.
#'
#' @source Simulated. The generating script is
#'   \code{data-raw/create_soil_structured.R}, which states every relationship
#'   and coefficient used.
#'
#' @examples
#' data(soil_structured)
#'
#' # The relationships real soil data has, which soil_data lacks
#' round(cor(soil_structured$OM, soil_structured$SOC, method = "spearman"), 3)
#' round(cor(soil_structured$OM, soil_structured$BD, method = "spearman"), 3)
#'
#' # Texture is compositional
#' range(soil_structured$Sand + soil_structured$Silt + soil_structured$Clay)
#'
#' \donttest{
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   props <- setdiff(names(soil_structured), "SampleID")
#'   agreement <- mds_consensus(soil_structured[, props])
#'   agreement$network$mds
#'   agreement$pca$mds
#' }
#' }
#'
#' @seealso \code{\link{soil_data}}, which is simpler but carries no
#'   covariance structure
"soil_structured"
