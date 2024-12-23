#' Hierarchical data under missing not at random.
#'
#' The data `simda2NA` contains  missing not at random (MNAR) values in the
#' hierarchical data.
#'
#' @format A data.frame with 2000 rows and 6 columns:
#' \describe{
#'   \item{id}{Unique identifier for each observation.}
#'   \item{y}{Binary response variable (factor).}
#'   \item{x1}{Ordered categorical variable.}
#'   \item{x2}{Categorical variable (factor).}
#'   \item{clus}{Cluster identifier.}
#'   \item{x1.mis}{Ordered categorical variable with missing values.}
#' }
#' @source The data was generated using the `simmnar2` function on the `simda2` data.
"simda2NA"
