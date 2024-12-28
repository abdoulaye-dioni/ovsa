#' Check the plausibility of imputed data under MAR and MNAR Mechanisms.
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
#' the number of levels of the ordinal variable multiplied by \code{p}),
#' where \code{p} is the
#' number of columns representing different MNAR conditions.
#' @param plot A logical value. If `TRUE`, the function returns both the
#' proportion table and a plot.
#'             If `FALSE`, only the proportion table is returned.
#' @return A list with two elements:
#'   - \code{table} A matrix of calculated proportions under MAR and MNAR mechanisms.
#'   - \code{plot (Optional)} A ggplot2 object visualizing the proportions.
#'
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
#' library(ggplot2)
#' summary(complete(imputed_mice,1))
#'
#'
#' # Formula for ordinal regression
#' formula <- "X1.mis.mar ~ Y + X2"
#' manydelta <- data.frame( delta1 = c(0,0,0,0), delta2 = c(0,-1,2,0),
#' delta3 = c(0,0.5,0,0.5), delta4 = c(-1,0.5,0,1))
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
#'
#' checkprop(data = out$mnardata, ord_mar = "X1.mis.mar",
#'  ord_mis = "X1.mis", manydelta = manydelta)
#'
#'
checkprop <- function(data, ord_mar, ord_mis, manydelta, plot = TRUE) {
  # Validate input arguments
  if (!is.list(data)) stop("'data' must be a list of data frames.")
  if (!all(sapply(data, is.data.frame))) stop("Each element in 'data' must be a data frame.")
  if (!is.character(ord_mar) || length(ord_mar) != 1) stop("'ord_mar' must be a single character string.")
  if (!is.character(ord_mis) || length(ord_mis) != 1) stop("'ord_mis' must be a single character string.")
  if (!is.data.frame(manydelta)) stop("'manydelta' must be a data frame.")
  if (!is.logical(plot) || length(plot) != 1) stop("'plot' must be a single logical value (TRUE or FALSE).")

  # Check that required columns exist in all datasets
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

  # Extract levels of 'ord_mis' and initialize the result table
  ord_mis_levels <- unique(unlist(lapply(data, function(d) levels(factor(d[[ord_mis]])))))
  n_levels <- length(ord_mis_levels)

  mytable <- matrix(
    NA,
    nrow = n_levels,
    ncol = 1 + ncol(manydelta),
    dimnames = list(ord_mis_levels, c("mar", paste0("mnar", seq_len(ncol(manydelta)))))
  )

  # Fill the result table for MAR and MNAR
  mytable[, "mar"] <- propmar(data, ord_mar, ord_mis)
  for (l in seq_len(ncol(manydelta))) {
    mytable[, paste0("mnar", l)] <- propmnar(data, l, ord_mis)
  }

  # If plot = FALSE, return only the table
  if (!plot) {
    return(mytable)
  }

  # Prepare data for ggplot2
  data_long <- data.frame(
    Level = rep(seq_len(n_levels), times = ncol(mytable)),
    Proportion = as.vector(as.matrix(mytable)),
    Mechanism = rep(colnames(mytable), each = n_levels)
  )
  data_long$Level <- as.factor(data_long$Level)

  # Create the plot using ggplot2
  plot <- ggplot2::ggplot(data_long, ggplot2::aes(x = Level, y = Proportion, group = Mechanism, color = Mechanism)) +
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

  # Return both the table and the plot
  return(list(table = mytable, plot = plot))
}

utils::globalVariables(c("Level", "Proportion", "Mechanism"))

