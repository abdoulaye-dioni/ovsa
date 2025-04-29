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
#' @param verbose Logical. If \code{TRUE}, displays a warning message about potential convergence issues
#' when using \code{jomo}. If \code{FALSE}, suppresses these warnings. Default is \code{TRUE}.

#'
#' @details
#' When \code{mi = "mice"}, the function uses the \code{mice} package, which performs
#' multiple imputation by chained equations, typically used for non-hierarchical data.
#' When \code{mi = "jomo"}, the function uses the \code{jomo} package, suitable for
#' hierarchical or clustered data through a multilevel imputation approach.
#'
#' Note: When using \code{jomo}, convergence warnings (e.g., degenerate Hessian matrix,
#' failed convergence) may appear during the imputation process. This behavior is
#' expected in some simulation scenarios and does not necessarily invalidate the
#' resulting imputations. Users should nonetheless examine the imputed datasets
#' for plausibility if extensive warnings occur.
#'
#' @return For `mi = "mice"`, returns a `mids` object containing multiple imputations.
#' For `mi = "jomo"`, returns a single completed dataset or a list, depending on the
#' arguments and output type of `jomo`.
#'
#' @export
#'
#' @examples
#' # Example 1: Imputation with mice (non-hierarchical data)
#' if (requireNamespace("ovsa", quietly = TRUE) &&
#' requireNamespace("mice", quietly = TRUE)) {
#'   data(simda)
#'
#'   set.seed(123)
#'   simdaNA <- simmnar(
#'     data = simda,
#'     Y = "Y",
#'     ord_var = "X1",
#'     A = 1,
#'     probA = 0.3,
#'     B = 5,
#'     probB = 0.5
#'   )
#'
#'   simdaNA$X1.mar <- simdaNA$X1.mis
#'
#'   imputed_mice <- firststep(
#'     data = simdaNA[, c("Y", "X1.mar", "X2")],
#'     mi = "mice",
#'     method = c("logreg", "polr", "polyreg"),
#'     m = 5,
#'     printFlag = FALSE
#'   )
#'
#'   print(head(mice::complete(imputed_mice, 1)))
#' }
#'
#' # Example 2: Imputation with jomo (hierarchical data)
#' if (requireNamespace("ovsa", quietly = TRUE) &&
#'     requireNamespace("jomo", quietly = TRUE) &&
#'     requireNamespace("mitml", quietly = TRUE)) {
#'
#'   data(simda2)
#' simda2$clus <- as.numeric(simda2$clus)
#'   # Simulate missingness
#'   missing_prob <- data.frame(
#'     matrix(c(0.2, 0.3, 0.5, 0.4, 0.4, 0.2, 0.3, 0.3),
#'            nrow = 2, byrow = FALSE,
#'            dimnames = list(c("0", "1"), paste0("proba", 1:4)))
#'   )
#'
#'   set.seed(215)
#'   simda2NA <- simmnar2(
#'     data = simda2,
#'     proba = missing_prob,
#'     cat_var = "X2",
#'     Y = "Y",
#'     id = "id",
#'     ord_var = "X1",
#'     A = 1,
#'     B = 3
#'   )
#'
#'
#'
#'   simda2NA$X1.mar <- simda2NA$X1.mis
#'
#'   formula <- Y ~ X1.mar + X2 + (1 | clus)
#'
#'   imputed_jomo <- firststep(
#'     data = simda2NA[, c("Y", "X1.mar", "X2", "clus")],
#'     mi = "jomo",
#'     formula = formula,
#'     nimp = 5,
#'     nburn = 10,
#'     nbetween = 10,
#'     output = 0
#'   )
#'
#'   print(head(mitml::jomo2mitml.list(imputed_jomo)[[1]]))
#' }
firststep <- function(data, mi = c("mice", "jomo"), verbose = TRUE, ...) {
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
    if (verbose) {
      message("Note: You may observe convergence warnings from jomo. This is expected and does not necessarily affect imputations.")
      imputed <- jomo::jomo.glmer(data, ...)
    } else {
      suppressWarnings(
        imputed <- jomo::jomo.glmer(data, ...)
      )
    }

    return(imputed)  # Returns a completed dataset
  } else {
    stop("Invalid method. Please choose 'mice' or 'jomo'.")
  }
}
