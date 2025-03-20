#' Contingency and proportional table as a character
#'
#' This is a wrapper to [base::table()] and [base::prop.table()] but returns the contingency and
#' proportional table as a single character string.
#'
#' @param x a factor.
#' @param digits number of digits for proportions.
#' @param useNA whether to include NA values in the table. See details in [base::table()].
#' @param sep separator between categories.
#' @return a character.
#' @export
#' @examples
#' data(mtcars)
#' crosstab(mtcars$am)
crosstab <- function(x, digits = 2, useNA = 'ifany', sep = '; ') {
	tab <- table(x, useNA = useNA)
	ptab <- round(prop.table(tab) * 100, digits = digits)
	paste0(
		paste0(names(tab), ': ', unname(tab), ' (', unname(ptab), '%)'),
		collapse = sep
	)
}
