#' Modify MAR imputations to reflect plausible MNAR scenarios (mice version)
#'
#' This function modifies datasets initially imputed under a MAR assumption
#' using \code{mice}, to create plausible datasets under an MNAR mechanism
#' by shifting thresholds estimated in an ordinal regression model.
#'
#' @name secondstep_mice
#' @param data A \code{data.frame} containing the original dataset with missing values.
#' @param mardata A \code{mids} object (output from \code{mice}) representing MAR imputations.
#' @param level_ord_var Integer. Number of levels of the ordinal variable.
#' @param formula A model formula for the ordinal regression (e.g., \code{X1.mis ~ Y + X2}).
#' @param manydelta Optional. A \code{data.frame} containing adjustment vectors for thresholds. One column per MNAR scenario.
#' @param mean Mean of the normal perturbation added to the latent variable (default 0).
#' @param sd Standard deviation of the perturbation (default 1).
#' @param seed Optional integer for reproducibility.
#' @param verbose Logical. If \code{TRUE}, shows progress messages.
#' @param ... Additional arguments (currently unused).
#'
#' @return A list containing:
#' \describe{
#'   \item{mnardata}{List of modified datasets under MNAR.}
#'   \item{zetanew}{Adjusted thresholds incorporating \code{manydelta}.}
#'   \item{zetaold}{Original thresholds estimated under MAR.}
#' }
#'
#' @examples
#' if (requireNamespace("mice", quietly = TRUE) && requireNamespace("ovsa", quietly = TRUE)) {
#'   data(simda, package = "ovsa")
#'
#'   # Simulate MNAR missingness
#'   simdaNA <- simmnar(
#'     data = simda,
#'     Y = "Y",
#'     ord_var = "X1",
#'     A = 1,
#'     probA = 0.6,
#'     B = 5,
#'     probB = 0.7
#'   )
#'
#'   imputed_mice <- firststep(
#'     data = simdaNA[, c("Y", "X1.mis", "X2")],
#'     mi = "mice",
#'     method = c("logreg", "polr", "polyreg"),
#'     m = 10,
#'     printFlag = FALSE
#'   )
#'
#'   formula <- "X1.mis.mar ~ Y + X2"
#'   manydelta <- data.frame(delta1 = c(0, 0, 0, 0),
#'                            delta2 = c(-2, 1, 0, 3),
#'                            delta3 = c(1, 0, 0, 2),
#'                            delta4 = c(-1, 0, 0, -1))
#'   level_ord_var <- 5
#'
#'   out <- secondstep_mice(
#'     data = simdaNA,
#'     mardata = imputed_mice,
#'     level_ord_var = level_ord_var,
#'     formula = formula,
#'     manydelta = manydelta,
#'     seed = 123,
#'     sd=1.5,
#'     verbose = TRUE
#'   )
#'
#'   summary(out$mnardata[[1]])
#' }
#' @importFrom stats coef
#' @export
secondstep_mice <- function(data, mardata, level_ord_var, formula, manydelta,
                            mean = 0, sd = 1, seed = NULL, verbose = TRUE, ...) {

  if (!is.null(seed)) set.seed(seed)
  if (!inherits(mardata, "mids")) stop("`mardata` must be a `mids` object from the mice package.")
  if (!is.numeric(level_ord_var) || level_ord_var < 2) stop("`level_ord_var` must be >= 2.")

  M <- mardata$m
  vars_with_na <- names(data)[sapply(data, function(x) anyNA(x))]

  if (verbose) message("Preparing imputed datasets...")

  # Imputed datasets with MAR values renamed
  mardata_list <- lapply(1:M, function(m) {
    imp <- mice::complete(mardata, m)
    colnames(imp) <- ifelse(colnames(imp) %in% vars_with_na,
                            paste0(colnames(imp), ".mar"),
                            colnames(imp))
    cbind(imp, data[, vars_with_na, drop = FALSE])
  })

  if (verbose) message("Fitting ordinal regression models...")

  # Fit polr models
  ord.regression <- lapply(mardata_list, function(imp) {
    MASS::polr(stats::as.formula(formula), method = "probit", Hess = TRUE, data = imp)
  })

  if (verbose) message("Extracting and adjusting thresholds...")

  # Extract original zeta thresholds
  zeta <- sapply(ord.regression, function(mod) as.numeric(mod$zeta))
  dimnames(zeta) <- list(paste0("k", 1:(level_ord_var - 1)), paste0("m", 1:M))

  # Adjust thresholds
  zetanew <- lapply(seq_len(ncol(manydelta)), function(l) zeta + manydelta[, l])

  if (verbose) message("Constructing latent variables and MNAR columns...")

  # Recompute eta and assign MNAR levels
  X_vars <- all.vars(stats::terms(stats::as.formula(formula)))[-1]

  mnardata <- lapply(seq_len(M), function(m) {
    imp_data <- mardata_list[[m]]
    model <- ord.regression[[m]]

    # Design matrix for eta
    X <- model.matrix(stats::as.formula(paste("~", paste(X_vars, collapse = "+"))), data = imp_data)[, -1, drop = FALSE]
    beta <- coef(model)

    eta <- as.vector(X %*% beta)
    etanew <- eta + stats::rnorm(length(eta), mean, sd)

    imp_data$eta <- eta
    imp_data$etanew <- etanew

    # Recode MNAR variables
    for (varname in vars_with_na) {
      if (!is.ordered(data[[varname]])) stop(paste0("'", varname, "' must be an ordered factor."))

      for (l in seq_len(ncol(manydelta))) {
        mnar_col <- paste0("mnar", l)
        imp_data[[mnar_col]] <- NA_integer_

        thresholds <- c(zetanew[[l]][, m], Inf)

        for (i in seq_len(nrow(imp_data))) {
          if (!is.na(imp_data[[varname]][i])) {
            # Use MAR-imputed value directly
            imp_data[[mnar_col]][i] <- as.integer(imp_data[[paste0(varname, ".mar")]][i])
          } else {
            # Assign based on latent variable
            imp_data[[mnar_col]][i] <- which(etanew[i] <= thresholds)[1]
          }
        }
        imp_data[[mnar_col]] <- ordered(imp_data[[mnar_col]], levels = 1:level_ord_var)
      }
    }

    return(imp_data)
  })

  if (verbose) message("Done. Returning modified datasets.")

  return(list(mnardata = mnardata, zetanew = zetanew, zetaold = zeta))
}
