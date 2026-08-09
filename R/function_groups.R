#' Soil indicators grouped by ecosystem function
#'
#' A grouping of soil indicators by the \strong{function} they serve, for use
#' as the \code{groups} argument of \code{\link{pca_select_mds}} and
#' \code{\link{na_select_mds}}. Selecting one indicator per function, rather
#' than picking across the whole pool at once, is what the literature calls an
#' expanded minimum data set (EMDS).
#'
#' @format A named list of five character vectors:
#' \describe{
#'   \item{carbon_cycling}{\code{OM}, \code{SOC} -- the organic carbon pool}
#'   \item{nutrient_cycling}{\code{N}, \code{P}, \code{K}, \code{Ca},
#'     \code{Mg}, \code{S} -- plant-available nutrient supply}
#'   \item{physical_structure}{\code{Sand}, \code{Silt}, \code{Clay},
#'     \code{BD} -- texture and compaction}
#'   \item{buffering_filtration}{\code{pH}, \code{CEC}, \code{EC} -- the
#'     capacity to buffer reaction and retain or transmit solutes}
#'   \item{biodiversity}{empty -- see Details}
#' }
#'
#' @details
#' \strong{Why group by function rather than by physical/chemical/biological.}
#' Two independent lines of evidence point the same way.
#'
#' Yuan and Shi (2026) found that fidelity to the total data set improved
#' monotonically with grouping detail: an expanded, function-grouped minimum
#' data set reached R-squared 0.74-0.77, above a reduced grouping, which was
#' above no grouping at all. The function-grouped route was also the most
#' \strong{stable} across scoring and aggregation choices.
#'
#' Maaz et al. (2023) attacked it from the other side. By confirmatory factor
#' analysis they tested whether the familiar physical / chemical / biological
#' split describes how soil indicators actually covary, and found it
#' \strong{has no statistical support}. It is a convention inherited from how
#' laboratories are organised, not a structure present in the data.
#'
#' \strong{This package still ships that split}, as
#' \code{soil_property_sets$physical} and \code{$chemical}. Those sets are
#' exported, documented and depended upon, so they are not going anywhere --
#' but they are a vocabulary for \emph{choosing which properties to measure},
#' not a basis for selecting a minimum data set. Use
#' \code{soil_function_groups} for selection.
#'
#' \strong{The empty biodiversity group is deliberate.} Yuan's fifth function,
#' soil biodiversity maintenance, has \strong{no indicator} in the vocabulary
#' this package's example data provides -- it needs microbial biomass carbon,
#' enzyme activity, respiration or a community measure, none of which are
#' present. The group is shipped empty rather than filled with a proxy,
#' because a plausible-looking stand-in would silently misrepresent which
#' functions the index actually covers. Selection functions skip empty groups.
#'
#' \strong{Some indicators serve more than one function.} Calcium and
#' magnesium are placed in nutrient cycling because they are measured as
#' plant-available nutrients, but they are also exchangeable bases and
#' contribute to buffering. Clay contributes to structure and to cation
#' retention. The assignment here is a defensible default, not a fact; supply
#' your own list where your interpretation differs.
#'
#' @references
#' Yuan, X. and Shi, Y. (2026), after Li et al. (2023) -- the five functions.
#' Maaz, T. M. et al. (2023) -- the confirmatory factor analysis.
#'
#' @examples
#' names(soil_function_groups)
#' soil_function_groups$carbon_cycling
#'
#' # The biodiversity group ships empty; nothing in the example data measures it
#' soil_function_groups$biodiversity
#'
#' # Use it to select within functions rather than across the whole pool
#' props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
#'            "CEC", "BD")
#' groups <- assign_function_groups(props)
#' pca_select_mds(standardize_numeric(soil_structured[, props]),
#'                groups = groups)
#'
#' @seealso \code{\link{assign_function_groups}} to map an arbitrary set of
#'   property names onto these functions; \code{\link{soil_property_sets}} for
#'   the measurement-oriented sets
"soil_function_groups"


#' Map property names onto soil function groups
#'
#' Assigns a set of property names to the functions in
#' \code{\link{soil_function_groups}}, producing a list suitable for the
#' \code{groups} argument of \code{\link{pca_select_mds}} and
#' \code{\link{na_select_mds}}.
#'
#' @details
#' Matching is case-insensitive and exact on the property name. Properties
#' that match nothing are reported in the \code{"unassigned"} element rather
#' than being silently dropped, so that a typo or an indicator outside the
#' known vocabulary is visible. Empty groups are removed unless
#' \code{drop_empty = FALSE}.
#'
#' An unassigned indicator is \strong{excluded from grouped selection}: the
#' selection functions only look inside the groups they are given. If an
#' indicator matters, put it in a group explicitly.
#'
#' @param properties Character vector of property names.
#' @param groups A named list of character vectors defining the functions.
#'   Defaults to \code{\link{soil_function_groups}}.
#' @param drop_empty If \code{TRUE} (the default), functions with no matching
#'   property are omitted from the result.
#'
#' @return A named list of character vectors, one per function, plus an
#'   \code{"unassigned"} element when some properties matched nothing.
#'
#' @examples
#' assign_function_groups(c("pH", "OM", "SOC", "BD", "N"))
#'
#' # Unknown names are surfaced, not swallowed
#' assign_function_groups(c("OM", "Zn", "typo"))
#'
#' @seealso \code{\link{soil_function_groups}}
#'
#' @export
assign_function_groups <- function(properties,
                                   groups = soil_function_groups,
                                   drop_empty = TRUE) {
  if (!is.character(properties) || length(properties) == 0) {
    stop("properties must be a non-empty character vector")
  }

  if (!is.list(groups) || is.null(names(groups))) {
    stop("groups must be a named list of character vectors")
  }

  assigned <- lapply(groups, function(members) {
    properties[tolower(properties) %in% tolower(members)]
  })

  unassigned <- setdiff(
    properties,
    unlist(assigned, use.names = FALSE)
  )

  if (drop_empty) {
    assigned <- assigned[vapply(assigned, length, integer(1)) > 0]
  }

  if (length(unassigned) > 0) {
    assigned[["unassigned"]] <- unassigned
  }

  assigned
}


# Internal: normalise and validate a `groups` argument against the columns
# actually present, shared by pca_select_mds() and na_select_mds().
.validate_groups <- function(groups, available, arg_name = "groups") {
  if (!is.list(groups) || is.null(names(groups)) || any(names(groups) == "")) {
    stop(arg_name, " must be a named list of character vectors")
  }

  # "unassigned" is produced by assign_function_groups() as a report of what
  # matched nothing. Selecting within it would defeat the point of grouping.
  groups <- groups[names(groups) != "unassigned"]

  if (!all(vapply(groups, is.character, logical(1)))) {
    stop(arg_name, " must contain only character vectors")
  }

  # Report what is missing BEFORE trimming, or there is nothing left to report.
  missing <- setdiff(unlist(groups, use.names = FALSE), available)
  if (length(missing) > 0) {
    warning("Ignoring indicators listed in ", arg_name,
            " but absent from the data: ",
            paste(missing, collapse = ", "))
  }

  groups <- lapply(groups, intersect, y = available)

  # Empty groups are dropped silently: soil_function_groups ships one on
  # purpose (biodiversity), and erroring on it would make the default unusable.
  groups <- groups[vapply(groups, length, integer(1)) > 0]

  if (length(groups) == 0) {
    stop("No group in ", arg_name, " contains any indicator present in the ",
         "data. Check that the group members match the column names.")
  }

  duplicated_members <- unlist(groups, use.names = FALSE)
  duplicated_members <- duplicated_members[duplicated(duplicated_members)]
  if (length(duplicated_members) > 0) {
    warning("These indicators appear in more than one group and will be ",
            "selected within each: ",
            paste(unique(duplicated_members), collapse = ", "))
  }

  groups
}
