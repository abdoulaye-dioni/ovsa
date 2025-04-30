#' Check the plausibility of imputed data under MAR and MNAR mechanisms
#'
#' @description
#'
#' This function computes and optionally plots the proportions of each level
#' of an ordinal variable under both MAR and MNAR mechanisms, based on multiple imputed datasets
#' modified through sensitivity parameters.
#'
#' @param data A list of data frames, where each data frame corresponds to an imputed dataset.
#' @param ord_mar Character string. Name of the ordinal variable imputed under the MAR assumption.
#' @param ord_mis Character string. Name of the original variable with missing values.
#' @param manydelta A data frame specifying the shifts applied to thresholds for different MNAR scenarios.
#' @param plot Logical. If \code{TRUE} (default), returns both the proportions table and a plot.
#' If \code{FALSE}, returns only the proportions table.
#'
#' @return If \code{plot = FALSE}, returns a table of proportions under MAR and MNAR mechanisms.
#' If \code{plot = TRUE}, returns a list containing:
#' \describe{
#'   \item{table}{A matrix of proportions (%) under MAR and MNAR for each level.}
#'   \item{plot}{A \code{ggplot2} object visualizing the proportions.}
#' }
#'
#' @details
#' The function calculates, for each level of the ordinal variable, the average proportion
#' across all imputations under MAR and under several MNAR scenarios defined via \code{manydelta}.
#' The plot provides a visual comparison of how the distributions differ across mechanisms.
#'
#' @examples
#' if (requireNamespace("ovsa", quietly = TRUE) && requireNamespace("mice", quietly = TRUE)) {
#'   data(simda, package = "ovsa")
#'
#'   # Simulate MNAR missingness
#'   simdaNA <- simmnar(data = simda, Y = "Y", ord_var = "X1",
#'                      A = 1, probA = 0.3, B = 5, probB = 0.5)
#'
#'   # Multiple imputation under MAR
#'   imputed_mice <- firststep(
#'     data = simdaNA[, c("Y", "X1.mis", "X2")],
#'     mi = "mice",
#'     method = c("logreg", "polr", "polyreg"),
#'     m = 5,
#'     printFlag = FALSE
#'   )
#'
#'   # Apply threshold shifts for MNAR scenarios
#'   formula <- "X1.mis ~ Y + X2"
#'   manydelta <- data.frame(
#'     delta1 = c(0, 0, 0, 0),
#'     delta2 = c(0, 1, 2, 0),
#'     delta3 = c(1, 0, 0, 2),
#'     delta4 = c(-1, 0, 0, -1)
#'   )
#'
#'   out <- secondstep_mice(
#'     data = simdaNA, mardata = imputed_mice,
#'     level_ord_var = 5, formula = formula,
#'     manydelta = manydelta, seed = 123
#'   )
#'
#'   # Check plausibility of MNAR modifications
#'   result <- checkprop(
#'     data = out$mnardata,
#'     ord_mar = "X1.mis.mar",
#'     ord_mis = "X1.mis",
#'     manydelta = manydelta
#'   )
#'   print(result$table)
#'   print(result$plot)
#' }
#'
#' @seealso \code{\link{secondstep}}, \code{\link{secondstep_mice}}
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point scale_color_brewer labs theme_minimal theme element_text
#' @importFrom utils globalVariables
#' @export
checkprop <- function(data, ord_mar, ord_mis, manydelta, plot = TRUE) {

  # Validate input arguments
  if (!is.list(data)) stop("'data' must be a list of data frames.")
  if (!all(sapply(data, is.data.frame))) stop("Each element in 'data' must be a data frame.")
  if (!is.character(ord_mar) || length(ord_mar) != 1) stop("'ord_mar' must be a single character string.")
  if (!is.character(ord_mis) || length(ord_mis) != 1) stop("'ord_mis' must be a single character string.")
  if (!is.data.frame(manydelta)) stop("'manydelta' must be a data frame.")
  if (!is.logical(plot) || length(plot) != 1) stop("'plot' must be a single logical value (TRUE or FALSE).")

  # Check that required columns exist
  required_columns <- c(ord_mar, ord_mis)
  if (!all(sapply(data, function(d) all(required_columns %in% colnames(d))))) {
    stop("All data frames in 'data' must contain the columns specified in 'ord_mar' and 'ord_mis'.")
  }

  # Internal function to compute proportions under MAR
  propmar <- function(data, ord_mar, ord_mis) {
    M <- length(data)
    matrices <- lapply(data, function(subset_data) {
      mar_values <- subset_data[[ord_mar]]
      mis_values <- subset_data[[ord_mis]]
      prop.table(table(mar_values[is.na(mis_values)])) * 100
    })
    Reduce("+", matrices) / M
  }

  # Internal function to compute proportions under MNAR
  propmnar <- function(data, l, ord_mis) {
    M <- length(data)
    matrices <- lapply(data, function(subset_data) {
      mnar_col <- paste0("mnar", l)
      if (!(mnar_col %in% colnames(subset_data))) {
        stop(paste("Column", mnar_col, "is not present in the data frame."))
      }
      mnar_values <- subset_data[[mnar_col]]
      mis_values <- subset_data[[ord_mis]]
      prop.table(table(mnar_values[is.na(mis_values)])) * 100
    })
    Reduce("+", matrices) / M
  }

  # Extract levels
  ord_mis_levels <- unique(unlist(lapply(data, function(d) levels(factor(d[[ord_mis]])))))
  n_levels <- length(ord_mis_levels)

  mytable <- matrix(
    NA,
    nrow = n_levels,
    ncol = 1 + ncol(manydelta),
    dimnames = list(ord_mis_levels, c("mar", paste0("mnar", seq_len(ncol(manydelta)))))
  )

  # Fill the table
  mytable[, "mar"] <- propmar(data, ord_mar, ord_mis)
  for (l in seq_len(ncol(manydelta))) {
    mytable[, paste0("mnar", l)] <- propmnar(data, l, ord_mis)
  }

  # Return the table if plot = FALSE
  if (!plot) {
    return(mytable)
  }

  # Prepare the plot
  data_long <- data.frame(
    Level = rep(seq_len(n_levels), times = ncol(mytable)),
    Proportion = as.vector(as.matrix(mytable)),
    Mechanism = rep(colnames(mytable), each = n_levels)
  )
  data_long$Level <- as.factor(data_long$Level)

  g <- ggplot2::ggplot(data_long, ggplot2::aes(x = Level, y = Proportion,
                                               group = Mechanism, color = Mechanism)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_color_brewer(palette = "Set1", name = "Mechanism") +
    ggplot2::labs(
      title = "Proportions under MAR and MNAR Mechanisms",
      x = "Levels",
      y = "Proportion (%)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      legend.position = "top"
    )

  # Return the table and the plot
  return(list(table = mytable, plot = g))
}

utils::globalVariables(c("Level", "Proportion", "Mechanism"))
