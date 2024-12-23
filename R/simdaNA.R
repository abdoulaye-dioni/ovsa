#' Non hierarchical data under missing not at random.
#'
#' The data `simdaNA` contains  missing not at random (MNAR) values in the
#' non hierarchical data.
#'
#'
#' @name simdaNA
#' @format A data frame with 1000 rows and 5 columns:
#' \describe{
#'   \item{id}{Unique identifier for each observation.}
#'   \item{Y}{Binary response variable, with values 0 and 1.}
#'   \item{X1}{Ordinal variable with 5 categories (1 to 5).}
#'   \item{X2}{Categorical variable with 4 categories (1 to 4).}
#'   \item{X1.mis}{Ordinal variable derived from \code{X1}, containing missing values.}
#' }
#'
#' @source The data was generated using the `simmnar` function on the `simda` data.
"simdaNA"
