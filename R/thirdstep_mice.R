#' Perform Rubin's rule
#'
#' This function  performs either MAR (Missing At Random) or
#' MNAR (Missing Not At Random) analysis based on the provided inputs.
#' It fits generalized linear models (GLMs) with a logistic link function and
#' pools the results using the Rubin's rule.
#'
#' @param data A dataset in the format of a `mitml.list`, containing the imputed
#'  datasets.
#' @param formula A character string representing the model formula for MAR analysis.
#' Required if performing MAR analysis.
#' @param manydelta A data frame or matrix where each column represents a
#' variable to be used in MNAR analysis. Required if performing MNAR analysis.
#'
#' @return If `formula` is provided, returns the pooled model summary for the MAR analysis.
#'         If `manydelta` is provided, returns a list of pooled model summaries for the MNAR analysis.
#'
#' @details
#' - For MAR analysis, a single GLM is fitted using the specified formula.
#' - For MNAR analysis, a GLM is fitted for each variable in `manydelta`.
#'
#' @export
thirdstep_mice <- function(data, formula = NULL, manydelta = NULL) {
  # Convert the data into a format suitable for imputation analysis
  data <- mitml::as.mitml.list(data)

  # Check input arguments
  if (!is.null(formula) && !is.null(manydelta)) {
    stop("Provide either 'formula' for a MAR analysis or 'manydelta' for a MNAR analysis, not both.")
  }
  if (is.null(formula) && is.null(manydelta)) {
    stop("You must provide either 'formula' for a MAR analysis or 'manydelta' for a MNAR analysis.")
  }

  # Function to fit a MAR model
  mar_analysis <- function(data, formula) {
    # Validate that 'formula' is a valid string representation of a formula
    if (!is.character(formula) || length(formula) != 1) {
      stop("'formula' must be a character string representing a valid formula.")
    }
    # Fit the MAR model using the provided formula
    mar.mod <- with(data, glm(as.formula(formula), family = binomial(link = "logit")))
    # Pool the results and compute confidence intervals
    mar_est <- summary(mice::pool(mar.mod), conf.int = TRUE)
    return(mar_est)
  }

  # Function to fit MNAR models
  mnar_analysis <- function(data, manydelta) {
    # Validate that 'manydelta' is either a data frame or matrix
    if (!is.data.frame(manydelta) && !is.matrix(manydelta)) {
      stop("'manydelta' must be a data frame or a matrix.")
    }
    # Ensure that 'manydelta' has valid column names
    if (is.null(colnames(manydelta)) || any(colnames(manydelta) == "")) {
      stop("'manydelta' must have valid column names.")
    }

    # Fit MNAR models for each column in 'manydelta'
    mnar.mod <- lapply(paste0("mnar", 1:ncol(manydelta)), function(temp) {
      with(data, glm(formula = as.formula(paste("Y ~", temp, "+ X2")),
                     family = binomial(link = "logit")))
    })

    # Pool the results for each MNAR model and compute confidence intervals
    mnar_est <- lapply(mnar.mod, function(mod) {
      summary(mice::pool(mod), conf.int = TRUE)
    })
    # Assign meaningful names to the results
    names(mnar_est) <- paste0("mnar", 1:ncol(manydelta))
    return(mnar_est)
  }

  # Execute the appropriate analysis based on the provided arguments
  if (!is.null(formula)) {
    return(mar_analysis(data, formula)) # Perform MAR analysis
  }
  if (!is.null(manydelta)) {
    return(mnar_analysis(data, manydelta)) # Perform MNAR analysis
  }
}



