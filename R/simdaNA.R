#' Example Dataset with missing data: simdaNA
#'
#' This dataset is a generated example for the package. It contains four variables:
#' - A binary response variable "Y".
#' - An ordinal variable "X1" with 5 categories.
#' - A categorical variable "X2" with 4 categories.
#' - A unique identifier "id" for each observation.
#' - An ordinal variable "X1.mnar" under MNAR.
#'
#' @format A data frame with 1000 rows and 5 columns:
#' \describe{
#'   \item{id}{Unique identifier for observations.}
#'   \item{Y}{Binary response variable, with values 0 and 1.}
#'   \item{X1}{Ordinal variable with 5 categories (1 to 5).}
#'   \item{X2}{Categorical variable with 4 categories (1 to 4).}
#'   \item{X1.mnar}{Ordinal variable with missing values.}
#' }
#' @source Generated with the script located in `data-raw/simdaNA.R`.
"simdaNA"
