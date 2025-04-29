#' Simulate a Non-Hierarchical Dataset with a Binary Response
#'
#' @description
#' Generates a simulated dataset with an ordinal predictor and a binary outcome.
#' The covariate X2 is a factor based on alphabetic levels (e.g., a, b, c, ...),
#' and X1 is an ordered factor with user-specified levels.
#'
#' @param n Integer. Number of observations to simulate (default is 1000).
#' @param levels_X2 Integer. Number of levels for the X2 factor (default is 4).
#'                 Must be between 2 and 26.
#' @param levels_X1 Integer. Number of ordered levels for the X1 factor (default is 5).
#' @param seed Integer or NULL. Random seed for reproducibility (default is NULL).
#'
#' @return A `data.frame` with the following columns:
#' \describe{
#'   \item{id}{Integer identifier for each observation}
#'   \item{X2}{Factor variable with alphabetic levels (e.g., a, b, c, ...)}
#'   \item{X1}{Ordered factor with levels 1 < 2 < ...}
#'   \item{Y}{Binary factor representing the outcome (0 or 1)}
#' }
#'
#' @examples
#' # Simulate 1000 observations with 4 levels of X2 and 5 levels of X1
#' dat1 <- simulate_bin_nonhier(n = 1000, levels_X2 = 4, levels_X1 = 5, seed = 123)
#' head(dat1)
#'
#' # Data struture
#' str(dat1)
#' @export
  simulate_bin_nonhier <- function(levels_X2 = 4, levels_X1 = 5, n = 1000, seed = NULL) {
    if (!is.null(seed)) set.seed(seed)

    if (levels_X2 < 2) stop("levels_X2 must be at least 2.")
    if (levels_X1 < 2) stop("levels_X1 must be at least 2.")
    if (levels_X2 > 26) stop("Cannot have more than 26 levels for X2 with alphabet letters.")
    # 1) Generate X2 with alphabet letters
    X2_levels <- letters[1:levels_X2]
    X2 <- factor(
      sample(X2_levels, size = n, replace = TRUE),
      levels = X2_levels
    )
    # 2) Construct weight matrix
    weight_mat <- matrix(
      rep(seq(1, 2, length.out = levels_X1), times = levels_X2 - 1),
      nrow = levels_X2 - 1,
      byrow = TRUE
    )
    # 3) Compute X1 probabilities via softmax
    mm2     <- stats::model.matrix(~ X2)[, -1, drop = FALSE]
    linpred <- mm2 %*% weight_mat
    prob_X1 <- t(apply(linpred, 1, function(x) {
      ex <- exp(x - max(x))
      ex / sum(ex)
    }))
    # 4) Sample X1
    X1_num <- apply(prob_X1, 1, function(p) sample(seq_len(levels_X1), size = 1, prob = p))
    X1     <- factor(X1_num, levels = seq_len(levels_X1), ordered = TRUE)

    # 5) Generate binary response Y
    mm_out <- stats::model.matrix(~ X1 + X2)
    # Create automatic coefficients
    coefs <- rep(1, length(colnames(mm_out)))
    names(coefs) <- colnames(mm_out)
    coefs["(Intercept)"] <- -1.5
    # Calculate linear predictor and generate Y
    lp <- as.vector(mm_out %*% coefs)
    p  <- stats::plogis(lp)
    Y  <- factor(stats::rbinom(n, 1, prob = p), levels = 0:1)
    # 6) Assemble and return
    data.frame(
      id = seq_len(n),
      X2 = X2,
      X1 = X1,
      Y  = Y,
      stringsAsFactors = FALSE
    )
  }

