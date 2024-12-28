#' Check the Plausibility of Imputed Data under MAR and MNAR Mechanisms
#'
#' This function calculates proportions for each level under MAR and MNAR of the ordinal
#' variable, computed across individuals initially missing for the specified variable.
#'
#' @name checkprop
#' @keywords missing-data, MAR, MNAR, proportions
#' @param data A list of data frames, where each data frame represents a dataset with
#' hierarchical or repeated measurements.
#' @param ord_mar A character string specifying the name of the ordinal variable
#' obtained under the MAR mechanism.
#' @param ord_mis A character string specifying the name of the ordinal variable
#' obtained under the MNAR mechanism.
#' @param manydelta A data frame containing a matrix with dimensions equal to
#' the number of levels of the ordinal variable multiplied by \(p\), where \(p\) is the
#' number of columns representing different MNAR conditions.
#' @return A matrix containing the MAR and MNAR proportions for each level of the ordinal
#' variable, computed across individuals initially missing for the specified variable.
#'
#'
#' @export
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
#
#' mytable <- checkprop( data = out$mnardata, ord_mar = "X1.mis.mar",
#'  ord_mis = "X1.mis", manydelta = manydelta)
#'
#'  print(mytable)

checkprop <- function(data, ord_mar, ord_mis, manydelta) {
  # Input validation
  if (!is.list(data)) stop("'data' must be a list.")
  if (!all(sapply(data, is.data.frame))) stop("Each element of 'data' must be a data.frame.")
  if (!is.character(ord_mar) || length(ord_mar) != 1) stop("'ord_mar' must be a single character string.")
  if (!is.character(ord_mis) || length(ord_mis) != 1) stop("'ord_mis' must be a single character string.")
  if (!is.data.frame(manydelta)) stop("'manydelta' must be a data.frame.")

  # Sub-function for MAR
  propmar <- function(data, ord_mar, ord_mis) {
    M <- length(data)
    matrices <- lapply(1:M, function(m) {
      subset_data <- data[[m]]

      # Check if columns exist
      if (!(ord_mar %in% colnames(subset_data)) || !(ord_mis %in% colnames(subset_data))) {
        stop(paste("The columns", ord_mar, "or", ord_mis, "are not present in the dataset."))
      }

      # Calculate conditional proportions
      mar_values <- subset_data[[ord_mar]]
      mis_values <- subset_data[[ord_mis]]
      prop.table(table(mar_values[is.na(mis_values)])) * 100
    })

    # Average proportions across matrices
    Reduce("+", matrices) / M
  }

  # Sub-function for MNAR
  propmnar <- function(data, l, ord_mis) {
    M <- length(data)
    matrices <- lapply(1:M, function(m) {
      subset_data <- data[[m]]
      mnar_col <- paste0("mnar", l)

      # Check if columns exist
      if (!(mnar_col %in% colnames(subset_data)) || !(ord_mis %in% colnames(subset_data))) {
        stop(paste("The columns", mnar_col, "or", ord_mis, "are not present in the dataset."))
      }

      # Calculate conditional proportions
      mnar_values <- subset_data[[mnar_col]]
      mis_values <- subset_data[[ord_mis]]
      prop.table(table(mnar_values[is.na(mis_values)])) * 100
    })

    # Average proportions across matrices
    Reduce("+", matrices) / M
  }

  # Initialize the results table
  ord_mis_levels <- unique(unlist(lapply(data, function(d) levels(factor(d[[ord_mis]])))))
  n_levels <- length(ord_mis_levels)

  mytable <- matrix(
    NA,
    nrow = n_levels,
    ncol = 1 + ncol(manydelta),
    dimnames = list(
      ord_mis_levels,
      c("mar", paste0("mnar", seq_len(ncol(manydelta))))
    )
  )

  # Populate the columns
  mytable[, "mar"] <- propmar(data, ord_mar, ord_mis)
  for (l in seq_len(ncol(manydelta))) {
    mytable[, paste0("mnar", l)] <- propmnar(data, l, ord_mis)
  }

  return(mytable)
}


