#' Hierarchical data with missing values
#'
#' The dataset `simda2NA` is an example generated from a hierarchical simulation.
#' It includes simulated variables representing clusters, categorical covariates,
#' and a binary response variable.
#'
#' @format A data.frame with 2000 rows and 6 columns:
#' \describe{
#'   \item{id}{Unique identifier for each observation.}
#'   \item{y}{Binary response variable (factor).}
#'   \item{x1}{Ordered categorical variable.}
#'   \item{x2}{Categorical variable (factor).}
#'   \item{clus}{Cluster identifier.}
#'   \item{x1.mnar}{Ordered categorical variable with missing values.}
#' }
#' @source Data generated using the `simulation_hierachical` function.`data-raw/simda2NA.R`
"simda2NA"
