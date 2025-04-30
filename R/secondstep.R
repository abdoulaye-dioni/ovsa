#' Second Step: Apply MNAR Transformation to MAR-Imputed Data
#'
#' @description
#'
#' This function serves as a wrapper to apply a second imputation step under MNAR mechanisms.
#' It routes to the appropriate method-specific function depending on the imputation engine used
#' in the first step, either \code{"mice"} or \code{"jomo"}.
#'
#' @param data A data.frame (for \code{mice}) or a list of imputed datasets (for \code{jomo}).
#' @param mi Character string. Indicates the imputation method used: either \code{"mice"} or \code{"jomo"}.
#' @param ... Additional arguments passed to either \code{\link{secondstep_mice}} or \code{\link{secondstep_jomo}}.
#'
#' @return A list containing the MNAR-modified datasets and additional components
#' depending on the underlying method used (e.g., threshold matrices).
#'
#' @seealso \code{\link{secondstep_mice}}, \code{\link{secondstep_jomo}}
#' @export
secondstep <- function(data, mi = c("mice", "jomo"), ...) {
  mi <- match.arg(mi)

  if (mi == "mice") {
    return(secondstep_mice(data = data, ...))
  }

  if (mi == "jomo") {
    return(secondstep_jomo(data = data, ...))
  }
}
