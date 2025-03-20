#' Recode levels of a factor that are below a given threshold.
#'
#' This function will first calculate a contingency table. For any categories that are below
#' the specified `threshold`, the raw values in `x` will be recoded. The default is `NA`, but can
#' be specified by the `recode_to` parameter. The resulting vector will be converted to a factor
#' using the `factor()` function.
#'
#' @param x a vector.
#' @param recode_to the value to recode small factor levels to.
#' @param threshold the threshold of a factor level count for it to be recoded.
#' @param ... other parameters passed to `factor()`.
#' @return a recoded factor. The result will be a factor regardless of the type of `x`.
#' @export
#' @examples
#' data(mtacars)
#' table(mtcars$carb)
#' cbind(mtcars$carb, medley::recode_small_levels(mtcars$carb, threshold = 2))
recode_small_levels <- function(x, recode_to = NA, threshold = length(x) * 0.01, ...) {
	x <- as.character(x)
	tab <- table(x)
	small_lvls <- tab[tab < threshold]
	if(length(small_lvls) > 0) {
		x[x %in% names(small_lvls)] <- recode_to
	}
	if(!is.na(recode_to)) {
		recode_to_count <- sum(x == recode_to, na.rm = TRUE)
		if(recode_to_count > 0 & recode_to_count < threshold) {
			warning(paste0('There are ', recode_to_count, ' values equal to ', recode_to,
			' which is smaller than the specified threshold of ', threshold, '.'))
		}
	}
	x <- factor(x, ...)
	return(x)
}
