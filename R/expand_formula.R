#' Utility function that will expand the formula if the independent variable(s)
#' are not full specified.
#'
#' This function will add all the independent variables to the formula if the
#' formula was specified as `y ~ .`.
#'
#' @param formula the formula to expand.
#' @param data the data.frame the formula will be applied to.
#' @return a formula with all independent variables specified explicitly.
expand_formula <- function(formula, data) {
	if(all.vars(formula)[2] == '.') {
		formula <- paste0(
			all.vars(formula)[1], ' ~ ', paste0(
				names(data)[!names(data) %in% all.vars(formula)[1]], collapse = ' + '
			)
		) |> formula()
	}
	return(formula)
}
