#' Calculated a confusion matrix
#'
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @return a data.frame of the confusion matrix.
#' @export
confusion_matrix <- function(observed, predicted) {
	if(length(unique(predicted)) > 2) {
		warning('Looks like predicted probabilities were provided. Dichotomizing at 0.5.')
		predicted <- predicted > 0.5
	}
	ct <- table(observed, predicted)
	pt <- prop.table(ct)
	result <- cbind(as.data.frame(ct), percent = as.data.frame(pt)[,3])
	class(result) <- c('confusionmatrix', 'data.frame')
	return(result)
}

#' @rdname confusion_matrix
#' @param x the result of [confusion_matrix()].
#' @param digits number of decimal places to print.
#' @param ... currently not used.
#' @method print confusionmatrix
#' @importFrom reshape2 dcast
#' @export
print.confusionmatrix <- function(x, digits = 2, ...) {
	class(x) <- 'data.frame'
	x$value <- paste0(
		x$Freq, ' (', formatC(100 * x$percent, digits = digits, flag = '0', format = 'f'), '%)'
	)
	x1 <- reshape2::dcast(x, observed ~ predicted, value.var = 'value')
	x2 <- reshape2::dcast(x, observed ~ predicted, value.var = 'percent')
	x1[,1] <- as.character(x1[,1])
	x1 <- cbind(c('Observed', ''), x1)
	x1 <- rbind(names(x1), x1)
	names(x1) <- c('', '', 'predicted', '')
	x1[1:2, 1] <- ''
	print(x1, row.names = FALSE, na.print = '')
	cat(paste0('Accuracy: ', round(100 * (x2[1,2] + x2[2,3]), digits = digits), '%'))
}

#' Provides the accuracy rate.
#'
#' This function provides the overall accuracy rate for the two vectors.
#'
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @return the accuracy as a numeric value.
#' @export
accuracy <- function(observed, predicted) {
	tab_out <- table(observed, predicted) |> prop.table()
	tab_out[1,1] + tab_out[2,2]
}
