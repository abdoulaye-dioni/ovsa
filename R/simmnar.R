#' Simulate a Missing Not At Random (MNAR) mechanism in the Non-Hierarchical data
#'
#' This function simulates a MNAR mechanism
#' by introducing missing values into an independent ordinal variable with
#' specific probabilities,  based on a binary response variable.
#'
#'
#' @name simmnar
#' @keywords MNAR,  missing data, Simulation,  Non-Hierarchical Context.
#' @param data A data.frame.
#' @param Y The name of the binary variable (0 or 1) used as a conditioning criterion.
#' @param id An optional vector of identifiers. If NULL, a sequential index is used.
#' @param ord_var The name of the ordinal variable where missing values will be introduced.
#' @param A The levels of \code{ord_var} affected by the Group A mechanism.
#' @param probA The probability of introducing missing values for observations in Group \code{A}.
#' @param B The levels of \code{ord_var} affected by the Group B mechanism.
#' @param probB The probability of introducing missing values for observations in Group \code{B}.
#'
#' @return A \code{data.frame} with a new column containing the modified \code{ord_var},
#'         now including missing values.
#'
#' @export
#' @examples
#' #  Example 1
#'
#' set.seed(123) # for reproducibility
#' simu <- data.frame(id = 1:1000,  Y = rbinom(1000, 1, 0.5),
#'           X1 = ordered(sample(1:5, 1000, replace = TRUE)),
#'           X2 = sample(letters[1:4], 1000, replace = TRUE))
#'
#' head(simu)
#'
#' simuNA <- simmnar( data = simu, Y = "Y",  id = "id", ord_var = "X1",
#'                          A = 1,  probA = 0.3, B = 5,  probB = 0.5)# use simmnar
#'
#' head(simuNA)
#'
#'
#'
#' #  Example 2
#'
#'#' set.seed(321) # for reproducibility
#' data("simda")
#' head(simda)
#' simdaNA <- simmnar( data = simda, Y = "Y",  id = "id",
#' ord_var = "X1", A = 2,  probA = 0.5, B = 4,  probB = 0.8) # use simmnar
#'
#' head(simdaNA)
#'
#' summary(simdaNA)


simmnar <-  function(data, Y, id = NULL, ord_var, A, probA, B, probB) {
  if (!is.data.frame(data)) stop("'data' must be a dataframe.")
  if (is.null(id)) {
    id <- seq_len(nrow(data))
  }
  if (!all(data[[Y]] %in% c(0, 1))) stop("'Y' must contain only 0 or 1.")
  if (!is.ordered(data[[ord_var]])) stop("'ord_var' must be an ordinal variable.")
  valid_levels <- levels(data[[ord_var]])
  if (is.null(valid_levels)) stop("'ord_var' must have defined levels.")
  if (!all(A %in% valid_levels)) stop("All elements of 'A' must be levels of 'ord_var'.")
  if (!all(B %in% valid_levels)) stop("All elements of 'B' must be levels of 'ord_var'.")
  if (!is.numeric(probA) || probA < 0 || probA > 1) {
    stop(sprintf("'probA' (%s) must be a numeric value between 0 and 1.", probA))
  }
  if (!is.numeric(probB) || probB < 0 || probB > 1) {
    stop("'probB' must be a numeric value between 0 and 1.")
  }
  if (anyNA(data[[ord_var]])) {
    warning("'ord_var' contains missing data. These missing values will be preserved.")
  }
  new_var_name <- paste0(ord_var, ".mis")
  data[[new_var_name]] <- data[[ord_var]]
  id.A <- which(data[[Y]] == 1 & data[[ord_var]] %in% A)
  if (length(id.A) > 0) {
    sample.A <- sample(id.A, size = round(length(id.A) * probA), replace = FALSE)
    data[[new_var_name]][sample.A] <- NA
  } else {
    warning("No individuals meet the criteria in category A.")
  }
  id.B <- which(data[[Y]] == 0 & data[[ord_var]] %in% B)
  if (length(id.B) > 0) {
    sample.B <- sample(id.B, size = round(length(id.B) * probB), replace = FALSE)
    data[[new_var_name]][sample.B] <- NA
  } else {
    warning("No individuals meet the criteria in category B.")
  }
  return(data)
}
