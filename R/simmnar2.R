#' Simulate a Missing Not At Random (MNAR) Mechanism in the Hierarchical data.
#'
#' This function simulates a Missing Not At Random (MNAR) mechanism by introducing
#' missing values into an independent ordinal variable with specific probabilities
#' based on a binary response variable and a independent categorical variable.
#'
#'
#'
#' @name simmnar2
#' @keywords MNAR,  missing data, Simulation,  Hierarchical Context.
#' @param data A dataframe.
#' @param proba A named list or dataframe containing the probabilities of missingness
#'   for each stratum of `cat_var`. Each stratum must contain a vector of two probabilities:
#'   one for group A and one for group B.
#' @param cat_var The name of the categorical variable (stratification variable).
#' @param Y The name of the binary variable indicating group membership (1 for group A, 0 for group B).
#' @param id The name of the variable identifying unique individuals.
#' @param ord_var The name of the ordinal variable where missingness will be introduced.
#' @param A a vector of values in `ord_var` defining group A.
#' @param B a vector of values in `ord_var` defining group B.
#' @return A dataframe with a new column named `<ord_var>.mis`, containing the ordinal variable
#'   with missing values introduced under the MNAR mechanism.
#'
#'
#' @export
#' @examples
#'
#'  data("simda2")
#'  head(simda2)
#'
#'  missing_prob <- data.frame(matrix(c(0.2,0.3,0.5,0.4,0.4,0.2,0.3,0.3),
#'  nrow = 2, byrow = FALSE,dimnames = list(c("0","1"),paste0("proba",1:4))))
#'  missing_prob
#'
#'  set.seed(215) # for reproducibility
#'  simda2NA <- simmnar2(data = simda2,proba = missing_prob,cat_var = "x2",
#'  Y = "y", id = "id", ord_var = "x1", A = 1, B = 3)
#'
#'  simda2NA[102:108,]
#'
#'  summary(simda2NA)
#'


simmnar2 <- function(data, proba, cat_var, Y, id, ord_var, A, B) {

  # Preliminary checks
  if (!is.data.frame(data)) stop("`data` must be a dataframe.")
  if (!is.vector(proba) && !is.data.frame(proba) && !is.list(proba))
    stop("`proba` must be a list or dataframe with probabilities for each stratum.")
  if (!cat_var %in% names(data)) stop("The specified `cat_var` does not exist in the dataset.")
  if (!Y %in% names(data)) stop("The variable `Y` does not exist in the dataset.")
  if (!id %in% names(data)) stop("The variable `id` does not exist in the dataset.")
  if (!ord_var %in% names(data)) stop("The ordinal variable `ord_var` does not exist in the dataset.")

  # Create a copy of the ordinal variable for introducing missingness
  new_ord_var <- paste0(ord_var, ".mis")
  data[[new_ord_var]] <- data[[ord_var]]

  # Internal function for MNAR mechanism within a stratum
  mnar_by_strata <- function(sub_data, Y, id, new_ord_var, probA, probB, A, B) {
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
      stop("`proba` must be either a named list or dataframe.")
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
      B = B
    )
  })

  # Combine results from all strata
  return(do.call(rbind, result))
}
