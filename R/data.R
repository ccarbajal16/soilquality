#' Example Soil Data from Ucayali, Peru
#'
#' A dataset containing soil physical, chemical, and fertility properties from
#' 50 soil samples collected in the Ucayali region of Peru. This dataset is
#' provided as an example for demonstrating the soil quality index (SQI)
#' calculation workflow.
#'
#' @format A data frame with 50 rows and 15 columns:
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
#' }
#'
#' @details
#' The dataset represents typical soil properties found in tropical agricultural
#' soils of the Ucayali region. Values are simulated but based on realistic
#' ranges for this region. The soils are generally acidic (pH 4-7.5), with
#' moderate organic matter content and variable nutrient levels.
#'
#' This dataset can be used to:
#' \itemize{
#'   \item Demonstrate the complete SQI calculation workflow
#'   \item Test different property selection strategies
#'   \item Explore various scoring rules and weighting methods
#'   \item Generate example visualizations
#' }
#'
#' @source Simulated data based on typical soil properties from the Ucayali
#'   region of Peru.
#'
#' @examples
#' # Load the dataset
#' data(soil_ucayali)
#'
#' # View structure
#' str(soil_ucayali)
#'
#' # Summary statistics
#' summary(soil_ucayali)
#'
#' # Basic SQI calculation with standard properties
#' \dontrun{
#' result <- compute_sqi_properties(
#'   data = soil_ucayali,
#'   properties = c("pH", "OM", "N", "P", "K", "CEC"),
#'   id_column = "SampleID"
#' )
#' print(result)
#' }
"soil_ucayali"

#' Extended Soil Data from Ucayali, Peru
#'
#' An extended dataset containing soil physical, chemical, and fertility properties
#' from 50 soil samples collected in the Ucayali region of Peru. This dataset includes
#' all properties from \code{\link{soil_ucayali}} plus an additional sulfur (S) measurement.
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
#' This dataset extends \code{\link{soil_ucayali}} with sulfur measurements, providing
#' a more comprehensive view of soil fertility properties. The soils are generally
#' acidic (pH 4-7.5), with moderate organic matter content and variable nutrient levels
#' typical of tropical agricultural soils in the Ucayali region.
#'
#' This dataset can be used to:
#' \itemize{
#'   \item Demonstrate SQI calculations with an extended set of soil properties
#'   \item Test property selection with additional nutrient parameters
#'   \item Compare results between standard and extended property sets
#'   \item Explore the impact of sulfur in soil quality assessment
#' }
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
#' @seealso \code{\link{soil_ucayali}} for the standard dataset without sulfur
"soil_data"
