#' Simulate a Missing Not At Random (MNAR) Mechanism in Non-Hierarchical Data
#'
#' @description
#' This function introduces missing values into an ordinal variable based on
#' the response variable \code{Y} (binary), creating a MNAR mechanism with
#' specified probabilities.
#'
#' @param data A \code{data.frame} containing the data.
#' @param Y The name of the binary outcome variable (must contain 0 and 1 only).
#' @param ord_var The name of the ordinal variable where missingness is introduced.
#' @param A Levels of \code{ord_var} for which missingness is introduced when \code{Y == 1}.
#' @param probA Probability of missingness in group A (between 0 and 1).
#' @param B Levels of \code{ord_var} for which missingness is introduced when \code{Y == 0}.
#' @param probB Probability of missingness in group B (between 0 and 1).
#' @param verbose Logical. If \code{TRUE}, prints the number of introduced missing values (default = TRUE).
#'
#' @return A \code{data.frame} with a new column \code{<ord_var>.mis} containing missing values.
#'
#' @export
#'
#' @examples
#' if (requireNamespace("ovsa", quietly = TRUE)) {
#'   data(simda)
#'
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
#'   summary(simdaNA)
#' }
simmnar <- function(data, Y, ord_var, A, probA, B, probB, verbose = TRUE) {

  # Validate data
  if (!is.data.frame(data)) stop("'data' must be a data.frame.")
  if (!all(data[[Y]] %in% c(0, 1))) stop("'Y' must contain only 0 or 1.")
  if (!is.ordered(data[[ord_var]])) stop("'ord_var' must be an ordered factor.")

  # Validate probabilities
  if (!is.numeric(probA) || probA < 0 || probA > 1) {
    stop("'probA' must be a numeric value between 0 and 1.")
  }
  if (!is.numeric(probB) || probB < 0 || probB > 1) {
    stop("'probB' must be a numeric value between 0 and 1.")
  }

  # Validate levels
  valid_levels <- levels(data[[ord_var]])
  if (is.null(valid_levels)) stop("'ord_var' must have defined levels.")
  if (!all(as.character(A) %in% valid_levels)) {
    stop("All elements of 'A' must be among the levels of 'ord_var'.")
  }
  if (!all(as.character(B) %in% valid_levels)) {
    stop("All elements of 'B' must be among the levels of 'ord_var'.")
  }

  if (anyNA(data[[ord_var]])) {
    warning("'ord_var' already contains missing data. These will be preserved.")
  }

  # Create new variable
  new_var_name <- paste0(ord_var, ".mis")
  data[[new_var_name]] <- data[[ord_var]]

  # Group A
  id_A <- which(data[[Y]] == 1 & data[[ord_var]] %in% A)
  if (length(id_A) > 0) {
    n_A <- round(length(id_A) * probA)
    sampled_A <- sample(id_A, size = n_A, replace = FALSE)
    data[[new_var_name]][sampled_A] <- NA
  } else {
    warning("No observations meet the criteria for group A.")
  }

  # Group B
  id_B <- which(data[[Y]] == 0 & data[[ord_var]] %in% B)
  if (length(id_B) > 0) {
    n_B <- round(length(id_B) * probB)
    sampled_B <- sample(id_B, size = n_B, replace = FALSE)
    data[[new_var_name]][sampled_B] <- NA
  } else {
    warning("No observations meet the criteria for group B.")
  }

  if (verbose) {
    total_NA <- sum(is.na(data[[new_var_name]]))
    message(total_NA, " missing values introduced into ", new_var_name, ".")
  }

  return(data)
}
