#' Simulate MNAR Missing Data for hierarchical data
#'
#' This function introduces missing data under a MNAR (Missing Not At Random) mechanism
#' in an ordinal variable based on a stratified approach.
#'
#' @name simmnar2
#' @keywords ordinal variable, categorical variable, MNAR, missing data
#' @param data A data frame containing the dataset.
#' @param proba A named list or data frame containing the probabilities of missingness
#'   for each stratum of `cat_var`. Each stratum must contain a vector of two probabilities:
#'   one for group A and one for group B.
#' @param cat_var The name of the categorical variable (stratification variable).
#' @param Y The name of the binary variable indicating group membership (1 for group A, 0 for group B).
#' @param id The name of the variable identifying unique individuals.
#' @param ord_var The name of the ordinal variable where missingness will be introduced.
#' @param A A vector of values in `ord_var` defining group A.
#' @param B A vector of values in `ord_var` defining group B.
#' @param seed An optional random seed for reproducibility. Defaults to 123.
#' @return A data frame with a new column named `<ord_var>.mis`, containing the ordinal variable
#'   with missing values introduced under the MNAR mechanism.
#'
#' @examples
#'  data("simda2")
#'  head(simda2)
#'
#'  missing_prob <- data.frame(matrix(c(0.2,0.3,0.5,0.4,0.4,0.2,0.3,0.3),
#'  nrow = 2, byrow = FALSE,dimnames = list(c("0","1"),paste0("proba",1:4))))
#'  missing_prob
#'
#'  simda2NA <- simmnar2(data = simda2,proba = missing_prob,cat_var = "x2",
#'  Y = "y", id = "id", ord_var = "x1", A = 1, B = 3)
#'
#'  simda2NA[102:108,]
#'
#'  summary(simda2NA)
#'
#' @export


simmnar2 <- function(data, proba, cat_var, Y, id, ord_var, A, B, seed = 123) {

  # Preliminary checks
  if (!is.data.frame(data)) stop("`data` must be a data frame.")
  if (!is.vector(proba) && !is.data.frame(proba) && !is.list(proba))
    stop("`proba` must be a list or data frame with probabilities for each stratum.")
  if (!cat_var %in% names(data)) stop("The specified `cat_var` does not exist in the dataset.")
  if (!Y %in% names(data)) stop("The variable `Y` does not exist in the dataset.")
  if (!id %in% names(data)) stop("The variable `id` does not exist in the dataset.")
  if (!ord_var %in% names(data)) stop("The ordinal variable `ord_var` does not exist in the dataset.")

  # Create a copy of the ordinal variable for introducing missingness
  new_ord_var <- paste0(ord_var, ".mis")
  data[[new_ord_var]] <- data[[ord_var]]

  # Internal function for MNAR mechanism within a stratum
  mnar_by_strata <- function(sub_data, Y, id, new_ord_var, probA, probB, A, B, seed) {
    set.seed(seed)  # Ensure reproducibility

    # Handle group A
    id.A <- sub_data[[id]][sub_data[[Y]] == 1 & sub_data[[new_ord_var]] %in% A]
    if (length(id.A) > 0) {
      sample.A <- sample(id.A, size = round(length(id.A) * probA), replace = FALSE)
      sub_data[[new_ord_var]][sub_data[[id]] %in% sample.A] <- NA
    }

    # Handle group B
    id.B <- sub_data[[id]][sub_data[[Y]] == 0 & sub_data[[new_ord_var]] %in% B]
    if (length(id.B) > 0) {
      sample.B <- sample(id.B, size = round(length(id.B) * probB), replace = FALSE)
      sub_data[[new_ord_var]][sub_data[[id]] %in% sample.B] <- NA
    }

    return(sub_data)
  }

  # Apply MNAR mechanism by stratum
  result <- lapply(unique(data[[cat_var]]), function(stratum) {
    subset_data <- subset(data, data[[cat_var]] == stratum)

    # Retrieve probabilities for the current stratum
    if (is.list(proba)) {
      probA <- proba[[stratum]][1]
      probB <- proba[[stratum]][2]
    } else if (is.data.frame(proba)) {
      probA <- proba[stratum, 1]
      probB <- proba[stratum, 2]
    } else {
      stop("`proba` must be either a named list or data frame.")
    }

    # Apply MNAR mechanism
    mnar_by_strata(
      sub_data = subset_data,
      Y = Y,
      id = id,
      new_ord_var = new_ord_var,
      probA = probA,
      probB = probB,
      A = A,
      B = B,
      seed = seed
    )
  })

  # Combine results from all strata
  return(do.call(rbind, result))
}
