#' Second Step for JOMO: Modify MAR imputations to plausible MNAR imputations
#'
#' This function modifies multiply imputed datasets obtained from `jomo`
#' under a MAR assumption, by applying threshold shifts and latent variable
#' modeling to create plausible MNAR scenarios.
#'
#' @param data A list of imputed datasets (each element a data.frame).
#' @param level_ord_var Integer. Number of levels of the ordinal variable.
#' @param formula A model formula for the ordinal regression.
#' @param manydelta A data.frame containing threshold adjustment vectors.
#' @param mean Mean of the normal noise to perturb the latent variable (default 0).
#' @param sd Standard deviation of the noise (default 1).
#' @param seed Optional seed for reproducibility.
#' @param verbose Logical. If TRUE, show progress messages.
#'
#' @return A list with:
#' \itemize{
#'   \item `mnardata`: the modified datasets (one per imputation)
#'   \item `zetaold`: original thresholds (zeta)
#'   \item `zetanew`: updated thresholds with applied deltas
#' }
#'
#' @export
secondstep_jomo <- function(data, level_ord_var, formula, manydelta,
                            mean = 0, sd = 1, seed = NULL, verbose = TRUE) {
  if (!is.null(seed)) set.seed(seed)

  M <- length(data)
  if (M < 1) stop("'data' must be a non-empty list of imputed datasets")
  if (!all(sapply(data, is.data.frame))) stop("Each element in 'data' must be a data frame.")
  if (!is.numeric(level_ord_var) || level_ord_var < 2) stop("`level_ord_var` must be an integer >= 2")
  if (!is.data.frame(manydelta)) stop("`manydelta` must be a data.frame")

  if (verbose) message("Fitting ordinal regression models on imputed data...")

  # Fit ordinal regressions
  ord.regression <- lapply(data, function(dat) {
    MASS::polr(formula = stats::as.formula(formula), method = "probit", Hess = TRUE, data = dat)
  })

  zeta <- sapply(ord.regression, function(model) as.numeric(model$zeta))
  dimnames(zeta) <- list(paste0("k", 1:(level_ord_var - 1)), paste0("m", 1:M))

  zetanew <- lapply(seq_len(ncol(manydelta)), function(l) zeta + manydelta[, l])

  if (verbose) message("Constructing latent variables and MNAR columns...")

  mnardata <- lapply(seq_len(M), function(m) {
    dat <- data[[m]]
    dat$eta <- as.numeric(ord.regression[[m]]$lp)
    dat$etanew <- dat$eta + stats::rnorm(nrow(dat), mean, sd)

    for (l in seq_len(ncol(manydelta))) {
      mnar_col <- paste0("mnar", l)
      dat[[mnar_col]] <- NA_integer_
      for (i in seq_len(nrow(dat))) {
        val <- NA
        for (k in seq_len(level_ord_var)) {
          if (k == 1) {
            if (dat$etanew[i] <= zetanew[[l]][1, m]) {
              val <- 1; break
            }
          } else if (k == level_ord_var) {
            if (dat$etanew[i] > zetanew[[l]][k - 1, m]) {
              val <- k; break
            }
          } else {
            if (dat$etanew[i] > zetanew[[l]][k - 1, m] && dat$etanew[i] <= zetanew[[l]][k, m]) {
              val <- k; break
            }
          }
        }
        dat[[mnar_col]][i] <- val
      }
      dat[[mnar_col]] <- ordered(dat[[mnar_col]], levels = seq_len(level_ord_var))
    }

    return(dat)
  })

  if (verbose) message("Done. Returning MNAR-adjusted datasets.")

  return(list(mnardata = mnardata, zetaold = zeta, zetanew = zetanew))
}
