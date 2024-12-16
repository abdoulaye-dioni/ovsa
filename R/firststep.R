#' Impute missing data under Missing At Random using mice or jomo
#'
#' This function imputes missing data in a dataset using either the `mice` or `jomo` package.
#'
#' @param data A data frame containing missing values to be imputed.
#' @param mi A character string specifying the imputation method: "mice" or "jomo".
#' @param m Number of imputations to perform (default is 5).
#' @param seed A seed for reproducibility (default is 123).
#' @param ... Additional arguments passed to the imputation functions.
#'
#' @return A list containing imputed datasets (`mice` output) or a single completed dataset (`jomo` output).
#' @export
#' @examples
#'
#' data("simda")
#'
#' simdaNA <- simmnar(simda, Y = "Y", id = "id", ord_var = "X1",
#'                    A = 1, Prob.A = 0.5, B = 5, Prob.B = 0.8)
#'
#' library(mice)
#'
#' # Imputation with mice
#' imputed_mice <- impute_mar(simdaNA[, c("Y","X1.mis","X2")], mi = "mice",
#' method = c("logreg", "polr", "polyreg"), m = 10,printFlag = FALSE)
#'
#' head(mice::complete(imputed_mice,1)) # imputation with mice
#'
#' library(jomo)
#' # Imputation with jomo
#' imputed_jomo <- impute_mar(data = simdaNA[, c("Y","X1.mis","X2")], mi = "jomo",
#' m = 5, output=0)
#'
#' imputed_jomo[1504:1510,] #  imputation with jomo
#'
impute_mar <- function(data, mi = c("mice","jomo"), m = 5, seed = 123, ...) {
  # Load required packages
  if (!requireNamespace("mice", quietly = TRUE)) stop("Please install the 'mice' package.")
  if (!requireNamespace("jomo", quietly = TRUE)) stop("Please install the 'jomo' package.")

  # Set seed for reproducibility
  set.seed(seed)

  if (mi == "mice") {
    # Use mice for imputation
    imputed <- mice::mice(data, m = m, ...)
    return(imputed)  # Returns a mids object
  } else if (mi == "jomo") {
    # Convert categorical variables to factors for jomo
    data <- data.frame(lapply(data, function(x) {
      if (is.character(x)) as.factor(x) else x
    }))

    # Use jomo for imputation
    imputed <- jomo::jomo1(Y = data, nimp = m,...)
    return(imputed)  # Returns a completed dataset
  } else {
    stop("Invalid method. Please choose 'mice' or 'jomo'.")
  }
}
