#' Impute Missing Data under Missing At Random using mice or jomo
#'
#' This function performs imputation of missing data in a dataset using either
#' the `mice` or `jomo` package, depending on the specified method. The `mice`
#' package uses multiple imputation by chained equations, while `jomo` employs
#' a multilevel imputation approach.
#'
#' @name firststep
#' @param data A dataframe containing missing values to be imputed.
#' @param mi A character string specifying the imputation method: either `"mice"` or `"jomo"`.
#' @param ... Additional arguments passed to the respective imputation functions.
#'
#' @return For `mi = "mice"`, returns a `mids` object containing multiple imputations.
#' For `mi = "jomo"`, returns a single completed dataset or a list, depending on the
#' arguments and output type of `jomo`.
#'
#' @export
#'
#' @examples
#'
#'
#'
#' data("simdaNA")
#' summary(simdaNA)
#' library(mice)
#' simdaNA$X1.mar <- simdaNA$X1.mis
#' imputed_mice <- firststep(
#'   data = simdaNA[, c("Y", "X1.mar", "X2")],
#'   mi = "mice",
#'   method = c("logreg", "polr", "polyreg"),
#'   m = 10,
#'   printFlag = FALSE
#' )
#' head(complete(imputed_mice, 1)) # View the first imputed dataset
#'
#' #---------  Example 2: Imputation with jomo -------------------------#
#'
#' # Example 2: Imputation with jomo
#' data("simda2NA")
#' summary(simda2NA)
#' library(jomo)
#'
#' simda2NA$x1.mar <- simda2NA$x1.mis
#' formula <- y ~ x1.mar + x2 + (1 | clus)
#' imputed_jomo <- firststep(
#'   data = simda2NA[, c("y", "x1.mar", "x2", "clus")],
#'   mi = "jomo",
#'   formula = formula,
#'   nimp = 5,
#'   nburn = 10,
#'   nbetween = 10,
#'   output=0
#' )
#' head((mitml::jomo2mitml.list(imputed_jomo))[[1]]) # Convert jomo output to mitml format
#'
firststep <- function(data, mi = c("mice", "jomo"), ...) {
  # Validate the chosen method
  mi <- match.arg(mi)

  # Load required packages based on the method
  if (mi == "mice") {
    if (!requireNamespace("mice", quietly = TRUE)) {
      stop("Please install the 'mice' package to use this function.")
    }
    # Perform imputation using mice
    imputed <- mice::mice(data, ...)
    return(imputed)  # Returns a mids object
  } else if (mi == "jomo") {
    if (!requireNamespace("jomo", quietly = TRUE)) {
      stop("Please install the 'jomo' package to use this function.")
    }
    # Perform imputation using jomo
    imputed <- jomo::jomo.glmer(data, ...)
    return(imputed)  # Returns a completed dataset
  } else {
    # This case should not occur due to match.arg()
    stop("Invalid method. Please choose 'mice' or 'jomo'.")
  }
}
