#' Example Simulated Hierarchical Dataset: simda2
#'
#' @description
#' A hierarchical dataset generated using \code{simulate_bin_hier()} with 3 levels of X1 and 4 levels of X2,
#' grouped into clusters with random effects.
#'
#' @format A `data.frame` with 5000 observations and 5 variables:
#' \describe{
#'   \item{id}{Integer identifier for each observation}
#'   \item{Y}{Binary outcome (factor: 0 or 1)}
#'   \item{X1}{Ordered factor with 3 levels (1 < 2 < 3 )}
#'   \item{X2}{Unordered factor with 4 alphabetic levels: a, b, c,d}
#'   \item{clus}{Cluster identifier (factor)}
#' }
#'
#' @usage data(simda2)
#'
#' @examples
#' data(simda2)
#' head(simda2)
#' str(simda2)
#'
#' @source Simulated internally using the \code{simulate_bin_hier()} function.
"simda2"
