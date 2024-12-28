#' Modifying the mice imputed data to reflect plausible scenarios under MNAR
#'
#' This function performs imputation of missing data in a dataset using either
#' the MICE or JOMO package, depending on the specified method. The MICE
#' package utilizes multiple imputation by chained equations, while JOMO employs
#' a multilevel imputation approach.
#'
#' @name secondstep
#' @param data A dataframe containing missing values to be imputed.
#' @param mardata Data imputed under MAR using the MICE package.
#' @param level_ord_var The number of ordinal variable levels.
#' @param manydelta A dataframe containing level_ord_var * p,
#' where p is the number of columns.
#' @param mean The mean of the normal distribution.
#' @param sd The standard deviation of the normal distribution.
#' @param formula A formula that will be used in the ordinal regression.
#' @param seed For reproducibility.
#' @param ... Additional arguments passed to the functions.
#' @return A dataframe that contains the modified data under the MNAR mechanism,
#' as well as the new intercept parameters and the old intercept parameters.
#'
#' @export
#'
#' @examples
#'
#' head(simdaNA)
#' str(simdaNA)
#'
#' imputed_mice <- firststep(simdaNA[, c("Y","X1.mis","X2")], mi = "mice",
#' method = c("logreg", "polr", "polyreg"), m = 10,printFlag = FALSE)
#'
#' library(mice)
#' summary(complete(imputed_mice,1))
#'
#'
#' # Formula for ordinal regression
#' formula <- "X1.mis.mar ~ Y + X2"
#' manydelta <- data.frame( delta1 = c(0,0,0,0), delta2 = c(0,1,2,0),
#' delta3 = c(1,0,0,2), delta4 = c(-1,0,0,-1))
#' level_ord_var = 5
#' seed = 123
#'
#' # Execution of the complete function
#' out <- secondstep( data = simdaNA, mardata = imputed_mice,
#' level_ord_var = level_ord_var, formula = formula, manydelta = manydelta,
#' seed = seed)
#'
#' summary(out$mnardata[[2]])
#'





secondstep <- function(data, mardata, level_ord_var, formula, manydelta,
                       mean = 0, sd = 1, seed = NULL, ...) {
  # Main function for ordinal regression and adding MNAR columns

  # Step 1: Checking and preparing imputed data
  set.seed(seed)
  if (!inherits(mardata, "mids")) stop("mardata must be a `mids` object from
the mice package.")
  M <- mardata[["m"]]

  # Identify variables with missing values within the initial data
  vars_with_na <- names(data)[sapply(data, function(col) anyNA(col))]

  # Prepare the imputed data, add missing columns, and rename the imputations
  mardata_list <- lapply(1:M, function(m) {
    imputed_data <- mice::complete(mardata, m)
    colnames(imputed_data) <- ifelse(
      colnames(imputed_data) %in% vars_with_na,
      paste0(colnames(imputed_data), ".mar"),
      colnames(imputed_data)
    )
    cbind(imputed_data, data[, vars_with_na, drop = FALSE])
  })

  # Ordinal Regression
  ord.regression <- lapply(mardata_list, function(imputation) {
    MASS::polr(stats::as.formula(formula), method = "probit", Hess = TRUE,
               data = imputation)
  })

  # Threshold extraction
  zeta <- sapply(ord.regression, function(ord_reg) as.numeric(ord_reg$zeta))
  dimnames(zeta) <- list(paste0("k", 1:(level_ord_var - 1)), paste0("m", 1:M))

  # Calculation of new adjusted thresholds
  zetanew <- lapply(seq_len(ncol(manydelta)), function(l) zeta + manydelta[, l])

  # Step 3: Adding MNAR columns and latent variable `etanew`
  mardata_list <- lapply(seq_along(mardata_list), function(m) {
    imp_data <- mardata_list[[m]]
    imp_data$eta <- as.numeric(ord.regression[[m]]$lp)
    imp_data$etanew <- imp_data$eta +stats::rnorm(nrow(imp_data), mean, sd)

    # Add MNAR columns for all ordinal variables containing missing values
    for (varname in vars_with_na) {
      if (is.ordered(data[[varname]])) {
        mnar_columns <- as.data.frame(
          replicate(
            ncol(manydelta),
            ordered(data[[varname]], levels = levels(data[[varname]])),
            simplify = FALSE
          )
        )
        colnames(mnar_columns) <- paste0("mnar", seq_len(ncol(manydelta)))
        imp_data <- cbind(imp_data, mnar_columns)
      } else {
        stop(paste("`", varname, "` must be an ordinal variable for this version.", sep = ""))
      }
    }
    return(imp_data)
  })

  # Step 4: Modifying data with `modified_mar`
  modified_mar <-  function(data, eta, zeta, manydelta, m, level_ord_var) {
    for (l in seq_len(ncol(manydelta))) {
      for (i in seq_along(eta)) {
        if (is.na(data[i, paste0("mnar", l)])) {
          for (level in seq_len(level_ord_var)) {
            # Vérifie les niveaux
            if (level == level_ord_var) {
              if (eta[i] > zeta[[l]][,m][level - 1]) {
                data[i, paste0("mnar", l)] <- level
              }
            } else if (level == 1) {
              if (eta[i] <= zeta[[l]][,m][level]) {
                data[i, paste0("mnar", l)] <- level
              }
            } else {
              if (eta[i] > zeta[[l]][,m][level - 1] && eta[i] <= zeta[[l]][,m][level]) {
                data[i, paste0("mnar", l)] <- level
              }
            }
          }
        }
      }
      # Fill missing values in with samples
      missing_indices <- is.na(data[, paste0("mnar", l)])
      if (any(missing_indices)) {
        data[missing_indices, paste0("mnar", l)] <- sample(
          data[!missing_indices, paste0("mnar", l)],
          sum(missing_indices),
          replace = TRUE
        )
      }
    }
    return(data)
  }

  mnardata <- lapply(seq_along(mardata_list), function(m) {
    modified_mar(
      data = mardata_list[[m]],
      eta = mardata_list[[m]]$etanew,
      zeta = zetanew,
      manydelta = manydelta,
      m = m,
      level_ord_var = level_ord_var
    )
  })

  # Return final results
  return(list(mnardata = mnardata, zetanew = zetanew, zetaold = zeta))
}
