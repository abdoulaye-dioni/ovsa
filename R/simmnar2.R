#' Simulate a Missing Not At Random (MNAR) Mechanism in Hierarchical Data
#'
#' This function simulates a Missing Not At Random (MNAR) mechanism by introducing
#' missing values into an independent ordinal variable, with specific probabilities,
#' based on a binary response variable and a categorical stratification variable.
#'
#' @name simmnar2
#' @keywords MNAR, missing data, Simulation, Hierarchical Context
#'
#' @param data A data.frame containing the dataset.
#' @param proba A named list or data.frame containing the probabilities of missingness
#'   for each stratum of \code{cat_var}. Each stratum must provide two probabilities:
#'   one for group A and one for group B.
#' @param cat_var Character. The name of the stratification (categorical) variable.
#' @param Y Character. The name of the binary variable indicating group membership (1 = group A, 0 = group B).
#' @param id Character. The name of the variable identifying unique individuals.
#' @param ord_var Character. The name of the ordinal variable where missingness will be introduced.
#' @param A A vector of levels in \code{ord_var} defining group A.
#' @param B A vector of levels in \code{ord_var} defining group B.
#' @param seed Optional. Numeric. Seed for reproducibility. Default is \code{NULL} (no fixed seed).
#' @param verbose Logical. If \code{TRUE}, prints progress messages. Default is \code{FALSE}.
#'
#' @details
#' The missingness is introduced separately within each level of \code{cat_var},
#' allowing for a hierarchical MNAR structure. Probabilities must be provided
#' for each stratum and differ between groups A and B.
#'
#' @return A data.frame identical to \code{data} with an additional column
#'   named \code{<ord_var>.mis}, containing the ordinal variable with missing values.
#'
#' @examples
#' if (requireNamespace("ovsa", quietly = TRUE)) {
#'   data("simda2", package = "ovsa")
#'   head(simda2)
#'
#'   missing_prob <- data.frame(matrix(c(0.2,0.3,0.1,0.4,0.4,0.1,0.1,0.3),
#'     nrow = 2, byrow = FALSE, dimnames = list(c("0", "1"), paste0("proba", 1:4))))
#'
#'   simda2NA <- simmnar2(
#'     data = simda2,
#'     proba = missing_prob,
#'     cat_var = "X2",
#'     Y = "Y",
#'     id = "id",
#'     ord_var = "X1",
#'     A = 1,
#'     B = 3,
#'     seed = 123,
#'     verbose = TRUE
#'   )
#'
#'   head(simda2NA)
#'   summary(simda2NA)
#' }
#' @export
simmnar2 <- function(data, proba, cat_var, Y, id, ord_var, A, B, seed = NULL, verbose = FALSE) {

  # Seed
  if (!is.null(seed)) set.seed(seed)

  # Preliminary checks
  if (!is.data.frame(data)) stop("`data` must be a data.frame.")
  if (!is.vector(proba) && !is.data.frame(proba) && !is.list(proba))
    stop("`proba` must be a list or data.frame with probabilities for each stratum.")
  if (!cat_var %in% names(data)) stop("The specified `cat_var` does not exist in the dataset.")
  if (!Y %in% names(data)) stop("The variable `Y` does not exist in the dataset.")
  if (!id %in% names(data)) stop("The variable `id` does not exist in the dataset.")
  if (!ord_var %in% names(data)) stop("The ordinal variable `ord_var` does not exist in the dataset.")
  if (!all(c(A, B) %in% unique(data[[ord_var]]))) {
    warning("Some values in A or B are not present in `ord_var`.")
  }

  # Create a copy of the ordinal variable for introducing missingness
  new_ord_var <- paste0(ord_var, ".mis")
  data[[new_ord_var]] <- data[[ord_var]]

  # Internal function to apply MNAR mechanism within each stratum
  mnar_by_strata <- function(sub_data, Y, id, new_ord_var, probA, probB, A, B) {
    # Group A
    id.A <- sub_data[[id]][sub_data[[Y]] == 1 & sub_data[[new_ord_var]] %in% A]
    if (length(id.A) > 0) {
      size.A <- min(round(length(id.A) * probA), length(id.A))
      sample.A <- sample(id.A, size = size.A, replace = FALSE)
      sub_data[[new_ord_var]][sub_data[[id]] %in% sample.A] <- NA
    }

    # Group B
    id.B <- sub_data[[id]][sub_data[[Y]] == 0 & sub_data[[new_ord_var]] %in% B]
    if (length(id.B) > 0) {
      size.B <- min(round(length(id.B) * probB), length(id.B))
      sample.B <- sample(id.B, size = size.B, replace = FALSE)
      sub_data[[new_ord_var]][sub_data[[id]] %in% sample.B] <- NA
    }

    return(sub_data)
  }

  # Apply MNAR mechanism across all strata
  result <- lapply(unique(data[[cat_var]]), function(stratum) {
    subset_data <- subset(data, data[[cat_var]] == stratum)

    if (verbose) message("Processing stratum: ", stratum)

    # Retrieve probabilities
    if (is.list(proba)) {
      probA <- proba[[as.character(stratum)]][1]
      probB <- proba[[as.character(stratum)]][2]
    } else if (is.data.frame(proba)) {
      probA <- proba[as.character(stratum), 1]
      probB <- proba[as.character(stratum), 2]
    } else {
      stop("`proba` must be a list or data.frame.")
    }

    mnar_by_strata(
      sub_data = subset_data,
      Y = Y,
      id = id,
      new_ord_var = new_ord_var,
      probA = probA,
      probB = probB,
      A = A,
      B = B
    )
  })

  # Combine and return
  return(do.call(rbind, result))
}
