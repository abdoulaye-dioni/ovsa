#' Example Simulated Dataset: simda
#'
#' @description
#' A dataset generated using \code{simulate_bin_nonhier()} with 4 levels of X2 and 5 levels of X1.
#'
#' @format A `data.frame` with 1000 observations and 4 variables:
#' \describe{
#'   \item{id}{Integer identifier}
#'   \item{X2}{Factor with 4 alphabetic levels: a, b, c, d}
#'   \item{X1}{Ordered factor with 5 levels (1 < 2 < 3 < 4 < 5)}
#'   \item{Y}{Binary outcome (factor: 0 or 1)}
#' }
#'
#' @usage data(simda)
#'
#' @examples
#' data(simda)
#' head(simda)
#' str(simda)
"simda"
