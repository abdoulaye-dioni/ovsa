#' Example of Simulated Data for a Hierarchical Structure
#'
#' The dataset `simda2` is an example generated from a hierarchical simulation.
#' It includes simulated variables representing clusters, categorical covariates,
#' and a binary response variable.
#'
#' @format A data.frame with 2000 rows and 5 columns:
#' \describe{
#'   \item{id}{Unique identifier for each observation.}
#'   \item{y}{Binary response variable (factor).}
#'   \item{x1}{Ordered categorical variable.}
#'   \item{x2}{Categorical variable (factor).}
#'   \item{clus}{Cluster identifier.}
#' }
#' @source Data generated using the `simulation_hierachical` function.
"simda2"
